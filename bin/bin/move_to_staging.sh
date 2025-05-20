#!/bin/bash

# Load environment variables
source /home/sadiq/.ssh/.mk_azure_env_for_pull_request

# Function to create a pull request
create_pull_request() {
  local repo=$1
  local source_branch=$2
  local target_branch=$3

  curl -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Basic $(echo -n :$AZURE_DEVOPS_TOKEN | base64)" \
    -d "{
             \"sourceRefName\": \"refs/heads/$source_branch\",
             \"targetRefName\": \"refs/heads/$target_branch\",
             \"title\": \"Merge $source_branch into $target_branch\",
             \"description\": \"Automated pull request\"
         }" \
    "https://dev.azure.com/$AZURE_DEVOPS_ORG/$AZURE_DEVOPS_PROJECT/_apis/git/repositories/$repo/pullrequests?api-version=6.0"
}

# List of repositories
repos=("MKAdminAPI" "MKFrontAPI" "MKAdminWebApp" "MKFrontWebApp")

# Create pull requests for each repository
for repo in "${repos[@]}"; do
  create_pull_request "$repo" "development" "staging"
done
