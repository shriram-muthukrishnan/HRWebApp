---
name: migration-oracle-to-postgresql
description: Migrates Java application database layer from Oracle Database to PostgreSQL, including JDBC driver changes, SQL syntax conversion, and Oracle-specific feature replacement. Uses project-specific coding_notes.md guidance when available. Use when migrating Java applications from Oracle to PostgreSQL, converting Oracle SQL to PostgreSQL syntax, or replacing Oracle JDBC drivers.
---

# Migrate from Oracle to PostgreSQL

Your task is to migrate a project from using Oracle to using PostgreSQL.

## Migration steps

1. Locate the `coding_notes.md` file:
    - If `coding_notes.md` is already provided in the prompt or context, use it and skip to step 2.
    - Otherwise, search for `coding_notes.md` in the migration project workspace using the pattern `.github/postgres-migrations/*/results/application_guidance/coding_notes.md`.
    - If multiple files are found, compare their modification timestamps and use the most recently modified file.
    - If no `coding_notes.md` file is found, proceed to step 3 and follow only the requirements below.
2. If `coding_notes.md` is found, read its entire content before listing files that need to be migrated.
    - The file contains project-specific migration guidance and rules that must be read before listing files that need to be migrated.
    - The file may exceed 1,000 lines; ensure you read it completely from start to end.
3. Review the requirements below. **Priority rule**: If any requirement conflicts with guidance in `coding_notes.md`, follow the `coding_notes.md` instructions instead.
4. Apply the requirements to the project.

## Requirements

- Don't modify any content that is not related to Oracle to PostgreSQL migration.
- Enable passwordless connection. Use managed identity by default. Add comments to show how to authenticate by service principal.
    - **IMPORTANT - JDBC only**: The following steps only work for JDBC connections. If the project uses R2DBC (check for `r2dbc:` URLs or `r2dbc-postgresql` dependencies), ignore this entire requirement.
    - In Java code, comment out all "username" and "password" related content which are ONLY corresponding to the PostgreSQL JDBC URL.
        ```diff
        - @Value("${spring.shardingsphere.dataSource1.username}")
        - private String username;
        - @Value("${spring.shardingsphere.dataSource1.password}")
        - private String password;
        + // Comment out all content about "username" and "password" because now PostgreSQL will authenticate using managed identity.
        + // @Value("${spring.shardingsphere.dataSource1.username}")
        + // private String username;
        + // @Value("${spring.shardingsphere.dataSource1.password}")
        + // private String password;
        ```
        ```diff
        - hikariDataSource.setUsername(dataSource1Config.getUsername());
        - hikariDataSource.setPassword(dataSource1Config.getPassword());
        + // Comment out all content about "username" and "password" because now PostgreSQL will authenticate using managed identity.
        + // hikariDataSource.setUsername(dataSource1Config.getUsername());
        + // hikariDataSource.setPassword(dataSource1Config.getPassword());
        ```
    - In build config file (like pom.xml), add this dependency:
        ```diff
        + <dependency>
        +     <groupId>com.azure</groupId>
        +     <artifactId>azure-identity-extensions</artifactId>
        +     <version>1.2.2</version>
        + </dependency>
        ```
    - In property file, update the PostgreSQL JDBC URL to support authentication by managed identity.
        - Add these parameters to the PostgreSQL JDBC URL:
            - user=${MANAGED_IDENTITY_NAME}
            - sslmode=require (IMPORTANT: Use "require" instead of other values like "verify-full")
            - authenticationPluginClassName=com.azure.identity.extensions.jdbc.postgresql.AzurePostgresqlAuthenticationPlugin
            - azure.managedIdentityEnabled=true
            - azure.clientId=${MANAGED_IDENTITY_CLIENT_ID}
        - Use environment variables for database host/port/database name if the original value is not Azure PostgreSQL.
        - Add comments about environment variables in the PostgreSQL JDBC URL.
        - Comment out all "username" and "password" related content which are ONLY corresponding to the PostgreSQL JDBC URL.
        - Do not add default values for environment variables.
            ```diff
            - url:  jdbc:postgresql://localhost:5432/testdb
            - username: testuser
            - password: testpass
            + # Remember to set the value for the environment variables in the url value below
            + # For Azure sovereign cloud, add these parameters in the url:
            + #  azure.scopes
            + #     - azure_china: https://ossrdbms-aad.database.chinacloudapi.cn/.default
            + #     - azure_germany: https://ossrdbms-aad.database.cloudapi.de/.default
            + #     - azure_us_government: https://ossrdbms-aad.database.usgovcloudapi.net/.default
            + #     - azure: https://ossrdbms-aad.database.windows.net/.default
            + #  azure.authorityHost
            + #     - azure_china: https://login.partner.microsoftonline.cn
            + #     - azure_germany: https://login.microsoftonline.de
            + #     - azure_us_government: https://login.microsoftonline.us
            + #     - azure: https://login.microsoftonline.com
            + url: jdbc:postgresql://${PGHOST}:${PGPORT}/${PGDATABASE}?user=${MANAGED_IDENTITY_NAME}&sslmode=require&authenticationPluginClassName=com.azure.identity.extensions.jdbc.postgresql.AzurePostgresqlAuthenticationPlugin&azure.managedIdentityEnabled=true&azure.clientId=${MANAGED_IDENTITY_CLIENT_ID}
            + # Comment out all content about "username" and "password" because now PostgreSQL will authenticate using managed identity.
            + # username: testuser
            + # password: testpass
            ```
    - In property file, add example PostgreSQL JDBC URL to show how to authenticate by service principal.
        - These parameters are required:
            - user=${SERVICE_PRINCIPAL_NAME}
            - sslmode=require (IMPORTANT: Use "require" instead of other values like "verify-full")
            - authenticationPluginClassName=com.azure.identity.extensions.jdbc.postgresql.AzurePostgresqlAuthenticationPlugin
            - azure.clientId=${SERVICE_PRINCIPAL_CLIENT_ID}
            - azure.clientSecret=${SERVICE_PRINCIPAL_CLIENT_SECRET}
            - azure.tenantId=${SERVICE_PRINCIPAL_TENANT_ID}
        - Do not add default values for environment variables.
            ```diff
            + # Example URL for authentication by Service Principal instead of Managed Identity
            + # url: jdbc:postgresql://${PGHOST}:${PGPORT}/${PGDATABASE}?user=${SERVICE_PRINCIPAL_NAME}&sslmode=require&authenticationPluginClassName=com.azure.identity.extensions.jdbc.postgresql.AzurePostgresqlAuthenticationPlugin&azure.clientId=${SERVICE_PRINCIPAL_CLIENT_ID}&azure.clientSecret=${SERVICE_PRINCIPAL_CLIENT_SECRET}&azure.tenantId=${SERVICE_PRINCIPAL_TENANT_ID}
            ```
- Use lowercase for identifiers (like table and column names) and data types (like varchar). Use uppercase for SQL keywords (like `SELECT`, `FROM`, `WHERE`). This includes SQL statements and JPA annotations like `@Table`, `@Column`, `@NamedNativeQuery`, and `@Query`.
    ```diff
    - String sql = """
    -         INSERT INTO EMPLOYEES (
    -             EMPLOYEE_ID, FIRST_NAME, LAST_NAME, EMAIL,
    -             PHONE_NUMBER, HIRE_DATE, JOB_ID, SALARY,
    -             COMMISSION_PCT, MANAGER_ID, DEPARTMENT_ID
    -         ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    -     """;
    + String sql = """
    +         INSERT INTO employees (
    +             employee_id, first_name, last_name, email,
    +             phone_number, hire_date, job_id, salary,
    +             commission_pct, manager_id, department_id
    +         ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    +     """;
    ```
    ```diff
    - @Entity
    - @Table(name = "ITEMS")
    - public class Item {
    -     @Id
    -     @Column(name = "ITEM_ID")
    -     private Long id;
    - }
    + @Entity
    + @Table(name = "items")
    + public class Item {
    +     @Id
    +     @Column(name = "item_id")
    +     private Long id;
    + }
    ```
- Migrate all other Oracle-specific content to PostgreSQL. Verify each change is functionally equivalent and compatible.
