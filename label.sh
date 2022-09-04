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
comments_url=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/pulls | jq -r '.[-1].comments_url')
labels=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/issues | jq -r '.[-1].url')

pr_created_at=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/pulls | jq -r '.[-1].created_at')
pr_updated_at=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/pulls | jq -r '.[-1].updated_at')

label_created_at=$(curl -X GET -u $owner:$token $issue_number/events | jq -r '.[-1] | select(.event == "labeled") | select( .label.name == "Stale") | .created_at')
label_on_pr=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/issues | jq -r '.[].labels[].name')

user=$(curl -X GET -u $owner:$token $BASE_URI/repos/$repo/issues/comments | jq -r '.[-1].user.type')


echo "pr number: $pr_number"
echo "issue number: $issue_number"
echo "comments: $comments_url"
echo "pr created at: $pr_created_at"
echo "pr updated at: $pr_updated_at"
echo "label created at: $label_created_at"
echo "labels on pr: $label_on_pr"
echo "labels: $labels"
echo "User: $user"


label="Stale"
GitBot="Bot"
one_day=100


comments()
{
if [ "$user" = "Bot" ];
then
  echo "Dont remove stale label"
fi

if [ "$user" = "User" ];
then
  echo "Remove stale label"
  curl -X DELETE -u $owner:$token $issue_number/labels \
  -d '{ "labels":["Stale"] }'
fi
}

prupdate()
{
if [ $UpdatedTime -lt $one_day ]
then
  echo "PR updated. Remove stale label"
  curl -X DELETE -u $owner:$token $issue_number/labels \
  -d '{ "labels":["Stale"] }'
fi
}

"$@"