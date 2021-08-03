#!/bin/bash

set -e

## constants
BIN_DIR=$(readlink -f $(dirname $0))
BASE_DIR=$(dirname $BIN_DIR)
CONF_FILE=$BASE_DIR/conf/aptly.conf
APTLY_CMD="aptly -config=$CONF_FILE"

## main

# CLI parameters
REPOSITORY=$1
DISTRIBUTION=$2

# source.list
source_list="deb [trusted=yes] http://package-server/dev/$REPOSITORY $DISTRIBUTION main"

# show distro and source
echo "Distribution available: $source_list"
# echo

# # show packages
# echo "It contains the following packages:"
# while read pkg ; do
# pkgs="$pkg $pkgs"
# echo "  $pkg"
# done < <($APTLY_CMD repo show -with-packages $DISTRIBUTION | awk -F_ '/^ / {print $1}' | sort -u)
# echo

# # show example usage
# echo "You can install those packages with these commands:"
# echo "  echo $source_list > /etc/apt/sources.list.d/${DISTRIBUTION}.list"
# echo "  apt update"
# echo "  apt install $pkgs"
