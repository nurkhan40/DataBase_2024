CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50),
    salary NUMERIC(10,2),
    hire_date DATE,
    manager_id INTEGER,
    email VARCHAR(100)
);

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    budget NUMERIC(12,2),
    start_date DATE,
    end_date DATE,
    status VARCHAR(20)
);

CREATE TABLE assignments (
    assignment_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(employee_id),
    project_id INTEGER REFERENCES projects(project_id),
    hours_worked NUMERIC(5,1),
    assignment_date DATE
);

INSERT INTO employees (first_name, last_name, department, salary, hire_date, manager_id, email) VALUES
('John', 'Smith', 'IT', 75000, '2020-01-15', NULL, 'john.smith@company.com'),
('Sarah', 'Johnson', 'IT', 65000, '2020-03-20', 1, 'sarah.j@company.com'),
('Michael', 'Brown', 'Sales', 55000, '2019-06-10', NULL, 'mbrown@company.com'),
('Emily', 'Davis', 'HR', 60000, '2021-02-01', NULL, 'emily.davis@company.com'),
('Robert', 'Wilson', 'IT', 70000, '2020-08-15', 1, NULL),
('Lisa', 'Anderson', 'Sales', 58000, '2021-05-20', 3, 'lisa.a@company.com');

INSERT INTO projects (project_name, budget, start_date, end_date, status) VALUES
('Website Redesign', 150000, '2024-01-01', '2024-06-30', 'Active'),
('CRM Implementation', 200000, '2024-02-15', '2024-12-31', 'Active'),
('Marketing Campaign', 80000, '2024-03-01', '2024-05-31', 'Completed'),
('Database Migration', 120000, '2024-01-10', NULL, 'Active');

INSERT INTO assignments (employee_id, project_id, hours_worked, assignment_date) VALUES
(1, 1, 120.5, '2024-01-15'),
(2, 1, 95.0, '2024-01-20'),
(1, 4, 80.0, '2024-02-01'),
(3, 3, 60.0, '2024-03-05'),
(5, 2, 110.0, '2024-02-20'),
(6, 3, 75.5, '2024-03-10');

--Part 1
--1
SELECT
    first_name || ' ' || last_name AS full_name,
    department,
    salary
FROM
    employees;

--2
SELECT DISTINCT
    department
FROM
    employees;

--3
SELECT
    project_name,
    budget,
    CASE
        WHEN budget > 150000 THEN 'Large'
        ELSE 'Other'
    END AS budget_category
FROM
    projects;

--4
SELECT
    first_name || ' ' || last_name AS full_name,
    COALESCE(email, 'No email provided') AS employee_email
FROM
    employees;

--Part 2
--1
SELECT
    first_name,
    last_name,
    hire_date
FROM
    employees
WHERE
    hire_date > '2020-01-01';

--2
SELECT
    first_name,
    last_name,
    salary
FROM
    employees
WHERE
    salary BETWEEN 60000 AND 70000;

--3
SELECT
    first_name,
    last_name
FROM
    employees
WHERE
    last_name LIKE 'S%' OR last_name LIKE 'J%'; 

--4
SELECT
    first_name,
    last_name,
    department,
    manager_id
FROM
    employees
WHERE
    manager_id IS NOT NULL AND department = 'IT';

--Part 3
--1
SELECT
    UPPER(first_name || ' ' || last_name) AS full_name_uppercase,
    LENGTH(last_name) AS last_name_length,
    SUBSTRING(COALESCE(email, '---'), 1, 3) AS email_prefix 
FROM
    employees;

--2
SELECT
    first_name || ' ' || last_name AS full_name,
    salary AS annual_salary,
    ROUND(salary / 12, 2) AS monthly_salary,
    (salary * 0.10) AS raise_amount 
FROM
    employees;

--3
SELECT
    'Project: ' || project_name || ' - Budget: $' || budget || ' - Status: ' || status AS project_report_string
FROM
    projects;
--4
SELECT
    first_name || ' ' || last_name AS full_name,
    hire_date,
    -- Calculates the difference between the current date and hire_date in years
    DATE_PART('year', AGE(CURRENT_DATE, hire_date)) AS years_of_service
FROM
    employees;

--Part 4
--1
SELECT
    department,
    AVG(salary) AS average_salary
FROM
    employees
GROUP BY
    department
ORDER BY
    average_salary DESC;

--2
SELECT
    p.project_name,
    SUM(a.hours_worked) AS total_hours_worked
FROM
    projects p
JOIN
    assignments a ON p.project_id = a.project_id
GROUP BY
    p.project_name
ORDER BY
    total_hours_worked DESC;

--3
SELECT
    department,
    COUNT(employee_id) AS employee_count
FROM
    employees
GROUP BY
    department
HAVING
    COUNT(employee_id) > 1
ORDER BY
    employee_count DESC;

--4
SELECT
    MAX(salary) AS maximum_salary,
    MIN(salary) AS minimum_salary,
    SUM(salary) AS total_payroll
FROM
    employees;

-- Query 1: Employees with salary > 65000
SELECT
    employee_id,
    first_name || ' ' || last_name AS full_name,
    salary
FROM
    employees
WHERE
    salary > 65000

UNION

--Part 5
--1
SELECT
    employee_id,
    first_name || ' ' || last_name AS full_name,
    salary
FROM
    employees
WHERE
    salary > 65000

UNION

SELECT
    employee_id,
    first_name || ' ' || last_name AS full_name,
    salary
FROM
    employees
WHERE
    hire_date > '2020-01-01'
ORDER BY
    employee_id;

--2
SELECT
    employee_id,
    first_name || ' ' || last_name AS full_name,
    department,
    salary
FROM
    employees
WHERE
    department = 'IT'

INTERSECT

SELECT
    employee_id,
    first_name || ' ' || last_name AS full_name,
    department,
    salary
FROM
    employees
WHERE
    salary > 65000
ORDER BY
    employee_id;

--3
SELECT
    employee_id,
    first_name || ' ' || last_name AS full_name
FROM
    employees

EXCEPT
SELECT
    e.employee_id,
    e.first_name || ' ' || e.last_name
FROM
    employees e
JOIN
    assignments a ON e.employee_id = a.employee_id
ORDER BY
    employee_id;

--Part 6
--1
SELECT
    employee_id,
    first_name || ' ' || last_name AS full_name
FROM
    employees e
WHERE
    EXISTS (
        SELECT 1
        FROM assignments a
        WHERE a.employee_id = e.employee_id
    )
ORDER BY
    employee_id;

--2
SELECT DISTINCT
    e.employee_id,
    e.first_name || ' ' || e.last_name AS full_name
FROM
    employees e
JOIN
    assignments a ON e.employee_id = a.employee_id
WHERE
    a.project_id IN (
        SELECT project_id
        FROM projects
        WHERE status = 'Active'
    )
ORDER BY
    e.employee_id;

--3
SELECT
    employee_id,
    first_name || ' ' || last_name AS full_name,
    department,
    salary
FROM
    employees
WHERE
    salary > ANY (
        SELECT salary
        FROM employees
        WHERE department = 'Sales'
    )
    AND department <> 'Sales'
ORDER BY
    salary DESC;

--Part 7
--1
SELECT
    e.first_name || ' ' || e.last_name AS employee_name,
    e.department,
    COALESCE(AVG(a.hours_worked), 0) AS average_hours_worked,
    RANK() OVER (
        PARTITION BY e.department
        ORDER BY e.salary DESC
    ) AS salary_rank_in_department
FROM
    employees e
LEFT JOIN
    assignments a ON e.employee_id = a.employee_id
GROUP BY
    e.employee_id, e.first_name, e.last_name, e.department, e.salary
ORDER BY
    e.department, salary_rank_in_department;

--2
SELECT
    e.first_name || ' ' || e.last_name AS employee_name,
    e.department,
    COALESCE(AVG(a.hours_worked), 0) AS average_hours_worked,
    RANK() OVER (
        PARTITION BY e.department
        ORDER BY e.salary DESC
    ) AS salary_rank_in_department
FROM
    employees e
LEFT JOIN
    assignments a ON e.employee_id = a.employee_id
GROUP BY
    e.employee_id, e.first_name, e.last_name, e.department, e.salary
ORDER BY
    e.department, salary_rank_in_department;

--3
WITH DepartmentMaxSalary AS (
    SELECT
        department,
        salary,
        first_name || ' ' || last_name AS employee_name,
        ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) as rn
    FROM
        employees
)
SELECT
    e.department,
    COUNT(e.employee_id) AS total_employees,
    AVG(e.salary) AS average_salary,
    dms.employee_name AS highest_paid_employee_name,
    GREATEST(AVG(e.salary), 0) AS greater_of_avg_salary_and_zero
FROM
    employees e
JOIN
    DepartmentMaxSalary dms ON e.department = dms.department AND dms.rn = 1
GROUP BY
    e.department, dms.employee_name
ORDER BY
    average_salary DESC;