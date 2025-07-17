#!/bin/bash

current_environment=$1       # dev / uat / prod
component_name=$2            # frontend, backend, etc.
version_postfix=$3           # git sha or build id

git fetch --tags

# Default last tag pattern
last_tag_pattern="$component_name-$current_environment-*"

# Fetch last tag
matching_tags=$(git tag --list "$last_tag_pattern" | sort -Vr)
last_tag=$(echo "$matching_tags" | head -n 1)

# Parse version
if [[ "$last_tag" =~ ([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
  major=${BASH_REMATCH[1]}
  minor=${BASH_REMATCH[2]}
  patch=${BASH_REMATCH[3]}
else
  major=0
  minor=0
  patch=0
fi

# Get last commit message
commit_message=$(git log -1 --pretty=%B)

# Determine bump type
if [ "$current_environment" == "dev" ]; then
  patch=$((patch + 1))

elif [ "$current_environment" == "uat" ]; then
  if echo "$commit_message" | grep -iq "merge.*dev"; then
    minor=$((minor + 1))
    patch=0
  else
    patch=$((patch + 1))
  fi

elif [ "$current_environment" == "prod" ]; then
  if echo "$commit_message" | grep -iq "merge.*uat"; then
    major=$((major + 1))
    minor=0
    patch=0
  else
    patch=$((patch + 1))
  fi
fi

new_version="$major.$minor.$patch"
new_tag="$component_name-$current_environment-$new_version-$version_postfix"

# Output for GitHub Actions
echo "version_tag=$new_tag"
