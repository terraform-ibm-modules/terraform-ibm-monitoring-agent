// Tests in this file are NOT run in the PR pipeline. They are run in the continuous testing pipeline along with the ones in pr_test.go
package test

import (
	"testing"

	"github.com/IBM/go-sdk-core/v5/core"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testaddons"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

// Adding this test to other_test.go as the DA tests in pr_test.go essentially cover the same test
func TestRunAgentVpcOcp(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  terraformDirMonitoringAgentROKS,
		Prefix:        "obs-agent-ocp",
		ResourceGroup: resourceGroup,
		Region:        validRegions[randInt(len(validRegions))],
		IgnoreUpdates: testhelper.Exemptions{ // Ignore for consistency check
			List: IgnoreUpdates,
		},
		CloudInfoService: sharedInfoSvc,
	})
	options.TerraformVars = map[string]any{
		"ocp_entitlement":         "cloud_pak",
		"prefix":                  options.Prefix,
		"resource_group":          resourceGroup,
		"existing_app_config_crn": permanentResources["app_config_crn"],
	}

	// Temp workaround for https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc?tab=readme-ov-file#the-specified-api-key-could-not-be-found
	createContainersApikey(t, options.Region, resourceGroup)

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestAgentDefaultConfiguration(t *testing.T) {
	t.Parallel()

	region := "eu-de"

	options := testaddons.TestAddonsOptionsDefault(&testaddons.TestAddonOptions{
		Testing:               t,
		Prefix:                "ma-def",
		QuietMode:             false,
		OverrideInputMappings: core.BoolPtr(true),
	})

	options.AddonConfig = cloudinfo.NewAddonConfigTerraform(
		options.Prefix,
		"deploy-arch-ibm-monitoring-agent",
		"fully-configurable",
		map[string]interface{}{
			"region":                       region,
			"existing_resource_group_name": resourceGroup,
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
		// Disable target / route creation to help prevent hitting quota in account
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

	// Temp workaround for https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc?tab=readme-ov-file#the-specified-api-key-could-not-be-found
	createContainersApikey(t, region, resourceGroup)

	err := options.RunAddonTest()
	require.NoError(t, err)
}
