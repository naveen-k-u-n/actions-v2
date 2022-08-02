# !/bin/bash

PR_URL="$PR_URL"
token="$GITHUB_TOKEN"
BASE_URI="https://api.github.com"
owner="$REPO_OWNER"
repo="$REPO_NAME"

PR_NUMBER=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/pulls | jq -r '.[-1].url')

pull_number="$PR_NUMBER"

#time
aday=86400 #24 hrs
four_days=345600
nine_days=777600
ten_days=864000

active=100
stale=120
close=60

#date and time of PR
# pr_updated_at=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/pulls | jq -r '.[-1].updated_at')
latest_commit_date=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/pulls/$pull_number/commits | jq -r '.[-1].commit.committer.date')
stale_date=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/pulls/$pull_number | jq -r '.updated_at')

comments_url=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/pulls | jq -r '.[-1].comments_url')
label=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/issues | jq -r '.[-1].url')

live_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
convert_live_date=$(date -u -d "$live_date" +%s)
convert_latest_commit_date=$(date -u -d "$latest_commit_date" +%s)
convert_stale_date=$(date -u -d "$stale_date" +%s)
DIFFERENCE=$((convert_live_date - convert_latest_commit_date))
label_diff=$((convert_live_date - convert_stale_date))

echo "latest commit date: $latest_commit_date"
echo "stale label date: $stale_date"
echo "live date: $live_date"
echo "convert live date: $convert_live_date"
echo "convert latest commit date: $convert_latest_commit_date"
echo "convert stale label date: $convert_stale_date"  
echo "difference time: $DIFFERENCE"
echo "label difference time: $label_diff"

case $((
(DIFFERENCE < $active) * 1 +
(DIFFERENCE <= $stale) * 2 +
(label_diff > $close) * 3)) in
(1) echo "This PR is active."
;;
(2) echo "This PR is Stale."
  curl -X POST -u $owner:$token $label \
  -d '{ "labels":["Stale"] }'

  curl -X POST -u $owner:$token $comments_url \
  -d '{"body":"This PR is stale because it has been open 15 days with no activity. Remove stale label or comment or this will be closed in 2 days."}' 
;;
(3) echo "This PR is stale and close"

  curl -X PATCH -u $owner:$token $pr_number \
  -d '{ "state": "closed" }'

  curl -X POST -u $owner:$token $comments_url \
  -d '{"body":"This PR was closed because it has been stalled for 2 days with no activity."}'
;;
(0) echo "Non of the match"
;;
esac  


# if [ $DIFFERENCE -lt $active ]
# then
#    echo "This PR is active. Don't close PR"
#    gh pr edit $PR_URL --remove-label "Stale"
# elif [ $DIFFERENCE -le $stale ]
# then
#    echo "This PR is stale because it has been open 10 days with no activity."
#    gh pr edit $PR_URL --add-label "Stale" 
#    gh pr comment $PR_URL --body "This issue is stale because it has been open 10 days with no activity. Remove stale label or comment or this will be closed in 4 days."
# elif [ $label_diff -gt $close ]
# then
#    echo "This PR was closed because it has been stalled for 4 days with no activity."
#    gh pr close $PR_URL
#    gh pr edit $PR_URL --remove-label "Stale"
#    gh pr comment $PR_URL --body "This PR was closed because it has been stalled for 4 days with no activity."

# else
#    echo "None of the condition met"
# fi