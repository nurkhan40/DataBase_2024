-- Lab-2

-- Part - 1
-- Task - 1.1

CREATE DATABASE university_main
    WITH OWNER = postgres
    TEMPLATE = template0
    ENCODING = 'UTF8';

CREATE DATABASE university_archive
    CONNECTION LIMIT = 50
    TEMPLATE = template0;

CREATE DATABASE university_test
    IS_TEMPLATE = True
    CONNECTION LIMIT = 10
    TEMPLATE = template0;

-- Task - 1.2

CREATE TABLESPACE student_data
    LOCATION 'C:/data/students';

CREATE TABLESPACE course_data
    LOCATION 'C:/data/courses';

CREATE DATABASE university_distributed
    TABLESPACE = student_data
    ENCODING = 'UTF8' --LATIN9 НЕ НАХОДИТ
    CONNECTION LIMIT = -1;

-- Part - 2
-- Task - 2.1

-- 1 
CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone CHAR(15),
    date_of_birth DATE NOT NULL,
    enrollment_date DATE NOT NULL,
    gpa NUMERIC(3,2) CHECK (gpa >= 0 AND gpa <= 4.0)
);

-- 2
CREATE TABLE professors(
    professor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    office_number VARCHAR(20),
    hire_date DATE NOT NULL,
    salary NUMERIC(12, 2) CHECK (salary >= 0),
    is_tenured BOOLEAN DEFAULT TRUE,
    years_of_experience INT CHECK (years_of_experience >= 0)
);

-- 3
CREATE TABLE courses(
    course_id SERIAL PRIMARY KEY,
    course_code CHAR(8) UNIQUE NOT NULL,
    course_title VARCHAR(100) NOT NULL,
    description TEXT,
    credits SMALLINT CHECK (credits > 0),
    max_enrollment INT CHECK (max_enrollment > 0),
    course_fee NUMERIC(10, 2) CHECK (course_fee >= 0),
    is_online BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Task - 2.2
-- 1
CREATE TABLE class_schedule(
    schedule_id SERIAL PRIMARY KEY,
    course_id INT NOT NULL REFERENCES courses(course_id) ON DELETE CASCADE,
    professor_id INT NOT NULL REFERENCES professors(professor_id) ON DELETE SET NULL,
    classroom VARCHAR(20),
    class_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    duration INTERVAL,
    CHECK (end_time > start_time)
);

-- 2
CREATE TABLE student_records(
    record_id SERIAL PRIMARY KEY,
    student_id INT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    course_id INT NOT NULL REFERENCES courses(course_id) ON DELETE CASCADE,
    semester VARCHAR(20) NOT NULL,
    year INT CHECK (year >= 2000),
    grade CHAR(2),
    attendance_percentage NUMERIC(4, 2) CHECK (attendance_percentage >= 0 AND attendance_percentage <=100),
    submission_timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    last_updated TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Part - 3
-- Task - 3.1

ALTER TABLE students
    ADD COLUMN middle_name VARCHAR(30),
    ADD COLUMN student_status VARCHAR(20),
    ALTER COLUMN phone TYPE VARCHAR(20),
    ALTER COLUMN student_status SET DEFAULT 'active',
    ALTER COLUMN gpa SET DEFAULT 0.00;

ALTER TABLE professors
    ADD COLUMN department_code CHAR(5),
    ADD COLUMN research_area TEXT,
    ALTER COLUMN years_of_experience TYPE SMALLINT,
    ALTER COLUMN is_tenured SET DEFAULT FALSE,
    ADD COLUMN last_promotion_date DATE;

ALTER TABLE courses
    ADD COLUMN prerequisite_course_id INT REFERENCES courses(course_id) ON DELETE SET NULL,
    ADD COLUMN difficulty_level INT,
    ALTER COLUMN course_code TYPE VARCHAR(10),
    ALTER COLUMN credits SET DEFAULT 3,
    ADD COLUMN lab_required BOOLEAN DEFAULT FALSE;

ALTER TABLE class_schedule
    ADD COLUMN room_capacity INT CHECK (room_capacity > 0),
    DROP COLUMN duration,
    ADD COLUMN course_code VARCHAR(5),
    ALTER COLUMN course_code TYPE VARCHAR(10),
    ADD COLUMN credits VARCHAR(10),
    ALTER COLUMN credits SET DEFAULT 3,
    ADD COLUMN lab_required BOOLEAN DEFAULT FALSE;

-- Task - 3.2

ALTER TABLE student_records
    ADD COLUMN extra_credit_points NUMERIC(4, 2) CHECK (extra_credit_points >=0),
    ALTER COLUMN grade TYPE VARCHAR(5),
    ALTER COLUMN extra_credit_points SET DEFAULT 0.00,
    ADD COLUMN final_exam_date DATE,
    DROP COLUMN last_updated;

-- Part - 4
-- Task - 4.1

CREATE TABLE departments(
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    department_code CHAR(5) UNIQUE NOT NULL,
    building VARCHAR(50),
    phone CHAR(15),
    budget NUMERIC(15, 2) CHECK (budget >=0),
    established_year INT
);

CREATE TABLE library_books(
    book_id SERIAL PRIMARY KEY,
    isbn CHAR(13) UNIQUE NOT NULL,
    title VARCHAR(200) NOT NULL,
    author VARCHAR(100) NOT NULL,
    publisher VARCHAR(100),
    publication_date DATE,
    price NUMERIC(10, 2) CHECK (price >= 0),
    is_available BOOLEAN DEFAULT TRUE,
    acquisition_timestamp TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE student_book_loans(
    loan_id SERIAL PRIMARY KEY,
    student_id INT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    book_id INT NOT NULL REFERENCES library_books(book_id) ON DELETE CASCADE,
    loan_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE,
    fine_amount NUMERIC(6, 2) CHECK (fine_amount >= 0) DEFAULT 0.00,
    loan_status VARCHAR(20)
);

-- Task - 4.2
ALTER TABLE professors
    ADD COLUMN department_id INT REFERENCES departments(department_id) ON DELETE SET NULL;

ALTER TABLE students
    ADD COLUMN adviser_id INT REFERENCES professors(professor_id) ON DELETE SET NULL;

ALTER TABLE courses
    ADD COLUMN department_id INT REFERENCES departments(department_id) ON DELETE SET NULL;

CREATE TABLE grade_scale(
    scale_id SERIAL PRIMARY KEY,
    letter_grade CHAR(2) UNIQUE NOT NULL,
    min_percentage NUMERIC(4, 1) CHECK (min_percentage >= 0 AND min_percentage <= 100),
    max_percentage NUMERIC(4, 1) CHECK (max_percentage >= 0 AND max_percentage <= 100),
    gpa_points NUMERIC(3, 2) CHECK (gpa_points >= 0 AND gpa_points <= 4.0)
);

CREATE TABLE semester_calendar(
    semester_id SERIAL PRIMARY KEY,
    semester_name VARCHAR(20) NOT NULL,
    academic_year INT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    registration_deadline TIMESTAMP NOT NULL,
    is_current BOOLEAN DEFAULT FALSE
);

-- Part - 5
-- Task - 5.1

DROP TABLE IF EXISTS student_book_loans;
DROP TABLE IF EXISTS library_books;
DROP TABLE IF EXISTS grade_scale;

CREATE TABLE grade_scale(
    grade_id SERIAL PRIMARY KEY,
    letter_grade CHAR(2) UNIQUE NOT NULL,
    min_percentage NUMERIC(4, 1) CHECK (min_percentage >= 0 AND min_percentage <= 100),
    max_percentage NUMERIC(4, 1) CHECK (max_percentage >= 0 AND max_percentage <= 100),
    gpa_points NUMERIC(3, 2) CHECK (gpa_points >= 0 AND gpa_points <= 4.0),
    description TEXT
);

DROP TABLE IF EXISTS semester_calendar CASCADE;

CREATE TABLE semester_calendar(
    semester_id SERIAL PRIMARY KEY,
    semester_name VARCHAR(20) NOT NULL,
    academic_year INT NOT NULL CHECK (academic_year >= 2000),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    registration_deadline TIMESTAMP NOT NULL,
    is_current BOOLEAN DEFAULT FALSE
);

-- Task - 5.2

DROP DATABASE IF EXISTS university_test;

DROP DATABASE IF EXISTS university_distributed;

CREATE DATABASE university_backup
    WITH TEMPLATE = university_main;


-- Class Work
-- Part A
--1
CREATE DATABASE library_system
    WITH OWNER = postgres
    CONNECTION LIMIT = 75
    ENCODING = 'UTF8';

--2
CREATE TABLESPACE digital_content
    LOCATION 'C:/data/digital';

--Part B

CREATE TABLE book_catalog(
    catalog_id SERIAL PRIMARY KEY,
    isbn CHAR(13) UNIQUE NOT NULL,
    book_title VARCHAR(150) NOT NULL,
    author_name VARCHAR(100) NOT NULL,
    publisher VARCHAR(80),
    total_pages INT CHECK (total_pages > 0),
    book_format CHAR(10),
    purchase_price NUMERIC(10, 2) CHECK (purchase_price >= 0),
    is_available BOOLEAN DEFAULT TRUE
);

CREATE TABLE digital_downloads(
    download_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    catalog_id INT NOT NULL REFERENCES book_catalog(catalog_id) ON DELETE CASCADE,
    download_timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    file_format VARCHAR(10),
    file_size_mb REAL,--real number
    download_completed BOOLEAN DEFAULT FALSE,
    expiry_date DATE,
    access_count SMALLINT CHECK (access_count >=0)
);

-- Part C
ALTER TABLE book_catalog
    ADD COLUMN genre VARCHAR(50),
    ADD COLUMN library_section CHAR(3),
    ALTER COLUMN genre SET DEFAULT 'UNKNOWN';

ALTER TABLE digital_downloads
    ADD COLUMN device_type VARCHAR(30),
    ALTER COLUMN file_size_mb TYPE INT,
    ADD COLUMN last_accessed TIMESTAMP;

-- Part D

CREATE TABLE reading_sessions(
    session_id SERIAL PRIMARY KEY,
    user_reference INT NOT NULL REFERENCES digital_downloads(user_id) ON DELETE CASCADE,
    book_reference INT NOT NULL REFERENCES book_catalog(catalog_id) ON DELETE CASCADE,
    session_start TIMESTAMP NOT NULL DEFAULT NOW(),
    reading_duration INTERVAL,
    pages_read SMALLINT CHECK (pages_read >= 0),
    session_active BOOLEAN DEFAULT TRUE
);