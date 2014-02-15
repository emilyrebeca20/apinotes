CREATE DATABASE TASKAPP;
USE TASKAPP;
CREATE TABLE tasks(id int primary key not null auto_increment, description varchar(500), creation_date datetime, plan_date datetime, first_plan_datetime datetime, priority int, finished bool, ntype varchar(100), user_id int );
CREATE TABLE users(id int primary key not null auto_increment, name varchar(50), last_name varchar(50), email varchar(50), password varchar(50), question varchar(100), answer varchar(100), role varchar(30));

ALTER TABLE tasks ADD CONSTRAINT FK_User FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;