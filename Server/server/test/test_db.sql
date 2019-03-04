CREATE DATABASE IF NOT EXISTS db_my_test;
USE db_my_test;

DROP TABLE IF EXISTS t_blob;
CREATE TABLE IF NOT EXISTS  t_blob
( 
	user_name varchar(33) NOT NULL, 
	user_data MEDIUMBLOB NOT NULL, 
	PRIMARY KEY (user_name) 
) ;

DROP TABLE IF EXISTS t_string;
CREATE TABLE IF NOT EXISTS t_string
(
	user_name int NOT NULL,
	user_data varchar(33) NOT NULL,
	PRIMARY KEY (user_name) 
);

