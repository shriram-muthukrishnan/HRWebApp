# Modernization Assessment Summary

**Target Azure Services**: Azure App Service, Azure Kubernetes Service, Azure Container Apps

## Overall Statistics

**Total Applications**: 1

**Name: JdbcWebSamples**
- Mandatory: 4 issues
- Potential: 2 issues
- Optional: 0 issues

> **Severity Levels Explained:**
> - **Mandatory**: The issue has to be resolved for the migration to be successful.
> - **Potential**: This issue may be blocking in some situations but not in others. These issues should be reviewed to determine whether a change is required or not.
> - **Optional**: The issue discovered is real issue fixing which could improve the app after migration, however it is not blocking.

## Applications Profile

### Name: JdbcWebSamples
- **JDK Version**: 1.8
- **Frameworks**: N/A
- **Languages**: Java
- **Build Tools**: Maven

**Key Findings**:
- **Mandatory Issues (8 locations)**:
  - <!--ruleid=azure-java-version-02000-->Legacy Java version (4 locations found)
  - <!--ruleid=local-storage-00001-->File system - Java IO (1 location found)
  - <!--ruleid=localhost-jdbc-00002-->Local JDBC Calls (2 locations found)
  - <!--ruleid=dockerfile-00000-->No Dockerfile found (1 location found)
- **Potential Issues (4 locations)**:
  - <!--ruleid=azure-database-postgresql-02000-->PostgreSQL database found (2 locations found)
  - <!--ruleid=azure-password-01000-->Password found in configuration file (2 locations found)

## Next Steps

For comprehensive migration guidance and best practices, visit:
- [GitHub Copilot modernization](https://aka.ms/ghcp-appmod)

Have questions or suggestions? [Share your feedback](https://aka.ms/ghcp-appmod/feedback)
