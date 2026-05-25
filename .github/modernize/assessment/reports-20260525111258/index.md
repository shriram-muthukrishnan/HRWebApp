# Consolidated Assessment Report

Code Assessment Summary

**Assessment Date:** May 25, 2026  
**Applications Assessed:** [1](#application-assessment-matrix)

## Dashboard

High-level consolidation assessment of application health and cloud readiness across tech stacks.

| Metric | Value |
|--------|-------|
| Total Apps | [1](#application-assessment-matrix) |
| Upgrades Needed | [1](#application-assessment-matrix) |
| Mandatory Blockers | 0 |
| Potential Issues | 0 |

### Technology Distribution

| Framework | Apps |
|-----------|------|
| Java EE 7 | [1](#application-assessment-matrix) |

### Effort and Resource Summary

| Effort | Apps |
|--------|------|
| S | [1](#application-assessment-matrix) |
| M | [0](#application-assessment-matrix) |
| L | [0](#application-assessment-matrix) |
| XL | [0](#application-assessment-matrix) |

## Recommendations

Key architectural decisions and recommended migration sequencing.

> **Important:** These architectural recommendations represent key decision points required to move forward with migration. Review them now to avoid delays.

### Recommended Azure Services

| Dependency | Apps | Recommendation | Rationale |
|------------|------|----------------|-----------|
| Local File System | 1 | Azure Blob Storage | Azure Blob Storage replaces local file system dependencies with scalable, geo-redundant cloud storage accessible from any Azure service. |

### Recommended Target Platform

| Recommendation | Apps | Rationale |
|----------------|------|-----------|
| App Service (Linux) | 1 | Modern .NET application recommended for App Service on Linux for best performance and cost efficiency. |

### Recommended Upgrade Path

| Framework | Apps | Recommendation | Rationale |
|-----------|------|----------------|-----------|
| Java EE 7 | 1 | Migrate to Jakarta EE 11 | Jakarta EE 11 is the latest LTS version supported by GitHub Copilot Modernization, enabling automated upgrades with minimal manual effort. |

### Migration Wave Plan

| Phase | Applications | Rationale |
|-------|-------------|-----------|
| Wave 1 - Quick Wins | - | Quick Wins — migrate now with minimal effort and risk. Fewer than 5 mandatory issues, no version upgrade issues. |
| Wave 2 - Core Cloud | HRWebApp | Moderate effort — applications that do not qualify as quick wins or long-term bets. |
| Wave 3 - Long term Bets | - | Long-term Bets — more than 10 mandatory issues and has version upgrade issues requiring significant framework migration. |

### 6R Recommendation

| 6R | Apps | Rationale |
|----|------|-----------|
| Replatform | 1: HRWebApp | |

## Application Assessment Matrix

Detailed framework upgrade plan with readiness assessment and migration requirements.

> **Legend:** M = Mandatory, P = Potential, O = Optional

| Application | Repo | Framework | Recommended Target Platform | Upgrade Recommendation | Issues (M/P/O) | Effort | Decision |
|-------------|------|-----------|-----------------|------------------------|----------------|--------|----------|
| [HRWebApp](repos/HRWebApp/report.md) |  | Java EE 7 | App Service (Linux) | Migrate to Jakarta EE 11 | 0/0/1 | S | Ready |

---

[Share feedback](https://aka.ms/ghcp-appmod/feedback)
