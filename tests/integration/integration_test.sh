#!/usr/bin/env bash

echoerr() { echo "$@" 1>&2; }
error_exit() { echoerr $1; exit 1; }

URL=$1
if [ -z "$URL" ] ; then error_exit "No url found"; fi

sleep 1; test $(curl -s -XDELETE $URL) == "OK" || error_exit "Reset failed"
sleep 1; test $(curl -s -XGET $URL) == "0" || error_exit "Failed asserting first get after reset is 0"
sleep 1; test $(curl -s -XPUT $URL) == "1" || error_exit "Failed asserting result of first put is 1"
sleep 1; test $(curl -s -XPUT $URL) == "2" || error_exit "Failed asserting result of second put is 2"
sleep 1; test $(curl -s -XGET $URL) == "2" || error_exit "Failed asserting result of get after second put is 2"
sleep 1; test $(curl -s -XDELETE $URL) == "OK" || error_exit "Reset failed"
sleep 1; test $(curl -s -XGET $URL) == "0" || error_exit "Failed asserting first get after reset is 0"
