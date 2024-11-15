/* This project will do some explarotary analysis on data that has already been collected
General Questions:

	a. By total employees, what were the top 5 companies with reported layoffs? 
		i. How much money was raised by those companies in each instance?
		ii. How many rounds of layoffs were there for each company?

	b. By total employees, what month/year had the highest reported layoffs ?
		i. Create a new table showing:
			a. company
			b. total employees laid off by each company in that month
			c. total layoffs reported in the month.
			d. each companies percent of the total layoffs for the month. 
			e. how much money each company raised with the layoffs
			f. what percentage of the total funds raised in that month were.

	c. By total employees, what industry had the highest reported layoffs?
		i. Create a new table showing:
			a. industry
			b. company with highest total layoffs 
			c. total employees laid off by the company
			d. location of company
			e. country
*/
--Bit of housekeeping, adding a stored procedure to ensure we can always call the base table. 
CREATE PROCEDURE view_layoffs
AS
BEGIN
	SELECT * FROM layoffs_staging;
END;



/*	a. By total employees, what were the top 5 companies with reported layoffs? 
		i. How much money was raised by those companies in each instance?
		ii. How many rounds of layoffs were there for each company?
*/
--top 5 companies by total laid off
SELECT TOP 5 company, SUM(total_laid_off) AS ttl_laid_off FROM layoffs_staging
GROUP BY company
ORDER BY ttl_laid_off DESC;

--i. how much money was raised by those companies in each instance?
SELECT TOP 5 company, 
SUM(total_laid_off) as ttl_laid_off, 
FORMAT(SUM(funds_raised_millions),'C0','en-US') AS total_funds_raised_millions
FROM layoffs_staging
GROUP BY company
ORDER BY ttl_laid_off DESC;

--To find just the total funds raised:
WITH funds_cte AS
(
SELECT TOP 5 company, SUM(total_laid_off) as ttl_laid_off, SUM(funds_raised_millions) AS total_funds_raised_millions
FROM layoffs_staging
GROUP BY company
ORDER BY ttl_laid_off DESC
)
SELECT FORMAT(SUM(total_funds_raised_millions),'C0','en-US') AS ttl_funds_millions FROM funds_cte;

--to include counts of layoffs:
With TotalLayoffs_cte AS
(
SELECT TOP 5 company, COUNT(company) AS layoff_roundsRaw, 
SUM(total_laid_off) AS ttl_laid_offRaw, 
SUM(funds_raised_millions) AS ttl_funds_millionsRaw
FROM layoffs_staging
GROUP BY company
ORDER BY SUM(total_laid_off) DESC
)
SELECT 
	company,
	layoff_roundsRaw,
	FORMAT(ttl_laid_offRaw,'N0') AS ttl_laid_off,
	FORMAT(ttl_funds_millionsRaw,'C0','en-US') AS ttl_funds_millions
FROM TotalLayoffs_cte
ORDER BY ttl_laid_offRaw DESC;

/* 	b. By total employees, what month/year had the highest reported layoffs 
		i. Create a new table showing:
			a. company
			b. total employees laid off by each company in that month
			c. total layoffs reported in the month.
			d. each companies percent of the total layoffs for the month. 
			e. how much money each company raised with the layoffs
			f. what percentage of the total funds raised in that month were.

*/

--B. By total Employees, what month/year had the highest reported layoffs? 
-- Find the month with the highest total layoffs
-- The results can be located in the Highest Month tab of the layoffs_Analysis Results csv document.
SELECT TOP 1 
    YEAR(date) AS Yr,
    MONTH(date) AS Mnth,
    SUM(total_laid_off) AS TtlLayoffs
FROM 
    layoffs_staging
WHERE 
    date IS NOT NULL
GROUP BY 
    YEAR(date), MONTH(date)
ORDER BY 
    TtlLayoffs DESC;

-- Data Table: Breakout of Layoffs in the Highest Total Month
WITH MaxLayoffMonth AS
(
    SELECT TOP 1 
        YEAR(date) AS Yr, 
        MONTH(date) AS Mnth, 
        SUM(total_laid_off) AS MonthsLayoffs
    FROM 
        layoffs_staging
    WHERE 
        total_laid_off IS NOT NULL 
        AND total_laid_off <> ''
    GROUP BY 
        YEAR(date), MONTH(date)
    ORDER BY 
        MonthsLayoffs DESC
),
Stages_CTE AS
(
    SELECT 
        YEAR(date) AS Year, 
        DATENAME(MONTH,DATEFROMPARTS(YEAR(date), MONTH(date),1)) AS Month, 
        company, 
        SUM(total_laid_off) AS CompanyLayoffsRaw,
        SUM(SUM(total_laid_off)) OVER(PARTITION BY YEAR(date), MONTH(date)) AS TotalLayoffsRaw,
        SUM(funds_raised_millions) AS CompanyFundsRaisedRaw,
        SUM(SUM(funds_raised_millions)) OVER(PARTITION BY YEAR(date), MONTH(date)) AS TotalFundsRaisedRaw
    FROM 
        layoffs_staging
    WHERE 
        total_laid_off IS NOT NULL
        AND total_laid_off <> ''
        AND YEAR(date) = (SELECT Yr FROM MaxLayoffMonth)
        AND MONTH(date) = (SELECT Mnth FROM MaxLayoffMonth)
    GROUP BY 
        YEAR(date), MONTH(date), company
)
SELECT
    Year,
    Month,
    company,
    FORMAT(CAST(CompanyLayoffsRaw AS INT), 'N0') AS CompanyLayoffs,
    FORMAT(CAST(TotalLayoffsRaw AS INT), 'N0') AS TotalLayoffs,
    FORMAT(CAST(CompanyLayoffsRaw AS FLOAT) / TotalLayoffsRaw * 100, 'N4') + '%' AS PrcntLaidOff,
    FORMAT(CAST(CompanyFundsRaisedRaw AS MONEY), 'C0', 'en-US') AS CompanyFundsRaised_millions,
    FORMAT(CAST(TotalFundsRaisedRaw AS MONEY), 'C0', 'en-US') AS TotalFundsRaised_millions,
    FORMAT(CAST(CompanyFundsRaisedRaw AS FLOAT) / TotalFundsRaisedRaw * 100, 'N4') + '%' AS PrcntFundsRaised
FROM 
    Stages_CTE
ORDER BY 
    CompanyLayoffsRaw DESC;

/* 	c. By total employees, what industry had the highest reported layoffs?
		i. Create a new table showing:
			a. industry
			b. company with highest total layoffs 
			c. total employees laid off by the company
			d. location of company
			e. country

*/

--c. By total employees, what industry had the highest reported layoffs?
WITH figures_cte AS
(
SELECT industry, SUM(total_laid_off) AS ttl_laid_offRaw
FROM layoffs_staging
WHERE total_laid_off IS NOT NULL AND total_laid_off <> ''
GROUP BY industry
)
SELECT	industry,
		FORMAT(ttl_laid_offRaw,'N0') AS ttl_laid_off
FROM figures_cte
ORDER BY ttl_laid_offRaw DESC;

/*	i. Return results showing:
			a. industry
			b. company with highest total layoffs 
			c. location of company
			d. country
			e. total employees laid off by the company
			f. total employees laid off in the industry
*/


WITH CompLayoffs_cte AS
(
SELECT
	industry, company, location, country, SUM(total_laid_off) AS CompanyLayoffs
FROM layoffs_staging
WHERE 
	total_laid_off IS NOT NULL 
	AND total_laid_off <>''
GROUP BY industry, company, location, country
),
MaxLayoffs_cte AS
(
SELECT
	industry, MAX(CompanyLayoffs) AS MaxLayoffs
FROM CompLayoffs_cte
GROUP BY industry
),
IndustryLayoffs_cte AS
(
SELECT 
	industry, SUM(CompanyLayoffs) AS IndustryLayoffs
FROM CompLayoffs_cte
GROUP BY industry
)
SELECT
	cl.industry,
	cl.company,
	cl.location,
	cl.country,
	FORMAT(cl.CompanyLayoffs,'N0') AS Company_Layoffs,
	FORMAT(ind.IndustryLayoffs,'N0') AS Industry_Layoffs

FROM CompLayoffs_cte AS cl
JOIN MaxLayoffs_cte AS ml 
	ON cl.industry = ml.industry
	AND cl.CompanyLayoffs = ml.MaxLayoffs

JOIN IndustryLayoffs_cte AS ind ON
	cl.industry = ind.industry

ORDER BY cl.industry;



