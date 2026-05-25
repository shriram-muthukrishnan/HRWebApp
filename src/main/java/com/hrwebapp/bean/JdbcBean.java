package com.hrwebapp.bean;

import com.hrwebapp.entity.Employee;
import java.util.List;

public interface JdbcBean {
  List<Employee> getEmployees();

  List<Employee> getEmployee(int empId);

  Employee updateEmployee(int empId);

  List<Employee> getEmployeeByFn(String fn);

  List<Employee> incrementSalary(int incrementPct);
}
