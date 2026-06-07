

--  step 1: create the database
--  run only this line first on its own before anything else
--  then select student_performance_db from the dropdown at
--  the top of ssms and continue running the rest

create database student_performance_db;
go

use student_performance_db;
go


--  step 2: drop tables if they already exist
--
--  this block removes any existing tables so you can run
--  the file fresh without getting duplicate table errors.
--  tables must be dropped in reverse order because of
--  foreign key dependencies you cannot drop a table that
--  another table is still referencing.
--  order: attendance and grade first (they reference others)
--         then enrollment (references student and course)
--         then course, instructor, student (reference dept)
--         then department last (referenced by everyone)

drop table if exists attendance;
drop table if exists grade;
drop table if exists enrollment;
drop table if exists course;
drop table if exists instructor;
drop table if exists student;
drop table if exists department;
go


--  step 3: create normalized tables
--
--  tables are created in the correct order so that a table
--  being referenced by a foreign key always exists before
--  the table that references it.
--  order: department first → then student, instructor, course
--         → then enrollment → then grade and attendance last


--  table 1: department
--
--  stores information about each academic department.
--  this table has no foreign keys — it is the root table
--  that all other tables reference through deptid.
--
--  primary key: deptid
--  foreign keys: none

create table department (
    deptid      int             not null primary key,  -- unique id for each department (pk)
    deptname    varchar(100)    not null,              -- name of the department e.g. computer science
    hod         varchar(100),                          -- head of department name
    location    varchar(50)                            -- physical location e.g. block a
);
go


--  table 2: student
--
--  stores personal and academic information about each student.
--  deptid is a foreign key linking each student to the
--  department they are enrolled in.
--
--  primary key: studentid
--  foreign key: deptid references department(deptid)

create table student (
    studentid      int             not null primary key,  -- unique id for each student (pk)
    firstname      varchar(50),                           -- student first name
    lastname       varchar(50),                           -- student last name
    dob            date,                                  -- date of birth
    email          varchar(100),                          -- student email address
    phone          varchar(25),                           -- contact number
    address        varchar(255),                          -- home address
    enrollmentdate date,                                  -- date student enrolled in university
    deptid         int foreign key references department(deptid)  -- links to department table (fk)
);
go


--  table 3: instructor
--
--  stores information about each instructor.
--  deptid is a foreign key linking each instructor to the
--  department they belong to.
--
--  primary key: instructorid
--  foreign key: deptid references department(deptid)

create table instructor (
    instructorid int             not null primary key,  -- unique id for each instructor (pk)
    firstname    varchar(50),                           -- instructor first name
    lastname     varchar(50),                           -- instructor last name
    email        varchar(100),                          -- instructor email address
    hiredate     date,                                  -- date the instructor was hired
    officenumber varchar(20),                           -- office room number
    deptid       int foreign key references department(deptid)  -- links to department table (fk)
);
go


--  table 4: course
--
--  stores information about each course offered.
--  deptid is a foreign key linking each course to the
--  department that offers it.
--
--  primary key: courseid
--  foreign key: deptid references department(deptid)

create table course (
    courseid   int             not null primary key,  -- unique id for each course (pk)
    coursename varchar(100),                          -- name of the course e.g. data structures
    credits    int,                                   -- number of credit hours
    deptid     int foreign key references department(deptid)  -- links to department table (fk)
);
go


--  table 5: enrollment
--
--  this table resolves the many-to-many relationship between
--  student and course. one student can enroll in many courses
--  and one course can have many students enrolled in it.
--  the enrollment table sits in between and links both.
--
--  primary key: enrollmentid
--  foreign key: studentid references student(studentid)
--  foreign key: courseid references course(courseid)

create table enrollment (
    enrollmentid   int             not null primary key,  -- unique id for each enrollment record (pk)
    studentid      int foreign key references student(studentid),  -- links to student table (fk)
    courseid       int foreign key references course(courseid),    -- links to course table (fk)
    semester       varchar(20),                                    -- semester e.g. fall, spring, summer
    year           int,                                            -- academic year e.g. 2023
    enrollmentdate date                                            -- date of enrollment in this course
);
go


--  table 6: grade
--
--  stores the marks and letter grade a student received
--  for a specific enrollment. linked to enrollment instead
--  of directly to student so we know exactly which course
--  and semester the grade belongs to.
--
--  primary key: gradeid
--  foreign key: enrollmentid references enrollment(enrollmentid)

create table grade (
    gradeid      int             not null primary key,  -- unique id for each grade record (pk)
    enrollmentid int foreign key references enrollment(enrollmentid),  -- links to enrollment table (fk)
    marks        decimal(5,2),                          -- numeric score e.g. 87.50
    lettergrade  varchar(2)                             -- letter grade e.g. a, b+, c
);
go


--  table 7: attendance
--
--  stores individual attendance records for each student
--  per course per day. studentid and courseid are both
--  foreign keys so we know which student attended which
--  course on which date.
--
--  primary key: attendanceid
--  foreign key: studentid references student(studentid)
--  foreign key: courseid references course(courseid)

create table attendance (
    attendanceid   int             not null primary key,  -- unique id for each attendance record (pk)
    studentid      int foreign key references student(studentid),  -- links to student table (fk)
    courseid       int foreign key references course(courseid),    -- links to course table (fk)
    attendancedate date,                                           -- date of the class
    status         varchar(10)                                     -- present or absent
);
go


--  step 4: insert data from imported flat file
--
--  these insert statements pull data from the flat file 
--  imported and distribute it into the correct normalized
--  tables. select distinct is used in every query to make
--  sure no duplicate rows are inserted for example
--  department data repeats for every student in the flat
--  file but we only want each department once in the
--  department table.

select * from Students_Performance_Flat

-- insert into department
-- select distinct rows only so each department appears once.
-- the flat file repeats deptname for every student but this
-- query collapses them into 8 unique department rows.
insert into department (deptid, deptname, hod, Location)
select distinct DeptID, DeptName, HOD, Location
from Students_Performance_Flat;
go

select * from department

-- insert into instructor
-- each instructor appears multiple times in the flat file
-- once per student in their department. select distinct
-- ensures we only insert 8 unique instructor records.
insert into instructor (instructorid, firstname, lastname, email, hiredate, officenumber, deptid)
select distinct
    InstructorID,
    instructor_firstname,
    instructor_lastname,
    instructor_email,
    hiredate,
    officenumber,
    deptid
from Students_Performance_Flat;
go

select * from instructor

-- insert into course
-- same logic — courses repeat in the flat file but we only
-- want each unique course once in the course table.
insert into course (courseid, coursename, credits, deptid)
select distinct courseid, coursename, credits, deptid
from Students_Performance_Flat;
go

select * from course

-- insert into student
-- one row per student. student_enrollmentdate in the flat
-- file maps to enrollmentdate in the student table.
-- must be inserted before enrollment since enrollment
-- has a foreign key that references this table.
insert into student (studentid, firstname, lastname, dob, email, phone, address, enrollmentdate, deptid)
select distinct
    studentid,
    firstname,
    lastname,
    dob,
    email,
    phone,
    address,
    student_enrollmentdate,
    deptid
from Students_Performance_Flat;
go

select * from student

-- insert into enrollment
-- links each student to their course with semester and year.
-- enrollmentid is already unique per row in the flat file
-- so select distinct simply ensures no accidental duplicates.
insert into enrollment (enrollmentid, studentid, courseid, semester, year, enrollmentdate)
select distinct
    enrollmentid,
    studentid,
    courseid,
    semester,
    year,
    student_enrollmentdate
from Students_Performance_Flat;
go

select * from enrollment

-- insert into grade
-- marks and lettergrade come directly from the flat file.
-- linked to enrollment not to student directly so the grade
-- is tied to a specific course and semester.
insert into grade (gradeid, enrollmentid, marks, lettergrade)
select distinct gradeid, enrollmentid, marks, lettergrade
from Students_Performance_Flat;
go

select * from grade

-- insert into attendance
-- attendancedate and attendancestatus map to the column
-- names in the flat file. three attendance records exist
-- per student in the flat file so select distinct is
-- important here to avoid duplicate insertions.
insert into attendance (attendanceid, studentid, courseid, attendancedate, status)
select distinct
    attendanceid,
    studentid,
    courseid,
    attendancedate,
    attendancestatus
from Students_Performance_Flat;
go


--  step 5: verify all tables loaded correctly
--
--  run this block after all inserts to confirm the correct
--  number of rows were loaded into each table.
--  expected results:
--  department  →  8 rows  (one per department)
--  student     →  500 rows
--  instructor  →  8 rows  (one per department)
--  course      →  16 rows (two per department)
--  enrollment  →  500 rows
--  grade       →  500 rows
--  attendance  →  500 rows (may be more if multiple records)

select 'department' as table_name, count(*) as row_count from department

select 'student',    count(*) from student

select 'instructor', count(*) from instructor

select 'course',     count(*) from course

select 'enrollment', count(*) from enrollment

select 'grade',      count(*) from grade

select 'attendance', count(*) from attendance;



select * from department;
go

select * from student;
go

select * from instructor;
go

select * from course;
go

select * from enrollment;
go

select * from grade;
go

select * from attendance;
go


-- DELIVRABLE 3 


-- DELIVERABLE 3: SQL IMPLEMENTATION & TESTING (UPDATED)
-- Queries + Aggregates + Filtering + Inserts/Deletes + View


-- 1. SIMPLE JOIN QUERIES

-- List all students with their departments
SELECT s.studentid, s.firstname, s.lastname, d.deptname
FROM student s
JOIN department d ON s.deptid = d.deptid;

-- List all instructors with their departments
SELECT i.instructorid, i.firstname, i.lastname, d.deptname
FROM instructor i
JOIN department d ON i.deptid = d.deptid;

-- List all courses with their departments
SELECT c.courseid, c.coursename, c.credits, d.deptname
FROM course c
JOIN department d ON c.deptid = d.deptid;

-- 2. JOIN + AGGREGATE QUERIES

-- Average, Minimum, and Maximum marks per course
SELECT c.coursename,
       AVG(g.marks) AS avgmarks,
       MIN(g.marks) AS minmarks,
       MAX(g.marks) AS maxmarks
FROM grade g
JOIN enrollment e ON g.enrollmentid = e.enrollmentid
JOIN course c ON e.courseid = c.courseid
GROUP BY c.coursename
ORDER BY avgmarks DESC;

-- Count students per department
SELECT d.deptname, COUNT(s.studentid) AS totalstudents
FROM department d
LEFT JOIN student s ON d.deptid = s.deptid
GROUP BY d.deptname;

-- Total marks (SUM) obtained per student across all courses
SELECT s.studentid, s.firstname, s.lastname, SUM(g.marks) AS totalmarks
FROM student s
JOIN enrollment e ON s.studentid = e.studentid
JOIN grade g ON e.enrollmentid = g.enrollmentid
GROUP BY s.studentid, s.firstname, s.lastname
ORDER BY totalmarks DESC;

-- 3. FILTERING QUERIES

-- Students scoring above 85 marks in any course
SELECT s.firstname, s.lastname, c.coursename, g.marks
FROM grade g
JOIN enrollment e ON g.enrollmentid = e.enrollmentid
JOIN student s ON e.studentid = s.studentid
JOIN course c ON e.courseid = c.courseid
WHERE g.marks > 85
ORDER BY g.marks DESC;

-- Students enrolled in more than 3 courses
SELECT s.studentid, s.firstname, s.lastname, COUNT(e.courseid) AS totalcourses
FROM student s
JOIN enrollment e ON s.studentid = e.studentid
GROUP BY s.studentid, s.firstname, s.lastname
HAVING COUNT(e.courseid) > 3;

-- Students with attendance rate above 90%
SELECT s.studentid, s.firstname, s.lastname,
       (SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END)*100.0 / COUNT(a.attendanceid)) AS attendance_rate
FROM attendance a
JOIN student s ON a.studentid = s.studentid
GROUP BY s.studentid, s.firstname, s.lastname
HAVING (SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END)*100.0 / COUNT(a.attendanceid)) > 90
ORDER BY attendance_rate DESC;

-- Attendance records marked 'Absent'
SELECT s.firstname, s.lastname, c.coursename, a.attendancedate, a.status
FROM attendance a
JOIN student s ON a.studentid = s.studentid
JOIN course c ON a.courseid = c.courseid
WHERE a.status = 'Absent';

-- 4. UPDATE and DELETE OPERATIONS

-- Add 5 new instructors
INSERT INTO instructor (instructorid, firstname, lastname, email, deptid)
VALUES
(501, 'Alyssa', 'Grant', 'alyssa.grant@university.com', 1),
(502, 'Marcus', 'Hill', 'marcus.hill@university.com', 2),
(503, 'Fatima', 'Khan', 'fatima.khan@university.com', 3),
(504, 'Jason', 'Nguyen', 'jason.nguyen@university.com', 4),
(505, 'Lina', 'Torres', 'lina.torres@university.com', 2);

-- Add 10 new courses (relevant and distributed)
INSERT INTO course (courseid, coursename, credits, deptid)
VALUES
(301, 'Digital Marketing', 3, 1),
(302, 'Financial Analytics', 4, 2),
(303, 'Data Warehousing', 3, 3),
(304, 'Organizational Behavior', 3, 4),
(305, 'Business Forecasting', 3, 2),
(306, 'International Trade', 3, 1),
(307, 'Network Security', 4, 3),
(308, 'Human Resource Strategy', 3, 4),
(309, 'AI for Business', 4, 1),
(310, 'Operations Research', 3, 2);

-- Update email domain for all instructors to standardized format
UPDATE instructor
SET email = LOWER(firstname + '.' + lastname + '@university.com');

-- Delete students with attendance lower than 50%
ALTER TABLE enrollment
DROP CONSTRAINT FK__enrollmen__stude__339FAB6E;

ALTER TABLE enrollment
ADD CONSTRAINT FK_enrollment_student
FOREIGN KEY (studentid)
REFERENCES student(studentid)
ON DELETE CASCADE;

-- 5. ADVANCED FEATURE: VIEW

-- Create a view showing student performance summary
CREATE VIEW vwstudentperformance AS
SELECT 
    s.studentid,
    s.firstname + ' ' + s.lastname AS fullname,
    d.deptname,
    COUNT(DISTINCT e.courseid) AS totalcourses,
    AVG(g.marks) AS avgmarks,
    MIN(g.marks) AS minmarks,
    MAX(g.marks) AS maxmarks,
    SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END)*100.0 / COUNT(a.attendanceid) AS attendance_rate
FROM student s
JOIN department d ON s.deptid = d.deptid
JOIN enrollment e ON s.studentid = e.studentid
JOIN grade g ON e.enrollmentid = g.enrollmentid
JOIN attendance a ON s.studentid = a.studentid
GROUP BY s.studentid, s.firstname, s.lastname, d.deptname;

-- Test the view
SELECT * FROM vwstudentperformance;

-- END OF DELIVERABLE 3 SQL


