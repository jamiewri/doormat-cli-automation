#!/usr/bin/env bash

# Required env args
args=(
  "TFC_ORGANIZATION_TOKEN"
  "TFC_ORGANIZATION"
  "DOORMAT_ACCOUNT"
)

# List of all AWS Demo workspaces
awsDemos=(
  "tfc-aws-network-dev"
  "tfc-aws-network-prod"
)

# Logging
LOG () {
  echo "`date "+%Y%m%d-%H%M%S"` $1: $2"
}

# Check for required env args
for i in ${args[@]}; do
  LOG "INFO" "Checking if the ${i} environment variable has been set."
  if [ ! -z "$(eval "echo \$$i")" ]; then
    LOG "INFO" "${i} environment variable was found."
  else
    LOG "${i} environment variable was NOT set. You must export/set the ${i} environment variable."
    LOG "FATAL" "Exiting."
    exit
  fi
done

# Test if doormat have a valid credential
doormat --smoke-test 2>&1 > /dev/null

if [ $? -eq 1 ]; then
  LOG "INFO" "Refreshing doormat credentials"
  doormat -r
else
  LOG "INFO" "Doormat credentials valid"
fi

# Get workspace ID by name
getWorkspaceIDFromName () {
  tecli workspace find-by-name --organization=${TFC_ORGANIZATION} --name="${1}" | jq .ID -r
}

#getWorkspacesContainTag () {
#  cat terraform.tfvars| hcl2json | jq '.workspaces[] | select(.tags[] | contains("dev"))'
#
#}

# Select which cloud provider
case $1 in 

  aws)
    LOG "INFO" "Starting AWS demos"

    for i in ${awsDemos[@]}; do
      LOG "INFO" "Pushing AWS credential to ${i}"
      doormat aws                                 \
        --tf-push                                 \
        --account ${DOORMAT_ACCOUNT}              \
        --tf-organization ${TFC_ORGANIZATION}     \
        --tf-workspace ${i}

      LOG "INFO" "Starting run for workspace ${i}"
      workspaceID=$(getWorkspaceIDFromName "${i}")
      tecli run create --workspace-id=${workspaceID} 2>&1 > /dev/null
    done
  ;;

  *)
    echo "Command not found"
  ;;
esac
