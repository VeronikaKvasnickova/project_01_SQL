-- connects two tables and selects only "NULL" region, which corresponds to the whole country, just to get an idea
SELECT *
FROM czechia_price price
JOIN czechia_price_category category 
	ON price.category_code =  category.code 
WHERE region_code IS NULL -- because only averages per the whole country is needed
	-- AND YEAR(price.date_from) = '2017'  -- this is just for getting an idea, what all the the dates are in the table within a year
ORDER BY price.value; 
	
SELECT *
FROM czechia_price_category cpc; 


-- TASK PRIMARY TABLE
-- I.
-- a) kategorie potravin dle jednotlivých let
SELECT 
	price.category_code,  
	AVG(price.value) AS 'avg_price_per_category', 
	YEAR(price.date_from) AS 'price_year'
FROM czechia_price AS price
WHERE price.region_code IS NULL
GROUP BY price.category_code , YEAR(price.date_from);


-- b) tabulka dle jednotlivých odvětví za jednotlivé roky (průměr za čtyři kvartály)
SELECT 
	cp.industry_branch_code,
	cp.payroll_year , 
	AVG(cp.value) AS 'average_pay'
FROM czechia_payroll cp 
WHERE cp.value_type_code  = '5958'
	AND cp.calculation_code = '200'
	AND cp.industry_branch_code IS NOT NULL
GROUP BY cp.industry_branch_code, cp.payroll_year;


-- II. 
-- PRIMARY: merges all needed tables together (tab. a and b) 
CREATE OR REPLACE TABLE t_veronika_kvasnickova_project_SQL_primary_final
SELECT
	cp.payroll_year AS 'year', 
	cp.industry_branch_code AS 'industry_code', 
	cpib.name AS 'industry_branch', 	
	ROUND(AVG(cp.value)) AS 'average_payroll', 
	price.category_code AS 'groceries_code', 
	categ.name AS 'groceries_name',
	ROUND(AVG(price.value), 2) AS 'avg_groceries_price' 
FROM czechia_payroll  AS cp
LEFT JOIN czechia_price AS price -- LEFT JOIN so AS TO LEAVE ALL the info FROM FIRST TABLE 
	ON cp.payroll_year = YEAR(price.date_from)
LEFT JOIN czechia_payroll_industry_branch AS cpib 
	ON cpib.code = cp.industry_branch_code
LEFT JOIN czechia_price_category AS categ	
	ON categ.code = price.category_code 	
WHERE price.region_code IS NULL -- because only averages per the whole country is needed
	AND cp.value_type_code = '5958' -- because ONLY wages ARE needed
	AND cp.calculation_code = '200' -- because ONLY "přepočetné" - recalculated(?) wages ARE needed
	AND cp.industry_branch_code IS NOT NULL -- because ONLY ALL the named branches ARE needed, NOT the ones that ARE unnnamed
GROUP BY 
	price.category_code, 
	cp.industry_branch_code, 
	cp.payroll_year
ORDER BY 
	cp.payroll_year, 
	cp.industry_branch_code;


SELECT *
FROM t_veronika_kvasnickova_project_SQL_primary_final;