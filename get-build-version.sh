#!/bin/bash

current_env=$1         # dev, uat, or prod
component=$2           # e.g. frontend
version_postfix=$3     # e.g. commit hash

git fetch --tags

# Helper to get latest tag for an environment
get_latest_tag() {
  local env=$1
  git tag --list "$component-$env-*" | sort -V | tail -n 1
}

# Parse semver from tag, or default to 0.0.0
parse_version() {
  local tag=$1
  if [[ $tag =~ ([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
    echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]}"
  else
    echo "0 0 0"
  fi
}

if [ "$current_env" == "dev" ]; then
  # For dev, bump patch from latest prod tag
  latest_tag=$(get_latest_tag "prod")
  read major minor patch <<< $(parse_version "$latest_tag")
  patch=$((patch + 1))

elif [ "$current_env" == "uat" ]; then
  # For uat, bump minor from latest dev tag, keep major from dev
  latest_tag=$(get_latest_tag "dev")
  read major minor patch <<< $(parse_version "$latest_tag")
  minor=$((minor + 1))
  patch=0

elif [ "$current_env" == "prod" ]; then
  # For prod, bump major from latest uat tag, reset minor and patch
  latest_tag=$(get_latest_tag "uat")
  read major minor patch <<< $(parse_version "$latest_tag")
  major=$((major + 1))
  minor=0
  patch=0

else
  echo "Unsupported environment: $current_env"
  exit 1
fi

new_version="${major}.${minor}.${patch}"
new_tag="${component}-${current_env}-${new_version}-${version_postfix}"

echo "$new_tag"
