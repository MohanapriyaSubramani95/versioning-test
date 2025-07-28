#!/bin/bash

current_environment=$1
component_name=$2
version_postfix=$3

git fetch --tags

last_tag_pattern="$component_name-*"

is_patch=false

if [ "$current_environment" == "uat" ]; then
  git fetch origin dev uat >/dev/null 2>&1
  dev_commit=$(git rev-parse origin/dev)
  uat_commit=$(git rev-parse origin/uat)

  # Check if UAT is ahead of dev (i.e., contains a merge commit from dev)
  if git merge-base --is-ancestor "$dev_commit" "$uat_commit"; then
    is_patch=false  # UAT contains latest dev -> increase minor
  else
    is_patch=true   # Not merged from dev -> treat as patch
  fi
elif [ "$current_environment" == "prod" ]; then
  git fetch origin uat prod >/dev/null 2>&1
  uat_commit=$(git rev-parse origin/uat)
  prod_commit=$(git rev-parse origin/prod)

  if git merge-base --is-ancestor "$uat_commit" "$prod_commit"; then
    is_patch=false
  else
    is_patch=true
  fi
fi


if [ $is_patch == true ]; then
  last_tag_pattern="$component_name-$current_environment-*"
fi

number_of_existing_tags=$(git tag --list "$last_tag_pattern" | wc -l)

if [ "$number_of_existing_tags" != "0" ]; then
  last_tag=$(git describe --match "$last_tag_pattern" --abbrev=0 --tags "$(git rev-list --tags --max-count=1)")
fi

major=0
minor=0
patch=0

if [[ $last_tag ]]; then
  version_number=$(echo "$last_tag" | cut -d- -f3)

  major=$(echo "$version_number" | cut -d. -f1)
  minor=$(echo "$version_number" | cut -d. -f2)
  patch=$(echo "$version_number" | cut -d. -f3)
fi

if [ "$current_environment" == "prod" ] && [ $is_patch == false ]; then
  major=$((major + 1))
  minor=0
  patch=0
elif [ "$current_environment" == "uat" ] && [ $is_patch == false ]; then
  minor=$((minor + 1))
  patch=0
else
  patch=$((patch + 1))
fi

echo "$component_name-$current_environment-$major.$minor.$patch-$version_postfix"
