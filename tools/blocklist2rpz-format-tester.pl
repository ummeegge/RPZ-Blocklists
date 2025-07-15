#!/usr/bin/perl

###############################################################################
# blocklist2rpz-format-tester.pl - Blocklist Format Tester for RPZ Conversion
#
# Purpose:
#   This script is a helper tool for the RPZ-Blocklists project
#   (https://github.com/twitOne/RPZ-Blocklists) to test whether blocklists can
#   be successfully converted to Response Policy Zone (RPZ) format before being
#   processed by blocklist2rpz-multi.pl. It reads a blocklist from a file, URL,
#   or STDIN, extracts domains, and outputs them in RPZ format to STDOUT.
#   Unprocessed lines are reported for debugging purposes.
#
# Features:
#   - Supports multiple input formats defined in @INPUT_FORMATS (e.g., Hosts,
#     Adblock Plus, Plain Domains, URLs, RPZ formats)
#   - Lines starting with # or ; are treated as comments
#   - Supports wildcard entries (*.<domain> CNAME .) with --wildcards/-w
#   - Optional exclusion of SOA/NS records with --no-soa/-n
#   - Converts Unicode domains (e.g., münchen.de) to Punycode (e.g., xn--mnchen-3ya.de)
#   - Outputs unprocessed lines for debugging potential format issues
#   - Validates domains to ensure they are suitable for RPZ
#   - Outputs to STDOUT for easy inspection
#   - Debug mode (--debug) for detailed processing information
#   - Detailed statistics on matched formats
#   - Optional logging of warnings to a file (--log-file)
#   - Reports processing time in the summary
#
# Supported Input Formats:
#   - Hosts: e.g., "0.0.0.0 example.com"
#   - Adblock Plus: e.g., "||example.com^"
#   - Plain Domain: e.g., "example.com" or "*.example.com"
#   - CSV/Tab-separated: e.g., "example.com,category"
#   - URL: e.g., "https://example.com"
#   - RPZ formats: CNAME, NXDOMAIN, DROP, NODATA, PASSTHRU, TXT, A, AAAA
#   - Invalid or duplicate domains are skipped automatically
#
# Usage:
#   perl blocklist2rpz-format-tester.pl [options] [URL]
#
# Options:
#   --wildcards, -w         Output wildcard RPZ entries (*.<domain> CNAME .)
#   --no-soa, -n            Do not output SOA and NS records in the RPZ file
#   --input, -i <file>      Input file with blocklist (default: STDIN or URL)
#   --debug, -d             Enable debug output to STDERR
#   --log-file, -l <file>   Write warnings to a log file instead of STDERR
#   --help, -h              Show this help message
#
# Examples:
#   perl blocklist2rpz-format-tester.pl https://raw.githubusercontent.com/badmojr/1Hosts/main/Lite/domains.txt
#   perl blocklist2rpz-format-tester.pl -w -i blocklist.txt -d
#   cat blocklist.txt | perl blocklist2rpz-format-tester.pl --wildcards --log-file errors.log
#
# Notes:
#   - This script is designed to test blocklist compatibility before adding them
#     to tools/urllist.txt or tools/list-mappings.csv in the RPZ-Blocklists project.
#   - Use the output to verify if domains are correctly extracted and converted.
#   - Unprocessed lines indicate potential format issues that may require new regex
#     patterns in @INPUT_FORMATS.
#
# Dependencies:
#   - Perl 5.10 or newer
#   - Core modules: strict, warnings, Getopt::Long, POSIX, Encode, Time::HiRes
#   - CPAN modules: LWP::UserAgent (for URL fetching)
#   - Optional: Encode::Punycode (for Unicode domain conversion, may require CPAN install)
#
# Author: ummeegge
# Version: 0.3.0
# Last Modified: 2025-07-15
# License: GNU General Public License v3.0 (GPLv3)
#
###############################################################################

use strict;
use warnings;
use Getopt::Long;
use LWP::UserAgent;
use POSIX qw(strftime);
use Encode qw(encode);
use Time::HiRes qw(time);  # For high-resolution timing

# Input format definitions for blocklist conversion to RPZ
# Each format includes:
# - name:    Descriptive name for logging
# - regex:   Regular expression to match the input line and capture the domain
# - group:   Capture group index containing the domain (usually 1 or 2)
my @INPUT_FORMATS = (
    {
        name   => 'Hosts',  # e.g., "0.0.0.0 example.com"
        regex  => qr/^\s*(?:0\.0\.0\.0|127\.0\.0\.1)\s+([^\s]+)/,
        group  => 1,
    },
    {
        name   => 'Adblock Plus',  # e.g., "||example.com^"
        regex  => qr/^\|\|([^\^]+)\^/,
        group  => 1,
    },
    {
        name   => 'Plain Domain',  # e.g., "example.com" or "*.example.com"
        regex  => qr/^(\*?[^\s]+?\.[^\s]+?)\s*(?:[#;].*)?$/,
        group  => 1,
    },
    {
        name   => 'CSV/Tab-separated',  # e.g., "example.com,category" or "example.com\tcategory"
        regex  => qr/^(\*?[^\s]+?\.[^\s]+?)[,\t]/,
        group  => 1,
    },
    {
        name   => 'URL',  # e.g., "https://example.com", "http://sub.example.co.uk/path", "https://*.xn--mnchen-3ya.de"
        regex  => qr{^https?://((?:[a-zA-Z0-9_-]+\.)*[a-zA-Z0-9_-]+\.[a-zA-Z0-9-]{2,})(?:/.*)?$},
        group  => 1,
    },
    # RPZ formats
    {
        name   => 'RPZ CNAME',  # e.g., "example.com CNAME .", "*.example.com CNAME ."
        regex  => qr/^(\*\.)?((?:[a-zA-Z0-9_-]+\.)+[a-zA-Z0-9-]{2,})\s+CNAME\s+\.$/,
        group  => 2,  # group 2 = domain (without wildcard), group 1 = wildcard if present
    },
    {
        name   => 'RPZ NXDOMAIN',  # e.g., "example.com NXDOMAIN .", "*.example.com NXDOMAIN ."
        regex  => qr/^(\*\.)?((?:[a-zA-Z0-9_-]+\.)+[a-zA-Z0-9-]{2,})\s+NXDOMAIN\s+\.$/,
        group  => 2,
    },
    {
        name   => 'RPZ DROP',  # e.g., "example.com DROP ."
        regex  => qr/^(\*\.)?((?:[a-zA-Z0-9_-]+\.)+[a-zA-Z0-9-]{2,})\s+DROP\s+\.$/,
        group  => 2,
    },
    {
        name   => 'RPZ NODATA',  # e.g., "example.com NODATA ."
        regex  => qr/^(\*\.)?((?:[a-zA-Z0-9_-]+\.)+[a-zA-Z0-9-]{2,})\s+NODATA\s+\.$/,
        group  => 2,
    },
    {
        name   => 'RPZ PASSTHRU',  # e.g., "example.com PASSTHRU ."
        regex  => qr/^(\*\.)?((?:[a-zA-Z0-9_-]+\.)+[a-zA-Z0-9-]{2,})\s+PASSTHRU\s+\.$/,
        group  => 2,
    },
    {
        name   => 'RPZ TXT',  # e.g., "example.com TXT \"some text\""
        regex  => qr/^(\*\.)?((?:[a-zA-Z0-9_-]+\.)+[a-zA-Z0-9-]{2,})\s+TXT\s+"(.*?)"$/,
        group  => 2,  # group 2 = domain, group 3 = TXT content
    },
    {
        name   => 'RPZ A',  # e.g., "example.com A 127.0.0.1"
        regex  => qr/^(\*\.)?((?:[a-zA-Z0-9_-]+\.)+[a-zA-Z0-9-]{2,})\s+A\s+(\d{1,3}(?:\.\d{1,3}){3})$/,
        group  => 2,  # group 2 = domain, group 3 = IP
    },
    {
        name   => 'RPZ AAAA',  # e.g., "example.com AAAA 2001:db8::1"
        regex  => qr/^(\*\.)?((?:[a-zA-Z0-9_-]+\.)+[a-zA-Z0-9-]{2,})\s+AAAA\s+([0-9a-fA-F:]+)$/,
        group  => 2,  # group 2 = domain, group 3 = IPv6
    },
);

# Command-line options
my $wildcards = 0;    # Output wildcard RPZ entries (*.<domain> CNAME .)
my $no_soa = 0;       # Do not output SOA and NS records
my $input_file;       # Optional input file
my $url;              # URL for direct download
my $debug = 0;        # Enable debug output
my $log_file;         # Optional log file for warnings
my $help = 0;         # Show help message

GetOptions(
    'wildcards|w'    => \$wildcards,
    'no-soa|n'       => \$no_soa,
    'input|i=s'      => \$input_file,
    'debug|d'        => \$debug,
    'log-file|l=s'   => \$log_file,
    'help|h'         => \$help,
) or die "Error in command line arguments. Use --help for usage.\n";

# Check for URL as command-line argument
if (@ARGV && $ARGV[0] =~ /^https?:\/\//) {
    $url = shift @ARGV;
}

# Show help if requested or no input provided
if ($help || (!$input_file && !$url && !(-t STDIN))) {
    print <<USAGE;
Usage: $0 [options] [URL]
Options:
    --wildcards, -w         Output wildcard RPZ entries (*.<domain> CNAME .)
    --no-soa, -n            Do not output SOA and NS records in the RPZ file
    --input, -i <file>      Input file with blocklist (default: STDIN or URL)
    --debug, -d             Enable debug output to STDERR
    --log-file, -l <file>   Write warnings to a log file instead of STDERR
    --help, -h              Show this help message
Example:
    $0 https://raw.githubusercontent.com/badmojr/1Hosts/main/Lite/domains.txt
    $0 -w -i blocklist.txt -d
    cat blocklist.txt | $0 --wildcards --log-file errors.log
USAGE
    exit 0;
}

# Open log file if specified
my $log_fh;
if ($log_file) {
    open $log_fh, '>>', $log_file or die "Cannot open log file $log_file: $!\n";
    print $log_fh "Log started at " . localtime() . "\n";
}

# Record start time
my $start_time = time();

# Read input from file, URL, or STDIN
my $content;
if ($url) {
    my $ua = LWP::UserAgent->new(timeout => 20);
    my $resp = $ua->get($url);
    die "Could not fetch $url: " . $resp->status_line . "\n" unless $resp->is_success;
    $content = $resp->decoded_content;
} elsif ($input_file) {
    open my $fh, '<', $input_file or die "Cannot open $input_file: $!\n";
    $content = do { local $/; <$fh> };
    close $fh;
} else {
    $content = do { local $/; <STDIN> };
    die "No input provided (use --input, URL, or pipe to STDIN)\n" unless $content;
}

# Convert blocklist to RPZ and output to STDOUT
my ($entry_count, $unprocessed_lines_ref, $format_stats_ref) = convert_blocklist_to_rpz($content, $wildcards, $no_soa, $debug, $log_fh);

# Calculate processing time
my $end_time = time();
my $processing_time = sprintf("%.2f", $end_time - $start_time);

# Print summary
print "\n" . "=" x 80 . "\n";
print "Summary:\n";
print "Processed domains: $entry_count\n";
print "Unprocessed lines: " . scalar(@$unprocessed_lines_ref) . "\n";
print "Processing time: $processing_time seconds\n";
print "Format statistics:\n";
foreach my $format (sort keys %$format_stats_ref) {
    print "  $format: $format_stats_ref->{$format} lines\n";
}
print "=" x 80 . "\n";

# Ask user if they want to see unprocessed lines
if (@$unprocessed_lines_ref) {
    print "Would you like to display unprocessed lines? (y/n): ";
    my $response = <STDIN>;
    chomp $response;
    if (lc($response) eq 'y') {
        print "\nUnprocessed lines:\n";
        print "------------------\n";
        print "$_\n" for @$unprocessed_lines_ref;
        print "------------------\n";
    }
}

# Close log file if open
if ($log_fh) {
    print $log_fh "Log ended at " . localtime() . "\n";
    close $log_fh;
}

exit 0;

# Log warnings to file or STDERR
sub log_warning {
    my ($message, $log_fh) = @_;
    if ($log_fh) {
        print $log_fh "$message\n";
    } else {
        warn "$message\n";
    }
}

# Convert Unicode domains to Punycode
sub convert_to_punycode {
    my ($domain, $debug, $log_fh) = @_;
    if ($domain =~ /[^\x00-\x7F]/) { # Contains non-ASCII characters
        eval {
            my $punycode = encode('Punycode', $domain);
            $punycode = "xn--$punycode" if $punycode !~ /^xn--/;
            log_warning("Converted '$domain' to Punycode: $punycode", $log_fh) if $debug;
            return $punycode;
        } or do {
            log_warning("Could not convert '$domain' to Punycode: $@. Ensure the domain contains valid Unicode characters.", $log_fh);
            return undef;
        };
    }
    return $domain;
}

# Convert blocklist to RPZ format
sub convert_blocklist_to_rpz {
    my ($content, $wildcards, $no_soa, $debug, $log_fh) = @_;
    my %seen;
    my %seen_wildcard; # Track wildcard entries separately
    my $entry_count = 0;
    my @unprocessed_lines;
    my %format_stats; # Track matches per format
    my @output_lines; # Store output for delayed printing

    # Prepare RPZ header
    unless ($no_soa) {
        my $current_date = strftime("%Y%m%d", gmtime);
        my $serial = sprintf("%s%02d", $current_date, 1);
        push @output_lines, "\$TTL 300";
        push @output_lines, "@ SOA localhost. root.localhost. $serial 43200 3600 86400 300";
        push @output_lines, "  NS  localhost.";
    }
    push @output_lines, ";";
    push @output_lines, "; Generated by blocklist2rpz-format-tester.pl on " . localtime();
    push @output_lines, "; Wildcards: " . ($wildcards ? "enabled" : "disabled");
    push @output_lines, "; SOA/NS records: " . ($no_soa ? "disabled" : "enabled");
    push @output_lines, "; Number of entries: <COUNT>"; # Placeholder for entry count
    push @output_lines, "; Conversion date: " . localtime();
    push @output_lines, "; ======================";
    push @output_lines, ";";

    # Process each line and store valid entries
    foreach my $line (split /\n/, $content) {
        chomp $line;
        my $orig_line = $line;
        $line =~ s/\r$//;
        $line =~ s/^\s+|\s+$//g;
        if ($line =~ /^\s*[#;!]/) {
            push @output_lines, "; $line";
            $format_stats{'Comment'}++;
            next;
        }
        next if $line =~ /^\s*$/;
        my $domain;
        my $is_wildcard = 0;
        my $matched_format;
        foreach my $format (@INPUT_FORMATS) {
            if ($line =~ $format->{regex}) {
                $is_wildcard = defined $1 && $1 eq '*.'; # Check for wildcard prefix
                $domain = $format->{group} == 1 ? $1 : $2; # Select the correct capture group
                $matched_format = $format->{name};
                $format_stats{$matched_format}++;
                last;
            }
        }
        if (!$domain) {
            log_warning("No domain matched for line: $orig_line", $log_fh) if $debug;
            push @unprocessed_lines, $orig_line;
            $format_stats{'Unprocessed'}++;
            next;
        }
        $domain =~ s/^\*\.//; # Remove *. if present
        log_warning("Extracted domain '$domain' from line: $orig_line (Format: $matched_format)", $log_fh) if $debug;
        $domain = convert_to_punycode($domain, $debug, $log_fh);
        if (!defined $domain || !is_valid_domain($domain, $debug, $log_fh)) {
            log_warning("Invalid domain '$domain' in line: $orig_line", $log_fh) if $debug;
            push @unprocessed_lines, $orig_line;
            $format_stats{'Invalid'}++;
            next;
        }
        if ($is_wildcard) {
            if (!$seen_wildcard{$domain}++) {
                push @output_lines, "*.$domain CNAME .";
                $entry_count++;
                log_warning("Added wildcard entry: *.$domain CNAME .", $log_fh) if $debug;
            } else {
                log_warning("Skipped duplicate wildcard entry: *.$domain", $log_fh) if $debug;
            }
        } else {
            if (!$seen{$domain}++) {
                push @output_lines, "$domain CNAME .";
                $entry_count++;
                log_warning("Added entry: $domain CNAME .", $log_fh) if $debug;
                if ($wildcards && !$seen_wildcard{$domain}) {
                    push @output_lines, "*.$domain CNAME .";
                    $seen_wildcard{$domain}++;
                    $entry_count++;
                    log_warning("Added wildcard entry: *.$domain CNAME .", $log_fh) if $debug;
                }
            } else {
                log_warning("Skipped duplicate entry: $domain", $log_fh) if $debug;
            }
        }
    }

    # Update header with correct entry count
    for (my $i = 0; $i < @output_lines; $i++) {
        if ($output_lines[$i] =~ /Number of entries: <COUNT>/) {
            $output_lines[$i] = "; Number of entries: $entry_count";
            last;
        }
    }

    # Print all output lines
    print "$_\n" for @output_lines;

    return ($entry_count, \@unprocessed_lines, \%format_stats);
}

# Validate domain format
sub is_valid_domain {
    my ($d, $debug, $log_fh) = @_;
    if ($d =~ /^\d+\.\d+\.\d+\.\d+$/) {
        log_warning("Domain '$d' rejected: matches IPv4 pattern", $log_fh) if $debug;
        return 0;
    }
    if ($d =~ /^\[?[a-fA-F0-9:.]+\]?$/ && $d !~ /\.[a-zA-Z]{2,}$/) {
        log_warning("Domain '$d' rejected: matches IPv6 pattern", $log_fh) if $debug;
        return 0;
    }
    if ($d =~ /^(?:[a-zA-Z0-9_-]+\.)*[a-zA-Z0-9_-]+\.[a-zA-Z0-9-]{2,}$/) {
        return 1;
    }
    log_warning("Domain '$d' rejected: does not match valid domain pattern", $log_fh) if $debug;
    return 0;
}

# EOF

