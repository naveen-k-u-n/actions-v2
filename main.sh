#!/bin/bash

MERGE_PR="$MERGE_PR"
CLOSE_PR="$CLOSE_PR"
PR_DESCRIPTION="$PR_DESCRIPTION"
BASE="$BASE_REF"
HEAD="$HEAD_REF"
SEP="&&"
STALE_DAYS=$STALE_DAYS
CLOSE_DAYS=$CLOSE_DAYS

# for curl API
token="$GITHUB_TOKEN"
BASE_URI="https://api.github.com"
owner="$REPO_OWNER"
repo="$REPO_NAME"
pull_number="$PR_NUMBER"

# Issue comments
merge() {
case "${MERGE_PR}" in
  "true") 
  echo "PR has Approved."
  curl -X PUT -u $owner:$token $BASE_URI/repos/$repo/pulls/$pull_number/merge \
  -d '{ "merged": true }'
  curl -X POST -u $owner:$token $BASE_URI/repos/$repo/issues/$pull_number/comments \
  -d '{"body":"Pull Request Merged!"}'
    ;;
esac
}

close() {
case "${CLOSE_PR}" in
  "true") 
  echo "PR has Closed manually by comments."
  curl -X PATCH -u $owner:$token $BASE_URI/repos/$repo/pulls/$pull_number \
  -d '{ "state": "closed" }'
  curl -X POST -u $owner:$token $BASE_URI/repos/$repo/issues/$pull_number/comments \
  -d '{"body":"Pull Request Closed!"}'
    ;;
esac
}

# Pull_request target master
target() {
case "${BASE}${SEP}${HEAD}" in
  "true${SEP}false") 
    curl -X PATCH -u $owner:$token $BASE_URI/repos/$repo/pulls/$pull_number \
  -d '{ "state": "closed" }'
    curl -X POST -u $owner:$token $BASE_URI/repos/$repo/issues/$pull_number/comments \
  -d '{"body":"Do not accept PR target from feature branch to master branch."}'
    ;;
esac
}

# Description
description() {
case "$PR_DESCRIPTION" in
  "true") 
    echo "PR has No valied description" 
    curl -X POST -u $owner:$token $BASE_URI/repos/$repo/issues/$pull_number/comments \
    -d '{"body":"No Description on PR body. Please add valid description."}'
    curl -X PATCH -u $owner:$token $BASE_URI/repos/$repo/pulls/$pull_number \
    -d '{ "state": "closed" }'
  ;;
esac  
}
"$@"
