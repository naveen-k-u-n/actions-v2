#!/bin/bash

STALE_DAYS=$STALE_DAYS
CLOSE_DAYS=$CLOSE_DAYS

# for curl API
token="$GITHUB_TOKEN"
BASE_URI="https://api.github.com"
owner="$REPO_OWNER"
repo="$REPO_NAME"
pull_number="$PR_NUMBER"

# Stale Pull Request

pr_number=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/pulls | jq -r '.[-1].url')
issue_number=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/issues | jq -r '.[-1].url')
labels=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/issues | jq -r '.[-1].url')

pr_created_at=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/pulls | jq -r '.[-1].created_at')
pr_updated_at=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/pulls | jq -r '.[-1].updated_at')

label_created_at=$(curl -X GET -u $owner:$token $issue_number/events | jq -r '.[-1] | select(.event == "labeled") | select( .label.name == "Stale") | .created_at')
label_on_pr=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/issues | jq -r '.[].labels[].name')

user=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/issues/comments | jq -r '.[-1].user.type')


live_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
convert_live_date=$(date -u -d "$live_date" +%s)
convert_pr_updated_at=$(date -u -d "$pr_updated_at" +%s)
convert_label_created_at=$(date -u -d "$label_created_at" +%s)

UpdatedTime=$((convert_live_date - convert_pr_updated_at))
LabelTime=$((convert_live_date - convert_label_created_at))

#time

# SECONDSPERDAY=86400    #24 hrs
# STALE_LABEL=$(( STALE_DAYS * SECONDSPERDAY ))
# STALE_CLOSE=$(( CLOSE_DAYS * SECONDSPERDAY ))
# STALE_LABEL=15
# STALE_CLOSE=5

five_days=100
fifteen_days=120
onemin=60

echo "pr number: $pr_number"
echo "issue number: $issue_number"
echo "pr created at: $pr_created_at"
echo "pr updated at: $pr_updated_at"
echo "label created at: $label_created_at"
echo "labels on pr: $label_on_pr"
echo "labels: $labels"
echo "User: $user"

echo "--------------------"
echo "live date: $live_date"
echo "convert live date: $convert_live_date"
echo "convert pr updated at: $convert_pr_updated_at" 
echo "convert label created at: $convert_label_created_at"  

echo "UpdatedTime: $UpdatedTime"
echo "LabelTime: $LabelTime"


label="Stale"
GitBot="Bot"

stale_label() 
{  

if [ $UpdatedTime -lt $fifteen_days ]
then
   echo "This PR is active. Don't close PR"

else [ $UpdatedTime -gt $fifteen_days ]
   echo "This PR is stale because it has been open 15 days with no activity."
   curl -X POST -u $owner:$token $labels \
  -d '{ "labels":["Stale"] }'

  curl -X POST -u $owner:$token $comments_url \
  -d '{"body":"This PR is stale because it has been open 15 days with no activity. Remove stale label or comment or this will be closed in 5 days."}' 

fi

}

stale_close()
{

if [ $LabelTime -gt $five_days ]
then
   echo "This PR is closed because it has been stalled from 5 days"

  curl -X PATCH -u $owner:$token $pr_number \
  -d '{ "state": "closed" }'

  curl -X POST -u $owner:$token $comments_url \
  -d '{"body":"This PR is closed because it has been stalled from 5 days."}'

fi

}



if [ "$label_on_pr" = "$label" ];
then
  stale_close
fi
if [ "$label_on_pr" != "$label" ];
then
  stale_label
fi



if [ "$user" = "$GitBot" ];
then
  echo "Dont remove stale label"
  # curl -X DELETE -u $owner:$token $labels \
  # -d '{ "labels":["Stale"] }'
fi
if [ "$user" != "$GitBot" ];
then
  echo "Remove stale label"
  curl -X DELETE -u $owner:$token $labels \
  -d '{ "labels":["Stale"] }'
fi

"$@"