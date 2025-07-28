#!/bin/bash

current_environment=$1
component_name=$2
version_postfix=$3

git fetch --tags

last_tag_pattern="$component_name-*"

is_patch=false

if [ "$current_environment" == "uat" ] || [ "$current_environment" == "prod" ]; then
  current_commit=$(git rev-parse HEAD)
  number_of_branches_with_commit=$(git branch -r --contains "$current_commit" | grep -Ec "origin/(dev|uat|prod)")

  if [ "$number_of_branches_with_commit" == "1" ]; then
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
