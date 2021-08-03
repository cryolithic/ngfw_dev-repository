#!/bin/bash

set -e

## constants
BIN_DIR=$(readlink -f $(dirname $0))
BASE_DIR=$(dirname $BIN_DIR)

## main

# CLI parameters
REPOSITORY=$1
DISTRIBUTION=$2

# get GITHUB_TOKEN from .env file
source ${BASE_DIR}/.env
export GITHUB_TOKEN

# find repository
# FIXME: this should be directly embedded in the distribution
# description; for that to happen, it needs to be included in the
# .changes file, which will require some more work
json=$(curl -s -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/search/issues?q=${DISTRIBUTION}+org:untangle+type:pr")
echo $json
repository_url=$(echo $json | jq -r '.items[0].repository_url')
repository=$(basename $repository_url)

# latest commit in this PR
number=$(echo $json | jq -r '.items[0].number')
json=$(curl \
  -X GET \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/untangle/ngfw_src/pulls/356/commits?per_page=100")
commit=$(echo $json | jq -r '.[-1].sha')

# post status
desc="$(cat /dev/stdin)"
curl \
  -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -d '{"state":"success", "target_url":"https://intranet.untangle.com/display/ngfw/Testing+packages+built+directly+from+GitHub+pull+requests", "context":"dev-packages", "description":"'"${desc}"'"}' \
  https://api.github.com/repos/untangle/$repository/statuses/$commit
