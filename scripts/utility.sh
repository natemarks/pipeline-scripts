#!/usr/bin/env bash

#######################################
# use assume role and set the temporary credentials
#######################################
function assumeRole() {
  local ACCOUNT="${1}"
  local ROLE_NAME="${2}"
  local SESSION_NAME="${3}"
  echo "## Assuming a role"
  creds=$(aws sts assume-role --role-arn "arn:aws:iam::${ACCOUNT}:role/${ROLE_NAME}" --role-session-name "${SESSION_NAME}")
  AWS_ACCESS_KEY_ID=$(echo "$creds" | jq -r .Credentials.AccessKeyId)
  export AWS_ACCESS_KEY_ID
  AWS_SECRET_ACCESS_KEY=$(echo "$creds "| jq -r .Credentials.SecretAccessKey)
  export AWS_SECRET_ACCESS_KEY
  AWS_SESSION_TOKEN=$(echo "$creds "| jq -r .Credentials.SessionToken)
  export AWS_SESSION_TOKEN
  # echo "fetching credentials"
  # creds=$(aws-vault exec -j $VAULT_PROFILE)
  # export AWS_ACCESS_KEY_ID=$(echo "$creds" | jq -r .AccessKeyId)
  # export AWS_SECRET_ACCESS_KEY=$(echo "$creds" | jq -r .SecretAccessKey)
  # export AWS_SESSION_TOKEN=$(echo "$creds "| jq -r .SessionToken)
}


#######################################
# Sets the AWS credentials from a given secret assuming the JSON keys are AWSAccessKeyID and AWSSecretAccessKey
# respectively
# This informal standard is used in the https://github.com/natemarks/easyaws project to store the test user credentials
#######################################
function credsFromSecretManager() {
  local SECRET_NAME="${1}"
  creds=$(aws secretsmanager get-secret-value --secret-id "${SECRET_NAME}" --query SecretString --output text)
  AWS_ACCESS_KEY_ID=$(echo "$creds" | jq -r .AWSAccessKeyID)
  export AWS_ACCESS_KEY_ID
  AWS_SECRET_ACCESS_KEY=$(echo "$creds "| jq -r .AWSSecretAccessKey)
  export AWS_SECRET_ACCESS_KEY
}


#######################################
# Extract a JSON value from a given key to a text file
# The functions uses 'r' to convert \n to newline, \t to tab, etc
# Usage:
# JSONKeyToFile  my_data.json  \
# my_data.json.userdata.sh \
# '.Resources.lc.Properties.UserData."Fn::Base64"'

#######################################
function JSONKeyToFile() {
  local JSON_FILE="${1}"
  local OUTPUT_FILE="${2}"
  local JSON_KEY="${3}"

  jq -r "$JSON_KEY" "${JSON_FILE}" > "${OUTPUT_FILE}"
}


#######################################
# Dump the contents of a text file to a JSON value given the target jey
# FileToJSONValue my_data.json \
# my_text_file.txt \
# '.Resources.lc.Properties.UserData."Fn::Base64"'

#######################################
function FileToJSONValue() {
  local JSON_FILE="${1}"
  local JSON_TMP="${JSON_FILE}.tmp.json"
  local VALUE_FILE="${2}"
  local JSON_KEY="${3}"
  declare VALUE
  VALUE="$(cat "${VALUE_FILE}")"

  jq --arg vv "$VALUE" "$JSON_KEY"' = $vv'  "${JSON_FILE}" > "${JSON_TMP}"
  cp -f "${JSON_TMP}" "${JSON_FILE}"
  rm -f "${JSON_TMP}"
}
