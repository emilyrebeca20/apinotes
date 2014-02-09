CREATE DATABASE TASKAPP;
USE TASKAPP;
CREATE TABLE tasks(id int primary key not null auto_increment, descripcion char(50), fecha_creacion date, fecha_plan date, fecha_p_plan date, prioridad int, terminada bool, type_id int, user_id int );
CREATE TABLE types(id int primary key not null auto_increment, nombre_tipo char(50) );
CREATE TABLE users(id int primary key not null auto_increment, nombre char(50), apellido char(50), email char(50), contrasena char(50), respuesta_pregunta char(100), rol char(30));

ALTER TABLE tasks ADD CONSTRAINT FK_Type FOREIGN KEY (type_id) REFERENCES types(id) ON DELETE CASCADE;
ALTER TABLE tasks ADD CONSTRAINT FK_User FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;