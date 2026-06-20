# Upstream v1.0.2 Review Plan

Use this process later from a clean `relay-branding-v0` working tree. It prepares a read-only comparison before any integration decision.

## 1. Confirm remotes and add upstream if missing

```powershell
git status --short
git remote -v
git remote add upstream https://github.com/open-jarvis/OpenJarvis.git
```

Run `git remote add upstream` only if an `upstream` remote does not already exist.

## 2. Fetch upstream references

```powershell
git fetch upstream --tags --prune
git tag --list "v1.0.2"
git show --no-patch --decorate refs/tags/v1.0.2
```

## 3. Review the change size and affected files

```powershell
git diff --stat relay-v0.4-local-command-center..refs/tags/v1.0.2
git diff --name-status relay-v0.4-local-command-center..refs/tags/v1.0.2
git log --left-right --graph --cherry-pick --oneline relay-v0.4-local-command-center...refs/tags/v1.0.2
```

Review branding, CLI aliases, frontend copy, launcher scripts, default model behavior, and compatibility identifiers before considering any integration.

> Do not run `jarvis self-update` on the Relay fork.
>
> Do not merge upstream without review.
