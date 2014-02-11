CREATE DATABASE TASKAPP;
USE TASKAPP;
CREATE TABLE tasks(id int primary key not null auto_increment, description char(50), creation_date date, plan_date date, first_plan_date date, priority int, finished bool, type char(50), user_id int );
CREATE TABLE users(id int primary key not null auto_increment, name char(50), last_name char(50), email char(50), password char(50), question char(50), answer char(100), role char(30));

ALTER TABLE tasks ADD CONSTRAINT FK_User FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;