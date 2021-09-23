#!/bin/bash

set -e

## constants
BIN_DIR=$(readlink -f $(dirname $0))
BASE_DIR=$(dirname $BIN_DIR)

## functions
log() {
  echo "$(basename $0): $@" >&2
}

usage() {
  echo "Usage: $(basename $0) <distribution>"
  exit 1
}

## main

# CLI parameters
if [[ $# != 1 ]] ; then
  usage
fi

DISTRIBUTION=$1

# get GITHUB_TOKEN from .env file
source ${BASE_DIR}/.env
export GITHUB_TOKEN

# get ats-podman's commit for master branch
branches=$(curl -s -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/untangle/ats-podman/branches)
master_commit=$(echo $branches | jq -r '.[] | select(.name == "master") | .commit.sha')

# create a new branch if necessary in ats-podman, with the same name
# as the current one, and push a commit on it; this will start ATS on
# that branch, and the magic extra_dev_distribution parameter will
# have that ATS run include packages from our newly created
# distribution

branch_commit=$(echo $branches | jq -r '.[] | select(.name == "'${DISTRIBUTION}'") | .commit.sha')
log "existing branch commit: $branch_commit"

if [[ -z "$branch_commit" ]] ; then
  curl -s \
       -X POST \
       -H "Authorization: token $GITHUB_TOKEN" \
       -H "Accept: application/vnd.github.v3+json" \
       -d '{"ref":"refs/heads/'${DISTRIBUTION}'", "sha":"'${master_commit}'"}' \
       https://api.github.com/repos/untangle/ats-podman/git/refs > /dev/null
  branches=$(curl -s -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/untangle/ats-podman/branches)
  branch_commit=$(echo $branches | jq -r '.[] | select(.name == "'${DISTRIBUTION}'") | .commit.sha')
  log "created new branch with commit $branch_commit"
fi

commit_info=$(curl -s \
		   -X GET \
		   -H "Authorization: token $GITHUB_TOKEN" \
		   -H "Accept: application/vnd.github.v3+json" \
		   -d '{"ref":"refs/heads/'${DISTRIBUTION}'", "sha":"'${master_commit}'"}' \
		   https://api.github.com/repos/untangle/ats-podman/commits/${branch_commit})

tree_sha=$(echo $commit_info | jq -r '.commit.tree.sha')
log "tree sha: $tree_sha"

# create commit
json=$(curl -s \
	    -X POST \
	    -H "Authorization: token $GITHUB_TOKEN" \
	    -H "Accept: application/vnd.github.v3+json" \
	    -d '{"message":"Trigger ATS", "parents":["'${branch_commit}'"], "tree":"'${tree_sha}'" }' \
	    https://api.github.com/repos/untangle/ats-podman/git/commits)
new_commit=$(echo $json | jq -r '.sha')
log "created new commit $new_commit"

# update branch
curl -s \
     -X POST \
     -H "Authorization: token $GITHUB_TOKEN" \
     -H "Accept: application/vnd.github.v3+json" \
     -d '{"sha":"'${new_commit}'" }' \
     https://api.github.com/repos/untangle/ats-podman/git/refs/heads/${DISTRIBUTION} > /dev/null
log "pushed that new commit on branch"

ats_url="http://jenkins.untangle.int/blue/organizations/jenkins/ats-podman/activity?branch=${DISTRIBUTION}"

echo $ats_url
