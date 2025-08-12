// Tests in this file are NOT run in the PR pipeline. They are run in the continuous testing pipeline along with the ones in pr_test.go
package test

import (
	"math/rand/v2"
	"testing"

	"github.com/stretchr/testify/assert"
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
		Region:        validRegions[rand.IntN(len(validRegions))],
		IgnoreUpdates: testhelper.Exemptions{ // Ignore for consistency check
			List: IgnoreUpdates,
		},
		IgnoreAdds: testhelper.Exemptions{
			List: IgnoreAdds,
		},
		CloudInfoService: sharedInfoSvc,
	})
	options.TerraformVars = map[string]any{
		"ocp_entitlement": "cloud_pak",
		"prefix":          options.Prefix,
	}

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}
