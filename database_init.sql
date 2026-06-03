-- Vorcas Manager Database Initialization Script

-- 1. Roles Table
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) UNIQUE NOT NULL,
    hierarchy_level INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Initial Roles
INSERT INTO roles (role_name, hierarchy_level) VALUES 
('SUPER_ADMIN', 1),
('ADMIN', 2),
('HR', 3),
('TEAM_LEAD', 4),
('EMPLOYEE', 5);

-- 2. Users Table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role_id INT REFERENCES roles(id),
    is_active BOOLEAN DEFAULT TRUE,
    fcm_token TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Departments Table
CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Initial Departments
INSERT INTO departments (department_name) VALUES 
('Management'), ('Engineering'), ('Marketing'), ('HR'), ('Operations');

-- 4. Employees Table (Self-referencing for hierarchy)
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    user_id INT UNIQUE REFERENCES users(id),
    employee_id VARCHAR(50) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    department_id INT REFERENCES departments(id),
    role_id INT REFERENCES roles(id),
    supervisor_id INT REFERENCES employees(id),
    hire_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Attendance Table
CREATE TABLE attendance (
    id SERIAL PRIMARY KEY,
    employee_id INT REFERENCES employees(id),
    check_in_time TIMESTAMP,
    check_out_time TIMESTAMP,
    location_lat DECIMAL(10, 8),
    location_long DECIMAL(11, 8),
    attendance_date DATE DEFAULT CURRENT_DATE,
    work_hours DECIMAL(4, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5b. Attendance Breaks Table
CREATE TABLE attendance_breaks (
    id SERIAL PRIMARY KEY,
    attendance_id INT REFERENCES attendance(id),
    break_start TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    break_end TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Leave Requests Table
CREATE TABLE leave_requests (
    id SERIAL PRIMARY KEY,
    employee_id INT REFERENCES employees(id),
    leave_type VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT,
    status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, APPROVED, REJECTED
    approved_by INT REFERENCES employees(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Tasks Table
CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    assigned_by INT REFERENCES employees(id),
    assigned_to INT REFERENCES employees(id),
    priority VARCHAR(20) DEFAULT 'MEDIUM', -- LOW, MEDIUM, HIGH, CRITICAL
    status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, IN_PROGRESS, COMPLETED, BLOCKED
    deadline TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. Notifications Table
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(50),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 9. Permissions Table
CREATE TABLE permissions (
    id SERIAL PRIMARY KEY,
    role_id INT REFERENCES roles(id),
    permission_name VARCHAR(100) NOT NULL,
    can_create BOOLEAN DEFAULT FALSE,
    can_read BOOLEAN DEFAULT TRUE,
    can_update BOOLEAN DEFAULT FALSE,
    can_delete BOOLEAN DEFAULT FALSE
);


-- Indexes for performance
CREATE INDEX idx_employee_supervisor ON employees(supervisor_id);
CREATE INDEX idx_attendance_date ON attendance(attendance_date);
CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to);
CREATE INDEX idx_leave_status ON leave_requests(status);
