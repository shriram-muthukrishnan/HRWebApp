package com.oracle.jdbc.samples.bean;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import com.oracle.jdbc.samples.entity.Employee;

// Migrated from Oracle to PostgreSQL: Removed Oracle-specific imports (oracle.jdbc.*)


/**
 * JDBC Bean Implementation for Employee database operations.
 * Migrated from Oracle to PostgreSQL database.
 * 
 * @author nirmala.sundarappa@oracle.com
 */
public class JdbcBeanImpl implements JdbcBean {

  // Migrated from Oracle to PostgreSQL: Changed driver from oracle.jdbc.OracleDriver to org.postgresql.Driver
  // Migrated from Oracle to PostgreSQL: Changed connection URL from Oracle thin format (jdbc:oracle:thin) to PostgreSQL format (jdbc:postgresql)
  public static Connection getConnection() throws SQLException {
    DriverManager.registerDriver(new org.postgresql.Driver());
    Connection connection = DriverManager.getConnection("jdbc:postgresql://localhost:5432/mydb", "hr", "hr");
    
    return connection;
  }

  @Override
  public List<Employee> getEmployees() {
    List<Employee> returnValue = new ArrayList<>();
    try (Connection connection = getConnection()) {
      try (Statement statement = connection.createStatement()) {
        // Migrated from Oracle to PostgreSQL according to java check item 6: Convert table and column names to lowercase
        try (ResultSet resultSet = statement.executeQuery("SELECT employee_id, first_name, last_name, email, phone_number, job_id, salary FROM employees")) {
          while(resultSet.next()) {
            returnValue.add(new Employee(resultSet));
          }
        }
      }
    } catch (SQLException ex) {
      logger.log(Level.SEVERE, null, ex);
      ex.printStackTrace();
    }
    
    return returnValue;
  }

  /**
   * Returns the employee object for the given empId.   Returns
   * @param empId
   * @return
   */
  @Override
  public List<Employee> getEmployee(int empId) {
    List<Employee> returnValue = new ArrayList<>();

    try (Connection connection = getConnection()) {
      // Migrated from Oracle to PostgreSQL according to java check item 6: Convert table and column names to lowercase
      try (PreparedStatement preparedStatement = connection.prepareStatement(
          "SELECT employee_id, first_name, last_name, email, phone_number, job_id, salary FROM employees WHERE employee_id = ?")) {
        preparedStatement.setInt(1, empId);
        try (ResultSet resultSet = preparedStatement.executeQuery()) {
          if(resultSet.next()) {
            returnValue.add(new Employee(resultSet));
          }
        }
      }
    } catch (SQLException ex) {
      logger.log(Level.SEVERE, null, ex);
      ex.printStackTrace();
    }

    return returnValue;
  }

  @Override
  public Employee updateEmployee(int empId) {
    throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
  }

  @Override
  public List<Employee> getEmployeeByFn(String fn) {
    List<Employee> returnValue = new ArrayList<>();

    try (Connection connection = getConnection()) {
      // Migrated from Oracle to PostgreSQL according to java check item 6: Convert table and column names to lowercase
      try (PreparedStatement preparedStatement = connection.prepareStatement(
          "SELECT employee_id, first_name, last_name, email, phone_number, job_id, salary FROM employees WHERE first_name LIKE ?")) {
        preparedStatement.setString(1, fn + '%');
        try (ResultSet resultSet = preparedStatement.executeQuery()) {
          while(resultSet.next()) {
            returnValue.add(new Employee(resultSet));
          }
        }
      }
    } catch (SQLException ex) {
      logger.log(Level.SEVERE, null, ex);
      ex.printStackTrace();
    }

    return returnValue;
  }

   // Migrated from Oracle to PostgreSQL: Replaced Oracle PL/SQL stored procedure call with PostgreSQL function
   // Oracle used: begin ? := refcur_pkg.incrementsalary(?); end; with OracleTypes.CURSOR
   // PostgreSQL uses: SELECT * FROM incrementsalary(?) which returns a result set directly
   @Override
   public List<Employee> incrementSalary (int incrementPct) {
     List<Employee> returnValue = new ArrayList<>();

     try (Connection connection = getConnection()) {
       // PostgreSQL function call - the function returns a result set directly
       try (PreparedStatement preparedStatement = connection.prepareStatement("SELECT * FROM incrementsalary(?)")) {
         preparedStatement.setInt(1, incrementPct);
         try (ResultSet resultSet = preparedStatement.executeQuery()) {
           while (resultSet.next()) {
             returnValue.add(new Employee(resultSet));
           }
         }
       }
     } catch (SQLException ex) {
       logger.log(Level.SEVERE, null, ex);
       ex.printStackTrace();
     }

     return returnValue;
   }

  static final Logger logger = Logger.getLogger("com.oracle.jdbc.samples.bean.JdbcBeanImpl");
}
