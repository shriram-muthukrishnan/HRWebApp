[← Back to aggregate report](../../index.md)

# JdbcWebSamples

## Summary

| Metric | Value |
|--------|-------|
| Total Issues | 6 |
| Mandatory Blockers | 4 |
| Potential Issues | 2 |

## Application Information

| Property | Value |
|----------|-------|
| Language | Java |
| Frameworks | N/A |
| Build tools | Maven |
| JDK version | 1.8 |

## Cloud Readiness Issues

| Issue Name | Criticality | Story Points | Occurrences |
|------------|-------------|--------------|-------------|
| Local JDBC Calls | Mandatory | 5 | [2](#Local_JDBC_Calls) |
| File system - Java IO | Mandatory | 3 | [1](#File_system_-_Java_IO) |
| No Dockerfile found | Mandatory | 3 | 1 |
| PostgreSQL database found | Potential | 5 | [2](#PostgreSQL_database_found) |
| Password found in configuration file | Potential | 3 | [2](#Password_found_in_configuration_file) |

### Issue Details

<details id="Local_JDBC_Calls">
<summary><b>Local JDBC Calls</b> — affected files</summary>

- `repos/HRWebApp/src/main/java/com/oracle/jdbc/samples/bean/JdbcBeanImpl.java (line 25)`
- `src/main/java/com/oracle/jdbc/samples/bean/JdbcBeanImpl.java (line 25)`

</details>

<details id="File_system_-_Java_IO">
<summary><b>File system - Java IO</b> — affected files</summary>

- `src/main/java/com/oracle/jdbc/samples/web/WebController.java (line 18)`

</details>

<details id="PostgreSQL_database_found">
<summary><b>PostgreSQL database found</b> — affected files</summary>

- `repos/HRWebApp/pom.xml (line 37)`

</details>

<details id="Password_found_in_configuration_file">
<summary><b>Password found in configuration file</b> — affected files</summary>

- `repos/HRWebApp/settings.xml (line 21)`
- `settings.xml (line 21)`

</details>

## Upgrade Issues

| Issue Name | Criticality | Story Points | Occurrences |
|------------|-------------|--------------|-------------|
| Legacy Java version | Mandatory | 5 | [4](#Legacy_Java_version) |

### Issue Details

<details id="Legacy_Java_version">
<summary><b>Legacy Java version</b> — affected files</summary>

- `pom.xml (line 49)`
- `pom.xml (line 50)`
- `repos/HRWebApp/pom.xml (line 49)`
- `repos/HRWebApp/pom.xml (line 50)`

</details>

---

[Share feedback](https://aka.ms/ghcp-appmod/feedback)
