#!/bin/bash

set +e

DOORMAT_PROJECT_NAME=jamiewright-test
SERVICE_ACCOUNT_NAME=jamiewright-cli

echo "Starting oauth workflow"

# Auth gcloud cli
gcloud auth login \
  --no-user-output-enabled



# Get google project Id from project name
PROJECT_ID=$(gcloud projects list --format=json | \
               jq -r '.[] | select(.name |contains('\"$DOORMAT_PROJECT_NAME\"')) | .projectId')

# Set the gcloud project to our project Id
gcloud config set project ${PROJECT_ID} \
  --no-user-output-enabled

# Check if service account already exists by this name
EXISTS=$(gcloud iam service-accounts list --format=json | \
           jq -r '.[] | select( .name |contains('\"$SERVICE_ACCOUNT_NAME\"')) | .name')

# Only create the service account if there isnt one that already exists by the same name
if [ -z "$EXISTS" ]; then

  echo "No existing service account called ${SERVICE_ACCOUNT_NAME} .. creating"
  gcloud iam service-accounts create ${SERVICE_ACCOUNT_NAME}

else

  echo "Service account already exists called ${SERVICE_ACCOUNT_NAME}"
  echo "Creating bind to existing service account called ${SERVICE_ACCOUNT_NAME}"

fi

# Bind this this service account to the role owner
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role=roles/owner \
  --no-user-output-enabled

# Create a directory to store the credentials in
mkdir -p ~/.credentials

# Save google credentials to disk called $SERVICE_ACCOUNT_NAME.json
gcloud iam service-accounts keys create \
  ~/.credentials/gcp-${SERVICE_ACCOUNT_NAME}.json \
  --iam-account=${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
  --no-user-output-enabled

# Save a version of the json file without new line characters for TFC
jq -r tostring ~/.credentials/gcp-${SERVICE_ACCOUNT_NAME}.json > ~/.credentials/gcp-${SERVICE_ACCOUNT_NAME}-tfc.json

# Output usage message to user
echo "########################################################################################"
echo ""
echo "   Run the following command to export these credentials to Terraform CLI"
echo ""
echo "   \$ export GOOGLE_APPLICATION_CREDENTIALS=~/.credentials/gcp-${SERVICE_ACCOUNT_NAME}.json"
echo ""
echo "   To use these credentials with TFC, save the contents of the following file to the "
echo "   workspace as an environment variable named GOOGLE_APPLICATION_CREDENTIALS"
echo "" 
echo "    -  ~/.credentials/gcp-${SERVICE_ACCOUNT_NAME}-tfc.json"
echo ""
echo "########################################################################################"


