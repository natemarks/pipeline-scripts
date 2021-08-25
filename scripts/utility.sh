#!/usr/bin/env bash
set -Eeuo pipefail

#######################################
# use assume role and set the temporary credentials
#######################################
function awsCreds() {
  local ACCOUNT="${1}"
  local ROLE_NAME="${2}"
  local SESSION_NAME="${3}"
  echo "## Assuming a role"
  creds=$(aws sts assume-role --role-arn "arn:aws:iam::${ACCOUNT}:role/${ROLE_NAME}" --role-session-name ${SESSION_NAME})
  export AWS_ACCESS_KEY_ID=$(echo "$creds" | jq -r .Credentials.AccessKeyId)
  export AWS_SECRET_ACCESS_KEY=$(echo "$creds "| jq -r .Credentials.SecretAccessKey)
  export AWS_SESSION_TOKEN=$(echo "$creds "| jq -r .Credentials.SessionToken)
  # echo "fetching credentials"
  # creds=$(aws-vault exec -j $VAULT_PROFILE)
  # export AWS_ACCESS_KEY_ID=$(echo "$creds" | jq -r .AccessKeyId)
  # export AWS_SECRET_ACCESS_KEY=$(echo "$creds" | jq -r .SecretAccessKey)
  # export AWS_SESSION_TOKEN=$(echo "$creds "| jq -r .SessionToken)
}

#######################################
# Clear the exported credentials
#######################################
function clearCreds() {
  echo "clearing credentials"
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN
}