#!/bin/bash

set -e
set -x

## constants
BIN_DIR=$(readlink -f $(dirname $0))
BASE_DIR=$(dirname $BIN_DIR)
CONF_FILE=$BASE_DIR/conf/aptly.conf
APTLY_CMD="aptly -config=$CONF_FILE"
GITHUB_SET_STATUS_CMD=${BIN_DIR}/github-set-status.sh
GITHUB_START_ATS_CMD=${BIN_DIR}/github-start-ats.sh

## functions
usage() {
  echo "Usage: $0 <repository> <changes_file>"
  exit 1
}

## main

# CLI parameters
if [[ $# != 2 ]] ; then
  usage
fi

REPOSITORY=$1
CHANGES_FILE=$2

# full path to changes file
changes_file_path=$BASE_DIR/incoming//$REPOSITORY/$CHANGES_FILE

# distribution used in the changes file is of the form
# <github_repo>.<github_branch>, with <github_repo> containing "."
# instead of "_" because the latter isn't allowed in a distribution
# name within a changelog
changes_distribution=$(awk '/^Distribution:/ {print $2}' $changes_file_path)
github_repo=${changes_distribution%.*}
github_repo=${github_repo//./_}
github_branch=${changes_distribution##*.}

# local distribution to use
distribution="${github_repo}.${github_branch}"

# endpoint to publish to
endpoint=filesystem:www:$REPOSITORY

# create the repository if needed
if ! $APTLY_CMD repo show $distribution 2> /dev/null ; then
  $APTLY_CMD repo create $distribution
fi

# include the changes file
$APTLY_CMD repo include -accept-unsigned -force-replace -repo $distribution $changes_file_path

# unpublish the repository to regenerate all architectures
if $APTLY_CMD publish show $distribution $endpoint 2> /dev/null ; then
  $APTLY_CMD publish drop $distribution $endpoint
fi

# publish
$APTLY_CMD publish repo -origin Untangle-dev -architectures amd64,source,arm64 -distribution $distribution $distribution $endpoint

# set GitHub's dev-packages status for this PR to success
case $CHANGES_FILE in
  *_amd64.changes)
    summary=$(${BIN_DIR}/summary.sh $REPOSITORY $distribution)
    $GITHUB_SET_STATUS_CMD $github_repo $github_branch dev-packages success "https://awakesecurity.atlassian.net/wiki/spaces/ngfw/pages/2075525433/Testing+packages+built+directly+from+GitHub+pull+requests" "$summary"
    ;;
esac

# start ATS and set GitHub's ATS status for this PR to pending
if [[ $github_repo =~ "ngfw" ]] && [[ $CHANGES_FILE =~ "_amd64.changes" ]] && [[ $REPOSITORY == "buster" ]]; then
  ats_url=$($GITHUB_START_ATS_CMD $distribution)
  $GITHUB_SET_STATUS_CMD $github_repo $github_branch ATS pending "$ats_url" pending
fi
