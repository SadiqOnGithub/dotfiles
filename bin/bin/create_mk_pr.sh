#!/bin/bash

# Load environment variables
source /home/sadiq/.ssh/.mk_azure_env_for_pull_request

# Your repository name
REPO_NAME="MKFrontWebApp"

# Function to create a pull request
create_pull_request() {
  curl -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Basic $(echo -n :$AZURE_DEVOPS_TOKEN | base64)" \
    -d '{
             "sourceRefName": "refs/heads/moving",
             "targetRefName": "refs/heads/development",
             "title": "Automated merge moving into development",
             "description": "Automated pull request from moving to development"
         }' \
    "https://dev.azure.com/$AZURE_DEVOPS_ORG/$AZURE_DEVOPS_PROJECT/_apis/git/repositories/$REPO_NAME/pullrequests?api-version=6.0"
}

# Create the pull request
create_pull_request
