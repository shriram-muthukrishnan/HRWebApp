-- SalaryHikeSP.sql
--
-- Copyright (c) 2015, Oracle and/or its affiliates. All rights reserved.
--
--    NAME
--      SalaryHikeSP.sql 
--
--    DESCRIPTION
--      Migrated from Oracle to PostgreSQL: Replaced Oracle Java stored procedure
--      with native PostgreSQL PL/pgSQL function.
--      
--      ORIGINAL: Oracle Java stored procedure with PL/SQL wrapper (refcur_pkg)
--      NEW: PostgreSQL PL/pgSQL function that can be called directly from JDBC
--
--    MODIFIED   (MM/DD/YY)
--    nbsundar    03/23/15 - Created
--    kmensah     03/23/15 - Contributor

-- Migrated from Oracle to PostgreSQL: Drop the old Oracle package-based function if it exists
-- DROP FUNCTION IF EXISTS incrementsalary(integer);

-- Migrated from Oracle to PostgreSQL: Create PostgreSQL function to replace Oracle Java stored procedure
-- This function increments employee salaries by a given percentage and returns the updated records
CREATE OR REPLACE FUNCTION incrementsalary(percent_increase integer)
RETURNS TABLE (
    employee_id integer,
    first_name varchar(50),
    last_name varchar(50),
    email varchar(100),
    phone_number varchar(20),
    job_id varchar(20),
    salary integer
) 
LANGUAGE plpgsql
AS $$
BEGIN
    -- Migrated from Oracle to PostgreSQL: Convert table and column names to lowercase
    -- Update all employee salaries by the given percentage
    UPDATE employees 
    SET salary = salary + (salary * percent_increase / 100);
    
    -- Return all updated employee records
    RETURN QUERY 
    SELECT e.employee_id, e.first_name, e.last_name, e.email, 
           e.phone_number, e.job_id, e.salary
    FROM employees e
    ORDER BY e.employee_id;
END;
$$;

-- Usage example for PostgreSQL:
-- SELECT * FROM incrementsalary(5);

-- Original Oracle usage (now obsolete):
-- declare
--   type EmpCur IS REF CURSOR;
--   rc EmpCur;
--   employee employees%ROWTYPE;
-- begin   
--   rc := refcur_pkg.incrementsalary(5);   
--   LOOP
--     fetch rc into employee;
--     exit when rc%notfound;
--     dbms_output.put_line(' Name = ' || employee.FIRST_NAME || ' Salary = ' || employee.SALARY);
--   end loop;
--   close rc;
-- end;



