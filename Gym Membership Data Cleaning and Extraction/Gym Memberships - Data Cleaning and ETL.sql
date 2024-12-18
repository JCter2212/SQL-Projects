Use GYM;

SELECT * FROM gym;

/* 
	Extract-Transform-Load:
	1. Create copy of table to avoid corrupting source data.
	2. Create new tables with the Member ID as the primary key.
		a. Members table: abbrevieated member data. 
		a. Days members visit the gym.
		b. Lessons members attend. 
		c. Drinks consumed by members. 

*/

SELECT * INTO gym_copy;
FROM gym;


--Creating a copy of the primary table.
CREATE PROCEDURE see_copy AS
BEGIN
	SELECT * FROM gym_copy
END;

--Create table for Member data. 
CREATE TABLE MemberData (
ID SMALLINT PRIMARY KEY NOT NULL,
gender VARCHAR(50) NOT NULL,
birthday DATE NOT NULL,
age TINYINT NOT NULL,
age_bin VARCHAR(50) NOT NULL,
subscription_type VARCHAR(50) NOT NULL,
visits_per_week TINYINT,
attend_group_lesson BIT,
avg_time_check_in VARCHAR(8),
avg_in_bin INT,
avg_time_check_out VARCHAR(8),
avg_out_bin INT,
avg_workout_time INT,
drink_subscription BIT,
personal_training BIT,
trainer VARCHAR(50),
uses_sauna BIT
);


INSERT INTO MemberData
(
ID, gender, birthday, age, 
age_bin, 
subscription_type, visits_per_week, attend_group_lesson, 
avg_time_check_in, 
avg_in_bin, 
avg_time_check_out, 
avg_out_bin, 
avg_workout_time, drink_subscription, personal_training, trainer, uses_sauna
)
SELECT
--genderal columns
id, gender, birthday, Age, 
CASE
	WHEN age <= 18 THEN '12 to 18' 
	WHEN age BETWEEN 19 AND 29 THEN '19 to 29'
	WHEN age BETWEEN 30 AND 39 THEN '30 to 39'
	WHEN age BETWEEN 40 AND 49 THEN '40 to 49'
	ELSE '50 and over'
END,
abonoment_type, visit_per_week, attend_group_lesson, 

--avg_time_check_in			formatting time in as string for end user
RIGHT('0' + CAST(DATEPART(HOUR, avg_time_check_in) AS VARCHAR(2)), 2) + ':' +
RIGHT('0' + CAST(DATEPART(MINUTE, avg_time_check_in) AS VARCHAR(2)), 2),

--avg_in_bin
CASE
	WHEN (DATEPART(HOUR,avg_time_check_in) +
		CASE
		WHEN DATEPART(MINUTE,avg_time_check_in) >= 30 THEN 1
		ELSE 0
	END + 1) % 24 = 0 THEN 24

	ELSE (DATEPART(HOUR, avg_time_check_in) + 
	CASE
		WHEN DATEPART(MINUTE, avg_time_check_in) >= 30 THEN 1
		ELSE 0
	END + 1) % 24
END,
		
--avg_time_check_out
RIGHT('0' + CAST(DATEPART(HOUR, avg_time_check_out) AS VARCHAR(2)),2) + ':' +
RIGHT('0' + CAST(DATEPART(MINUTE, avg_time_check_out) AS VARCHAR(2)),2),

--avg_out_bin
CASE
	WHEN (DATEPART(HOUR,avg_time_check_out) +
		CASE
			WHEN DATEPART(MINUTE,avg_time_check_out) >= 30 THEN 1
			ELSE 0
		END + 1) % 24 = 0 THEN 24

	ELSE (DATEPART(HOUR,avg_time_check_out) +
		CASE
			WHEN DATEPART(MINUTE,avg_time_check_out) >= 30 THEN 1
			ELSE 0
		END + 1) % 24
END,

avg_time_in_gym, drink_abo, personal_training, name_personal_trainer, uses_sauna
FROM gym_copy;


--Days dimension table created to monitor foot traffic. 
CREATE TABLE dim_Days
(
ID SMALLINT PRIMARY KEY,
Visits TINYINT,
Mon BIT,
Tue BIT,
Wed BIT,
Thu BIT,
Fri BIT,
Sat BIT,
Sun BIT,
);

INSERT INTO dim_Days
(
ID, Visits, Mon, Tue, Wed, Thu, Fri, Sat, Sun
)
SELECT
id, visit_per_week, 

CASE WHEN CHARINDEX('Mon',days_per_week) > 0 THEN 1 ELSE 0 END AS Mon,

CASE WHEN CHARINDEX('Tue',days_per_week) > 0 THEN 1 ELSE 0 END AS Tue,

CASE WHEN CHARINDEX('Wed',days_per_week) > 0 THEN 1 ELSE 0 END AS Wed,

CASE WHEN CHARINDEX('Thu',days_per_week) > 0 THEN 1 ELSE 0 END AS Thu,

CASE WHEN CHARINDEX('Fri',days_per_week) > 0 THEN 1 ELSE 0 END AS Fri,

CASE WHEN CHARINDEX('Sat',days_per_week) > 0 THEN 1 ELSE 0 END AS Sat,

CASE WHEN CHARINDEX('Sun',days_per_week) > 0 THEN 1 ELSE 0 END AS Sun

FROM gym_copy;

--Dimension table for lessons taken by members.
CREATE TABLE dim_Lessons
(
ID INT PRIMARY KEY,
BodyBalance BIT,
BodyPump BIT,
HIT BIT,
Kickboxen BIT,
LesMiles BIT,
Pilates BIT,
Running BIT,
Spinning BIT,
XCore BIT,
Yoga BIT,
Zumba BIT
);

INSERT INTO dim_Lessons
(
ID, BodyBalance, BodyPump, HIT, Kickboxen, LesMiles, Pilates, Running, Spinning, XCore, Yoga, Zumba
)
SELECT
id,
CASE WHEN CHARINDEX('BodyBalance',fav_group_lesson) > 0 THEN 1 ELSE 0 END AS BodyBalance,

CASE WHEN CHARINDEX('BodyPump',fav_group_lesson) > 0 THEN 1 ELSE 0 END AS BodyPump,

CASE WHEN CHARINDEX('HIT',fav_group_lesson) > 0 THEN 1 ELSE 0 END AS HIT,

CASE WHEN CHARINDEX('Kickboxen',fav_group_lesson) > 0 THEN 1 ELSE 0 END AS Kickboxen,

CASE WHEN CHARINDEX('LesMiles',fav_group_lesson) > 0 THEN 1 ELSE 0 END AS LesMiles,

CASE WHEN CHARINDEX('Pilates',fav_group_lesson) > 0 THEN 1 ELSE 0 END AS Pilates,

CASE WHEN CHARINDEX('Running',fav_group_lesson) > 0 THEN 1 ELSE 0 END AS Running,

CASE WHEN CHARINDEX('Spinning',fav_group_lesson) > 0 THEN 1 ELSE 0 END AS Spinning,

CASE WHEN CHARINDEX('XCore',fav_group_lesson) > 0 THEN 1 ELSE 0 END AS XCore,

CASE WHEN CHARINDEX('Yoga',fav_group_lesson) > 0 THEN 1 ELSE 0 END AS Yoga,

CASE WHEN CHARINDEX('Zumba',fav_group_lesson) > 0 THEN 1 ELSE 0 END AS Zumba
FROM gym_copy;

--Dimension table for drinks consumed by members.
CREATE TABLE dim_Drinks
(
ID INT PRIMARY KEY,
fav_drink VARCHAR(255),
BerryBoost BIT,
BlackCurrant BIT,
CoconutPineapple BIT,
Lemon BIT,
Orange BIT,
PassionFruit BIT
);

INSERT INTO dim_Drinks
(
ID, fav_drink, BerryBoost, BlackCurrant, CoconutPineapple, Lemon, Orange, PassionFruit
)
SELECT 
id as ID,
fav_drink AS fav_drink,
CASE WHEN CHARINDEX('berry_boost',fav_drink) > 0 THEN 1 ELSE 0 END AS BerryBoost,
CASE WHEN CHARINDEX('black_currant',fav_drink) > 0 THEN 1 ELSE 0 END AS BlackCurrant,
CASE WHEN CHARINDEX('coconut_pineapple',fav_drink) > 0 THEN 1 ELSE 0 END AS CoconutPineapple,
CASE WHEN CHARINDEX('lemon',fav_drink) > 0 THEN 1 ELSE 0 END AS Lemon,
CASE WHEN CHARINDEX('orange',fav_drink) > 0 THEN 1 ELSE 0 END AS Orange,
CASE WHEN CHARINDEX('passion_fruit',fav_drink) > 0 THEN 1 ELSE 0 END AS PassionFruit
FROM gym_copy;



