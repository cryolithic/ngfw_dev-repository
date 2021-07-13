#! /bin/bash

set -e

## constants
BIN_DIR=$(readlink -f $(dirname $0))
BASE_DIR=$(dirname $BIN_DIR)
CONF_FILE=$BASE_DIR/conf/aptly.conf
APTLY_CMD="aptly -config=$CONF_FILE"

## main

# CLI parameters
REPOSITORY=$1
CHANGES_FILE=$2

# derive some variables
changes_file_path=$BASE_DIR/incoming//$REPOSITORY/$CHANGES_FILE
distribution=$(awk '/^Distribution:/ {print $2}' $changes_file_path)
endpoint=filesystem:www:$REPOSITORY

# create the repository if needed
if ! $APTLY_CMD repo show $distribution 2> /dev/null ; then
  $APTLY_CMD repo create $distribution
fi

# include the changes file
$APTLY_CMD repo include -accept-unsigned $changes_file_path

# unpublish the repository to regenerate all architectures
if $APTLY_CMD publish show $distribution $endpoint 2> /dev/null ; then
  $APTLY_CMD publish drop $distribution $endpoint
fi

# publish
$APTLY_CMD publish repo -origin Untangle -distribution $distribution $distribution $endpoint
