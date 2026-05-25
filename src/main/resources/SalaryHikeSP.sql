-- SalaryHikeSP.sql
--
-- Creates a PostgreSQL function that applies a salary increase and
-- returns updated employee rows.

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
    UPDATE employees
    SET salary = salary + (salary * percent_increase / 100);

    RETURN QUERY
    SELECT e.employee_id, e.first_name, e.last_name, e.email,
           e.phone_number, e.job_id, e.salary
    FROM employees e
    ORDER BY e.employee_id;
END;
$$;

-- Usage:
-- SELECT * FROM incrementsalary(5);
