#!/usr/bin/env bash

echoerr() { echo "$@" 1>&2; }
error_exit() { echoerr $1; exit 1; }

URL=$1
if [ -z "$URL" ] ; then error_exit "No url found"; fi

# GETs
echo "=== Testing GETs =========================================="
START_TIME=$SECONDS
ab -n 500 -c 10 $URL
GET_ELAPSED_TIME=$(($SECONDS - $START_TIME))

# PUTs
echo ""
echo "=== Testing PUTs =========================================="
START_TIME=$SECONDS
ab -n 500 -c 10 -u /dev/null $URL
PUT_ELAPSED_TIME=$(($SECONDS - $START_TIME))

echo ""
echo "500 GET requests took $GET_ELAPSED_TIME seconds"
echo "500 PUT requests took $PUT_ELAPSED_TIME seconds"

if [ $GET_ELAPSED_TIME -gt 20 ] ; then error_exit "GET requests were too slow"; fi
if [ $PUT_ELAPSED_TIME -gt 20 ] ; then error_exit "PUT requests were too slow"; fi