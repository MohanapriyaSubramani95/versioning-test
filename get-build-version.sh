#!/bin/bash

current_environment=$1
component_name=$2
version_postfix=$3

git fetch --tags

# Get latest prod version (fallback to 0.0.0 if not found)
prod_latest_tag=$(git tag --list "$component_name-prod-*" | sort -V | tail -n 1)

prod_major=0
prod_minor=0
prod_patch=0

if [[ -n "$prod_latest_tag" ]]; then
  prod_version=$(echo "$prod_latest_tag" | cut -d- -f3)
  prod_major=$(echo "$prod_version" | cut -d. -f1)
  prod_minor=$(echo "$prod_version" | cut -d. -f2)
  prod_patch=$(echo "$prod_version" | cut -d. -f3)
fi

# Initialize version to prod version
major=$prod_major
minor=$prod_minor
patch=0

if [ "$current_environment" == "prod" ]; then
  major=$((prod_major + 1))
  minor=0
  patch=0

elif [ "$current_environment" == "uat" ]; then
  # Find latest uat version
  latest_uat_tag=$(git tag --list "$component_name-uat-*" | sort -V | tail -n 1)
  if [[ -n "$latest_uat_tag" ]]; then
    uat_version=$(echo "$latest_uat_tag" | cut -d- -f3)
    uat_minor=$(echo "$uat_version" | cut -d. -f2)
    minor=$((uat_minor + 1))
  else
    minor=$((prod_minor + 1))
  fi
  patch=0

elif [ "$current_environment" == "dev" ]; then
  latest_dev_tag=$(git tag --list "$component_name-dev-*" | sort -V | tail -n 1)
  if [[ -n "$latest_dev_tag" ]]; then
    dev_version=$(echo "$latest_dev_tag" | cut -d- -f3)
    dev_major=$(echo "$dev_version" | cut -d. -f1)
    dev_minor=$(echo "$dev_version" | cut -d. -f2)
    dev_patch=$(echo "$dev_version" | cut -d. -f3)

    if [[ "$dev_major" -eq "$prod_major" && "$dev_minor" -eq "$prod_minor" ]]; then
      patch=$((dev_patch + 1))
    else
      patch=0
    fi
  else
    patch=0
  fi
fi

echo "$component_name-$current_environment-$major.$minor.$patch-$version_postfix"
