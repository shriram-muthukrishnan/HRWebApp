# Modernization Plan: oracle-to-postgres

**Project**: HRWebApp (JdbcWebSamples)

---

## Technical Framework

- **Language**: Java 1.8
- **Framework**: Java Servlet 3.1 (Jakarta/Java EE web application)
- **Build Tool**: Maven
- **Database**: Oracle Database (currently in migration; PostgreSQL JDBC driver already present)
- **Key Dependencies**: javax.servlet-api 3.1.0, gson 2.8.9, postgresql 42.7.2, junit 4.13.1

---

## Overview

This migration moves the HRWebApp data layer from Oracle Database to Azure Database for
PostgreSQL Flexible Server. The application currently uses Oracle-specific JDBC drivers,
SQL syntax, and stored procedures for HR data access. The new architecture will:

- Replace the Oracle JDBC driver and connection logic with PostgreSQL equivalents so the
  application can connect to Azure Database for PostgreSQL Flexible Server.
- Convert Oracle-specific SQL (data types, sequences, stored procedures, functions, and
  built-in operators) to PostgreSQL-compatible syntax so existing HR features continue to
  work against PostgreSQL.
- Remediate any known CVEs in project dependencies introduced or affected by the migration
  so the modernized application is secure before delivery.

The migration follows a phased approach: first migrate the database layer to PostgreSQL,
then scan and remediate vulnerable dependencies.

---

## Migration Impact Summary

| Application | Original Service | New Azure Service                              | Authentication     | Comments                                                  |
|-------------|------------------|------------------------------------------------|--------------------|-----------------------------------------------------------|
| HRWebApp    | Oracle Database  | Azure Database for PostgreSQL Flexible Server  | Managed Identity   | User requested Oracle → Azure PostgreSQL Flexible Server  |

---

## Tasks

The detailed task breakdown is tracked in `tasks.json` in this folder. High-level summary:

1. **001-transform-migration-oracle-to-postgresql** — Migrate the Java data access layer
   (JDBC driver, connection code, SQL syntax, Oracle-specific features) from Oracle to
   PostgreSQL targeting Azure Database for PostgreSQL Flexible Server.
2. **002-security-validate-cves-and-fix** — Scan all project dependencies for known CVEs
   and remediate any identified vulnerabilities to ensure the modernized application is
   secure before deployment.
