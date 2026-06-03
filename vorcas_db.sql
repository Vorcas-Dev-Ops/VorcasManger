DROP TABLE IF EXISTS "public"."attendance_breaks";
-- Sequence and defined type
CREATE SEQUENCE IF NOT EXISTS attendance_breaks_id_seq;

-- Table Definition
CREATE TABLE "public"."attendance_breaks" (
    "id" int4 NOT NULL DEFAULT nextval('attendance_breaks_id_seq'::regclass),
    "attendance_id" int4,
    "break_start" timestamp DEFAULT CURRENT_TIMESTAMP,
    "break_end" timestamp,
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "attendance_breaks_attendance_id_fkey" FOREIGN KEY ("attendance_id") REFERENCES "public"."attendance"("id"),
    PRIMARY KEY ("id")
);

DROP TABLE IF EXISTS "public"."task_assignments";
-- Sequence and defined type
CREATE SEQUENCE IF NOT EXISTS task_assignments_id_seq;

-- Table Definition
CREATE TABLE "public"."task_assignments" (
    "id" int4 NOT NULL DEFAULT nextval('task_assignments_id_seq'::regclass),
    "task_id" int4,
    "employee_id" int4,
    CONSTRAINT "task_assignments_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "public"."employees"("id"),
    CONSTRAINT "task_assignments_task_id_fkey" FOREIGN KEY ("task_id") REFERENCES "public"."tasks"("id") ON DELETE CASCADE,
    PRIMARY KEY ("id")
);


-- Indices
CREATE UNIQUE INDEX task_assignments_task_id_employee_id_key ON public.task_assignments USING btree (task_id, employee_id);

DROP TABLE IF EXISTS "public"."notifications";
-- Sequence and defined type
CREATE SEQUENCE IF NOT EXISTS notifications_id_seq;

-- Table Definition
CREATE TABLE "public"."notifications" (
    "id" int4 NOT NULL DEFAULT nextval('notifications_id_seq'::regclass),
    "user_id" int4,
    "title" varchar(255) NOT NULL,
    "body" text NOT NULL,
    "type" varchar(50),
    "is_read" bool DEFAULT false,
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE,
    PRIMARY KEY ("id")
);

DROP TABLE IF EXISTS "public"."users";
-- Sequence and defined type
CREATE SEQUENCE IF NOT EXISTS users_id_seq;

-- Table Definition
CREATE TABLE "public"."users" (
    "id" int4 NOT NULL DEFAULT nextval('users_id_seq'::regclass),
    "email" varchar(100) NOT NULL,
    "password_hash" text NOT NULL,
    "role_id" int4,
    "is_active" bool DEFAULT true,
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    "must_change_password" bool NOT NULL DEFAULT true,
    "fcm_token" text,
    "password_changed_at" timestamptz,
    CONSTRAINT "users_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id"),
    PRIMARY KEY ("id")
);


-- Indices
CREATE UNIQUE INDEX users_email_key ON public.users USING btree (email);

DROP TABLE IF EXISTS "public"."roles";
-- Sequence and defined type
CREATE SEQUENCE IF NOT EXISTS roles_id_seq;

-- Table Definition
CREATE TABLE "public"."roles" (
    "id" int4 NOT NULL DEFAULT nextval('roles_id_seq'::regclass),
    "role_name" varchar(50) NOT NULL,
    "hierarchy_level" int4 NOT NULL,
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("id")
);


-- Indices
CREATE UNIQUE INDEX roles_role_name_key ON public.roles USING btree (role_name);

DROP TABLE IF EXISTS "public"."employees";
-- Sequence and defined type
CREATE SEQUENCE IF NOT EXISTS employees_id_seq;

-- Table Definition
CREATE TABLE "public"."employees" (
    "id" int4 NOT NULL DEFAULT nextval('employees_id_seq'::regclass),
    "user_id" int4,
    "employee_id" varchar(50) NOT NULL,
    "first_name" varchar(100) NOT NULL,
    "last_name" varchar(100) NOT NULL,
    "phone" varchar(20),
    "department_id" int4,
    "role_id" int4,
    "supervisor_id" int4,
    "hire_date" date NOT NULL,
    "status" varchar(20) DEFAULT 'ACTIVE'::character varying,
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    "profile_picture_url" text,
    CONSTRAINT "employees_department_id_fkey" FOREIGN KEY ("department_id") REFERENCES "public"."departments"("id"),
    CONSTRAINT "employees_manager_id_fkey" FOREIGN KEY ("supervisor_id") REFERENCES "public"."employees"("id"),
    CONSTRAINT "employees_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id"),
    CONSTRAINT "employees_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id"),
    PRIMARY KEY ("id")
);


-- Indices
CREATE UNIQUE INDEX employees_user_id_key ON public.employees USING btree (user_id);
CREATE UNIQUE INDEX employees_employee_id_key ON public.employees USING btree (employee_id);
CREATE INDEX idx_employee_supervisor ON public.employees USING btree (supervisor_id);

DROP TABLE IF EXISTS "public"."leave_requests";
-- Sequence and defined type
CREATE SEQUENCE IF NOT EXISTS leave_requests_id_seq;

-- Table Definition
CREATE TABLE "public"."leave_requests" (
    "id" int4 NOT NULL DEFAULT nextval('leave_requests_id_seq'::regclass),
    "employee_id" int4,
    "leave_type" varchar(50) NOT NULL,
    "start_date" date NOT NULL,
    "end_date" date NOT NULL,
    "reason" text,
    "status" varchar(20) DEFAULT 'PENDING'::character varying,
    "approved_by" int4,
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "leave_requests_approved_by_fkey" FOREIGN KEY ("approved_by") REFERENCES "public"."employees"("id"),
    CONSTRAINT "leave_requests_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "public"."employees"("id"),
    PRIMARY KEY ("id")
);


-- Indices
CREATE INDEX idx_leave_status ON public.leave_requests USING btree (status);

DROP TABLE IF EXISTS "public"."tasks";
-- Sequence and defined type
CREATE SEQUENCE IF NOT EXISTS tasks_id_seq;

-- Table Definition
CREATE TABLE "public"."tasks" (
    "id" int4 NOT NULL DEFAULT nextval('tasks_id_seq'::regclass),
    "title" varchar(200) NOT NULL,
    "description" text,
    "assigned_by" int4,
    "assigned_to" int4,
    "priority" varchar(20) DEFAULT 'MEDIUM'::character varying,
    "status" varchar(20) DEFAULT 'PENDING'::character varying,
    "deadline" timestamp,
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    "department_id" int4,
    "task_type" varchar(20) DEFAULT 'TASK'::character varying,
    "start_time" time,
    "meeting_link" text,
    "github_url" text,
    CONSTRAINT "tasks_assigned_by_fkey" FOREIGN KEY ("assigned_by") REFERENCES "public"."employees"("id"),
    CONSTRAINT "tasks_assigned_to_fkey" FOREIGN KEY ("assigned_to") REFERENCES "public"."employees"("id"),
    CONSTRAINT "tasks_department_id_fkey" FOREIGN KEY ("department_id") REFERENCES "public"."departments"("id"),
    PRIMARY KEY ("id")
);


-- Indices
CREATE INDEX idx_tasks_assigned_to ON public.tasks USING btree (assigned_to);

DROP TABLE IF EXISTS "public"."attendance";
-- Sequence and defined type
CREATE SEQUENCE IF NOT EXISTS attendance_id_seq;

-- Table Definition
CREATE TABLE "public"."attendance" (
    "id" int4 NOT NULL DEFAULT nextval('attendance_id_seq'::regclass),
    "employee_id" int4,
    "check_in_time" timestamp,
    "check_out_time" timestamp,
    "location_lat" numeric(10,8),
    "location_long" numeric(11,8),
    "attendance_date" date DEFAULT CURRENT_DATE,
    "work_hours" numeric(4,2),
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    "is_late" bool DEFAULT false,
    "is_early_checkout" bool DEFAULT false,
    "early_checkout_reason" text,
    CONSTRAINT "attendance_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "public"."employees"("id"),
    PRIMARY KEY ("id")
);


-- Indices
CREATE INDEX idx_attendance_date ON public.attendance USING btree (attendance_date);

DROP TABLE IF EXISTS "public"."company_events";
-- Sequence and defined type
CREATE SEQUENCE IF NOT EXISTS company_events_id_seq;

-- Table Definition
CREATE TABLE "public"."company_events" (
    "id" int4 NOT NULL DEFAULT nextval('company_events_id_seq'::regclass),
    "title" varchar(255) NOT NULL,
    "description" text,
    "event_date" date NOT NULL,
    "event_type" varchar(50) NOT NULL,
    "created_by" int4,
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "company_events_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."employees"("id"),
    PRIMARY KEY ("id")
);

DROP TABLE IF EXISTS "public"."departments";
-- Sequence and defined type
CREATE SEQUENCE IF NOT EXISTS departments_id_seq;

-- Table Definition
CREATE TABLE "public"."departments" (
    "id" int4 NOT NULL DEFAULT nextval('departments_id_seq'::regclass),
    "department_name" varchar(100) NOT NULL,
    "created_at" timestamp DEFAULT CURRENT_TIMESTAMP,
    "description" text,
    PRIMARY KEY ("id")
);

INSERT INTO "public"."attendance_breaks" ("id", "attendance_id", "break_start", "break_end", "created_at") VALUES
(11, 24, '2026-04-15 10:52:01.498717', '2026-04-15 10:52:02.688323', '2026-04-15 10:52:01.498717'),
(12, 24, '2026-04-15 10:52:04.262275', '2026-04-15 10:52:24.784168', '2026-04-15 10:52:04.262275'),
(13, 25, '2026-04-16 10:39:58.014729', '2026-04-16 10:40:10.235476', '2026-04-16 10:39:58.014729'),
(14, 25, '2026-04-16 10:55:30.098619', '2026-04-16 10:55:53.903126', '2026-04-16 10:55:30.098619'),
(15, 26, '2026-04-16 10:57:37.742319', '2026-04-16 10:57:45.943306', '2026-04-16 10:57:37.742319'),
(16, 30, '2026-04-16 11:09:34.560981', '2026-04-16 11:09:36.322106', '2026-04-16 11:09:34.560981'),
(17, 30, '2026-04-16 11:19:36.163692', '2026-04-16 11:19:46.077582', '2026-04-16 11:19:36.163692'),
(18, 26, '2026-04-16 11:38:50.745773', NULL, '2026-04-16 11:38:50.745773'),
(19, 31, '2026-04-16 11:46:20.187417', '2026-04-16 11:46:22.14646', '2026-04-16 11:46:20.187417'),
(20, 35, '2026-04-29 12:07:42.756076', '2026-04-29 12:08:08.206307', '2026-04-29 12:07:42.756076'),
(21, 36, '2026-04-29 12:14:14.415848', NULL, '2026-04-29 12:14:14.415848'),
(22, 39, '2026-04-29 13:07:05.734001', '2026-04-29 13:07:10.753251', '2026-04-29 13:07:05.734001'),
(23, 39, '2026-04-29 13:07:17.5008', '2026-04-29 13:07:20.676516', '2026-04-29 13:07:17.5008'),
(24, 39, '2026-04-29 13:07:31.29658', '2026-04-29 13:09:14.188289', '2026-04-29 13:07:31.29658'),
(25, 46, '2026-04-29 16:10:53.236472', '2026-04-29 16:10:54.529235', '2026-04-29 16:10:53.236472'),
(26, 47, '2026-04-29 16:16:22.26017', NULL, '2026-04-29 16:16:22.26017'),
(27, 47, '2026-04-29 16:16:23.271322', NULL, '2026-04-29 16:16:23.271322'),
(28, 48, '2026-04-29 16:16:25.503114', '2026-04-29 16:16:31.718071', '2026-04-29 16:16:25.503114'),
(29, 52, '2026-05-04 14:16:22.912226', '2026-05-04 14:16:27.448309', '2026-05-04 14:16:22.912226'),
(30, 60, '2026-05-08 12:53:13.307971', NULL, '2026-05-08 12:53:13.307971'),
(31, 61, '2026-05-08 13:44:39.790815', '2026-05-08 13:44:56.93155', '2026-05-08 13:44:39.790815'),
(32, 61, '2026-05-08 13:44:43.771801', '2026-05-08 13:44:52.886349', '2026-05-08 13:44:43.771801'),
(33, 61, '2026-05-08 13:45:25.889599', '2026-05-08 13:48:21.415624', '2026-05-08 13:45:25.889599'),
(34, 61, '2026-05-08 13:46:12.05994', '2026-05-08 13:48:14.007816', '2026-05-08 13:46:12.05994'),
(35, 61, '2026-05-08 13:48:34.621201', '2026-05-08 13:49:36.580228', '2026-05-08 13:48:34.621201'),
(36, 61, '2026-05-08 13:48:40.199494', '2026-05-08 13:49:31.523015', '2026-05-08 13:48:40.199494'),
(37, 63, '2026-05-08 14:25:21.026918', '2026-05-08 14:27:31.637587', '2026-05-08 14:25:21.026918');
INSERT INTO "public"."task_assignments" ("id", "task_id", "employee_id") VALUES
(1, 2, 3),
(2, 2, 6),
(6, 3, 7),
(7, 4, 5),
(8, 4, 7),
(27, 5, 7),
(168, 6, 7),
(169, 7, 7),
(170, 8, 7),
(262, 9, 7),
(271, 10, 7);
INSERT INTO "public"."notifications" ("id", "user_id", "title", "body", "type", "is_read", "created_at") VALUES
(1, 7, 'New Task Assigned', 'You have been assigned a new task: esrdtghf', 'TASK', 't', '2026-04-15 16:15:17.800171'),
(2, 7, 'New Task Assigned', 'You have been assigned a new task: ddddddddd', 'TASK', 't', '2026-04-15 16:24:29.367298'),
(3, 6, 'New Leave Request', 'Test EMPLOYEE has requested Annual Leave leave.', 'LEAVE', 't', '2026-04-15 16:27:18.077032'),
(4, 7, 'New Task Assigned', 'You have been assigned a new task: rwetdryyghj', 'TASK', 't', '2026-04-15 16:27:49.176229'),
(5, 7, 'New Task Assigned', 'You have been assigned a new task: meetng', 'TASK', 't', '2026-04-16 11:24:55.420995'),
(6, 6, 'Task Completed', 'Task "meetng" has been marked as completed.', 'TASK', 't', '2026-04-29 11:29:01.843698'),
(7, 7, 'New Task Assigned', 'You have been assigned a new task: ha t', 'TASK', 't', '2026-04-29 12:15:11.693149'),
(8, 6, 'Task Completed', 'Task "esrdtghf" has been marked as completed.', 'TASK', 't', '2026-04-29 14:10:08.4729'),
(9, 6, 'Task Completed', 'Task "ha t" has been marked as completed.', 'TASK', 't', '2026-04-29 14:10:12.72498'),
(10, 6, 'New Leave Request', 'Test11 EMPLOYEE has requested Annual Leave leave.', 'LEAVE', 't', '2026-04-29 15:44:08.51107'),
(11, 6, 'Task Completed', 'Task "rwetdryyghj" has been marked as completed.', 'TASK', 't', '2026-04-29 23:41:13.22663'),
(12, 6, 'New Leave Request', 'Test11 EMPLOYEE has requested Sick Leave leave.', 'LEAVE', 't', '2026-05-04 11:44:56.336354'),
(13, 7, 'Leave Status Update', 'Your leave request has been approved.', 'LEAVE', 't', '2026-05-04 13:47:49.384414'),
(14, 7, 'Leave Status Update', 'Your leave request has been fully approved.', 'LEAVE', 't', '2026-05-04 14:52:21.63281'),
(15, 6, 'New Leave Request', 'Test11 EMPLOYEE has requested Annual Leave leave.', 'LEAVE', 't', '2026-05-04 16:39:38.691765'),
(16, 7, 'Leave Status Update', 'The leave request for Test11 EMPLOYEE has been approved by the Team Lead and is now pending HR approval.', 'LEAVE', 't', '2026-05-04 16:56:01.302419'),
(17, 5, 'Final Leave Approval Required', 'A leave request from Test11 EMPLOYEE has been approved by a TL and requires your final review.', 'LEAVE', 'f', '2026-05-04 16:56:01.941489'),
(18, 7, 'Leave Status Update', 'The leave request for Test11 EMPLOYEE has been rejected.', 'LEAVE', 't', '2026-05-04 16:56:34.747117'),
(19, 6, 'New Leave Request', 'Test11 EMPLOYEE has requested Annual Leave leave.', 'LEAVE', 't', '2026-05-04 16:57:19.468583'),
(20, 7, 'Leave Status Update', 'The leave request for Test11 EMPLOYEE has been fully approved.', 'LEAVE', 't', '2026-05-04 16:57:31.963559'),
(21, 6, 'New Leave Request', 'Test11 EMPLOYEE has requested Casual Leave leave.', 'LEAVE', 't', '2026-05-04 17:05:40.934113'),
(22, 7, 'Leave Status Update', 'The leave request for Test11 EMPLOYEE has been fully approved.', 'LEAVE', 't', '2026-05-04 17:11:49.267041'),
(23, 6, 'New Leave Request', 'Test11 EMPLOYEE has requested Sick Leave leave.', 'LEAVE', 't', '2026-05-07 11:03:46.873137'),
(24, 7, 'Leave Status Update', 'The leave request for Test11 EMPLOYEE has been approved by the Team Lead and is now pending HR approval.', 'LEAVE', 't', '2026-05-07 11:09:33.755881'),
(25, 5, 'Final Leave Approval Required', 'A leave request from Test11 EMPLOYEE has been approved by a TL and requires your final review.', 'LEAVE', 'f', '2026-05-07 11:09:34.008264'),
(26, 7, 'Leave Status Update', 'The leave request for Test11 EMPLOYEE has been fully approved.', 'LEAVE', 't', '2026-05-07 11:10:01.483227'),
(27, 6, 'New Leave Request', 'Test11 EMPLOYEE has requested Annual Leave leave.', 'LEAVE', 't', '2026-05-07 11:40:46.071953'),
(28, 7, 'Leave Status Update', 'The leave request for Test11 EMPLOYEE has been approved by the Team Lead and is now pending HR approval.', 'LEAVE', 't', '2026-05-07 11:41:04.806682'),
(29, 5, 'Final Leave Approval Required', 'A leave request from Test11 EMPLOYEE has been approved by a TL and requires your final review.', 'LEAVE', 'f', '2026-05-07 11:41:04.964487'),
(30, 6, 'New Leave Request', 'Test11 EMPLOYEE has requested Casual Leave leave.', 'LEAVE', 't', '2026-05-07 11:51:59.036569'),
(31, 7, 'Leave Status Update', 'The leave request for Test11 EMPLOYEE has been approved by the Team Lead and is now pending HR approval.', 'LEAVE', 't', '2026-05-07 11:52:33.602355'),
(32, 5, 'Final Leave Approval Required', 'A leave request from Test11 EMPLOYEE has been approved by a TL and requires your final review.', 'LEAVE', 'f', '2026-05-07 11:52:33.808346'),
(33, 7, 'Leave Status Update', 'The leave request for Test11 EMPLOYEE has been fully approved.', 'LEAVE', 't', '2026-05-07 11:53:09.962596'),
(34, 7, 'Leave Status Update', 'The leave request for Test11 EMPLOYEE has been fully approved.', 'LEAVE', 'f', '2026-05-07 11:58:01.15199'),
(35, 6, 'New Leave Request', 'Test11 EMPLOYEE has requested Annual Leave leave.', 'LEAVE', 't', '2026-05-07 12:12:28.284078'),
(36, 7, 'Leave Status Update', 'The leave request for Test11 EMPLOYEE has been fully approved.', 'LEAVE', 'f', '2026-05-07 12:12:41.947216'),
(37, 6, 'New Leave Request', 'Test11 EMPLOYEE has requested Sick Leave leave.', 'LEAVE', 'f', '2026-05-07 12:18:43.152766'),
(38, 6, 'New Leave Request', 'Test11 EMPLOYEE has requested Casual Leave leave.', 'LEAVE', 'f', '2026-05-07 12:20:44.823709'),
(39, 6, 'New Leave Request', 'Test11 EMPLOYEE has requested Casual Leave leave.', 'LEAVE', 'f', '2026-05-07 12:31:54.482851'),
(40, 7, 'Leave Status Update', 'The leave request for Test11 EMPLOYEE has been approved by the Team Lead and is now pending HR approval.', 'LEAVE', 'f', '2026-05-07 12:32:40.63604'),
(41, 5, 'Final Leave Approval Required', 'A leave request from Test11 EMPLOYEE has been approved by a TL and requires your final review.', 'LEAVE', 'f', '2026-05-07 12:32:42.146196'),
(42, 7, 'Leave Status Update', 'The leave request for Test11 EMPLOYEE has been approved by the Team Lead and is now pending HR approval.', 'LEAVE', 'f', '2026-05-07 12:32:49.526027'),
(43, 5, 'Final Leave Approval Required', 'A leave request from Test11 EMPLOYEE has been approved by a TL and requires your final review.', 'LEAVE', 'f', '2026-05-07 12:32:49.716476'),
(44, 7, 'Leave Status Update', 'The leave request for Test11 EMPLOYEE has been approved by the Team Lead and is now pending HR approval.', 'LEAVE', 'f', '2026-05-07 12:33:03.192806'),
(45, 5, 'Final Leave Approval Required', 'A leave request from Test11 EMPLOYEE has been approved by a TL and requires your final review.', 'LEAVE', 'f', '2026-05-07 12:33:03.416413'),
(46, 6, 'New Leave Request', 'Test11 EMPLOYEE has requested Sick Leave leave.', 'LEAVE', 'f', '2026-05-07 14:53:22.162975'),
(47, 7, 'Leave Status Update', 'The leave request for Test11 EMPLOYEE has been approved by the Team Lead and is now pending HR approval.', 'LEAVE', 'f', '2026-05-07 14:53:44.782372'),
(48, 5, 'Final Leave Approval Required', 'A leave request from Test11 EMPLOYEE has been approved by a TL and requires your final review.', 'LEAVE', 'f', '2026-05-07 14:53:44.977094'),
(49, 6, 'New Leave Request', 'Test11 EMPLOYEE has requested Sick Leave leave.', 'LEAVE', 'f', '2026-05-07 14:54:05.063641'),
(50, 7, 'Leave Status Update', 'The leave request for Test11 EMPLOYEE has been approved by the Team Lead and is now pending HR approval.', 'LEAVE', 'f', '2026-05-07 14:55:29.028407'),
(51, 5, 'Final Leave Approval Required', 'A leave request from Test11 EMPLOYEE has been approved by a TL and requires your final review.', 'LEAVE', 'f', '2026-05-07 14:55:29.210965'),
(52, 7, 'Leave Status Update', 'The leave request for Test11 EMPLOYEE has been fully approved.', 'LEAVE', 'f', '2026-05-07 14:58:20.420067'),
(53, 7, 'Leave Status Update', 'The leave request for Test11 EMPLOYEE has been fully approved.', 'LEAVE', 'f', '2026-05-07 14:58:28.75163'),
(54, 7, 'Leave Status Update', 'The leave request for Test11 EMPLOYEE has been fully approved.', 'LEAVE', 'f', '2026-05-07 14:58:39.704584'),
(55, 7, 'Leave Status Update', 'The leave request for Test11 EMPLOYEE has been rejected.', 'LEAVE', 'f', '2026-05-07 14:58:46.007501'),
(56, 7, 'Leave Status Update', 'The leave request for Test11 EMPLOYEE has been rejected.', 'LEAVE', 'f', '2026-05-07 14:58:47.569421');
INSERT INTO "public"."users" ("id", "email", "password_hash", "role_id", "is_active", "created_at", "updated_at", "must_change_password", "fcm_token", "password_changed_at") VALUES
(2, 'admin@vorcas.com', '$2b$10$uILnFXtIxn2i8A6NNBwT0eoOUuMQ1B8Bk.6qX2s/oL8HZnjbXLn6u', 1, 't', '2026-03-16 16:31:43.194343', '2026-03-16 16:31:43.194343', 'f', 'cGbD_GovSXWNyfiRdNaDLD:APA91bE3a3hwue6lC_LSa6uFyqezos-xphWG6IxvIULHX_jYTL0xXg5YsAYznZA1OJTQx_sRAhnviXIMfmO8dTyvRLorjAQWr4i1XtIGHIDaVF9sQ6DSbAg', '2026-05-07 14:42:13.181519+05:30'),
(3, 'admin_test@vorcas.com', '$2b$10$uILnFXtIxn2i8A6NNBwT0eoOUuMQ1B8Bk.6qX2s/oL8HZnjbXLn6u', 2, 't', '2026-03-16 16:59:44.107916', '2026-03-16 16:59:44.107916', 'f', 'cGbD_GovSXWNyfiRdNaDLD:APA91bE3a3hwue6lC_LSa6uFyqezos-xphWG6IxvIULHX_jYTL0xXg5YsAYznZA1OJTQx_sRAhnviXIMfmO8dTyvRLorjAQWr4i1XtIGHIDaVF9sQ6DSbAg', '2026-05-07 14:42:13.181519+05:30'),
(5, 'hr_test@vorcas.com', '$2b$10$uILnFXtIxn2i8A6NNBwT0eoOUuMQ1B8Bk.6qX2s/oL8HZnjbXLn6u', 3, 't', '2026-03-16 16:59:44.107916', '2026-03-16 16:59:44.107916', 'f', 'cr8Uff8pRzCbs-602dbH99:APA91bHvWMOJBNSdIb7IhpXUeBeCMqC8M6sIXBptVdngCXyuOfAiXx2InBIJF6rO8C9HFYsAlBPQM8M4C8X7Beavq0o3j_kIPP9rDQl57Nkl78qEo9IyLYA', '2026-05-07 14:42:13.181519+05:30'),
(6, 'lead_test@vorcas.com', '$2b$10$uILnFXtIxn2i8A6NNBwT0eoOUuMQ1B8Bk.6qX2s/oL8HZnjbXLn6u', 4, 't', '2026-03-16 16:59:44.107916', '2026-03-16 16:59:44.107916', 'f', 'ddNSNi2yRhC5E_Vzq0ub_j:APA91bHVkIIYUaEDkbIZu9OBSMNsdATW0x564gvJcz4j4hquG1n0EtoafhO-hZmgHbUryRfGxTTF7V5t00AFYT0W8ZoGea_dc5UJICb8U9yA6XzlcmAYWbw', '2026-05-07 14:42:13.181519+05:30'),
(7, 'employee_test@vorcas.com', '$2b$10$uILnFXtIxn2i8A6NNBwT0eoOUuMQ1B8Bk.6qX2s/oL8HZnjbXLn6u', 5, 't', '2026-03-16 16:59:44.107916', '2026-03-16 16:59:44.107916', 'f', 'dP-D7lm-RAeNTTYaXvhjYY:APA91bGS6t6zBaosdJ-QI8mjo1DQAk2eYuBOohISP23LxsgpEsJHN5kfdKmLapopZu0slGszyWHGJ1kX-jJa_pw6zCFRNeTs65Cy9WCfHKZND8uVLI2SjVY', '2026-05-07 14:42:13.181519+05:30'),
(8, 'lead2_test@gmail.com', '$2b$10$qAbBTIjoDvsfygJ5ywtHVOiAXc7ZUQxW0A.ECp4CZ7C1uEdl/5hGK', 4, 't', '2026-04-14 17:07:32.123249', '2026-04-14 17:07:32.123249', 't', NULL, '2026-05-07 13:26:47.287898+05:30'),
(9, '2mp2@gmail.com', '$2b$10$qAbBTIjoDvsfygJ5ywtHVOiAXc7ZUQxW0A.ECp4CZ7C1uEdl/5hGK', 5, 't', '2026-04-14 17:08:28.144672', '2026-04-14 17:08:28.144672', 't', NULL, '2026-05-07 13:26:47.287898+05:30');
INSERT INTO "public"."roles" ("id", "role_name", "hierarchy_level", "created_at") VALUES
(1, 'SUPER_ADMIN', 1, '2026-03-16 15:42:50.54422'),
(2, 'ADMIN', 2, '2026-03-16 15:42:50.54422'),
(3, 'HR', 3, '2026-04-06 12:03:38.893287'),
(4, 'TEAM_LEAD', 4, '2026-04-06 12:03:38.893287'),
(5, 'EMPLOYEE', 5, '2026-04-06 12:03:38.893287');
INSERT INTO "public"."employees" ("id", "user_id", "employee_id", "first_name", "last_name", "phone", "department_id", "role_id", "supervisor_id", "hire_date", "status", "created_at", "updated_at", "profile_picture_url") VALUES
(2, 2, 'ADM001', 'Super', 'Admin', NULL, 1, 1, NULL, '2026-03-16', 'ACTIVE', '2026-03-16 16:32:17.416628', '2026-03-16 16:32:17.416628', NULL),
(3, 3, 'EMP003', 'Test', 'ADMIN', '1234567890', 4, 2, NULL, '2026-03-16', 'ACTIVE', '2026-03-16 17:00:33.28892', '2026-03-16 17:00:33.28892', NULL),
(5, 5, 'EMP005', 'Test', 'HR', '1234567890', 4, 3, NULL, '2026-03-16', 'ACTIVE', '2026-03-16 17:00:33.28892', '2026-03-16 17:00:33.28892', NULL),
(6, 6, 'EMP006', 'Test', 'TEAM_LEADD', '1234567890', 4, 4, NULL, '2026-03-14', 'ACTIVE', '2026-03-16 17:00:33.28892', '2026-03-16 17:00:33.28892', NULL),
(7, 7, 'EMP007', 'Test11', 'EMPLOYEE', '9876543210', 4, 5, 6, '2026-03-15', 'ACTIVE', '2026-03-16 17:00:33.28892', '2026-03-16 17:00:33.28892', 'data:image/jpeg;base64,/9j/4QBqRXhpZgAATU0AKgAAAAgABAEAAAQAAAABAAABvwEBAAQAAAABAAABv4dpAAQAAAABAAAAPgESAAMAAAABAAAAAAAAAAAAAZIIAAMAAAABAAAAAAAAAAAAAQESAAMAAAABAAAAAAAAAAD/4AAQSkZJRgABAQAAAQABAAD/4gHYSUNDX1BST0ZJTEUAAQEAAAHIAAAAAAQwAABtbnRyUkdCIFhZWiAH4AABAAEAAAAAAABhY3NwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAA9tYAAQAAAADTLQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAlkZXNjAAAA8AAAACRyWFlaAAABFAAAABRnWFlaAAABKAAAABRiWFlaAAABPAAAABR3dHB0AAABUAAAABRyVFJDAAABZAAAAChnVFJDAAABZAAAAChiVFJDAAABZAAAAChjcHJ0AAABjAAAADxtbHVjAAAAAAAAAAEAAAAMZW5VUwAAAAgAAAAcAHMAUgBHAEJYWVogAAAAAAAAb6IAADj1AAADkFhZWiAAAAAAAABimQAAt4UAABjaWFlaIAAAAAAAACSgAAAPhAAAts9YWVogAAAAAAAA9tYAAQAAAADTLXBhcmEAAAAAAAQAAAACZmYAAPKnAAANWQAAE9AAAApbAAAAAAAAAABtbHVjAAAAAAAAAAEAAAAMZW5VUwAAACAAAAAcAEcAbwBvAGcAbABlACAASQBuAGMALgAgADIAMAAxADb/2wBDAAoHBwgHBgoICAgLCgoLDhgQDg0NDh0VFhEYIx8lJCIfIiEmKzcvJik0KSEiMEExNDk7Pj4+JS5ESUM8SDc9Pjv/2wBDAQoLCw4NDhwQEBw7KCIoOzs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozv/wAARCAG/Ab8DASIAAhEBAxEB/8QAHAABAAIDAQEBAAAAAAAAAAAAAAIDAQQFBgcI/8QAQBAAAgEDAwIFAgQDBgQGAwEAAQIAAxEhBBIxBUEGEyJRYTJxFIGRoQcjQhUzUrHB0SRi4fAXQ1NygvEWg5Ki/8QAGwEBAAMBAQEBAAAAAAAAAAAAAAECAwQFBgf/xAAqEQEAAgICAwACAgEDBQAAAAAAAQIDERIhBDFBBRMyUSIUM2EVQlKBsf/aAAwDAQACEQMRAD8A+zREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERARMRARK6lVKSlnYKo7k2E8j1nx5T02+l02l+IcC3mthL/AB7zO+StI3MqWvWvt7KJ8uPj/rT7VAoowJLEpi3tNvS/xG1n4tTqdNT/AA5YBtn1AfFzmYR5eOWcZ6TL6NE43TPE3TOqnZQ1G2rYE0nG1h/v+U64NxzOit629S2i0T6TiYmZdJERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAxK61elQTfVdUHuxtOd1/qydG6VV1ZKl1sEVj9THA/3/KfPj1/qPUNo1VVqrWwQAAPvb/u058ueuPr6xyZYp19ey1ficBag01I4wrtx97Ti6jr/U6pFVdUUUYAQAA/lzOO61dhLVhbF0A5My5NULsJBtYkdpxWzXt9cVst5+sarV1tQxGor1KxBwHcnPvmcyrRJW7naBbCzec2BUj7kzVcepsk4wLzG079s9zPtovTQXGxCCOwz+sqN917C1g1vmbNQjdt9W72FzKvwz+k1GKY+kZb/aZ6EAxDKFYi+SwPE9J0Pxvr+nqlHVH8TpwLLuPrA+/+880VRBf1k2K8iRGwYG/9Zat7UnqVq3tWen1zpfi3pPVGFNK/lVT/AEVBtJ/Pgzugg8T4SHsQVP39zO70fxX1LpTqrVW1NDjy3N7D4PadmPy/lodVPI/8n1qJy+i9d0nW9N52nYhh9dNvqQzqTvraLRuHVExPpmIiWSREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQMSLNtFza0z2nzTxv4zqNq6/RdHZUpsq1atyDuGSv2xM8l4pXcqXtFY21fG3UV6j4ganTqb6enQUxY43csR/lOLRYhB5ZO0fGT/37ShKihi+8292Iv8ApL6dRX+i7fCrn9Z4uW82vt517cp23KVdybVC3l8G8201ClQGNmHsMTmh6pc0vJclBY5GP3llOnqm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'),
(13, 8, 'EMP008', 'Test', 'Lead 2', '9876543210', 3, 4, NULL, '2026-04-12', 'ACTIVE', '2026-04-14 17:07:32.123249', '2026-04-14 17:07:32.123249', NULL),
(14, 9, 'EMP009', 'emp2', 'emp', '9988776655', 3, 5, 13, '2026-04-13', 'ACTIVE', '2026-04-14 17:08:28.144672', '2026-04-14 17:08:28.144672', NULL);
INSERT INTO "public"."leave_requests" ("id", "employee_id", "leave_type", "start_date", "end_date", "reason", "status", "approved_by", "created_at") VALUES
(7, 7, 'Sick Leave', '2026-05-05', '2026-05-07', 'aweshdtfyhl;', 'APPROVED', 5, '2026-05-04 11:44:56.32908'),
(8, 7, 'Annual Leave', '2026-05-13', '2026-05-20', 'erytuyuio;uytrerdtgjhkl;', 'REJECTED', 5, '2026-05-04 16:39:38.675493'),
(9, 7, 'Annual Leave', '2026-05-20', '2026-05-31', 'aesdfjykgfhgj', 'APPROVED', 5, '2026-05-04 16:57:19.464254'),
(10, 7, 'Casual Leave', '2026-05-15', '2026-05-19', 'qwwertyuiop[asdfghjkl;zxcvbnm,', 'APPROVED', 3, '2026-05-04 17:05:40.89482'),
(11, 7, 'Sick Leave', '2026-05-07', '2026-05-08', 'wASZdfghj', 'APPROVED', 5, '2026-05-07 11:03:46.858592'),
(12, 7, 'Annual Leave', '2026-05-19', '2026-05-31', 'asdfjklasdfghjklsdfgh,.', 'APPROVED', 5, '2026-05-07 11:40:46.057105'),
(13, 7, 'Casual Leave', '2026-05-19', '2026-05-30', 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff', 'APPROVED', 5, '2026-05-07 11:51:59.02572'),
(14, 7, 'Annual Leave', '2026-05-14', '2026-05-29', 'asdfghjesdrfghbn', 'APPROVED', 5, '2026-05-07 12:12:28.265953'),
(15, 7, 'Sick Leave', '2026-05-11', '2026-05-12', 'azxcvbnmmhgfd', 'APPROVED', 5, '2026-05-07 12:18:43.129523'),
(16, 7, 'Casual Leave', '2026-05-27', '2026-05-30', 'ddddddddddddddddddddddddddddddddddddddddd', 'APPROVED', 5, '2026-05-07 12:20:44.809309'),
(17, 7, 'Casual Leave', '2026-05-26', '2026-05-30', 'ddddddddddddddddddddddddddd', 'APPROVED', 5, '2026-05-07 12:31:54.465981'),
(18, 7, 'Sick Leave', '2026-05-08', '2026-05-09', 'ddadadadadadada', 'REJECTED', 5, '2026-05-07 14:53:22.14519'),
(19, 7, 'Sick Leave', '2026-05-20', '2026-05-21', 'hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh', 'REJECTED', 5, '2026-05-07 14:54:05.060921');
INSERT INTO "public"."tasks" ("id", "title", "description", "assigned_by", "assigned_to", "priority", "status", "deadline", "created_at", "updated_at", "department_id", "task_type", "start_time", "meeting_link", "github_url") VALUES
(1, 'MEeting', 'Terms and condition at 5:30pm', NULL, NULL, 'MEDIUM', 'PENDING', '2026-04-11 00:00:00', '2026-04-09 10:52:02.513771', '2026-04-09 10:52:02.513771', 4, 'TASK', NULL, NULL, NULL),
(2, 'Pay Check', 'fyfygfuiegoirsg', NULL, 3, 'MEDIUM', 'PENDING', '2026-04-14 14:56:03.376818', '2026-04-14 15:00:34.499608', '2026-04-14 15:00:34.499608', NULL, 'MEETING', '17:30:00', 'earstdfyguhk', NULL),
(3, 'daefsrgdtfygu', 'fsgdxhcfg', NULL, 7, 'MEDIUM', 'PENDING', '2026-04-14 15:15:42.703649', '2026-04-14 15:17:00.681942', '2026-04-14 15:17:00.681942', NULL, 'TASK', NULL, NULL, NULL),
(4, 'fdsgdfh', 'frghdtyju', NULL, 5, 'MEDIUM', 'IN_PROGRESS', '2026-04-14 15:15:42.703649', '2026-04-14 15:17:36.238952', '2026-04-14 15:17:36.238952', NULL, 'TASK', NULL, NULL, NULL),
(5, 'wfegrdgfhj', 'erdhtfhgj', 6, 7, 'MEDIUM', 'IN_PROGRESS', '2026-04-14 16:34:54.653042', '2026-04-14 16:35:10.355544', '2026-04-14 16:35:10.355544', NULL, 'TASK', NULL, NULL, NULL),
(6, 'esrdtghf', 'esrgdf', 6, 7, 'MEDIUM', 'COMPLETED', '2026-04-15 16:14:59.673078', '2026-04-15 16:15:17.718731', '2026-04-15 16:15:17.718731', NULL, 'TASK', NULL, NULL, NULL),
(7, 'ddddddddd', 'asdfghjkl', 6, 7, 'MEDIUM', 'PENDING', '2026-04-16 00:00:00', '2026-04-15 16:24:29.263847', '2026-04-15 16:24:29.263847', NULL, 'TASK', '16:23:00', NULL, NULL),
(8, 'rwetdryyghj', 'sdrhfygjkjl', 6, 7, 'MEDIUM', 'COMPLETED', '2026-04-15 16:27:33.774178', '2026-04-15 16:27:49.106849', '2026-04-15 16:27:49.106849', NULL, 'TASK', NULL, NULL, NULL),
(9, 'meetng', 'gnbvc', 6, 7, 'MEDIUM', 'COMPLETED', '2026-04-16 11:07:16.63524', '2026-04-16 11:24:55.31438', '2026-04-16 11:24:55.31438', NULL, 'TASK', NULL, NULL, NULL),
(10, 'ha t', 'SMC se', 6, 7, 'MEDIUM', 'COMPLETED', '2026-04-29 12:14:48.359034', '2026-04-29 12:15:11.620891', '2026-04-29 12:15:11.620891', NULL, 'TASK', NULL, NULL, NULL);
INSERT INTO "public"."attendance" ("id", "employee_id", "check_in_time", "check_out_time", "location_lat", "location_long", "attendance_date", "work_hours", "created_at", "is_late", "is_early_checkout", "early_checkout_reason") VALUES
(21, 5, '2026-04-14 11:46:55.435137', '2026-04-14 11:47:05.833846', 37.42199830, -122.08400000, '2026-04-14', 0.00, '2026-04-14 11:46:55.435137', 't', 't', NULL),
(22, 5, '2026-04-14 11:57:52.68095', '2026-04-14 11:58:15.751959', 37.42199830, -122.08400000, '2026-04-14', 0.01, '2026-04-14 11:57:52.68095', 't', 't', NULL),
(23, 6, '2026-04-14 15:41:37.815028', '2026-04-14 15:52:50.374936', 37.42199830, -122.08400000, '2026-04-14', 0.19, '2026-04-14 15:41:37.815028', 't', 't', NULL),
(24, 7, '2026-04-15 10:51:59.910079', '2026-04-15 17:24:24.377932', 37.42199830, -122.08400000, '2026-04-15', 6.54, '2026-04-15 10:51:59.910079', 't', 't', 'aesfgd'),
(25, 7, '2026-04-16 10:39:56.310934', '2026-04-16 10:57:28.935835', 37.42199830, -122.08400000, '2026-04-16', 0.29, '2026-04-16 10:39:56.310934', 't', 't', NULL),
(26, 7, '2026-04-16 10:57:31.065694', '2026-04-16 11:39:08.008905', 37.42199830, -122.08400000, '2026-04-16', 0.69, '2026-04-16 10:57:31.065694', 'f', 't', NULL),
(27, 6, '2026-04-16 11:09:00.730257', '2026-04-16 11:09:04.887316', 37.42199830, -122.08400000, '2026-04-16', 0.00, '2026-04-16 11:09:00.730257', 'f', 't', NULL),
(28, 6, '2026-04-16 11:09:11.085652', '2026-04-16 11:09:13.076575', 37.42199830, -122.08400000, '2026-04-16', 0.00, '2026-04-16 11:09:11.085652', 'f', 't', NULL),
(29, 6, '2026-04-16 11:09:16.193556', '2026-04-16 11:09:22.445348', 37.42199830, -122.08400000, '2026-04-16', 0.00, '2026-04-16 11:09:16.193556', 'f', 't', NULL),
(30, 6, '2026-04-16 11:09:30.931033', '2026-04-16 11:25:14.964728', 37.42199830, -122.08400000, '2026-04-16', 0.26, '2026-04-16 11:09:30.931033', 'f', 't', NULL),
(31, 6, '2026-04-16 11:46:19.207283', '2026-04-16 11:46:26.605328', 37.42199830, -122.08400000, '2026-04-16', 0.00, '2026-04-16 11:46:19.207283', 'f', 't', NULL),
(32, 6, '2026-04-16 13:43:56.640244', NULL, 13.02126170, 77.68718170, '2026-04-16', NULL, '2026-04-16 13:43:56.640244', 'f', 'f', NULL),
(33, 7, '2026-04-16 13:47:31.250203', '2026-04-16 13:47:59.363493', 13.02126170, 77.68718170, '2026-04-16', 0.01, '2026-04-16 13:47:31.250203', 'f', 't', 'Automatic check-out: Outside geofence'),
(34, 7, '2026-04-16 13:49:07.487647', '2026-04-16 13:49:37.205861', 13.02176500, 77.68733170, '2026-04-16', 0.01, '2026-04-16 13:49:07.487647', 'f', 't', 'Automatic check-out: Outside geofence'),
(35, 7, '2026-04-29 12:07:22.855869', '2026-04-29 12:09:49.084135', 13.02128580, 77.68718130, '2026-04-29', 0.04, '2026-04-29 12:07:22.855869', 'f', 't', NULL),
(36, 6, '2026-04-29 12:13:27.68729', '2026-04-29 15:48:45.679237', 13.02127630, 77.68718080, '2026-04-29', 3.59, '2026-04-29 12:13:27.68729', 'f', 't', NULL),
(37, 5, '2026-04-29 12:20:26.046501', '2026-04-29 23:49:42.32161', 13.02128740, 77.68717680, '2026-04-29', 11.49, '2026-04-29 12:20:26.046501', 'f', 'f', 'Automatic check-out: Outside geofence'),
(38, 7, '2026-04-29 12:38:59.050712', '2026-04-29 13:06:39.2102', 13.02128210, 77.68717960, '2026-04-29', 0.46, '2026-04-29 12:38:59.050712', 'f', 't', NULL),
(39, 7, '2026-04-29 13:06:58.941081', '2026-04-29 13:52:28.827464', 13.02129180, 77.68717210, '2026-04-29', 0.76, '2026-04-29 13:06:58.941081', 'f', 't', NULL),
(40, 7, '2026-04-29 13:53:15.116735', '2026-04-29 13:53:18.59897', 13.02128820, 77.68714930, '2026-04-29', 0.00, '2026-04-29 13:53:15.116735', 'f', 't', NULL),
(41, 7, '2026-04-29 14:03:07.199268', '2026-04-29 14:03:10.632658', 13.02129070, 77.68715070, '2026-04-29', 0.00, '2026-04-29 14:03:07.199268', 'f', 't', NULL),
(42, 7, '2026-04-29 15:38:36.321716', '2026-04-29 15:42:26.02158', 13.02129680, 77.68705860, '2026-04-29', 0.06, '2026-04-29 15:38:36.321716', 'f', 't', 'Automatic check-out: Outside geofence'),
(43, 7, '2026-04-29 15:42:41.97496', '2026-04-29 23:39:58.925889', 13.02129676, 77.68717200, '2026-04-29', 7.95, '2026-04-29 15:42:41.97496', 'f', 'f', 'Automatic check-out: Outside geofence'),
(44, 6, '2026-04-29 16:04:33.104121', '2026-04-29 16:04:35.512142', 13.02129676, 77.68717200, '2026-04-29', 0.00, '2026-04-29 16:04:33.104121', 'f', 't', NULL),
(45, 6, '2026-04-29 16:04:46.133269', '2026-04-29 16:04:54.18436', 13.02129676, 77.68717200, '2026-04-29', 0.00, '2026-04-29 16:04:46.133269', 'f', 't', NULL),
(46, 6, '2026-04-29 16:10:51.574838', '2026-04-29 16:10:55.504264', 13.02129676, 77.68717200, '2026-04-29', 0.00, '2026-04-29 16:10:51.574838', 'f', 't', NULL),
(47, 6, '2026-04-29 16:16:13.607703', '2026-04-29 16:16:20.506591', 13.02129676, 77.68717200, '2026-04-29', 0.00, '2026-04-29 16:16:13.607703', 'f', 't', NULL),
(48, 6, '2026-04-29 16:16:24.103567', '2026-04-29 16:16:35.941537', 13.02129676, 77.68717200, '2026-04-29', 0.00, '2026-04-29 16:16:24.103567', 'f', 't', NULL),
(49, 6, '2026-04-29 16:16:44.605379', '2026-04-29 16:16:56.24745', 13.02129676, 77.68717200, '2026-04-29', 0.00, '2026-04-29 16:16:44.605379', 'f', 't', NULL),
(50, 6, '2026-04-29 16:50:41.600039', '2026-04-29 23:30:44.939284', 13.02129676, 77.68717200, '2026-04-29', 6.67, '2026-04-29 16:50:41.600039', 'f', 'f', 'Automatic check-out: Outside geofence'),
(51, 7, '2026-05-04 11:44:24.932479', '2026-05-04 17:03:13.429505', 13.02126170, 77.68718170, '2026-05-04', 5.31, '2026-05-04 11:44:24.932479', 'f', 't', NULL),
(52, 6, '2026-05-04 14:16:15.738506', '2026-05-04 14:16:33.074304', 13.02126170, 77.68718170, '2026-05-04', 0.00, '2026-05-04 14:16:15.738506', 'f', 't', NULL),
(53, 6, '2026-05-04 14:16:53.428999', '2026-05-04 14:23:28.871529', 13.02126170, 77.68718170, '2026-05-04', 0.11, '2026-05-04 14:16:53.428999', 'f', 't', NULL),
(54, 5, '2026-05-04 16:58:10.286483', '2026-05-04 17:03:58.142162', 13.02126170, 77.68718170, '2026-05-04', 0.10, '2026-05-04 16:58:10.286483', 'f', 't', NULL),
(55, 6, '2026-05-04 17:06:09.285063', '2026-05-04 17:15:06.266278', 13.02126170, 77.68718170, '2026-05-04', 0.15, '2026-05-04 17:06:09.285063', 'f', 't', NULL),
(56, 6, '2026-05-06 15:08:48.377934', '2026-05-06 15:08:53.025458', 13.02126170, 77.68718170, '2026-05-06', 0.00, '2026-05-06 15:08:48.377934', 'f', 't', NULL),
(57, 7, '2026-05-07 11:01:34.656283', '2026-05-07 11:02:53.862139', 13.02126170, 77.68718170, '2026-05-07', 0.02, '2026-05-07 11:01:34.656283', 'f', 't', 'Automatic check-out: Outside geofence'),
(58, 7, '2026-05-07 11:03:12.44552', '2026-05-07 12:29:19.531672', 13.02126170, 77.68718170, '2026-05-07', 1.44, '2026-05-07 11:03:12.44552', 'f', 't', 'Automatic check-out: Outside geofence'),
(59, 6, '2026-05-07 14:49:54.455507', '2026-05-07 14:57:44.774424', 13.02126170, 77.68718170, '2026-05-07', 0.13, '2026-05-07 14:49:54.455507', 'f', 't', NULL),
(60, 7, '2026-05-08 12:20:29.486496', '2026-05-08 12:53:29.689834', 13.02126170, 77.68718170, '2026-05-08', 0.55, '2026-05-08 12:20:29.486496', 'f', 't', 'Automatic check-out: Outside geofence'),
(61, 7, '2026-05-08 13:43:43.634038', '2026-05-08 14:07:08.241039', 13.02126170, 77.68718170, '2026-05-08', 0.39, '2026-05-08 13:43:43.634038', 'f', 't', 'Automatic check-out: Outside geofence'),
(62, 7, '2026-05-08 14:08:14.577833', '2026-05-08 14:24:45.032394', 13.02126170, 77.68718170, '2026-05-08', 0.28, '2026-05-08 14:08:14.577833', 'f', 't', 'Automatic check-out: Outside geofence'),
(63, 7, '2026-05-08 14:25:10.343809', '2026-05-08 14:27:47.331843', 13.02126170, 77.68718170, '2026-05-08', 0.04, '2026-05-08 14:25:10.343809', 'f', 't', NULL);

INSERT INTO "public"."departments" ("id", "department_name", "created_at", "description") VALUES
(1, 'UI/UX', '2026-03-16 15:42:50.54422', NULL),
(2, 'Full Stack Developer', '2026-03-16 15:42:50.54422', NULL),
(3, 'App Developer', '2026-03-16 15:42:50.54422', NULL),
(4, 'HR', '2026-03-16 15:42:50.54422', NULL),
(5, 'Operations', '2026-03-16 15:42:50.54422', NULL);
