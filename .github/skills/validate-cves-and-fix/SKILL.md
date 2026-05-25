---
name: validate-cves-and-fix
description: Validate project dependencies against known CVEs from GitHub Security Advisories and the NuGet Vulnerability API, and update vulnerable dependencies to secure versions. Supports Java (Maven/Gradle) and .NET (NuGet) projects. Use when the user mentions "security", "cve", "vulnerability", "CVE scan", or "dependency security".
---

## Overview

This skill validates project dependencies against known CVEs (Common Vulnerabilities and Exposures) from GitHub Security Advisories and the NuGet Vulnerability API. It auto-detects the project type and handles both Java (Maven/Gradle) and .NET (NuGet) ecosystems.

The scripts query the GitHub Security Advisories REST API for Maven packages and the NuGet Vulnerability API for .NET packages.

- **Unix/Linux/Mac**: Uses `curl` + `jq` (both widely available)
- **Windows**: Uses PowerShell 5.1+ (built into Windows 10+)

## User Input

modernization-work-folder (Mandatory): The folder to save the cve report and fix summary
task-id (Optional): The ID of the task being executed, used for logging and reporting

## Workflow

### Step 1: Precheck — detect project type and build tool

Before running any build or dependency commands, verify that the required build tool is available.

1. **Detect the project type** by examining the project root:

   | File(s) found | Project type | Ecosystem |
   |---|---|---|
   | `pom.xml` | Maven (Java) | maven |
   | `build.gradle` or `build.gradle.kts` | Gradle (Java) | maven |
   | `*.sln` | .NET solution | nuget |
   | `*.csproj` | C# project | nuget |

2. **Resolve the build command**:

   **Java projects** — prefer project-local wrappers over globally installed tools:

   | Project type | Check order (prefer first match) | Fallback |
   |---|---|---|
   | Maven | `./mvnw` (Unix) or `mvnw.cmd` (Windows) | `mvn` on PATH |
   | Gradle | `./gradlew` (Unix) or `gradlew.bat` (Windows) | `gradle` on PATH |

   **.NET projects** — verify the dotnet CLI:
   ```shell
   dotnet --version
   ```

3. **If the required tool is not found**, stop and report the error. Do not proceed with subsequent steps.

### Step 2: Validate dependencies against CVE databases

Run the all-in-one script which automatically detects the project type, lists dependencies, and checks CVEs against the GitHub Security Advisories API (Maven) and the NuGet Vulnerability API (.NET):

```shell
# For Unix/Linux/Mac
./scripts/all-in-one-cve-check.sh . {{modernization-work-folder}}/{{task-id}}
```

```powershell
# For Windows (PowerShell)
.\scripts\all-in-one-cve-check.ps1 -TaskFolder {{modernization-work-folder}}/{{task-id}}
```

The script produces `cve-report.json` in the task folder. After each scan completes, rename the output with a sequential number to preserve all scan results:

```shell
mv {{modernization-work-folder}}/{{task-id}}/cve-report.json {{modernization-work-folder}}/{{task-id}}/cve-report-1.json
```

Increment the number for each subsequent scan (`cve-report-2.json`, `cve-report-3.json`, etc.).

**Large projects**: For projects with many dependencies, the CVE check script can take a long time to complete. In this case:

1. Run the script in a **background (async) terminal** so you are not blocked waiting for it to finish.
2. While the script is running, proceed to review and fix any vulnerabilities already identified from earlier runs or known issues.
3. Once the script completes, check its output and address any newly discovered vulnerabilities.

This approach maximizes efficiency by overlapping the scan with remediation work.

### Step 3: Review CVE report and identify vulnerable dependencies

Parse the latest `cve-report-N.json` (e.g., `{{modernization-work-folder}}/{{task-id}}/cve-report-1.json` after the first scan) and examine each vulnerability:

1. Read the report file and parse the JSON
2. Group vulnerabilities by severity: **critical** > **high** > **medium** > **low**
3. For each vulnerability note:
   - The affected dependency and its current version
   - The vulnerable version range
   - The first patched version (upgrade target)
   - The CVE/GHSA identifier and summary
4. Prioritize critical and high severity issues for immediate remediation

Example report structure:
```json
{
  "scan_date": "2025-02-25T10:30:00+00:00",
  "ecosystem": "maven",
  "total_dependencies_scanned": 12,
  "total_vulnerabilities_found": 3,
  "vulnerabilities": [
    {
      "dependency": "org.springframework:spring-core:5.3.9",
      "cve_id": "CVE-2022-22965",
      "ghsa_id": "GHSA-36p3-wjmg-h94x",
      "severity": "critical",
      "summary": "Spring Framework RCE via Data Binding on JDK 9+",
      "url": "https://github.com/advisories/GHSA-36p3-wjmg-h94x",
      "vulnerable_range": ">= 5.3.0, < 5.3.18",
      "patched_version": "5.3.18"
    }
  ]
}
```

### Step 4: Update vulnerable dependencies to secure versions

For each vulnerable dependency, update to a secure version using the appropriate method for the ecosystem.

#### Java — Maven (pom.xml)
1. Find the dependency version in `pom.xml` (may be in `<properties>`, `<dependencyManagement>`, or inline `<version>` tags)
2. Update the version to the patched version (or the latest stable version if the patched version is also outdated)
3. If the dependency inherits its version from a parent POM (e.g., Spring Boot starter parent), update the parent version instead

#### Java — Gradle (build.gradle)
1. Find the dependency version in `build.gradle` or `gradle.properties`
2. Update the version string to the patched version
3. If using a BOM or platform dependency, update the BOM version

#### .NET (csproj)
1. Find the `<PackageReference Include="PackageName" Version="X.Y.Z" />` in the project file
2. Update the `Version` attribute to the patched version
3. If the package version is managed centrally via `Directory.Packages.props`, update it there instead
4. Alternatively use the dotnet CLI: `dotnet add package PackageName --version X.Y.Z`

### Step 5: Re-run CVE check to confirm all issues are resolved

Run the same script from Step 2 again and rename the output with the next sequential number (e.g., `cve-report-2.json`). Verify:
- The report shows `total_vulnerabilities_found: 0`
- The script exits with code 0 (success)

If vulnerabilities remain, return to Step 4 and address the remaining issues. Repeat this cycle, incrementing the report number each time.

### Step 6: Build and test the project to ensure stability after updates

Use the build command resolved in Step 1.

**Maven** (example using wrapper):
```shell
./mvnw clean verify
```

**Gradle** (example using wrapper):
```shell
./gradlew clean build
```

**.NET**:
```shell
dotnet build
dotnet test
```

Verify:
- The build completes without errors
- All existing tests pass
- The application starts up correctly (if applicable)

If the build fails due to breaking API changes from a dependency upgrade, apply the necessary code fixes and re-run the build.

### Step 7: Document the changes made and the CVEs fixed

1. Create a summary of the CVEs that were fixed, including:
   - CVE/GHSA ID
   - Affected dependency and version
   - Patched version
   - Severity
   - Brief description of the vulnerability
2. File this summary in `{{modernization-work-folder}}/{{task-id}}/cve-fix-summary.md`  
3. Final scan the project (re-run the script from Step 2), then rename the output as the final report:
   ```shell
   mv {{modernization-work-folder}}/{{task-id}}/cve-report.json {{modernization-work-folder}}/{{task-id}}/final-cve-report.json
   ```
   All intermediate reports (`cve-report-1.json`, `cve-report-2.json`, etc.) are preserved for audit history.
4. Update the task cveReport field with the path to `{{modernization-work-folder}}/{{task-id}}/final-cve-report.json`
5. Follow up, if you need to upgrade any major version to fix all the issues, you need to create a follow up item in the summary file.

---

## Environment Setup

### Prerequisites

1. **Windows**: PowerShell 5.1+ (built into Windows 10+):
   ```cmd
   powershell -Command "$PSVersionTable.PSVersion"
   ```

2. **Build tool** (one of):
   ```bash
   mvn --version      # Maven (Java)
   gradle --version   # Gradle (Java)
   dotnet --version   # .NET SDK
   ```

3. **Make Scripts Executable** (Unix):
   ```bash
   chmod +x scripts/*.sh
   ```

4. **Set GitHub Token** (optional but recommended — raises rate limit from 60 to 5000 requests/hour):
   ```bash
   export GITHUB_TOKEN="<gh auth token>"
   ```

---

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| `No dependencies provided` | Missing `--dependencies` argument | Provide dependencies in the correct format |
| `HTTP 403 / rate limit exceeded` | Too many API calls without auth | Set `GITHUB_TOKEN` env var |
| `WARNING: Failed to query` | Network error or API issue | Check network connectivity and proxy settings |
| `Skipping malformed dependency` | Wrong coordinate format | Maven: `groupId:artifactId:version`; NuGet: `PackageName:version` |
| `jq is required` | jq not installed (Unix) | Install jq: `apt install jq` / `brew install jq` |
| `PowerShell is required` | PowerShell missing (Windows) | Install PowerShell 5.1+ |
| `Maven/Gradle not found` | Build tool not in PATH | Install Maven/Gradle or ensure wrapper scripts exist |
| `dotnet CLI not found` | .NET SDK not installed | Install .NET SDK |
| `No supported project files found` | Unrecognized project type | Ensure project root contains pom.xml, build.gradle, *.sln, or *.csproj |

---

## Performance Considerations

- **Caching**: Advisories are cached per unique package — multiple versions of the same package only trigger one API call
- **Rate Limits**: 
  - Without token: 60 requests/hour
  - With token: 5000 requests/hour
- **Throttling**: A 100ms delay is inserted between API calls to avoid hitting rate limits
- **API Pagination**: Up to 100 advisories per package are fetched (sufficient for all known packages)

---

## Troubleshooting

### Script Not Found
```bash
# Verify scripts exist
ls -la scripts/cve.sh scripts/all-in-one-cve-check.sh scripts/all-in-one-cve-check.ps1
```

### Permission Denied (Unix)
```bash
chmod +x scripts/*.sh
```

### All-in-One Script Fails

**Java — list dependencies manually:**
```bash
# Maven
mvn dependency:list -DoutputFile=deps.txt -q
grep -E "^   [a-zA-Z]" deps.txt | sed 's/^   //' | awk -F: '{print $1":"$2":"$4}' > coordinates.txt

# Gradle
./gradlew dependencies --configuration compileClasspath > deps.txt
```

**.NET — list dependencies manually:**
```bash
dotnet list package > deps.txt
grep -E "^\s+>" deps.txt | sed 's/^\s*>\s*//' | awk '{print $1":"$NF}' > coordinates.txt
```

**Then check CVEs directly:**
```bash
./scripts/cve.sh --ecosystem maven --dependencies "$(paste -sd, coordinates.txt)"
./scripts/cve.sh --ecosystem nuget --dependencies "$(paste -sd, coordinates.txt)"
```

### Rate Limit Errors
```bash
# Obtain a GitHub token and set it as an environment variable
export GITHUB_TOKEN=$(gh auth token)
# Then re-run the script
```
