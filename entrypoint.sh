#!/bin/bash -l

set -e

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Required the GITHUB_TOKEN environment variable."
  exit 1
fi

if [[ -z "$GIT_USER_NAME" ]]; then
    echo "require to set with: GIT_USER_NAME."
  exit 1
fi

if [[ -z "$GIT_EMAIL" ]]; then
  echo "require to set with: GIT_EMAIL."
  exit 1
fi

git remote set-url origin "https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY"
DEFAULT_BRANCH=$(git remote show $REMOTE | grep "HEAD branch" | sed 's/.*: //')
git checkout ${DEFAULT_BRANCH}
BRANCH_NAME="bundle_update/$(date "+%Y%m%d_%H%M%S")"
git checkout -b ${BRANCH_NAME}

export PATH="/usr/local/bundle/bin:$PATH"

if [[ -n "$INPUT_BUNDLER_VERSION" ]]; then
  gem install bundler -v "$INPUT_BUNDLER_VERSION"
else
  gem install bundler
fi

gem install bundler-diff

if [[ -n "$INPUT_JFROG_PATH" ]]; then
  gem update --system 3.1.1 > /dev/null
  bundle config set --global $INPUT_JFROG_PATH $INPUT_JFROG_USERNAME:$INPUT_JFROG_API_TOKEN
fi


bundle lock --update
bundle diff -f md_table
BUNDLE_DIFF="$(bundle diff -f md_table)"

if [ "$(git diff --name-only origin/master --diff-filter=d | wc -w)" == 0 ]; then
  echo "not update"
  exit 1
fi

export GITHUB_USER="$GITHUB_ACTOR"

git config --global user.name $GIT_USER_NAME
git config --global user.email $GIT_EMAIL


if [[ -n "$INPUT_YARN_UPGRADE" ]]; then
  export NPM_TOKEN=$INPUT_NPM_TOKEN
  yarn
  yarn upgrade
  hub add yarn.lock
fi

hub add Gemfile Gemfile.lock
hub commit -m "dependency updates ✨"
hub push origin ${BRANCH_NAME}

TITLE="Automatically Generated Bundle Update $(date "+%Y%m%d_%H%M%S") 🤖"

PR_ARG="-m \"$TITLE\" -m \"$BUNDLE_DIFF\""

if [[ -n "$INPUT_REVIEWERS" ]]; then
  PR_ARG="$PR_ARG -r \"$INPUT_REVIEWERS\""
fi

COMMAND="hub pull-request -b master -h $BRANCH_NAME --no-edit $PR_ARG || true"

echo "$COMMAND"
sh -c "$COMMAND"
