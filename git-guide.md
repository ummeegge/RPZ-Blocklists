# Git Guide for RPZ-Blocklists

This guide provides essential Git commands and best practices for contributing to the RPZ-Blocklists repository. It’s designed for developers working on the main branch with frequent automated updates from the GitHub Actions workflow.
Prerequisites

Install Git: sudo apt install git (Linux) or equivalent for your OS.
Configure Git:git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"



## Basic Workflow

Clone the Repository:
```bash
git clone https://github.com/twitOne/RPZ-Blocklists.git
cd RPZ-Blocklists
```

Pull Latest Changes:Before making changes, sync with the remote main branch:
`git pull --rebase origin main`


Make Changes:Edit files (e.g., tools/urllist.txt, README.md). Test locally:
`perl tools/blocklist2rpz-multi.pl -w -d ./ -l tools/urllist.txt -m tools/list-mappings.csv`


Commit Changes:
```bash
git add .
git commit -m "Descriptive message (e.g., Add new blocklist source)"
```

Push Changes:Use the pushup alias to pull remote changes and push safely:
`git pushup`

See “Set Up Pushup Alias” below for setup.


Set Up Pushup Alias
To avoid “fetch first” errors due to frequent workflow commits, use this alias:
`git config --global alias.pushup '!git pull --rebase origin main && git push origin main'`


Usage: After committing, run git pushup.
Why: It pulls remote changes with --rebase to keep history clean, then pushes.
Conflicts: If conflicts occur, resolve them:# Edit conflicting files, resolve markers (<<<<<<<, =======, >>>>>>>)
```bash
git add <file>
git rebase --continue
git push origin main
```


Handling Conflicts
The workflow updates .rpz files hourly, so conflicts are rare unless you edit the same files (e.g., urllist.txt). If `git pull --rebase` fails:

Resolve conflicts in marked files.
Continue with:
```bash
git add <file>
git rebase --continue
git push origin main
```


Best Practices

    - Pull Frequently: Run `git pull --rebase origin main` before editing to stay in sync.
    - Commit Often: Small, focused commits with clear messages (e.g., “Update README with guide”).
    - Test Locally: Validate changes with the Perl script before pushing.
    - Avoid Force Push: Never use git push --force in this repo to prevent overwriting workflow commits.
    - Check Workflow Logs: After pushing, verify the GitHub Actions run in the “Actions” tab.

Notes

The workflow commits to main hourly (e.g., commit 17c20fb), so always pull before pushing.
Logs are in tools/logs/ (git-ignored) and available as rpz-logs artifacts in GitHub Actions.
For questions, open an issue or ping the team.
