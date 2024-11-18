/* 
SQL Project: Data Cleaning and ETL
	Data Cleaning:
	1. Copy table to prevent corruption of source data. 
	2. Check for duplicate entries
	3. Standardize Data
	4. Handle nulls/blanks
	5. Remove extraneous rows/columns
*/

--1. Copy table to prevent corruption of source data
SELECT * INTO gym_staging
FROM gym;

--create procedure to call full table throughout process
CREATE PROCEDURE view_gym_dup
AS
BEGIN
SELECT * FROM gym_staging
END;

EXEC view_gym_dup;

/* 
2. Check for duplicate entries
	--Because the table only provides an id associated with the entry, we must assume no lines are duplicate even if additional data fields are identical.  
 */

 /* 
3. Standardize data
	--check through each column to see if there are discrepancies in values by using DISTINCT
*/

EXEC view_gym_dup;

--abonoment_type
SELECT DISTINCT abonoment_type FROM gym_staging;

--changing abonement_type column name to Membership type
EXEC sp_rename 'gym_staging.abonoment_type','membership_type';

--selecting distinct values in columns revealed no issues with standardization. 
--Creating a new column for time format in the avg check in and avg check out columns--Time(7) shows extra digits after the decimal point that are unnecessary. 
--check in
ALTER TABLE gym_staging
ADD TempTimeIn TIME(0);

UPDATE gym_staging
SET TempTimeIn = CONVERT(TIME(0), avg_time_check_in);

ALTER TABLE gym_staging
DROP COLUMN avg_time_check_in;

EXEC sp_rename 'gym_staging.TempTimeIn','avg_check_in_time';

--Check out time
ALTER TABLE gym_staging
ADD TempTimeOut TIME(0);

UPDATE gym_staging
SET TempTimeOut = CONVERT(TIME(0), avg_time_check_out);

ALTER TABLE gym_staging
DROP COLUMN avg_time_check_out;

EXEC sp_rename 'gym_staging.TempTimeOut','avg_check_out_time'

EXEC view_gym_dup;

/* 
4. Handle nulls/blanks
	All nulls and blanks are appropriate for this table. 
*/
/* 
5. Remove extraneous rows/columns
	All data can be used for reporting statistics in the gym. Howver, there is a column that could be exceedinlgy useful prior to using this table for any kind of data analysis--an age bins column. 
*/

--Create column for age bins
ALTER TABLE gym_staging
ADD age_bins NVARCHAR(50);

UPDATE gym_staging
SET age_bins = CASE
				WHEN Age BETWEEN 0 AND 18 THEN '18 And Under'
				WHEN Age BETWEEN 19 AND 29 THEN '19-29'
				WHEN Age BETWEEN 30 AND 39 THEN '30-39'
				WHEN Age BETWEEN 40 AND 49 THEN '40-49'
				END;



--Because the age bins, and time in/time out columns should be in a different location, a new table can be created to re-order the columns. 
CREATE TABLE GymDataTemp 
(id INT PRIMARY KEY,
gender VARCHAR(10),
birthday DATE,
Age INT,
age_bin VARCHAR(50),
membership_type VARCHAR(50) NOT NULL,
visit_per_week SMALLINT,
days_per_week VARCHAR(50),
attend_group_lesson BIT NOT NULL,
fav_group_lesson VARCHAR(50),
avg_check_in_time TIME(0),
avg_check_out_time TIME(0),
avg_time_in_gym TINYINT,
drink_membership BIT NOT NULL,
fav_drink VARCHAR(50),
personal_training BIT NOT NULL,
trainer_assigned VARCHAR(50),
uses_sauna BIT NOT NULL,
);
--file the table with data
INSERT INTO GymDataTemp (id, gender, birthday, Age, age_bin, membership_type, visit_per_week, days_per_week, attend_group_lesson, fav_group_lesson, avg_check_in_time, avg_check_out_time, avg_time_in_gym, drink_membership, fav_drink, personal_training, trainer_assigned, uses_sauna)
SELECT id, gender, birthday, Age, age_bins, membership_type, visit_per_week, days_per_week, attend_group_lesson, fav_group_lesson, avg_check_in_time, avg_check_out_time, avg_time_in_gym, drink_abo, fav_drink, personal_training, name_personal_trainer, uses_sauna
FROM gym_staging;

--remove the old table
DROP TABLE gym_staging;

--rename the intermediary table
EXEC sp_rename 'GymDataTemp','gym_clean';

SELECT * FROM gym_clean;