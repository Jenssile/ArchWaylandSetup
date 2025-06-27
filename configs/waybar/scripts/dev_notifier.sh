#!/usr/bin/env bash

# ---------------- CONFIG ---------------------
GITHUB_TOKEN="${GITHUB_TOKEN:-your_github_token}"
GITLAB_TOKEN="${GITLAB_TOKEN:-your_gitlab_token}"
AZURE_TOKEN="${AZURE_TOKEN:-your_azure_token}"
AZURE_ORG="your_azure_org"
AZURE_PROJECT="your_project"
GITHUB_USERNAME="${GITHUB_USERNAME:-your_github_username}"
GITHUB_REPO="${GITHUB_REPO:-your_repo}"
GITLAB_USERNAME="${GITLAB_USERNAME:-your_gitlab_username}"

SERVICES="${SERVICES:-github,gitlab,azure}"  # controlled via Waybar
IFS=',' read -ra ENABLED <<< "$SERVICES"

# Icons (FiraCode Nerd Font Mono)
ICON_GITHUB=""          # nf-fa-github
ICON_GITLAB=""          # nf-fa-gitlab
ICON_AZURE=""           # nf-dev-visualstudio

ICON_BELL="󰂚"           # nf-md-bell
ICON_PR=""             # nf-cod-git_pull_request
ICON_REVIEW="󱍸"         # nf-md-eye_arrow_right

# JSON output
output=()

# ----------------- GITHUB --------------------
if [[ " ${ENABLED[*]} " =~ " github " ]]; then
  GH_HEADERS=(-H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github+json")

  GH_NOTIFS=$(curl -s "${GH_HEADERS[@]}" https://api.github.com/notifications | jq length)

  GH_PRS=$(curl -s "${GH_HEADERS[@]}" https://api.github.com/repos/$GITHUB_USERNAME/$GITHUB_REPO/pulls | jq length)

  GH_REVIEWS=$(curl -s "${GH_HEADERS[@]}" https://api.github.com/repos/$GITHUB_USERNAME/$GITHUB_REPO/pulls \
    | jq '[.[] | select(.requested_reviewers | length > 0)] | length')

  output+=("{\"text\": \"$ICON_GITHUB $ICON_BELL $GH_NOTIFS $ICON_PR $GH_PRS $ICON_REVIEW $GH_REVIEWS\", \"class\": \"github\", \"tooltip\": \"GitHub: $GH_NOTIFS Notifications, $GH_PRS PRs, $GH_REVIEWS Reviews\"}")
fi

# ----------------- GITLAB --------------------
if [[ " ${ENABLED[*]} " =~ " gitlab " ]]; then
  GL_HEADERS=(-H "PRIVATE-TOKEN: $GITLAB_TOKEN")

  GL_TODOS=$(curl -s "${GL_HEADERS[@]}" https://gitlab.com/api/v4/todos | jq length)

  GL_PRS=$(curl -s "${GL_HEADERS[@]}" https://gitlab.com/api/v4/merge_requests?scope=assigned_to_me | jq length)

  GL_REVIEWS=$(curl -s "${GL_HEADERS[@]}" "https://gitlab.com/api/v4/merge_requests?reviewer_username=$GITLAB_USERNAME" | jq length)

  output+=("{\"text\": \"$ICON_GITLAB $ICON_BELL $GL_TODOS $ICON_PR $GL_PRS $ICON_REVIEW $GL_REVIEWS\", \"class\": \"gitlab\", \"tooltip\": \"GitLab: $GL_TODOS Todos, $GL_PRS MRs, $GL_REVIEWS Reviews\"}")
fi

# ----------------- AZURE --------------------
if [[ " ${ENABLED[*]} " =~ " azure " ]]; then
  AZ_AUTH=$(echo -n ":$AZURE_TOKEN" | base64)

  AZ_WORK_ITEMS=$(curl -s -H "Authorization: Basic $AZ_AUTH" \
    "https://dev.azure.com/$AZURE_ORG/$AZURE_PROJECT/_apis/wit/workitems?api-version=6.0" | jq '.count')

  AZ_PRS=$(curl -s -H "Authorization: Basic $AZ_AUTH" \
    "https://dev.azure.com/$AZURE_ORG/$AZURE_PROJECT/_apis/git/pullrequests?searchCriteria.status=active&api-version=6.0" | jq '.count')

  output+=("{\"text\": \"$ICON_AZURE $ICON_BELL $AZ_WORK_ITEMS $ICON_PR $AZ_PRS\", \"class\": \"azure\", \"tooltip\": \"Azure: $AZ_WORK_ITEMS Work Items, $AZ_PRS PRs\"}")
fi

# ----------------- OUTPUT --------------------
echo "[${output[*]}]"
