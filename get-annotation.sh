#!/bin/bash

# Defaults:
HOST=mpulse.soasta.com

usage()
{
cat << EOF
usage: $0 options

This script gets a list of all annotations or an annotation with a particular id.

OPTIONS:
   -h      Show this message
   -s      Override the mPulse server (default: $HOST)
   -a      Your mPulse API token (required)
   -n      Tenant Name (required if not passing in an Annotation ID)
   -b      Start Date: start of the range to query for. Annotation start to be greater than or equal to this value. (required if not passing in an Annotation ID)
   -e      End Date: end of the range to query for. Annotation start to be less than or equal to this value (optional)
   -i      Annotation ID: returns only the specified annotation (required if not passing in a Start Date)
   -d      Domain ID (optional)
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

while getopts "s:a:b:e:n:d:i:h" OPTION
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
    b)
      DATE_START=$OPTARG
      ;;
    e)
      DATE_END=$OPTARG
      ;;
    n)
      TENANT_NAME=$OPTARG
      ;;
    d)
      DOMAIN_ID=$OPTARG
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

if [ -z "$ANNOTATION_ID" ] && [ -z "$DATE_START" ]; then
  echo "You must supply either an Annotation ID (-i) or a Start Date (-b)."
  exit 1
else
  if [ -n "$DATE_START" ]; then
    if [ -z "$TENANT_NAME" ]; then
      echo "Tenant Name is required (use the -n parameter)."
      exit 1
    fi
    # Make sure the timestamp is valid.
    if ! validTimestamp "$DATE_START"; then
      echo "date-start is invalid.  It must be in epoch millis."
      exit 1
    else
      if [ -n "$DATE_END" ]; then
        # Make sure the timestamp is valid.
        if ! validTimestamp "$DATE_END"; then
          echo "date-end is invalid.  It must be in epoch millis."
          exit 1
        fi
      else
        # No timestamp provided.
        # Get the current time in epoch millis.
        DATE_END=$(date +%s)000
      fi
      if [ -n "$DOMAIN_ID" ]; then
        url="https://$HOST/concerto/mpulse/api/annotations/v1?date-start=$DATE_START&date-end=$DATE_END&domain=$DOMAIN_ID"
      else
        url="https://$HOST/concerto/mpulse/api/annotations/v1?date-start=$DATE_START&date-end=$DATE_END"
      fi
    fi
  else
    url="https://$HOST/concerto/mpulse/api/annotations/v1/$ANNOTATION_ID"
  fi
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

response=$(curl --fail --silent --show-error -H "X-Auth-Token: $token_raw" -X GET $url)
curl_result=$?

if [ $curl_result -ne 0 ]; then
  echo "Failed to retrieve annotation(s) (curl exit code: $curl_result)."
  exit 1
else
  echo $response | jq
fi

# Clean up our security token
curl --fail --silent --show-error -X DELETE https://$HOST/concerto/services/rest/RepositoryService/v1/Tokens/$token_raw
