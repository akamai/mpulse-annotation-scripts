#!/bin/bash

# Defaults:
HOST=mpulse.soasta.com

usage()
{
cat << EOF
usage: $0 options

This script deletes an mPulse annotation.

OPTIONS:
   -h      Show this message
   -s      Override the mPulse server (default: $HOST)
   -a      Your mPulse API token
   -i      Annotation ID
EOF
}

while getopts "s:a:i:h" OPTION
do
  case $OPTION in
    h)
      usage
      exit 1
      ;;
    s)
      HOST=$OPTARG
      ;;
    a)
      API_TOKEN=$OPTARG
      ;;
    i)
      ANNOTATION_ID=$OPTARG
      ;;
    ?)
      usage
      exit 1
      ;;
  esac
done

which jq > /dev/null
if [ $? -ne 0 ]; then
  echo "The jq utility must be installed to run this script."
  echo "See https://stedolan.github.io/jq/"
  exit 1
fi

if [ -z "$API_TOKEN" ]; then
  echo "API token is required (use the -a parameter)."
  exit 1
fi
if [ -z "$ANNOTATION_ID" ]; then
  echo "Annotation ID is required (use the -i parameter)."
  exit 1
fi

credentials_json_file=$(mktemp)
cat > $credentials_json_file << EOF
{ "apiToken": "$API_TOKEN", "tenant": "$TENANT_NAME" }
EOF

token_json=$(curl --fail --silent --show-error -X PUT --data-binary @$credentials_json_file https://$HOST/concerto/services/rest/RepositoryService/v1/Tokens)
curl_result=$?
rm $credentials_json_file

if [ $curl_result -ne 0 ]; then
  echo "Failed to obtain a security token (curl exit code: $curl_result)."
  exit 1
fi

token_quoted=$(echo $token_json | jq .token)
token_raw=$(echo $token_quoted | sed 's/\"//g')

curl --fail --silent --show-error -H "X-Auth-Token: $token_raw" -X DELETE https://$HOST/concerto/mpulse/api/annotations/v1/$ANNOTATION_ID
curl_result=$?

if [ $curl_result -ne 0 ]; then
  echo "Failed to delete annotation (curl exit code: $curl_result)."
  exit 1
fi

# Clean up our security token
curl --fail --silent --show-error -X DELETE https://$HOST/concerto/services/rest/RepositoryService/v1/Tokens/$token_raw
