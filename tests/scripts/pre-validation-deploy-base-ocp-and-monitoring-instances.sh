#! /bin/bash

############################################################################################################
## This script is used by the catalog pipeline to deploy the OCP and Monitoring instances,
## which are the prerequisites for the Monitoring Agent DA.
############################################################################################################

set -e

DA_DIR="solutions/fully-configurable"
TERRAFORM_SOURCE_DIR="tests/resources"
JSON_FILE="${DA_DIR}/catalogValidationValues.json"
REGION="us-south"
TF_VARS_FILE="terraform.tfvars"

(
  cwd=$(pwd)
  cd ${TERRAFORM_SOURCE_DIR}
  echo "Provisioning prerequisite OCP cluster and Monitoring Instance .."
  terraform init || exit 1
  # $VALIDATION_APIKEY is available in the catalog runtime
  {
    echo "ibmcloud_api_key=\"${VALIDATION_APIKEY}\""
    echo "region=\"${REGION}\""
    echo "prefix=\"ocp-$(openssl rand -hex 2)\""
  } >> ${TF_VARS_FILE}
  terraform apply -input=false -auto-approve -var-file=${TF_VARS_FILE} || exit 1

  cluster_id_var_name="cluster_id"
  cluster_id_value=$(terraform output -state=terraform.tfstate -raw cluster_id)
  cluster_resource_group_id_var_name="cluster_resource_group_id"
  cluster_resource_group_id_value=$(terraform output -state=terraform.tfstate -raw cluster_resource_group_id)
  cloud_monitoring_instance_region_var_name="cloud_monitoring_instance_region"
  access_key_var_name="access_key"
  access_key_value=$(terraform output -state=terraform.tfstate -raw access_key)

  echo "Appending '${cluster_id_var_name}', '${cluster_resource_group_id_var_name}', '${cloud_monitoring_instance_region_var_name}' and '${access_key_var_name}' input variable values to ${JSON_FILE}.."

  cd "${cwd}"
  jq -r --arg cluster_id_var_name "${cluster_id_var_name}" \
        --arg cluster_id_value "${cluster_id_value}" \
        --arg cluster_resource_group_id_var_name "${cluster_resource_group_id_var_name}" \
        --arg cluster_resource_group_id_value "${cluster_resource_group_id_value}" \
        --arg access_key_var_name "${access_key_var_name}" \
        --arg access_key_value "${access_key_value}" \
        --arg cloud_monitoring_instance_region_var_name "${cloud_monitoring_instance_region_var_name}" \
        --arg cloud_monitoring_instance_region_var_value "${REGION}" \
        '. + {($cluster_id_var_name): $cluster_id_value, ($cluster_resource_group_id_var_name): $cluster_resource_group_id_value, ($cloud_monitoring_instance_region_var_name): $cloud_monitoring_instance_region_var_value, ($access_key_var_name): $access_key_value}' "${JSON_FILE}" > tmpfile && mv tmpfile "${JSON_FILE}" || exit 1

  echo "Pre-validation complete successfully"
)
