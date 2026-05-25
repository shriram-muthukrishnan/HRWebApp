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
| Mandatory Blockers | 4 |
| Potential Issues | 2 |

### Technology Distribution

| Framework | Apps |
|-----------|------|
| Java EE 7 | [1](#application-assessment-matrix) |

### Effort and Resource Summary

| Effort | Apps |
|--------|------|
| S | [0](#application-assessment-matrix) |
| M | [1](#application-assessment-matrix) |
| L | [0](#application-assessment-matrix) |
| XL | [0](#application-assessment-matrix) |

## Recommendations

Key architectural decisions and recommended migration sequencing.

> **Important:** These architectural recommendations represent key decision points required to move forward with migration. Review them now to avoid delays.

### Recommended Azure Services

| Dependency | Apps | Recommendation | Rationale |
|------------|------|----------------|-----------|
| Local File System | 1 | Azure Storage File Share | Azure Storage File Share provides managed, mountable file shares replacing local file system dependencies for cloud deployments. |
| Plaintext Credentials | 1 | Azure Key Vault with Managed Identity | Storing credentials in Azure Key Vault with managed identity eliminates plaintext secrets from code, improving security and compliance. |
| PostgreSQL | 1 | Azure Database for PostgreSQL | Azure Database for PostgreSQL provides a fully managed PostgreSQL service with high availability, intelligent performance, and managed identity. |

### Recommended Target Platform

| Recommendation | Apps | Rationale |
|----------------|------|-----------|
| Azure App Service | 1 | Fewest mandatory blockers (3) among target platforms. |

### Recommended Upgrade Path

| Framework | Apps | Recommendation | Rationale |
|-----------|------|----------------|-----------|
| Java EE 7 | 1 | Migrate to Jakarta EE 11 | Jakarta EE 11 is the latest LTS version supported by GitHub Copilot Modernization, enabling automated upgrades with minimal manual effort. |

### Migration Wave Plan

| Phase | Applications | Rationale |
|-------|-------------|-----------|
| Wave 1 - Quick Wins | - | Quick Wins — migrate now with minimal effort and risk. Fewer than 5 mandatory issues, no version upgrade issues. |
| Wave 2 - Core Cloud | JdbcWebSamples | Moderate effort — applications that do not qualify as quick wins or long-term bets. |
| Wave 3 - Long term Bets | - | Long-term Bets — more than 10 mandatory issues and has version upgrade issues requiring significant framework migration. |

### 6R Recommendation

| 6R | Apps | Rationale |
|----|------|-----------|
| Replatform | 1: JdbcWebSamples | |

## Application Assessment Matrix

Detailed framework upgrade plan with readiness assessment and migration requirements.

> **Legend:** M = Mandatory, P = Potential, O = Optional

| Application | Repo | Framework | Recommended Target Platform | Upgrade Recommendation | Issues (M/P/O) | Effort | Decision |
|-------------|------|-----------|-----------------|------------------------|----------------|--------|----------|
| [JdbcWebSamples](repos/HRWebApp/report.md) | HRWebApp | Java EE 7 | Azure App Service | Migrate to Jakarta EE 11 | 4/2/0 | M | Blocked |

---

[Share feedback](https://aka.ms/ghcp-appmod/feedback)
