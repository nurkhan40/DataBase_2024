--Part 1
--1
CREATE DATABASE advanced_lab
    WITH OWNER = postgres
    ENCODING = 'UTF8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

\c advanced_lab;

CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL UNIQUE,
    budget INT CHECK (budget >= 0),
    manager_id INT
);

CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    dept_id INT REFERENCES departments(dept_id),
    salary INT CHECK (salary > 0),
    hire_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'active'
);

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    dept_id INT REFERENCES departments(dept_id),
    start_date DATE NOT NULL,
    end_date DATE,
    budget INT CHECK (budget >= 0)
);

--Part 2
--4
INSERT INTO departments (dept_id, dept_name, budget, manager_id) VALUES
(1, 'IT', 500000, NULL),
(2, 'Marketing', 300000, NULL)
ON CONFLICT (dept_id) DO NOTHING;

--2
INSERT INTO employees (emp_id, first_name, last_name, hire_date) VALUES
(1, 'Almukhan', 'Dawit', '2022-01-15'),
(2, 'Zhanerke', 'Bolsinbek',  '2023-05-20')
ON CONFLICT (emp_id) DO NOTHING;

--3
INSERT INTO employees (first_name, last_name, dept_id, salary, status, hire_date) VALUES
('Alimkhan', 'Zhandosuli', 1, 60000, DEFAULT, '2024-03-01'),
('Nurlan', 'Kudaibergen', 2, 45000, DEFAULT, '2024-04-10');

--5
INSERT INTO employees (first_name, last_name, dept_id, hire_date, salary) VALUES
('Diana', 'Rysbek', 1, CURRENT_DATE, 55000),
('Aizhan', 'Erzhanova', 2, CURRENT_DATE, 38500);

UPDATE departments SET manager_id = 1 WHERE dept_id = 1;
UPDATE departments SET manager_id = 2 WHERE dept_id = 2;

--6
CREATE TEMPORARY TABLE temp_employees (
    emp_id INT,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    dept_id INT,
    salary INT
);

INSERT INTO temp_employees (emp_id, first_name, last_name, dept_id, salary)
SELECT emp_id, first_name, last_name, dept_id, salary
FROM employees
WHERE dept_id = 1;

--Part 3
--7
UPDATE employees SET salary = salary * 1.10;

--8
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000 AND hire_date < '2020-01-01';

--9
UPDATE employees
SET status =
    CASE
        WHEN salary > 80000 THEN 'Management'
        WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
        ELSE 'Junior'
    END;

--10
ALTER TABLE departments ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active';
UPDATE departments
SET status = DEFAULT
WHERE status = 'Inactive';

--11
UPDATE departments d
SET budget = d.budget + (sub.avg_salary * 0.20)
FROM (
    SELECT dept_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY dept_id
) AS sub
WHERE d.dept_id = sub.dept_id;

--12
UPDATE employees
SET salary = salary * 1.5, status = 'Promoted'
WHERE dept_id = 2;

--Part 4
--13
DELETE FROM employees
WHERE status = 'Terminated';

--14
DELETE FROM employees
WHERE salary < 40000
AND hire_date > '2023-01-01'
AND dept_id IS NULL;

--15
DELETE FROM departments
WHERE dept_id NOT IN (
    SELECT DISTINCT dept_id
    FROM employees
    WHERE dept_id IS NOT NULL
);

--16
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

--Part 5
--17
INSERT INTO employees (first_name, last_name, salary, dept_id, hire_date) VALUES
('Kuanish', 'Berik', NULL, NULL, CURRENT_DATE);

--18
UPDATE employees
SET status = 'Unassigned'
WHERE dept_id IS NULL;

--19
DELETE FROM employees
WHERE salary IS NULL OR dept_id IS NULL;

--Part 6
INSERT INTO departments (dept_name, budget) VALUES ('HR', 200000), ('Sales', 250000), ('Management', 400000)
ON CONFLICT (dept_name) DO NOTHING;

--20
INSERT INTO employees (first_name, last_name, hire_date, dept_id) VALUES
('Fatima', 'Seitova', '2024-01-01', (SELECT dept_id FROM departments WHERE dept_name = 'HR'))
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

--21
UPDATE employees
SET salary = salary + 5000
WHERE dept_id = (SELECT dept_id FROM departments WHERE dept_name = 'IT')
RETURNING emp_id, salary AS new_salary;

--22
DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

--23
INSERT INTO employees (first_name, last_name, hire_date, dept_id)
SELECT 'Almukhan', 'Dawit', '2022-01-15', (SELECT dept_id FROM departments WHERE dept_name = 'IT')
WHERE NOT EXISTS (
    SELECT 1 FROM employees WHERE first_name = 'Almukhan' AND last_name = 'Dawit'
);

--24
UPDATE employees
SET salary = salary *
    CASE
        WHEN (
            SELECT budget FROM departments
            WHERE departments.dept_id = employees.dept_id
        ) > 100000
        THEN 1.10
        ELSE 1.05
    END
WHERE dept_id IS NOT NULL;

--25
INSERT INTO employees (first_name, last_name, salary, dept_id) VALUES
('Alik', 'Smail', 50000, (SELECT dept_id FROM departments WHERE dept_name = 'IT')),
('Kuka', 'Gromiko', 45000, (SELECT dept_id FROM departments WHERE dept_name = 'Sales')),
('Serik', 'Baiber', 75000, (SELECT dept_id FROM departments WHERE dept_name = 'Management')),
('Dorash', 'Arman', 65000, (SELECT dept_id FROM departments WHERE dept_name = 'IT')),
('Zhansaya', 'Serikbol', 40000, (SELECT dept_id FROM departments WHERE dept_name = 'Sales'));

UPDATE employees
SET salary = salary * 1.10
WHERE (first_name, last_name) IN (
    ('Alik', 'Smail'),
    ('Kuka', 'Gromiko'),
    ('Serik', 'Baiber'),
    ('Dorash', 'Arman'),
    ('Zhansaya', 'Serikbol')
);

--26
CREATE TABLE IF NOT EXISTS employees_archive AS
SELECT * FROM employees WHERE 1 = 0;

INSERT INTO employees_archive
SELECT * FROM employees WHERE status = 'Inactive';

DELETE FROM employees
WHERE status = 'Inactive';

--27
UPDATE projects
SET end_date = end_date + INTERVAL '30 day'
WHERE budget > 50000
AND (
    SELECT COUNT(*)
    FROM employees
    WHERE employees.dept_id = projects.dept_id
) > 3;