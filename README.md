# RPZ-Blocklists

Multi-Source RPZ Blocklists for DNS Filtering (automated conversion and updates)

This repository provides categorized, automatically converted Response Policy Zone (RPZ) blocklists from various free sources. The goal is to offer an easy-to-use, regularly updated collection for DNS filtering with Unbound or any RPZ-compatible resolver.

## Repository Structure

```text
RPZ-Blocklists/
├── ads/         # RPZ files for ad and tracker domains
├── malware/     # RPZ files for malware and malicious domains
├── phishing/    # RPZ files for phishing and fraud domains
├── tracking/    # RPZ files for tracking and spyware domains
├── misc/        # RPZ files for mixed or uncategorized sources
├── tools/
│   ├── urllist.txt             # List of all blocklist sources (<category>,<url> per line)
│   ├── blocklist2rpz-multi.pl  # Perl script to convert and validate blocklists
│   └── logs/                   # (Git-ignored) log files for errors, status, validation
└── README.md
```

## How to Use

    Edit Blocklist Sources:
    Edit tools/urllist.txt to add or remove blocklist sources.
    The file must use the format <category>,<url> (e.g. ads,https://adaway.org/hosts.txt).
    Categories determine the output subdirectory.

    Convert Lists to RPZ:
    Use the Perl script to fetch, convert, and validate blocklists. Example:
    `perl tools/blocklist2rpz-multi.pl -w -d ./ -l tools/urllist.txt \
  -e tools/logs/error_$(date +%Y%m%d_%H%M%S).log \
  -s tools/logs/status_$(date +%Y%m%d_%H%M%S).txt \
  --validate --validation-report tools/logs/validation_$(date +%Y%m%d_%H%M%S).txt`

    -w enables wildcard entries.

    -d sets the output base directory (here: current directory, subfolders by category).

    -l specifies the source list.

    --validate checks the generated RPZ files.

    --validation-report writes a validation summary.

    -e and -s write error and status logs (recommended: use tools/logs/).

For more options, run:
    `perl tools/blocklist2rpz-multi.pl --help`



    Integrate with Unbound (or similar):
    The generated .rpz files can be included in your DNS resolver configuration.

## Categories

    ads: Ad and tracker domains

    malware: Malware, botnets, exploit domains

    phishing: Phishing and fraud domains

    tracking: Tracking, spyware, telemetry

    misc: Mixed or uncategorized sources

## Automation with GitHub Actions

This repository includes a GitHub Actions workflow that automatically updates all RPZ blocklists on a regular schedule (e.g., daily). The workflow:

- Checks out the repository
- Installs required Perl dependencies
- Runs the conversion and validation script
- Commits and pushes any updated `.rpz` files automatically

You can find the workflow file in `.github/workflows/update-rpz.yml`.  
Manual runs are also possible via the GitHub Actions tab.

*Tip: Locally generated RPZ files are not required; the workflow will always generate fresh lists on the server.*

Logging and .gitignore

    All logs (error, status, validation) are stored in tools/logs/ and are excluded from the repository via .gitignore.

    This keeps the repository clean and avoids committing large or sensitive log files.

Notes

    Blocklists are updated and validated regularly.

    All tools and configuration files are located in the tools/ directory.

    Failed or unreachable sources are logged automatically.

    The script warns if a GitHub HTML URL is detected (use RAW URLs!).

Contributing

Contributions and suggestions for new high-quality sources are welcome!
Feel free to open an issue or pull request.
