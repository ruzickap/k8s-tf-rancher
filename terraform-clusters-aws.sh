#!/usr/bin/env bash

get_variable_from_group_cluster_tfvars () {
  local CLUSTER_PATH="$1" TF_CODE_VARIABLE="$2" VARIABLE_HELPER

  if grep -q "${TF_CODE_VARIABLE}" "${CLUSTER_PATH}/cluster-variables.tfvars" ; then
    VARIABLE_HELPER=$(awk -F \" "/^${TF_CODE_VARIABLE}/ { print \$2 }" "${CLUSTER_PATH}/cluster-variables.tfvars")
  else
    VARIABLE_HELPER=$(awk -F \" "/^${TF_CODE_VARIABLE}/ { print \$2 }" "${CLUSTER_PATH}/../group-variables.tfvars")
  fi
  export "${TF_CODE_VARIABLE^^}"="${VARIABLE_HELPER}"
  echo "export ${TF_CODE_VARIABLE^^}=\"${VARIABLE_HELPER}\""
}

##############
# Main
##############

set -euo pipefail

CLUSTER_PATH=$(find ./clusters -type d -regextype "posix-extended" -regex ".*/${1}\$.*")
echo -e "\n🍏 Cluster path: ${CLUSTER_PATH}\n"

echo "# ---------------------------------------------------"

echo "export CLUSTER_PATH=\"${CLUSTER_PATH}\""
get_variable_from_group_cluster_tfvars "${CLUSTER_PATH}" "aws_default_region"
get_variable_from_group_cluster_tfvars "${CLUSTER_PATH}" "cluster_fqdn"
get_variable_from_group_cluster_tfvars "${CLUSTER_PATH}" "cluster_name"
get_variable_from_group_cluster_tfvars "${CLUSTER_PATH}" "terraform_code_dir"
get_variable_from_group_cluster_tfvars "${CLUSTER_PATH}" "rancher_api_url"

echo -e "\n# ------------- Secrets - must be ADDED !!! -------------\n"

cat << \EOF
export RANCHER_ADMIN_PASSWORD=${MY_PASSWORD}
### export AWS_ACCESS_KEY_ID='<secrets belongs to AWS_ACCESS_KEY_ID>
### export AWS_SECRET_ACCESS_KEY='<secrets belongs to AWS_SECRET_ACCESS_KEY>'
EOF

echo -e "\n# ------------------------ Code -------------------------"

cat << \EOF
LOGIN_TOKEN=$( curl -k -s "${RANCHER_API_URL}/v3-public/localProviders/local?action=login" -H 'content-type: application/json' --data-binary "{\"username\":\"admin\",\"password\":\"${RANCHER_ADMIN_PASSWORD}\"}" | jq -r .token )
TF_VAR_rancher_token_key=$( curl -k -s "${RANCHER_API_URL}/v3/token" -H 'Content-Type: application/json' -H "Authorization: Bearer ${LOGIN_TOKEN}" --data-binary "{\"type\":\"token\",\"description\":\"Rancher Token used by ${USER}@$(hostname)\", \"ttl\": 43200000}" | jq -r '.token' )
export TF_VAR_rancher_token_key

aws cloudformation deploy \
  --parameter-overrides "ClusterFQDN=${CLUSTER_FQDN}" \
  --stack-name "${CLUSTER_FQDN//./-}-s3-dynamodb-tfstate" --template-file "./cloudformation/s3-dynamodb-tfstate.yaml"

terraform -chdir="${TERRAFORM_CODE_DIR}" init \
  -backend-config="bucket=${CLUSTER_FQDN}" \
  -backend-config="key=terraform-${CLUSTER_FQDN}.tfstate" \
  -backend-config="region=${AWS_DEFAULT_REGION}" \
  -backend-config="dynamodb_table=${CLUSTER_FQDN}"

terraform -chdir="${TERRAFORM_CODE_DIR}" plan \
  -var-file="${PWD}/${CLUSTER_PATH}/../../main-variables.tfvars" \
  -var-file="${PWD}/${CLUSTER_PATH}/../group-variables.tfvars" \
  -var-file="${PWD}/${CLUSTER_PATH}/cluster-variables.tfvars"
EOF
