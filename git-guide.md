# Git Guide for RPZ-Blocklists

This guide provides essential Git commands and best practices for contributing to the RPZ-Blocklists repository.
It is designed for developers contributing via feature or patch branches, with frequent automated updates from the GitHub Actions workflow.

## Prerequisites

Install Git (Linux):
```bash
sudo apt install git
```
For other operating systems, use the appropriate package manager or installer.

## Configure Git

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

## Required Perl Modules

To run the provided Perl scripts locally, you can install the required Perl modules with this command:
```bash
cpan install LWP::UserAgent LWP::Protocol::https IO::Socket::SSL Text::CSV JSON XML::Simple URI Getopt::Long POSIX File::Basename File::Path
```
Or, with cpanm (if available):
```bash
cpanm LWP::UserAgent LWP::Protocol::https IO::Socket::SSL Text::CSV JSON XML::Simple URI Getopt::Long POSIX File::Basename File::Path
```

## Recommended Workflow: Feature or Patch Branches

Note:
Working directly on main is discouraged.
Always create a feature or patch branch for your changes and use Pull Requests to merge into main.

1. **Clone the Repository**

```bash
git clone https://github.com/twitOne/RPZ-Blocklists.git
cd RPZ-Blocklists
```

2. **Update Your Local main**

Before starting new work, ensure your local main is up to date and Pull Latest Changes
```bash
git pull --rebase origin main
```

3. **Create a New Branch**

Name your branch according to the feature or fix you are working on:
```bash
git checkout -b feature/your-feature-name
# or for bugfixes:
git checkout -b patch/your-fix-description

```

4. **Make and Test Your Changes**

Edit and test your files locally as needed:
```bash
# Edit files, e.g.:
vim tools/urllist.txt
# Test locally
perl tools/blocklist2rpz-multi.pl -w -d ./ -l tools/urllist.txt -m tools/list-mappings.csv
```

5. **Commit Your Changes**

```bash
git add .
git commit -m "Descriptive message (e.g., Add new blocklist source)"
```

6. **Push Your Branch to Github**

For the first push of a new branch, set the upstream:
```bash
git push -u origin feature/your-feature-name
```
For subsequent pushes, simply use:
```bash
git push
```
or use the pushup alias (see below).

Note:
When working on a feature or patch branch, you can use the following alias to update your branch with the latest changes from main and push it safely:
```bash
git config --global alias.pushup '!git fetch origin && git rebase origin/main && git push origin HEAD'
```
Now you can update and push your branch with a single command:
```bash
git pushup
```
This ensures your branch is up to date before pushing and avoids conflicts with frequent workflow commits on main.
Always create a Pull Request to merge your branch into main after pushing.

7. **Create a Pull Request**

After pushing your branch, open a Pull Request on GitHub to merge your branch into main.
Request a review if needed. Only after approval and successful checks should the changes be merged.

## Working Directly on main (Not Recommended)

If you must work directly on main, set up this alias to avoid "fetch first" errors due to frequent workflow commits:

```bash
git config --global alias.pushup '!git pull --rebase origin main && git push origin main'
```
After committing, run:
```bash
git pushup
```

## Handling Conflicts

The workflow updates `.rpz` files hourly, so conflicts are rare unless you edit the same files (e.g., `urllist.txt`).  
If `git pull --rebase` fails:

1. Resolve conflicts in the marked files (`<<<<<<<`, `=======`, `>>>>>>>`).
2. Continue with:
    ```
    git add <file>
    git rebase --continue
    git push origin <your-branch>
    ```

## Best Practices

- Pull Frequently: Run `git pull --rebase origin main` before editing to stay in sync.
- Commit Often: Small, focused commits with clear messages (e.g., “Update README with guide”).
- Test Locally: Validate changes with the Perl script before pushing.
- Avoid Force Push: Never use `git push --force` in this repo to prevent overwriting workflow commits.
- Check Workflow Logs: After pushing, verify the GitHub Actions run in the “Actions” tab.

## Running GitHub Actions Workflows Locally

You can test and run GitHub Actions workflows locally using the [act](https://github.com/nektos/act) tool.

By default, act requires Docker to simulate the GitHub Actions environment.
If you do not want to use Docker, you can run act in "self-hosted" mode, but this comes with limitations (no isolation, some actions may not work as expected)

```bash
# Run act with Docker (recommended)
act

# Run act without Docker (less isolation, may not work for all workflows)
act -P ubuntu-latest=-self-hosted
```

- Make sure to install act and (for the default mode) Docker on your system.
- For more details, see the [act documentation](https://github.com/nektos/act).

**Note:**  
- Running workflows locally is helpful for debugging and developing workflows before pushing to GitHub.
- Some GitHub-hosted features may behave differently or be unavailable without Docker or in self-hosted mode.

## GitHub Actions Workflow

The repository uses GitHub Actions to automatically update RPZ blocklists every hour.
The workflow currently sets up Perl 5.36 and installs the following modules:

- LWP::UserAgent
- LWP::Protocol::https
- IO::Socket::SSL
- Text::CSV
- JSON
- XML::Simple

If you require additional modules, update both your local environment and the workflow configuration.

## Notes

- The workflow commits to main hourly (e.g., commit 17c20fb), so always pull before pushing.
- Logs are in tools/logs/ (git-ignored) and available as rpz-logs artifacts in GitHub Actions.
- For questions, open an issue or ping the team.

**Happy contributing!**
