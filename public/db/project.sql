-- Drop existing DB and create fresh one
DROP DATABASE IF EXISTS college_mgmt;
CREATE DATABASE college_mgmt;
USE college_mgmt;

-- Create a new user and grant privileges
-- Replace 'new_user' and 'new_password' with your desired username and password
CREATE USER 'new_user'@'localhost' IDENTIFIED BY 'new_password';

-- Grant all privileges on the college_mgmt database to the new user
GRANT ALL PRIVILEGES ON college_mgmt.* TO 'new_user'@'localhost';

-- Apply the privilege changes immediately
FLUSH PRIVILEGES;

-- ========== TABLE DEFINITIONS ==========

-- Department
CREATE TABLE department (
    did INT PRIMARY KEY NOT NULL,
    dname VARCHAR(50)
);

-- Student
CREATE TABLE student (
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    full_name VARCHAR(200) AS (CONCAT_WS(' ', first_name, last_name)),
    sapid VARCHAR(11) PRIMARY KEY NOT NULL,
    gender VARCHAR(6) NOT NULL,
    dob DATE,
    did INT,
    FOREIGN KEY(did) REFERENCES department(did)
);

-- Faculty
CREATE TABLE faculty (
    fid INT PRIMARY KEY NOT NULL,
    fname VARCHAR(50),
    salary DECIMAL(8,2),
    email VARCHAR(50),
    did INT,
    FOREIGN KEY(did) REFERENCES department(did)
);

-- Add HOD in department
ALTER TABLE department
    ADD hod INT;

ALTER TABLE department
    ADD FOREIGN KEY (hod) REFERENCES faculty(fid);

-- Course
CREATE TABLE course (
    courseid INT PRIMARY KEY NOT NULL,
    course_name VARCHAR(50),
    credits INT,
    did INT,
    FOREIGN KEY(did) REFERENCES department(did)
);

-- Teaches (relationship between faculty and course)
CREATE TABLE teaches (
    fid INT,
    courseid INT,
    FOREIGN KEY(fid) REFERENCES faculty(fid),
    FOREIGN KEY(courseid) REFERENCES course(courseid)
);

-- Research projects
CREATE TABLE research_proj (
    pid INT PRIMARY KEY NOT NULL,
    pname VARCHAR(50),
    p_desc VARCHAR(100)
);

-- Research faculty relationship
CREATE TABLE research_faculty (
    fid INT,
    pid INT,
    FOREIGN KEY(fid) REFERENCES faculty(fid),
    FOREIGN KEY(pid) REFERENCES research_proj(pid)
);

-- Research student relationship
CREATE TABLE research_student (
    sapid VARCHAR(11),
    pid INT,
    FOREIGN KEY(sapid) REFERENCES student(sapid),
    FOREIGN KEY(pid) REFERENCES research_proj(pid)
);

-- Library
CREATE TABLE library (
    bookid INT PRIMARY KEY AUTO_INCREMENT,
    bname VARCHAR(50),
    edition INT,
    author VARCHAR(50)
);

-- Borrowed (books borrowed by faculty or students)
CREATE TABLE borrowed (
    bookid INT,
    fid INT,
    sapid VARCHAR(11),
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(fid) REFERENCES faculty(fid),
    FOREIGN KEY(sapid) REFERENCES student(sapid),
    FOREIGN KEY(bookid) REFERENCES library(bookid)
);

-- Committee
CREATE TABLE committee (
    committee_id INT PRIMARY KEY NOT NULL,
    c_name VARCHAR(50),
    c_head VARCHAR(11),
    tech_c BOOLEAN,
    compi_wins INT,
    events_organised INT,
    FOREIGN KEY(c_head) REFERENCES student(sapid)
);

-- Core members of committees
CREATE TABLE core_members (
    committee_id INT NOT NULL,
    sapid VARCHAR(11) NOT NULL,
    FOREIGN KEY(committee_id) REFERENCES committee(committee_id),
    FOREIGN KEY(sapid) REFERENCES student(sapid)
);

-- Co‑members of committees
CREATE TABLE co_members (
    committee_id INT NOT NULL,
    sapid VARCHAR(11) NOT NULL,
    FOREIGN KEY(committee_id) REFERENCES committee(committee_id),
    FOREIGN KEY(sapid) REFERENCES student(sapid)
);

-- Messages table (for storing validation notices)
CREATE TABLE messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sapid VARCHAR(11),
    message VARCHAR(255) NOT NULL,
    FOREIGN KEY(sapid) REFERENCES student(sapid)
);

-- ========== TRIGGERS ==========

DELIMITER $$

-- After deleting a student, cleanup dependent tables
CREATE TRIGGER after_student_delete
AFTER DELETE ON student
FOR EACH ROW
BEGIN
    DELETE FROM co_members WHERE sapid = OLD.sapid;
    DELETE FROM core_members WHERE sapid = OLD.sapid;
    DELETE FROM research_student WHERE sapid = OLD.sapid;
END$$

-- After deleting a faculty, cleanup teaches & research_faculty
CREATE TRIGGER after_faculty_delete
AFTER DELETE ON faculty
FOR EACH ROW
BEGIN
    DELETE FROM teaches WHERE fid = OLD.fid;
    DELETE FROM research_faculty WHERE fid = OLD.fid;
END$$

-- After deleting a research project, cleanup relationships
CREATE TRIGGER after_project_delete
AFTER DELETE ON research_proj
FOR EACH ROW
BEGIN
    DELETE FROM research_student WHERE pid = OLD.pid;
    DELETE FROM research_faculty WHERE pid = OLD.pid;
END$$

-- After deleting a committee, cleanup members
CREATE TRIGGER after_committee_delete
AFTER DELETE ON committee
FOR EACH ROW
BEGIN
    DELETE FROM co_members WHERE committee_id = OLD.committee_id;
    DELETE FROM core_members WHERE committee_id = OLD.committee_id;
END$$

-- Trigger to check gender at insert
CREATE TRIGGER gender_trigger
AFTER INSERT ON student
FOR EACH ROW
BEGIN
    IF NOT (NEW.gender = 'male' OR NEW.gender = 'female') THEN
        INSERT INTO messages(sapid, message)
        VALUES (NEW.sapid, 'Please update your gender');
    END IF;
END$$

DELIMITER ;

-- ========== INSERT RECORDS ==========

-- Departments
INSERT INTO department (did, dname) VALUES 
  (1, "Computer Engineering"),
  (2, "Mechanical Engineering"),
  (3, "Electronics Engineering"),
  (4, "Data Science");

-- Faculty
INSERT INTO faculty (fid, fname, salary, email, did) VALUES
  (34, "Neha Sharma",   50000, "neha@faculty.com", 1),
  (56, "Rohan Kakade",  60000, "rohan@faculty.com", 1),
  (66, "Mohan Mistry",  70000, "mohan@faculty.com", 1),
  (12, "Pratik Sharma", 50000, "pratik@faculty.com", 2),
  (26, "Manav Shah",    60000, "manav@faculty.com", 2),
  (42, "Rohan Savla",   70000, "rohan@faculty.com", 2),
  (2,  "Dipesh Agarwal",    50000, "dipesh@faculty.com", 3),
  (24, "Kreena Kapoor",     60000, "kreena@faculty.com", 3),
  (18, "Karishma Shah",     70000, "karishma@faculty.com", 3),
  (73, "Shivesh Bhandari",  50000, "shivesh@faculty.com", 4),
  (48, "Poonam Choudhary",  60000, "poonam@faculty.com", 4),
  (37, "Manika Saxena",     70000, "manika@faculty.com", 4),
  (33, "Darpan Sonawne",    50000, "darpan@faculty.com", 1),
  (55, "Mona Bajekal",      60000, "mona@faculty.com", 1),
  (11, "Rajiv Mishra",      50000, "rajiv@faculty.com", 2),
  (25, "Sonali Bindra",     60000, "sonali@faculty.com", 2),
  (3,  "Bhavesh Mehta",     50000, "bhavesh@faculty.com", 3),
  (23, "Manan Mehta",       60000, "manan@faculty.com", 3),
  (72, "Pooja Shukla",      50000, "pooja@faculty.com", 4),
  (47, "Rahul Sharma",      60000, "rahul@faculty.com", 4);

-- Update HODs in departments
UPDATE department SET hod = 66 WHERE did = 1;
UPDATE department SET hod = 42 WHERE did = 2;
UPDATE department SET hod = 18 WHERE did = 3;
UPDATE department SET hod = 37 WHERE did = 4;

-- Students
INSERT INTO student (first_name, last_name, sapid, gender, dob, did) VALUES
  ("Nemil", "Shah",     "60004180061", "male",   "2001-01-20", 1),
  ("Nimit", "Vasavat",  "60004180064", "male",   "2000-08-08", 1),
  ("Naman", "Dangi",    "60004180056", "male",   "2000-07-30", 1),
  ("Kanishk", "Shah",   "60005180061", "male",   "2000-12-08", 2),
  ("Kedar", "Kini",     "60005180064", "male",   "2000-10-08", 2),
  ("Jinit", "Jain",     "60005180056", "male",   "2000-09-12", 2),
  ("Muskaan", "Sharma", "60003180061", "female", "2000-02-03", 3),
  ("Pankti", "Galia",   "60003180064", "female", "2000-05-15", 3),
  ("Shreya", "Jain",    "60003180056", "female", "2000-12-02", 3),
  ("Abhinav", "Kumar",  "60007180061", "male",   "2000-04-13", 4),
  ("Rhea", "Maheshwari","60007180064", "female", "2000-06-23", 4),
  ("Aakansha", "Nair",  "60007180056", "female", "2000-03-15", 4),
  ("Advaith","Gill",     "60004180001", "male",   "2000-01-20", 1),
  ("Shanaya","Pau",      "60004180002", "female", "2000-02-21", 1),
  ("Bhavana","Kothari",  "60004180003", "female", "2000-03-22", 1),
  ("Parth","Baral",      "60004180004", "male",   "2000-04-23", 1),
  ("Swarna","Gara",      "60004180005", "female", "2000-05-24", 1),
  ("Devansh","Gada",     "60004180006", "male",   "2000-06-25", 1),
  ("Lata","Tripathi",    "60004180007", "female", "2000-07-26", 1),
  ("Radha","Puri",       "60004180008", "female", "2000-08-27", 1),
  ("Abha","Iyenger",     "60004180009", "female", "2000-09-28", 1),
  ("Padma","Sani",       "60004180010", "female", "2000-10-29", 1),
  ("Karishma","Dey",     "60004180011", "female", "2000-11-30", 1),
  ("Ravindra","Sami",    "60004180012", "male",   "2000-12-31", 1),
  ("Richa","Shah",       "60004180013", "female", "2000-12-01", 1),
  ("Kushal","Bhattacharyya","60004180014","male", "2000-11-02", 1),
  ("Diksha","Srinivas",  "60004180015","female","2000-10-03", 1),
  ("Rajiv","Oza",        "60004180016","male",  "2000-09-04", 1),
  ("Shivansh","Tripathi","60004180017","male",  "2000-08-05", 1),
  ("Dayaram","Vala",     "60005180001","male",  "2000-07-06", 2),
  ("Aditi","Rana",       "60005180002","female","2000-06-07", 2),
  ("Hrithik","Gokhale",   "60005180003","male", "2000-05-08", 2),
  ("Madhur","Thaman",     "60005180004","male","2000-04-09", 2),
  ("Kalpana","Chandra",   "60005180005","female","2000-03-10", 2),
  ("Mukta","Solanki",     "60005180006","female","2000-02-11", 2),
  ("Isha","Nadkarni",     "60005180007","female","2000-01-12", 2),
  ("Arnav","Thakkar",     "60005180008","male","2000-01-13", 2),
  ("Alisha","D'Alia",     "60005180009","female","2000-02-14", 2),
  ("Kavita","Iyer",       "60005180010","female","2000-03-15", 2),
  ("Aryan","Nayar",       "60005180011","male","2000-04-16", 2),
  ("Advay","Hayre",       "60005180012","male","2000-05-17", 2),
  ("Devina","Sachdev",    "60005180013","female","2000-06-18", 2),
  ("Ranya","Nori",        "60005180014","female","2000-07-19", 2),
  ("Shantanu","Chhabra",  "60005180015","male","2000-08-20", 2),
  ("Sai","Khalsa",        "60005180016","male","2000-09-21", 2),
  ("Surya","Rau",         "60005180017","male","2000-10-22", 2),
  ("Krishna","Mitra",     "60003180001","male","2000-11-23", 3),
  ("Abha","Narasimhan",   "60003180002","female","2000-12-24", 3),
  ("Akash","Bansal",      "60003180003","male","2000-12-25", 3),
  ("Ryka","Srinivasan",   "60003180004","female","2000-11-26", 3),
  ("Tanu","Goel",         "60003180005","female","2000-10-27", 3),
  ("Abhay","Basi",        "60003180006","male","2000-09-28", 3),
  ("Malini","Kanda",      "60003180007","female","2000-08-29", 3),
  ("Lakshmi","Savant",    "60003180008","female","2000-07-30", 3),
  ("Bhavana","Prashad",   "60003180009","female","2000-06-01", 3),
  ("Sarita","Sankar",     "60003180010","female","2000-05-02", 3),
  ("Ryka","Gour",         "60003180011","female","2000-04-03", 3),
  ("Isha","Din",          "60003180012","female","2000-03-04", 3),
  ("Riya","Cheema",       "60003180013","female","2000-02-05", 3),
  ("Pravin","Patel",      "60003180014","male","2000-01-06", 3),
  ("Kamala","Chhabra",    "60003180015","female","2000-01-07", 3),
  ("Namrata","Ghosh",     "60003180016","female","2000-02-08", 3),
  ("Gauri","Soni",        "60003180017","female","2000-03-09", 3),
  ("Ishaan","Sangha",     "60007180001","male","2000-04-10", 4),
  ("Shakti","Tara",       "60007180002","female","2000-05-11", 4),
  ("Diti","Sandal",        "60007180003","female","2000-06-12", 4),
  ("Ana","Grover",         "60007180004","female","2000-07-13", 4),
  ("Sai","Uppal",          "60007180005","male","2000-08-14", 4),
  ("Anik","Gokhale",       "60007180006","male","2000-09-15", 4),
  ("Aruna","Thakur",       "60007180007","female","2000-10-16", 4),
  ("Pravin","Mital",       "60007180008","male","2000-11-17", 4),
  ("Kshitij","Sant",       "60007180009","male","2000-12-18", 4),
  ("Kamala","Das",         "60007180010","female","2000-12-19", 4),
  ("Chiran","Rastogi",     "60007180011","male","2000-11-20", 4),
  ("Rajendra","Bhat",      "60007180012","male","2000-10-21", 4),
  ("Ankur","Chada",        "60007180013","male","2000-09-22", 4),
  ("Shanta","Kohli",       "60007180014","female","2000-08-23", 4),
  ("Gita","Khosla",        "60007180015","female","2000-07-24", 4),
  ("Rajesh","Hayre",       "60007180016","male","2000-06-25", 4),
  ("Arnav","Sawhney",      "60007180017","male","2000-05-26", 4);

-- Courses
INSERT INTO course (courseid, course_name, credits, did) VALUES
  (2, "Advanced Algorithms",       4, 1),
  (4, "Operating System",          4, 1),
  (6, "Fluids",                     4, 2),
  (8, "Mechanical Forces",         4, 2),
  (10, "Microprocessor",           4, 3),
  (12, "Electronics Communication",4, 3),
  (14, "Applied Statistics",       4, 4),
  (16, "Machine Learning",         4, 4),
  (1, "Data Structures",            4, 1),
  (3, "Object Oriented Programming",4,1),
  (5, "Thermodynamics",             4,2),
  (7, "Laws of Motion",             4,2),
  (9, "Semiconductors",             4,3),
  (11, "Network Analysis",          4,3),
  (13, "Data Preprocessing",        4,4),
  (15, "Artificial Intelligence",   4,4);

-- Teaches (faculty → courses)
INSERT INTO teaches (fid, courseid) VALUES
  (34, 2), (56, 4),
  (12, 6), (26, 8),
  (2, 10), (24, 12),
  (73, 14), (48, 16),
  (33, 1), (55, 3),
  (11, 5), (25, 7),
  (3, 9), (23, 11),
  (72, 13), (47, 15);

-- Research Projects
INSERT INTO research_proj (pid, pname, p_desc) VALUES
  (1, "Farmer's Tech", "Working on technology to help farmers improve on the efficiency of their farm fields."),
  (2, "Analysis of Air Pollution in India", "Working on trends of air quality of different cities in India."),
  (3, "Master Boot Record", "Studying on working of MBR"),
  (4, "Optimization of Bus Routes in Mumbai", "Optimizing bus routes to reduce vehicle traffic.");

-- Research Faculty
INSERT INTO research_faculty (fid, pid) VALUES
  (12, 1), (34, 2),
  (23, 3), (47, 4);

-- Research Student
INSERT INTO research_student (sapid, pid) VALUES
  ("60004180056", 1),
  ("60005180061", 1),
  ("60004180064", 1),
  ("60004180061", 2),
  ("60003180061", 2),
  ("60007180064", 2),
  ("60003180007", 3),
  ("60003180011", 3),
  ("60004180003", 3),
  ("60007180015", 4),
  ("60007180011", 4),
  ("60007180009", 4);

-- Library (books)
INSERT INTO library (bname, edition, author) VALUES
  ("Deep Learning", 2, "Andrew NG"),
  ("Web Development Basics", 2, "Angela Yu"),
  ("Computer Vision", 2, "Jeff Bezos"),
  ("Electric Vehicles", 2, "Elon Musk"),
  ("Polysaccharides of Microbial Origin", 2, "Oliveira"),
  ("Adverse Aeroelastic Rotorcraft", 2, "Masarati"),
  ("Encyclopedia of Ocean Engineering", 2, "Cui"),
  ("System and Circuit Design", 2, "Sanchez-Sinencio"),
  ("Handbook of Biochips", 2, "Sawan"),
  ("Nanoworkbenches", 2, "Ahner"),
  ("Handbook of Single-Cell Technologies", 2, "Santra"),
  ("Testing, Modelling and Engineering of YC", 2, "Koenders"),
  ("Wearable Medical Sensors and Systems", 2, "Zhang"),
  ("Chip Design and Manufacturing", 2, "Lanzerotti"),
  ("Vascularization of Tissue Engineering", 2, "Banfi"),
  ("Signal Processing", 2, "Paul"),
  ("The Stability of Equilibrium Capillary Surfaces", 2, "Slobozhanin"),
  ("Organ Tissue Engineering", 2, "Lee"),
  ("Encyclopedia of Systems and Control", 2, "Samad"),
  ("Rapid Roboting", 2, "Auat Cheein"),
  ("Semiconductors for Optoelectronics", 2, "Balkan"),
  ("Load Transportation Using Aerial Robots", 2, "Fierro"),
  ("Liposome-Based Drug Delivery Systems", 2, "Lu"),
  ("Nanotechnology in Oil and Gas Processing", 2, "Nassar"),
  ("Adhesive Bonding of Aircraft Composite Structures", 2, "Cavalcanti"),
  ("Automotive Control", 2, "Isermann"),
  ("High Performance Analog", 2, "Garimella"),
  ("Comfort and Perception in Architecture", 2, "Jakubiec"),
  ("Vibration Engineering for a Sustainable Future", 2, "Oberst"),
  ("Acoustics for Mechanical Structures", 2, "Herisanu");

-- Committees
INSERT INTO committee (committee_id, c_name, c_head, tech_c, compi_wins, events_organised) VALUES
  (1, "Association of Computer Machinery", "60004180056", 1, 1, 0),
  (2, "Unicode", "60004180064", 1, 4, 0),
  (3, "National Social Service", "60007180061", 0, 0, 24);

-- Core members & Co-members
INSERT INTO core_members (committee_id, sapid) VALUES
  (1, "60005180061"),
  (2, "60004180061"),
  (3, "60003180064");

INSERT INTO co_members (committee_id, sapid) VALUES
  (1, "60005180056"),
  (2, "60003180056"),
  (3, "60005180064");

-- Additional core/co members as in your later inserts
INSERT INTO core_members (committee_id, sapid) VALUES
  (1, "60004180012");

INSERT INTO co_members (committee_id, sapid) VALUES
  (1, "60004180008"),
  (1, "60004180009"),
  (1, "60004180013"),
  (1, "60005180004");

INSERT INTO core_members (committee_id, sapid) VALUES
  (2, "60007180001");

INSERT INTO co_members (committee_id, sapid) VALUES
  (2, "60007180003"),
  (2, "60003180014"),
  (2, "60007180015"),
  (2, "60007180009");

INSERT INTO core_members (committee_id, sapid) VALUES
  (3, "60003180001");

INSERT INTO co_members (committee_id, sapid) VALUES
  (3, "60003180004"),
  (3, "60003180005"),
  (3, "60003180006"),
  (3, "60003180011");

-- End of script
