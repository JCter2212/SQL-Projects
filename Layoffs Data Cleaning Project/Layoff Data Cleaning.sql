

/* 
Steps:
1. Create duplicate table to preserve the original data. 
2. Check for and remove duplicates. 
3. Standardize data: trim, spellings, ambiguous data, data types, etc. 
4. Handle Nulls / Blanks
5. Deal with extraneous rows and columns
*/ 
--create duplicate table
SELECT * INTO layoffs_staging
FROM layoffs;

--take a quick peek at the data
SELECT * FROM layoffs_staging;

--going to use this a lot, so I'm creating a stored procedure
CREATE PROCEDURE view_table
AS
BEGIN
	SELECT * FROM layoffs_staging
END;

/* 2. Remove dupulicates. Compare across all columns for duplicat entries, and assign a row number. 
Delete row numbers greater than 1. 
Using SQL server, this can be done with a CTE.  
first check to make sure it's working correctly, then execute the delete command. 
*/

WITH duplicate_cte
AS
(
SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions ORDER BY company) as row_num
FROM layoffs_staging
)
DELETE FROM duplicate_cte WHERE row_num>1;

/* 3. Standardize data. Requires column exploration. 
a. TRIM already performed on all data. 
b. View distinct values in company, location, industry, and country. 
c. standardize data. 
*/


--check locations
SELECT DISTINCT(location) FROM layoffs_staging
ORDER BY location ASC;

--check company names
SELECT DISTINCT(company) FROM layoffs_staging
ORDER BY company ASC;

--location shows two versions of Dusseldorf and Düsseldorf. A replace action will need to be done. 
UPDATE layoffs_staging
SET location = REPLACE(location, 'Dusseldorf','Düsseldorf');

SELECT DISTINCT(industry) FROM layoffs_staging
ORDER BY industry ASC;

--industry has three items for Crypto Currency. Distilling down to Crypto. 
UPDATE layoffs_staging
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

--Check country names
SELECT DISTINCT(country) FROM layoffs_staging
ORDER BY country ASC;

--Two versions of the United States were found, one with a trailing period. 
UPDATE layoffs_staging
SET country = REPLACE(country,'United States.','United States');

EXEC view_table;

/* 4. Handle null and blank values. 
a. total_laid_off, percentage_laid_off, and funds_raised_millions cannot be extrapolated. 
b. entries with total_laid_off and percentage_laid_off as blank or null will be removed at the end. 
c. Checking for nulls in company, location, industry, and country. if we have matching values for 
company and location, we can infer that the industry is the same, and try to assign that value if necessary.
*/


--check for null company
SELECT * FROM layoffs_staging
WHERE company IS NULL OR company = '';

--check for null location
SELECT DISTINCT(location) FROM layoffs_staging
ORDER BY location ASC;

SELECT * FROM layoffs_staging
WHERE industry IS NULL OR industry = ''
ORDER BY company ASC, location ASC;

--Null values found, check for entries we can use to infer industry
SELECT t1.company, t1.location, t1.industry, t2.company, t2.location, t2.industry FROM layoffs_staging AS t1
JOIN layoffs_staging AS t2 ON t1.company = t2.company AND t1.location = t2.location 
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;

--confirmed this has occurred, update table. 
Update t1
SET t1.industry = t2.industry
FROM layoffs_staging t1
JOIN ( 
	SELECT company, location, industry
	FROM layoffs staging
	WHERE industry is NOT NULL 
	) t2
ON t1.company = t2.Company and t1.location = t2.location
WHERE t1.industry IS NULL OR t1.industry = '';

--confirm update worked
SELECT * FROM layoffs_staging
WHERE industry IS NULL OR industry ='';

/* 5. Clean up rows and columns
a. Becuase the data set is small and the current columns are potentially useful, there are no columns to remove. 
b. However, rows missing data for both total laid and percentage laid off can be removed, since the data is of
no value. 
*/

--Delete rows where total laid off and percentage laid off are blank
DELETE
FROM layoffs_staging
WHERE (total_laid_off IS NULL OR total_laid_off = '')
	AND (percentage_laid_off IS NULL OR percentage_laid_off = '');

