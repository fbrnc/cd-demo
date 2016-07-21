#!/usr/bin/env bash

echoerr() { echo "$@" 1>&2; }
error_exit() { echoerr $1; exit 1; }

TMP_FILE=/tmp/phplint.tmp
touch $TMP_FILE;

for dir in $@; do
    if [ ! -d $dir ] ; then error_exit "Invalid dir"; fi
    for i in $(find $dir -type f \( -name '*.php' -o -name '*.phtml' \)); do
        md5=($(md5sum $i)); # cache key
        if grep -Fxq "$md5" $TMP_FILE; then
            echo "No syntax errors detected in $i (cached)"
        else
            php -l "$i" || error_exit "Unable to parse file '$i'";
            echo $md5 >> $TMP_FILE
        fi
    done
done
