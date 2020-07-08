#!/usr/bin/env bash

set -e
# set -x

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
REBASED_BRANCH="${2}"
FETCH_DEPTH="${3}"
GITHUB_TOKEN="${4}"

if [[ -z "${BASE_REF}" ]]; then
  echo "Missing \$BASE_REF"
  exit 1
fi

if [[ -z "${REBASED_BRANCH}" ]]; then
  echo "Missing \$REBASED_BRANCH"
  exit 1
fi

if ! git check-ref-format --allow-onelevel --normalize "${BASE_REF}" &>/dev/null; then
  echo "BASE_REF is invalid: ${BASE_REF}"
else
  BASE_REF=$(git check-ref-format --allow-onelevel --normalize "${BASE_REF}")
fi

if ! git check-ref-format --allow-onelevel --normalize "${REBASED_BRANCH}" &>/dev/null; then
  echo "REBASED_BRANCH is invalid: ${REBASED_BRANCH}"
else
  REBASED_BRANCH=$(git check-ref-format --allow-onelevel --normalize "${REBASED_BRANCH}")
fi

echo "BASE_REF=${BASE_REF}"
echo "REBASED_BRANCH=${REBASED_BRANCH}"

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

if [[ "${REBASED_BRANCH}" == refs/heads/* ]]; then
  REBASED_BRANCH="${REBASED_BRANCH#refs/heads/}"
elif [[ "${REBASED_BRANCH}" == refs/remotes/* ]]; then
  REBASED_BRANCH="${REBASED_BRANCH#refs/remotes/}"
elif [[ "${REBASED_BRANCH}" == refs/tags/* ]]; then
  REBASED_BRANCH="${REBASED_BRANCH#refs/tags/}"
fi

git fetch --deepen="${FETCH_DEPTH}" origin "${BASE_REF}" "${REBASED_BRANCH}"

git switch "${REBASED_BRANCH}"
git rebase --autosquash --autostash origin/"${BASE_REF}" "${REBASED_BRANCH}"
git push --force-with-lease origin "${REBASED_BRANCH}"
