#!/bin/bash

# Defaults:
HOST=mpulse.soasta.com

usage()
{
cat << EOF
usage: $0 options

This script creates an mPulse annotation.

OPTIONS:
   -h      Show this message
   -s      Override the mPulse server (default: $HOST)
   -a      Your mPulse API token
   -n      Override the mPulse tenant name
   -t      Annotation title
   -b      Annotation body
   -d      Domain ID list (comma-separated)
   -m      Override the timestamp in epoch millis (defaults to now)
EOF
}

validTimestamp()
{
  timestamp_ms="$1"

  # First, check if it's numeric.
  if ! [[ "$timestamp_ms" =~ ^[0-9]+$ ]]; then
    # It's not numeric.

    echo "$timestamp_ms is not a valid timestamp (must be epoch millis)."
    return 1
  else
    # It's numeric.

    # Make sure it's a reasonable value (after 2/1/2012).
    # In particular, this catches epoch seconds vs millis.
    if (( $timestamp_ms < 1328054400000 )); then
      echo "$timestamp_ms is not a valid timestamp (looks too small, are you sure you used millis?)"
      return 1
    fi
  fi

  # In Bash, 0 is true, not false.
  # See http://stackoverflow.com/questions/5431909/bash-functions-return-boolean-to-be-used-in-if.
  return 0
}

while getopts "s:a:t:n:b:d:m:h" OPTION
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
    t)
      ANNOTATION_TITLE=$OPTARG
      ;;
    b)
      ANNOTATION_BODY=$OPTARG
      ;;
    d)
      DOMAIN_IDS=$OPTARG
      ;;
    n)
      TENANT_NAME=$OPTARG
      ;;
    m)
      ANNOTATION_TIMESTAMP=$OPTARG
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
if [ -z "$ANNOTATION_TITLE" ]; then
  echo "Title is required (use the -t parameter)."
  exit 1
fi
if [ -z "$DOMAIN_IDS" ]; then
  echo "Domain ID list is required (use the -d parameter)."
  exit 1
fi

if [ -n "$ANNOTATION_TIMESTAMP" ]; then
  # Make sure the timestamp is valid.
  if ! validTimestamp "$ANNOTATION_TIMESTAMP"; then
    exit 1
  fi
else
  # No timestamp provided.
  # Get the current time in epoch millis.
  ANNOTATION_TIMESTAMP=$(date +%s)000
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

annotation_json_file=$(mktemp)
cat > $annotation_json_file << EOF
{
  "title":"$ANNOTATION_TITLE",
  "start":$ANNOTATION_TIMESTAMP,
  "text":"$ANNOTATION_BODY",
  "domainIds":[$DOMAIN_IDS]
}
EOF

id_json=$(curl --fail --silent --show-error -H "X-Auth-Token: $token_raw" -H "Content-Type: application/json" --data-binary @$annotation_json_file https://$HOST/concerto/mpulse/api/annotations/v1)
curl_result=$?
rm $annotation_json_file

if [ $curl_result -ne 0 ]; then
  echo "Failed to create annotation (curl exit code: $curl_result)."
  exit 1
fi

echo $id_json

# Clean up our security token
curl --fail --silent --show-error -X DELETE https://$HOST/concerto/services/rest/RepositoryService/v1/Tokens/$token_raw
