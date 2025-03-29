// Tests in this file are run in the PR pipeline
package test

import (
	"fmt"
	"math/rand/v2"
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
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"
)

const resourceGroup = "geretain-test-observability-agents"
const fullyConfigurableSolutionDir = "solutions/fully-configurable"
const fullyConfigurableSolutionKubeconfigDir = "solutions/fully-configurable/kubeconfig"
const terraformDirMonitoringAgentIKS = "examples/obs-agent-iks"
const terraformDirMonitoringAgentROKS = "examples/obs-agent-ocp"

var sharedInfoSvc *cloudinfo.CloudInfoService

// Currently only including regions that Event Notification support
var validRegions = []string{
	"au-syd",
	"eu-gb",
	"eu-de",
	"eu-es",
	"us-south",
}

// TestMain will be run before any parallel tests, used to set up a shared InfoService object to track region usage
// for multiple tests
func TestMain(m *testing.M) {
	sharedInfoSvc, _ = cloudinfo.NewCloudInfoServiceFromEnv("TF_VAR_ibmcloud_api_key", cloudinfo.CloudInfoServiceOptions{})

	os.Exit(m.Run())
}

func setupOptions(t *testing.T, prefix string, terraformDir string) *testhelper.TestOptions {

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  terraformDir,
		Prefix:        prefix,
		ResourceGroup: resourceGroup,
		IgnoreUpdates: testhelper.Exemptions{ // Ignore for consistency check
			List: []string{
				"module.monitoring_agent.helm_release.cloud_monitoring_agent",
			},
		},
		CloudInfoService: sharedInfoSvc,
	})

	// add ocp entitlement to keep costs down for tests
	if terraformDir == terraformDirMonitoringAgentROKS {
		options.TerraformVars["ocp_entitlement"] = "cloud_pak"
	}

	return options
}

func TestFullyConfigurableSolution(t *testing.T) {
	t.Parallel()

	var region = validRegions[rand.IntN(len(validRegions))]
	// ------------------------------------------------------------------------------------------------------
	// Deploy SLZ ROKS Cluster and Observability instances since it is needed to deploy Monitoring Agent
	// ------------------------------------------------------------------------------------------------------

	prefix := fmt.Sprintf("slz-%s", strings.ToLower(random.UniqueId()))
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
		assert.True(t, existErr == nil, "Init and Apply of temp resources (SLZ-ROKS and Observability Instances) failed")
	} else {

		options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
			Testing: t,
			Prefix:  "monitoring-agent",
			TarIncludePatterns: []string{
				"*.tf",
				"kubeconfig/*.*",
				"scripts/*.*",
				fullyConfigurableSolutionDir + "/*.*",
				fullyConfigurableSolutionKubeconfigDir + "/*.*",
			},
			IgnoreUpdates: testhelper.Exemptions{ // Ignore for consistency check
				List: []string{
					"module.monitoring_agent.helm_release.cloud_monitoring_agent",
				},
			},
			ResourceGroup:          resourceGroup,
			TemplateFolder:         fullyConfigurableSolutionDir,
			Tags:                   []string{"test-schematic"},
			DeleteWorkspaceOnFail:  false,
			WaitJobCompleteMinutes: 60,
			Region:                 region,
		})

		options.TerraformVars = []testschematic.TestSchematicTerraformVar{
			{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
			{Name: "cloud_monitoring_instance_region", Value: region, DataType: "string"},
			{Name: "cluster_id", Value: terraform.Output(t, existingTerraformOptions, "workload_cluster_id"), DataType: "string"},
			{Name: "cluster_resource_group_id", Value: terraform.Output(t, existingTerraformOptions, "cluster_resource_group_id"), DataType: "string"},
			{Name: "cloud_monitoring_access_key", Value: terraform.Output(t, existingTerraformOptions, "cloud_monitoring_access_key"), DataType: "string", Secure: true},
			{Name: "prefix", Value: options.Prefix, DataType: "string"},
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

	var region = validRegions[rand.IntN(len(validRegions))]

	// ------------------------------------------------------------------------------------------------------
	// Deploy SLZ ROKS Cluster and Observability instances since it is needed to deploy Monitoring Agent
	// ------------------------------------------------------------------------------------------------------

	prefix := fmt.Sprintf("slz-%s", strings.ToLower(random.UniqueId()))
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
		assert.True(t, existErr == nil, "Init and Apply of temp resources (SLZ-ROKS and Observability Instances) failed")
	} else {

		options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
			Testing: t,
			Prefix:  "monitoring-agent",
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
		})

		options.TerraformVars = []testschematic.TestSchematicTerraformVar{
			{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
			{Name: "cloud_monitoring_instance_region", Value: region, DataType: "string"},
			{Name: "cluster_id", Value: terraform.Output(t, existingTerraformOptions, "workload_cluster_id"), DataType: "string"},
			{Name: "cluster_resource_group_id", Value: terraform.Output(t, existingTerraformOptions, "cluster_resource_group_id"), DataType: "string"},
			{Name: "cloud_monitoring_access_key", Value: terraform.Output(t, existingTerraformOptions, "cloud_monitoring_access_key"), DataType: "string", Secure: true},
			{Name: "prefix", Value: options.Prefix, DataType: "string"},
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

	options := setupOptions(t, "obs-agent-iks", terraformDirMonitoringAgentIKS)
	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunAgentVpcOcp(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "obs-agent-roks", terraformDirMonitoringAgentROKS)
	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunAgentVpcOcpUpgrade(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "log-agent-upg", terraformDirMonitoringAgentROKS)

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}
