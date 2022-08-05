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

pr_number=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/pulls | jq -r '.[-1].url')
issue_number=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/issues | jq -r '.[-1].url')
comments_url=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/pulls | jq -r '.[-1].comments_url')
pr_created_at=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/pulls | jq -r '.[-1].created_at')
pr_updated_at=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/pulls | jq -r '.[-1].updated_at')
label_created_at=$(curl -X GET -u $owner:$token $issue_number/events | jq -r '.[-1] | select(.event == "labeled") | select( .label.name == "Stale") | .created_at')
unlabel_created_at=$(curl -X GET -u $owner:$token $issue_number/events | jq -r '.[-1] | select(.event == "unlabeled") | select( .label.name == "Stale") | .created_at')

live_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
convert_live_date=$(date -u -d "$live_date" +%s)
convert_pr_updated_at=$(date -u -d "$pr_updated_at" +%s)
convert_label_created_at=$(date -u -d "$label_created_at" +%s)
convert_unlabel_created_at=$(date -u -d "$unlabel_created_at" +%s)

DIFFERENCE=$((convert_live_date - convert_pr_updated_at))
DIFFERENCE_LABEL=$((convert_live_date - convert_label_created_at))
DIFFERENCE_UNLABEL=$((convert_live_date - convert_unlabel_created_at))
updateAt_labelCreate=$((convert_pr_updated_at - convert_label_created_at))

SECONDSPERDAY=86400
STALE_DAYS=120
UPDATED_AT=120
STALE_CLOSE=160

echo "pr number: $pr_number"
echo "issue number: $issue_number"
echo "pr created at: $pr_created_at"
echo "pr updated at: $pr_updated_at"
echo "label created at: $label_created_at"
echo "unlabel created at: $unlabel_created_at"

echo "--------------------"
echo "live date: $live_date"
echo "convert live date: $convert_live_date"
echo "convert pr updated at: $convert_pr_updated_at" 
echo "convert label created at: $convert_label_created_at"  
echo "convert unlabel created at: $convert_unlabel_created_at" 
echo "difference updateAt-labelCreate: $updateAt_labelCreate"

echo "difference time: $DIFFERENCE"
echo "difference label time: $DIFFERENCE_LABEL"
echo "Days Before Stale in seconds: $STALE_DAYS"
echo "Days Before Close in seconds: $STALE_CLOSE"


case $((
(DIFFERENCE >= 0 && DIFFERENCE <= STALE_DAYS) * 1 +
(DIFFERENCE > STALE_CLOSE) * 2)) in
(1) echo "This PR is active."
  curl -X DELETE -u $owner:$token $issue_number/labels/Stale
;;
(2) echo "This PR is Stale."
  # curl -X POST -u $owner:$token $label \
  # -d '{ "labels":["stale"] }'

  curl -X POST -u $owner:$token $comments_url \
  -d '{"body":"This PR is stale because it has been open 15 days with no activity. Remove stale label or comment or this will be closed in 2 days."}' 
;;

esac  

# case $((
# (DIFFERENCE < STALE_DAYS) * 1 +
# (DIFFERENCE_LABEL > STALE_CLOSE) * 2)) in
# (1) echo "This PR is active."
#   curl -X DELETE -u $owner:$token $issue_number/labels/Stale
# ;;
# (2) echo "This PR is stale and close"

#   # curl -X PATCH -u $owner:$token $pr_number \
#   # -d '{ "state": "closed" }'

#   curl -X POST -u $owner:$token $comments_url \
#   -d '{"body":"This PR was closed because it has been stalled for 2 days with no activity."}'
# ;;
# (0) echo "Non of the match"
# ;;
# esac  

}


"$@"