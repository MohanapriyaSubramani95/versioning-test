#!/bin/bash

current_environment=$1
component_name=$2
version_postfix=$3

git fetch --tags

last_tag_pattern="$component_name-*"

is_patch=false

if [ "$current_environment" == "uat" ] || [ "$current_environment" == "prod" ]; then
  current_commit=$(git rev-parse HEAD)

  # Detect if commit message includes 'merge dev' (case-insensitive)
  git log -1 --pretty=%B | grep -iq "merge.*dev"
  if [ $? -eq 0 ]; then
    is_patch=false
  else
    is_patch=true
  fi

  last_tag_pattern="$component_name-$current_environment-*"
fi

matching_tags=$(git tag --list "$last_tag_pattern" | sort -r)
tag_count=$(echo "$matching_tags" | wc -l)

if [ "$tag_count" -eq 0 ]; then
  last_tag=""
else
  last_tag=$(echo "$matching_tags" | head -n 1)
fi

if [[ $last_tag =~ ([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
  major=${BASH_REMATCH[1]}
  minor=${BASH_REMATCH[2]}
  patch=${BASH_REMATCH[3]}
else
  major=0
  minor=0
  patch=0
fi

if [ "$is_patch" == "true" ]; then
  patch=$((patch + 1))
else
  minor=$((minor + 1))
  patch=0
fi

new_version="$major.$minor.$patch"
new_tag="$component_name-$current_environment-$new_version-$version_postfix"

# IMPORTANT: Output ONLY this line for GitHub Actions to capture as output
echo "version_tag=$new_tag"
