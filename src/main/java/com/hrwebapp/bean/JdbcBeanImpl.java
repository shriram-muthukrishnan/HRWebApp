package com.hrwebapp.bean;

import com.hrwebapp.entity.Employee;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class JdbcBeanImpl implements JdbcBean {

  private static final Logger LOGGER = Logger.getLogger(JdbcBeanImpl.class.getName());

  public static Connection getConnection() throws SQLException {
    DriverManager.registerDriver(new org.postgresql.Driver());

    // Comment out all content about "username" and "password" because now PostgreSQL authenticates using managed identity.
    // String username = System.getenv("PGUSER");
    // String password = System.getenv("PGPASSWORD");

    return DriverManager.getConnection(buildManagedIdentityJdbcUrl());
  }

  private static String buildManagedIdentityJdbcUrl() {
    return "jdbc:postgresql://"
        + requiredEnv("PGHOST")
        + ":"
        + requiredEnv("PGPORT")
        + "/"
        + requiredEnv("PGDATABASE")
        + "?user="
        + requiredEnv("MANAGED_IDENTITY_NAME")
        + "&sslmode=require"
        + "&authenticationPluginClassName=com.azure.identity.extensions.jdbc.postgresql.AzurePostgresqlAuthenticationPlugin"
        + "&azure.managedIdentityEnabled=true"
        + "&azure.clientId="
        + requiredEnv("MANAGED_IDENTITY_CLIENT_ID");
  }

  private static String requiredEnv(String variable) {
    String value = System.getenv(variable);
    if (value == null || value.trim().isEmpty()) {
      throw new IllegalStateException(
          "Missing required environment variable: "
              + variable
              + ". Configure Azure Database for PostgreSQL connection settings before startup.");
    }
    return value;
  }

  @Override
  public List<Employee> getEmployees() {
    List<Employee> returnValue = new ArrayList<>();
    try (Connection connection = getConnection();
        Statement statement = connection.createStatement();
        ResultSet resultSet =
            statement.executeQuery(
                "SELECT employee_id, first_name, last_name, email, phone_number, job_id, salary FROM employees")) {
      while (resultSet.next()) {
        returnValue.add(new Employee(resultSet));
      }
    } catch (SQLException ex) {
      LOGGER.log(Level.SEVERE, null, ex);
    }

    return returnValue;
  }

  @Override
  public List<Employee> getEmployee(int empId) {
    List<Employee> returnValue = new ArrayList<>();

    try (Connection connection = getConnection();
        PreparedStatement preparedStatement =
            connection.prepareStatement(
                "SELECT employee_id, first_name, last_name, email, phone_number, job_id, salary FROM employees WHERE employee_id = ?")) {
      preparedStatement.setInt(1, empId);
      try (ResultSet resultSet = preparedStatement.executeQuery()) {
        if (resultSet.next()) {
          returnValue.add(new Employee(resultSet));
        }
      }
    } catch (SQLException ex) {
      LOGGER.log(Level.SEVERE, null, ex);
    }

    return returnValue;
  }

  @Override
  public Employee updateEmployee(int empId) {
    throw new UnsupportedOperationException("Not supported yet.");
  }

  @Override
  public List<Employee> getEmployeeByFn(String fn) {
    List<Employee> returnValue = new ArrayList<>();

    try (Connection connection = getConnection();
        PreparedStatement preparedStatement =
            connection.prepareStatement(
                "SELECT employee_id, first_name, last_name, email, phone_number, job_id, salary FROM employees WHERE first_name LIKE ?")) {
      preparedStatement.setString(1, fn + '%');
      try (ResultSet resultSet = preparedStatement.executeQuery()) {
        while (resultSet.next()) {
          returnValue.add(new Employee(resultSet));
        }
      }
    } catch (SQLException ex) {
      LOGGER.log(Level.SEVERE, null, ex);
    }

    return returnValue;
  }

  @Override
  public List<Employee> incrementSalary(int incrementPct) {
    List<Employee> returnValue = new ArrayList<>();

    try (Connection connection = getConnection();
        PreparedStatement preparedStatement =
            connection.prepareStatement("SELECT * FROM incrementsalary(?)")) {
      preparedStatement.setInt(1, incrementPct);
      try (ResultSet resultSet = preparedStatement.executeQuery()) {
        while (resultSet.next()) {
          returnValue.add(new Employee(resultSet));
        }
      }
    } catch (SQLException ex) {
      LOGGER.log(Level.SEVERE, null, ex);
    }

    return returnValue;
  }
}
