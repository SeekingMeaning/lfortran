#!/bin/bash

# This script extracts the project's current version from git. If there is a
# tag attached to the current commit (of the form "v1.0.1"), then it will be
# used ("1.0.1"), otherwise the first 7 characters of the hash of the current
# commit will be used ("eb757a8"). The result will be saved to a "version"
# file.

set -e
set -x

if [[ $CI_COMMIT_SHA == "" ]]; then
    # Use sha and tag values provided by git (requires git to be installed)
    COMMIT_TAG=$(git tag -l --points-at HEAD)
    COMMIT_SHA=$(git rev-parse HEAD)
else
    # Use sha and tag variables provides by the CI
    COMMIT_TAG=${CI_COMMIT_TAG}
    COMMIT_SHA=${CI_COMMIT_SHA}
fi

if [[ $COMMIT_TAG == "" ]]; then
    # The commit is not tagged, use the first 7 chars of git commit hash
    version="0.0+git${COMMIT_SHA:0:7}"
else
    # The commit is tagged, convert tag version properly:v1.0.1 -> "1.0.1"
    version=${COMMIT_TAG:1}
fi

echo ${version} > version
