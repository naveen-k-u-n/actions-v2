#!/bin/bash

# STALE_DAYS=$STALE_DAYS
# CLOSE_DAYS=$CLOSE_DAYS

# for curl API
token="$GITHUB_TOKEN"
BASE_URI="https://api.github.com"
owner="$REPO_OWNER"
repo="$REPO_NAME"
pull_number="$PR_NUMBER"

# Stale Pull Request
stale-close() {

pr_created_at=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/pulls | jq -r '.[-1].created_at')
pr_updated_at=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/pulls | jq -r '.[-1].updated_at')

pr_number=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/pulls | jq -r '.[-1].url')
issue_number=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/issues | jq -r '.[-1].url')
comments_url=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/pulls | jq -r '.[-1].comments_url')
label=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/issues | jq -r '.[-1].url')


label_created_at=$(curl -X GET -u $issue_number/timeline | jq -r '.[-1].created_at')
timeline_label=$(curl -X GET -u $issue_number/timeline | jq -r '.[] | select( .label.name == "Stale" )')

# echo "live date: $live_date"
# echo "convert live date: $convert_live_date"
echo "pr created at: $pr_created_at"
echo "pr updated at: $pr_updated_at"
echo "label created at timeline: $label_created_at"
echo "label name: $timeline_label"


live_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
convert_live_date=$(date -u -d "$live_date" +%s)
convert_pr_updated_at=$(date -u -d "$pr_updated_at" +%s)
convert_label_created_at=$(date -u -d "$label_created_at" +%s)
DIFFERENCE=$((convert_live_date - convert_pr_updated_at))
DIFFERENCE_LABEL=$((convert_live_date - convert_label_created_at))
SECONDSPERDAY=86400
MIN_LABEL=500
MAX_LABEL=800


echo "live date: $live_date"
echo "convert live date: $convert_live_date"
echo "pr updated at: $pr_updated_at"
echo "convert pr updated at: $convert_pr_updated_at" 
echo "label created at: $label_created_at" 
echo "convert label created at: $convert_label_created_at"  
echo "difference time: $DIFFERENCE"
echo "difference time: $DIFFERENCE_LABEL"
echo "pr number: $pr_number"
echo "Days Before Stale in seconds: $MIN_LABEL"
echo "Days Before Close in seconds: $MIN_LABEL"

case $((
(DIFFERENCE_LABEL <= MIN_LABEL) * 1 +
(DIFFERENCE_LABEL > MAX_LABEL) * 2)) in
(1) echo "This PR is active."
;;
(2) echo "This PR is stale and close"

  # curl -X PATCH -u $owner:$token $pr_number \
  # -d '{ "state": "closed" }'

  # curl -X POST -u $owner:$token $comments_url \
  # -d '{"body":"This PR was closed because it has been stalled for 2 days with no activity."}'
;;
(0) echo "Non of the match"
;;
esac  

}

"$@"