#!/usr/bin/env bash
#
# CVE Validation Script for Unix/Linux/Mac
# Queries GitHub Security Advisories REST API to validate dependencies.
# Supports Maven (Java) and NuGet (.NET) ecosystems.
# Requires: curl, jq
#

set -euo pipefail

# Auto-set GITHUB_TOKEN from gh CLI if not already set
if [[ -z "${GITHUB_TOKEN:-}" ]] && command -v gh &>/dev/null; then
    GITHUB_TOKEN=$(gh auth token 2>/dev/null) && export GITHUB_TOKEN || true
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Defaults
DEPENDENCIES=""
OUTPUT_FILE=""
FORMAT="text"
ECOSYSTEM=""
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

show_help() {
    cat << 'EOF'
Usage: cve.sh [OPTIONS]

Validate CVEs for dependencies using GitHub Security Advisories.
Supports Maven (Java) and NuGet (.NET) ecosystems.

OPTIONS:
    --dependencies <deps>    Comma-separated dependency coordinates (required)
                            Maven format:  groupId:artifactId:version
                            NuGet format:  PackageName:version
    --ecosystem <type>      Package ecosystem: maven|nuget (optional)
                            Auto-detected from dependency format if omitted
    --output <file>         Output file path (optional)
    --format <type>         Output format: json|text|markdown (default: text)
    --github-token <token>  GitHub token for higher rate limits (optional)
    --help                  Show this help message

EXAMPLES:
    # Java / Maven
    cve.sh --dependencies "org.springframework:spring-core:5.3.9"
    cve.sh --ecosystem maven --dependencies "org.springframework:spring-core:5.3.9,log4j:log4j:1.2.17"

    # .NET / NuGet
    cve.sh --dependencies "Newtonsoft.Json:12.0.3"
    cve.sh --ecosystem nuget --dependencies "Newtonsoft.Json:12.0.3,System.Text.Json:6.0.0"

ENVIRONMENT VARIABLES:
    GITHUB_TOKEN    GitHub Personal Access Token (raises rate limit from 60 to 5000 req/hr)
EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dependencies) DEPENDENCIES="$2"; shift 2 ;;
        --ecosystem) ECOSYSTEM="$2"; shift 2 ;;
        --output) OUTPUT_FILE="$2"; shift 2 ;;
        --format) FORMAT="$2"; shift 2 ;;
        --github-token) GITHUB_TOKEN="$2"; shift 2 ;;
        --help|-h) show_help ;;
        *) echo -e "${RED}Error: Unknown option $1${NC}" >&2; exit 1 ;;
    esac
done

# Validate inputs
if [[ -z "$DEPENDENCIES" ]]; then
    echo -e "${RED}Error: --dependencies is required${NC}" >&2
    exit 1
fi

# Auto-detect ecosystem from the first dependency if not specified
if [[ -z "$ECOSYSTEM" ]]; then
    first_dep=$(echo "$DEPENDENCIES" | cut -d',' -f1 | xargs)
    colon_count=$(echo "$first_dep" | tr -cd ':' | wc -c | tr -d ' ')
    if [[ "$colon_count" -ge 2 ]]; then
        ECOSYSTEM="maven"
    else
        ECOSYSTEM="nuget"
    fi
    echo -e "${YELLOW}Auto-detected ecosystem: $ECOSYSTEM${NC}" >&2
fi

if [[ "$ECOSYSTEM" != "maven" && "$ECOSYSTEM" != "nuget" ]]; then
    echo -e "${RED}Error: --ecosystem must be 'maven' or 'nuget'${NC}" >&2
    exit 1
fi

# Check prerequisites
if ! command -v curl &>/dev/null; then
    echo -e "${RED}Error: curl is required but not found${NC}" >&2
    exit 1
fi
if ! command -v jq &>/dev/null; then
    echo -e "${RED}Error: jq is required but not found${NC}" >&2
    echo "Install: apt install jq / brew install jq / yum install jq" >&2
    exit 1
fi

# Compare two version strings.
# Returns via exit code: 0 = v1 < v2, 1 = v1 == v2, 2 = v1 > v2
compare_versions() {
    local v1="$1" v2="$2"
    # Strip common version suffixes (covers both Maven and NuGet conventions)
    v1=$(echo "$v1" | sed -E 's/[.-]?(RELEASE|Final|GA|SNAPSHOT|M[0-9]+|RC[0-9]+|CR[0-9]+|beta[0-9]*|alpha[0-9]*|SP[0-9]+|preview[.0-9]*|dev[.0-9]*)$//I')
    v2=$(echo "$v2" | sed -E 's/[.-]?(RELEASE|Final|GA|SNAPSHOT|M[0-9]+|RC[0-9]+|CR[0-9]+|beta[0-9]*|alpha[0-9]*|SP[0-9]+|preview[.0-9]*|dev[.0-9]*)$//I')

    IFS='.-' read -ra parts1 <<< "$v1"
    IFS='.-' read -ra parts2 <<< "$v2"

    local max=${#parts1[@]}
    [[ ${#parts2[@]} -gt $max ]] && max=${#parts2[@]}

    for ((i = 0; i < max; i++)); do
        local p1="${parts1[$i]:-0}"
        local p2="${parts2[$i]:-0}"
        p1=$(echo "$p1" | grep -oE '^[0-9]+' || echo "0")
        p2=$(echo "$p2" | grep -oE '^[0-9]+' || echo "0")
        if ((p1 < p2)); then return 0; fi
        if ((p1 > p2)); then return 2; fi
    done
    return 1
}

# Check if a version falls within a vulnerability range.
version_in_range() {
    local version="$1" range="$2"
    [[ -z "$range" || "$range" == "null" ]] && return 0

    IFS=',' read -ra constraints <<< "$range"
    for constraint in "${constraints[@]}"; do
        constraint=$(echo "$constraint" | xargs)
        local op ver
        op=$(echo "$constraint" | grep -oE '^[><=!]+' || true)
        ver=$(echo "$constraint" | sed -E 's/^[><=!]+[[:space:]]*//')
        [[ -z "$op" || -z "$ver" ]] && continue

        compare_versions "$version" "$ver"
        local cmp=$?

        case "$op" in
            ">=") [[ $cmp -eq 0 ]] && return 1 ;;
            ">")  [[ $cmp -ne 2 ]] && return 1 ;;
            "<=") [[ $cmp -eq 2 ]] && return 1 ;;
            "<")  [[ $cmp -ne 0 ]] && return 1 ;;
            "="|"==") [[ $cmp -ne 1 ]] && return 1 ;;
        esac
    done
    return 0
}

# Query GitHub Security Advisories API.
query_advisories() {
    local package="$1"
    local curl_args=(-s --get
        --data-urlencode "affects=$package"
        --data-urlencode "ecosystem=$ECOSYSTEM"
        --data-urlencode "per_page=100"
        --data-urlencode "type=reviewed"
        -H "Accept: application/vnd.github+json"
        -H "X-GitHub-Api-Version: 2022-11-28"
        -w "\n%{http_code}"
    )
    if [[ -n "$GITHUB_TOKEN" ]]; then
        curl_args+=(-H "Authorization: Bearer $GITHUB_TOKEN")
    fi

    local response http_code body
    response=$(curl "${curl_args[@]}" "https://api.github.com/advisories" 2>/dev/null) || {
        echo "[]"; return
    }
    http_code=$(echo "$response" | tail -1)
    body=$(echo "$response" | sed '$d')

    if [[ "$http_code" -ge 400 ]]; then
        if [[ "$http_code" == "403" ]]; then
            local msg
            msg=$(echo "$body" | jq -r '.message // ""' 2>/dev/null || echo "")
            if echo "$msg" | grep -qi "rate limit"; then
                echo -e "${RED}ERROR: GitHub API rate limit exceeded. Set GITHUB_TOKEN for 5000 req/hr.${NC}" >&2
            fi
        else
            echo -e "${YELLOW}WARNING: HTTP $http_code for $package${NC}" >&2
        fi
        echo "[]"
        return
    fi

    echo "$body"
}

# --- Parse dependency string into (package, version) based on ecosystem ---
# Maven: groupId:artifactId:version  → package=groupId:artifactId, version=version
# NuGet: PackageName:version          → package=PackageName,        version=version
parse_dependency() {
    local dep_str="$1"
    if [[ "$ECOSYSTEM" == "maven" ]]; then
        IFS=':' read -r _groupId _artifactId _version <<< "$dep_str"
        if [[ -z "$_groupId" || -z "$_artifactId" || -z "$_version" ]]; then
            DEP_PACKAGE=""
            DEP_VERSION=""
            return 1
        fi
        DEP_PACKAGE="${_groupId}:${_artifactId}"
        DEP_VERSION="$_version"
    else
        # NuGet: PackageName:version
        IFS=':' read -r _packageName _version <<< "$dep_str"
        if [[ -z "$_packageName" || -z "$_version" ]]; then
            DEP_PACKAGE=""
            DEP_VERSION=""
            return 1
        fi
        DEP_PACKAGE="$_packageName"
        DEP_VERSION="$_version"
    fi
    return 0
}

# --- Main scanning logic ---

SCAN_DATE=$(date -u +"%Y-%m-%dT%H:%M:%S+00:00" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || echo "unknown")

VULN_FILE=$(mktemp)
echo "[]" > "$VULN_FILE"
CACHE_DIR=$(mktemp -d)
trap "rm -rf '$VULN_FILE' '$CACHE_DIR'" EXIT

echo -e "${YELLOW}Validating CVEs for $ECOSYSTEM dependencies...${NC}" >&2

IFS=',' read -ra DEP_LIST <<< "$DEPENDENCIES"
TOTAL_DEPS=${#DEP_LIST[@]}
PROCESSED=0

for dep_str in "${DEP_LIST[@]}"; do
    dep_str=$(echo "$dep_str" | xargs)
    [[ -z "$dep_str" ]] && continue

    if ! parse_dependency "$dep_str"; then
        echo -e "${YELLOW}WARNING: Skipping malformed dependency: $dep_str${NC}" >&2
        continue
    fi

    package="$DEP_PACKAGE"
    version="$DEP_VERSION"

    PROCESSED=$((PROCESSED + 1))
    cache_file="$CACHE_DIR/$(echo "$package" | tr ':/.+' '____').json"

    if [[ ! -f "$cache_file" ]]; then
        echo -e "  [$PROCESSED/$TOTAL_DEPS] Querying $package..." >&2
        query_advisories "$package" > "$cache_file"
        sleep 0.1
    else
        echo -e "  [$PROCESSED/$TOTAL_DEPS] $package (cached)" >&2
    fi

    advisories=$(cat "$cache_file")
    [[ "$advisories" == "[]" || -z "$advisories" ]] && continue

    adv_count=$(echo "$advisories" | jq 'if type == "array" then length else 0 end' 2>/dev/null || echo 0)
    for ((a = 0; a < adv_count; a++)); do
        cve_id=$(echo "$advisories" | jq -r ".[$a].cve_id // \"N/A\"")
        ghsa_id=$(echo "$advisories" | jq -r ".[$a].ghsa_id // \"N/A\"")
        severity=$(echo "$advisories" | jq -r ".[$a].severity // \"unknown\"")
        summary=$(echo "$advisories" | jq -r ".[$a].summary // \"N/A\"")
        html_url=$(echo "$advisories" | jq -r ".[$a].html_url // \"\"")

        vuln_count=$(echo "$advisories" | jq ".[$a].vulnerabilities | length" 2>/dev/null || echo 0)
        for ((v = 0; v < vuln_count; v++)); do
            pkg_eco=$(echo "$advisories" | jq -r ".[$a].vulnerabilities[$v].package.ecosystem // \"\"")
            pkg_name=$(echo "$advisories" | jq -r ".[$a].vulnerabilities[$v].package.name // \"\"")
            [[ "$pkg_eco" != "$ECOSYSTEM" || "$pkg_name" != "$package" ]] && continue

            vrange=$(echo "$advisories" | jq -r ".[$a].vulnerabilities[$v].vulnerable_version_range // \"\"")
            patched=$(echo "$advisories" | jq -r ".[$a].vulnerabilities[$v].first_patched_version | if type == \"object\" then .identifier else . end // \"none\"")

            if version_in_range "$version" "$vrange"; then
                new_vuln=$(jq -n \
                    --arg dep "$dep_str" \
                    --arg cve "$cve_id" \
                    --arg ghsa "$ghsa_id" \
                    --arg sev "$severity" \
                    --arg sum "$summary" \
                    --arg url "$html_url" \
                    --arg vr "$vrange" \
                    --arg pv "$patched" \
                    '{ dependency: $dep, cve_id: $cve, ghsa_id: $ghsa, severity: $sev, summary: $sum, url: $url, vulnerable_range: $vr, patched_version: $pv }')

                jq ". + [$new_vuln]" "$VULN_FILE" > "$VULN_FILE.tmp" && mv "$VULN_FILE.tmp" "$VULN_FILE"
            fi
        done
    done
done

VULN_COUNT=$(jq 'length' "$VULN_FILE")
echo "Scan complete. $PROCESSED dependencies checked." >&2

# --- Format output ---

case "$FORMAT" in
    json)
        OUTPUT=$(jq -n \
            --arg date "$SCAN_DATE" \
            --arg eco "$ECOSYSTEM" \
            --argjson total "$PROCESSED" \
            --argjson count "$VULN_COUNT" \
            --slurpfile vulns "$VULN_FILE" \
            '{ scan_date: $date, ecosystem: $eco, total_dependencies_scanned: $total, total_vulnerabilities_found: $count, vulnerabilities: $vulns[0] }')
        ;;
    markdown)
        OUTPUT="# CVE Scan Report"$'\n\n'
        OUTPUT+="- **Date**: $SCAN_DATE"$'\n'
        OUTPUT+="- **Ecosystem**: $ECOSYSTEM"$'\n'
        OUTPUT+="- **Dependencies scanned**: $PROCESSED"$'\n'
        OUTPUT+="- **Vulnerabilities found**: $VULN_COUNT"$'\n\n'
        if [[ "$VULN_COUNT" -eq 0 ]]; then
            OUTPUT+="> No known vulnerabilities found."
        else
            OUTPUT+="| Dependency | CVE | Severity | Summary | Vulnerable Range | Patched Version |"$'\n'
            OUTPUT+="|---|---|---|---|---|---|"$'\n'
            OUTPUT+=$(jq -r '.[] | "| \(.dependency) | \(.cve_id) | \(.severity) | \(.summary | gsub("\\|"; "\\\\|")) | \(.vulnerable_range) | \(.patched_version) |"' "$VULN_FILE")
        fi
        ;;
    *)
        OUTPUT="======================================"$'\n'
        OUTPUT+="  CVE Scan Report ($ECOSYSTEM)"$'\n'
        OUTPUT+="======================================"$'\n'
        OUTPUT+="Date: $SCAN_DATE"$'\n'
        OUTPUT+="Dependencies scanned: $PROCESSED"$'\n'
        OUTPUT+="Vulnerabilities found: $VULN_COUNT"$'\n\n'
        if [[ "$VULN_COUNT" -eq 0 ]]; then
            OUTPUT+="No known vulnerabilities found."
        else
            OUTPUT+="--------------------------------------"$'\n'
            OUTPUT+=$(jq -r '.[] | "\n  Dependency: \(.dependency)\n  CVE:        \(.cve_id)\n  GHSA:       \(.ghsa_id)\n  Severity:   \(.severity)\n  Summary:    \(.summary)\n  Range:      \(.vulnerable_range)\n  Fix:        Upgrade to \(.patched_version)\n  URL:        \(.url)\n--------------------------------------"' "$VULN_FILE")
        fi
        ;;
esac

# Write output
if [[ -n "$OUTPUT_FILE" ]]; then
    echo "$OUTPUT" > "$OUTPUT_FILE"
    echo -e "${GREEN}✓ Results saved to $OUTPUT_FILE${NC}" >&2
else
    echo "$OUTPUT"
fi

# Exit with appropriate code
if [[ "$VULN_COUNT" -gt 0 ]]; then
    echo -e "${YELLOW}WARNING: Found $VULN_COUNT vulnerabilities${NC}" >&2
    exit 1
else
    echo -e "${GREEN}✓ No known CVEs found${NC}" >&2
    exit 0
fi
