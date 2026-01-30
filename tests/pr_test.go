// Tests in this file are run in the PR pipeline
package test

import (
	"crypto/rand"
	"fmt"
	"log"
	"math/big"
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testaddons"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"
)

const resourceGroup = "geretain-test-observability-agents"
const fullyConfigurableSolutionDir = "solutions/fully-configurable"
const fullyConfigurableSolutionKubeconfigDir = "solutions/fully-configurable/kubeconfig"
const terraformDirMonitoringAgentIKS = "examples/obs-agent-iks"
const terraformDirMonitoringAgentROKS = "examples/obs-agent-ocp"

const terraformVersion = "terraform_v1.12.2" // This should match the version in the ibm_catalog.json
// Define a struct with fields that match the structure of the YAML data
const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"

var sharedInfoSvc *cloudinfo.CloudInfoService
var permanentResources map[string]interface{}

var validRegions = []string{
	"au-syd",
	"us-east",
	"eu-gb",
	"eu-de",
	"eu-es",
	"us-south",
	"jp-osa",
	"jp-tok",
	"br-sao",
	"ca-tor",
}

var IgnoreUpdates = []string{
	"module.monitoring_agent.helm_release.cloud_monitoring_agent",
}

// workaround for https://github.com/terraform-ibm-modules/terraform-ibm-scc-workload-protection/issues/243
var IgnoreAdds = []string{"module.scc_wp.restapi_object.cspm"}

// randInt returns a cryptographically secure random integer in the range [0, max)
func randInt(max int) int {
	n, err := rand.Int(rand.Reader, big.NewInt(int64(max)))
	if err != nil {
		log.Fatal(err)
	}
	return int(n.Int64())
}

// TestMain will be run before any parallel tests, used to set up a shared InfoService object to track region usage
// for multiple tests
func TestMain(m *testing.M) {
	var err error
	sharedInfoSvc, err = cloudinfo.NewCloudInfoServiceFromEnv("TF_VAR_ibmcloud_api_key", cloudinfo.CloudInfoServiceOptions{})
	if err != nil {
		log.Fatal(err)
	}

	permanentResources, err = common.LoadMapFromYaml(yamlLocation)
	if err != nil {
		log.Fatal(err)
	}

	os.Exit(m.Run())
}

func TestFullyConfigurableSolution(t *testing.T) {
	t.Parallel()

	var region = validRegions[randInt(len(validRegions))]
	// ------------------------------------------------------------------------------------------------------
	// Deploy OCP Cluster and Monitoring instance since it is needed to deploy agent
	// ------------------------------------------------------------------------------------------------------

	prefix := fmt.Sprintf("ocp-%s", strings.ToLower(random.UniqueId()))
	realTerraformDir := "./resources"
	tempTerraformDir, _ := files.CopyTerraformFolderToTemp(realTerraformDir, fmt.Sprintf(prefix+"-%s", strings.ToLower(random.UniqueId())))

	// Verify ibmcloud_api_key variable is set
	checkVariable := "TF_VAR_ibmcloud_api_key"
	val, present := os.LookupEnv(checkVariable)
	require.True(t, present, checkVariable+" environment variable not set")
	require.NotEqual(t, "", val, checkVariable+" environment variable is empty")

	logger.Log(t, "Tempdir: ", tempTerraformDir)
	existingTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tempTerraformDir,
		Vars: map[string]any{
			"prefix": prefix,
			"region": region,
		},
		// Set Upgrade to true to ensure latest version of providers and modules are used by terratest.
		// This is the same as setting the -upgrade=true flag with terraform.
		Upgrade: true,
	})

	terraform.WorkspaceSelectOrNew(t, existingTerraformOptions, prefix)
	_, existErr := terraform.InitAndApplyE(t, existingTerraformOptions)

	if existErr != nil {
		assert.True(t, existErr == nil, "Init and Apply of temp resources (SLZ-ROKS and Monitoring Instances) failed")
	} else {

		options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
			Testing: t,
			Prefix:  "mon-agent",
			TarIncludePatterns: []string{
				"*.tf",
				"kubeconfig/*.*",
				"scripts/*.*",
				fullyConfigurableSolutionDir + "/*.*",
				fullyConfigurableSolutionKubeconfigDir + "/*.*",
			},
			IgnoreUpdates: testhelper.Exemptions{ // Ignore for consistency check
				List: IgnoreUpdates,
			},
			ResourceGroup:          resourceGroup,
			TemplateFolder:         fullyConfigurableSolutionDir,
			Tags:                   []string{"test-schematic"},
			DeleteWorkspaceOnFail:  false,
			WaitJobCompleteMinutes: 60,
			Region:                 region,
			TerraformVersion:       terraformVersion,
		})
		options.TerraformVars = []testschematic.TestSchematicTerraformVar{
			{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
			{Name: "prefix", Value: options.Prefix, DataType: "string"},
			{Name: "cluster_id", Value: terraform.Output(t, existingTerraformOptions, "cluster_id"), DataType: "string"},
			{Name: "cluster_resource_group_id", Value: terraform.Output(t, existingTerraformOptions, "cluster_resource_group_id"), DataType: "string"},
			{Name: "instance_crn", Value: terraform.Output(t, existingTerraformOptions, "instance_crn"), DataType: "string", Secure: true},
			{Name: "access_key", Value: terraform.Output(t, existingTerraformOptions, "access_key"), DataType: "string", Secure: true},
			{Name: "priority_class_name", Value: "sysdig-daemonset-priority", DataType: "string"},
		}

		err := options.RunSchematicTest()
		assert.Nil(t, err, "This should not have errored")
	}

	// Check if "DO_NOT_DESTROY_ON_FAILURE" is set
	envVal, _ := os.LookupEnv("DO_NOT_DESTROY_ON_FAILURE")
	// Destroy the temporary existing resources if required
	if t.Failed() && strings.ToLower(envVal) == "true" {
		fmt.Println("Terratest failed. Debug the test and delete resources manually.")
	} else {
		logger.Log(t, "START: Destroy (existing resources)")
		terraform.Destroy(t, existingTerraformOptions)
		terraform.WorkspaceDelete(t, existingTerraformOptions, prefix)
		logger.Log(t, "END: Destroy (existing resources)")
	}
}

func TestFullyConfigurableUpgradeSolution(t *testing.T) {
	t.Parallel()

	var region = validRegions[randInt(len(validRegions))]

	// ------------------------------------------------------------------------------------------------------
	// Deploy OCP Cluster and Monitoring instance since it is needed to deploy agent
	// ------------------------------------------------------------------------------------------------------

	prefix := fmt.Sprintf("ocp-%s", strings.ToLower(random.UniqueId()))
	realTerraformDir := "./resources"
	tempTerraformDir, _ := files.CopyTerraformFolderToTemp(realTerraformDir, fmt.Sprintf(prefix+"-%s", strings.ToLower(random.UniqueId())))

	// Verify ibmcloud_api_key variable is set
	checkVariable := "TF_VAR_ibmcloud_api_key"
	val, present := os.LookupEnv(checkVariable)
	require.True(t, present, checkVariable+" environment variable not set")
	require.NotEqual(t, "", val, checkVariable+" environment variable is empty")

	logger.Log(t, "Tempdir: ", tempTerraformDir)
	existingTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tempTerraformDir,
		Vars: map[string]any{
			"prefix": prefix,
			"region": region,
		},
		// Set Upgrade to true to ensure latest version of providers and modules are used by terratest.
		// This is the same as setting the -upgrade=true flag with terraform.
		Upgrade: true,
	})

	terraform.WorkspaceSelectOrNew(t, existingTerraformOptions, prefix)
	_, existErr := terraform.InitAndApplyE(t, existingTerraformOptions)

	if existErr != nil {
		assert.True(t, existErr == nil, "Init and Apply of temp resources (SLZ-ROKS and Monitoring Instances) failed")
	} else {

		options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
			Testing: t,
			Prefix:  "mon-agent",
			TarIncludePatterns: []string{
				"*.tf",
				"kubeconfig/*.*",
				"scripts/*.*",
				fullyConfigurableSolutionDir + "/*.*",
				fullyConfigurableSolutionKubeconfigDir + "/*.*",
			},
			ResourceGroup:          resourceGroup,
			TemplateFolder:         fullyConfigurableSolutionDir,
			Tags:                   []string{"test-schematic"},
			DeleteWorkspaceOnFail:  false,
			WaitJobCompleteMinutes: 60,
			Region:                 region,
			IgnoreUpdates: testhelper.Exemptions{ // Ignore for consistency check
				List: IgnoreUpdates,
			},
			TerraformVersion:           terraformVersion,
			CheckApplyResultForUpgrade: true,
		})

		options.TerraformVars = []testschematic.TestSchematicTerraformVar{
			{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
			{Name: "prefix", Value: options.Prefix, DataType: "string"},
			{Name: "cluster_id", Value: terraform.Output(t, existingTerraformOptions, "cluster_id"), DataType: "string"},
			{Name: "cluster_resource_group_id", Value: terraform.Output(t, existingTerraformOptions, "cluster_resource_group_id"), DataType: "string"},
			{Name: "instance_crn", Value: terraform.Output(t, existingTerraformOptions, "instance_crn"), DataType: "string", Secure: true},
			{Name: "access_key", Value: terraform.Output(t, existingTerraformOptions, "access_key"), DataType: "string", Secure: true},
		}

		err := options.RunSchematicUpgradeTest()
		assert.Nil(t, err, "This should not have errored")
	}

	// Check if "DO_NOT_DESTROY_ON_FAILURE" is set
	envVal, _ := os.LookupEnv("DO_NOT_DESTROY_ON_FAILURE")
	// Destroy the temporary existing resources if required
	if t.Failed() && strings.ToLower(envVal) == "true" {
		fmt.Println("Terratest failed. Debug the test and delete resources manually.")
	} else {
		logger.Log(t, "START: Destroy (existing resources)")
		terraform.Destroy(t, existingTerraformOptions)
		terraform.WorkspaceDelete(t, existingTerraformOptions, prefix)
		logger.Log(t, "END: Destroy (existing resources)")
	}
}

func TestRunAgentVpcKubernetes(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  terraformDirMonitoringAgentIKS,
		Prefix:        "obs-agent-vpc-iks",
		Region:        validRegions[randInt(len(validRegions))],
		ResourceGroup: resourceGroup,
		IgnoreUpdates: testhelper.Exemptions{ // Ignore for consistency check
			List: IgnoreUpdates,
		},
		IgnoreAdds: testhelper.Exemptions{
			List: IgnoreAdds,
		},
		CloudInfoService: sharedInfoSvc,
	})
	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunAgentClassicKubernetes(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  terraformDirMonitoringAgentIKS,
		Prefix:        "obs-agent-iks",
		Region:        validRegions[randInt(len(validRegions))],
		ResourceGroup: resourceGroup,
		IgnoreUpdates: testhelper.Exemptions{ // Ignore for consistency check
			List: IgnoreUpdates,
		},
		IgnoreAdds: testhelper.Exemptions{
			List: IgnoreAdds,
		},
		CloudInfoService: sharedInfoSvc,
	})
	options.TerraformVars = map[string]any{
		"resource_group": resourceGroup,
		"datacenter":     "syd01",
		"prefix":         options.Prefix,
	}

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestAgentDefaultConfiguration(t *testing.T) {

	t.Parallel()

	options := testaddons.TestAddonsOptionsDefault(&testaddons.TestAddonOptions{
		Testing:   t,
		Prefix:    "ma-def",
		QuietMode: false,
	})

	options.AddonConfig = cloudinfo.NewAddonConfigTerraform(
		options.Prefix,
		"deploy-arch-ibm-monitoring-agent",
		"fully-configurable",
		map[string]interface{}{
			"region": "eu-de",
		},
	)

	options.AddonConfig.Dependencies = []cloudinfo.AddonConfig{
		//	use existing secrets manager instance to help prevent hitting trial instance limit in account
		{
			OfferingName:   "deploy-arch-ibm-secrets-manager",
			OfferingFlavor: "fully-configurable",
			Inputs: map[string]interface{}{
				"existing_secrets_manager_crn":         permanentResources["privateOnlySecMgrCRN"],
				"service_plan":                         "__NULL__", // no plan value needed when using existing SM
				"skip_secrets_manager_iam_auth_policy": true,       // since using an existing Secrets Manager instance, attempting to re-create auth policy can cause conflicts if the policy already exists
				"secret_groups":                        []string{}, // passing empty array for secret groups as default value is creating general group and it will cause conflicts as we are using an existing SM
			},
		},
		// // Disable target / route creation to help prevent hitting quota in account
		{
			OfferingName:   "deploy-arch-ibm-cloud-monitoring",
			OfferingFlavor: "fully-configurable",
			Inputs: map[string]interface{}{
				"enable_metrics_routing_to_cloud_monitoring": false,
			},
		},
		{
			OfferingName:   "deploy-arch-ibm-activity-tracker",
			OfferingFlavor: "fully-configurable",
			Inputs: map[string]interface{}{
				"enable_activity_tracker_event_routing_to_cloud_logs": false,
			},
		},
	}

	err := options.RunAddonTest()
	require.NoError(t, err)
}
