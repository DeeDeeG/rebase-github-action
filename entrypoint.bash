#!/usr/bin/env bash

set -e
set -x

if [[ -n "${SSH_PRIVATE_KEY}" ]]; then
  echo "Saving SSH_PRIVATE_KEY"

  mkdir -p /root/.ssh
  echo "${SSH_PRIVATE_KEY}" > /root/.ssh/id_rsa
  chmod 600 /root/.ssh/id_rsa

  # Github action changes $HOME to /github at runtime
  # therefore we always copy the SSH key to $HOME (aka. ~)
  mkdir -p ~/.ssh
  cp /root/.ssh/* ~/.ssh/ 2> /dev/null || true
fi

BASE_REF="${1}"
HEAD_BRANCH="${2}"
GITHUB_TOKEN="${3}"

echo "GITHUB_TOKEN=${GITHUB_TOKEN}"

if [[ -z "${BASE_REF}" ]]; then
  echo "Missing \$BASE_REF"
  exit 1
fi

if [[ -z "${HEAD_BRANCH}" ]]; then
  echo "Missing \$HEAD_BRANCH"
  exit 1
fi

if ! git check-ref-format --allow-onelevel --normalize "${BASE_REF}"; then
  echo "BASE_REF is invalid: ${BASE_REF}"
else
  BASE_REF=$(git check-ref-format --allow-onelevel --normalize "${BASE_REF}")
fi

if ! git check-ref-format --allow-onelevel --normalize "${HEAD_BRANCH}"; then
  echo "HEAD_BRANCH is invalid: ${HEAD_BRANCH}"
else
  HEAD_BRANCH=$(git check-ref-format --allow-onelevel --normalize "${HEAD_BRANCH}")
fi

echo "BASE_REF=${BASE_REF}"
echo "HEAD_BRANCH=${HEAD_BRANCH}"

git init
git remote add origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

git config user.name "${GITHUB_ACTOR}"
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"

git remote -v

# These refs exist at the remote, but not at our local clone/checkout.
if [[ "${BASE_REF}" == refs/heads/* ]]; then
  BASE_REF="${BASE_REF#refs/heads/}"
elif [[ "${BASE_REF}" == refs/remotes/* ]]; then
  BASE_REF="${BASE_REF#refs/remotes/}"
elif [[ "${BASE_REF}" == refs/tags/* ]]; then
  BASE_REF="${BASE_REF#refs/tags/}"
fi

if [[ "${HEAD_BRANCH}" == refs/heads/* ]]; then
  HEAD_BRANCH="${HEAD_BRANCH#refs/heads/}"
elif [[ "${HEAD_BRANCH}" == refs/remotes/* ]]; then
  HEAD_BRANCH="${HEAD_BRANCH#refs/remotes/}"
elif [[ "${HEAD_BRANCH}" == refs/tags/* ]]; then
  HEAD_BRANCH="${HEAD_BRANCH#refs/tags/}"
fi

git fetch --unshallow origin "${BASE_REF}" "${HEAD_BRANCH}"

git switch "${HEAD_BRANCH}"
git rebase --autosquash --autostash origin/"${BASE_REF}" "${HEAD_BRANCH}"
git push --force origin "${HEAD_BRANCH}"
