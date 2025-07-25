#!/bin/bash

current_environment=$1      # dev / uat / prod
component_name=$2           # e.g., booking
version_postfix=$3          # e.g., build123

git fetch --tags

last_tag_pattern="$component_name-*"

# Check if this is a patch-level change
is_patch=false
if [ "$current_environment" == "uat" ] || [ "$current_environment" == "prod" ]; then
  current_commit=$(git rev-parse HEAD)
  number_of_branches_with_commit=$(git branch -r --contains "$current_commit" | grep -E 'origin/(dev|uat|prod)' | wc -l)

  if [ "$number_of_branches_with_commit" -eq 1 ]; then
    is_patch=true
  fi
fi

# If it's a patch release, restrict search pattern
if [ "$is_patch" = true ]; then
  last_tag_pattern="$component_name-$current_environment-*"
fi

last_tag=$(git tag --list "$last_tag_pattern" | sort -V | tail -n1)

major=0
minor=0
patch=0

if [[ -n "$last_tag" ]]; then
  version_number=$(echo "$last_tag" | cut -d- -f3)
  major=$(echo "$version_number" | cut -d. -f1)
  minor=$(echo "$version_number" | cut -d. -f2)
  patch=$(echo "$version_number" | cut -d. -f3)
fi

# Version bump logic
if [ "$current_environment" == "prod" ] && [ "$is_patch" = false ]; then
  major=$((major + 1))
  minor=0
  patch=0
elif [ "$current_environment" == "uat" ] && [ "$is_patch" = false ]; then
  minor=$((minor + 1))
  patch=0
else
  patch=$((patch + 1))
fi

final_version="$component_name-$current_environment-$major.$minor.$patch-$version_postfix"
echo "$final_version"
