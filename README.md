# Local Git Rebase

This task rebases a local branch onto another local branch or ref, all within the current GitHub repository.

Use this task to automate rebases within your own GitHub repository. Useful for floating ongoing work on top of an existing long-running branch or tag. (Such as when maintaining a fork.) For rebasing on top of a branch from another repository, considering triggering this task against a branch managed by an automated pull utility, such as this one from the Probot community: https://probot.github.io/apps/pull/)

## Usage (example workflow):

```yaml
name: Example Rebase
on:
  push:
    branches:
      # All pushes to this branch will trigger the task.
      - my-rebase-upstream-branch
    tags:
      # All pushes to this tag will trigger the task.
      - my-rebase-upstream-tag

jobs:
  rebase_branches:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
        with:
          # Default ref to checkout is the ref that triggered the workflow.
          # Set manually to override this behavior (we want to checkout the "rebase head" branch).
          ref: my-rebase-head-breanch
      # Recommended: specify a version such as `@v1.0` rather than `@main`
      - uses: DeeDeeG/rebase-github-action@main
        with:
          # Head branch, which will be rebased onto the base_ref.
          head_branch: my-rebase-head-breanch
          # Branch, or Git ref, that the head_branch will be rebased onto.
          base_ref: my-rebase-upstream-ref-or-branch
```

### Requirements

- `base_ref` must be a valid ref according to the folowing Git command:

  - `git check-ref-format --allow-onelevel --normalize "${base_ref}"`

- `base_ref` must be an existing ref or branch at your GitHub repository.

- `head_branch` must be an existing branch at your GitHub repository.

## Acknlowledgements

This Action is based heavily on:
-  https://github.com/actions-registry/github-repo-sync-upstream 
and somewhat on:
-  https://github.com/everlytic/branch-merge.

Their license notices can be viewed here:
https://github.com/DeeDeeG/rebase-github-action/tree/main/UPSTREAM_LICENSE_NOTICES

If you want to rebase your branch on top of an upstream of your fork, and you don't mind scheduling the Action, consider just using https://github.com/actions-registry/github-repo-sync-upstream. that Action is the rebase-across-repositories version, whereas this Action is the local-to-your-repository version.
