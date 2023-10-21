-- PRIMARY table
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
	AND cp.industry_branch_code IS NOT NULL -- because ONLY ALL the named branches ARE needed, NOT the ones that ARE unnamed
GROUP BY 
	price.category_code, 
	cp.industry_branch_code, 
	cp.payroll_year
ORDER BY 
	cp.payroll_year, 
	cp.industry_branch_code;


SELECT *
FROM t_veronika_kvasnickova_project_SQL_primary_final;


-- TASK ONE 
-- A)
-- creates a view with only selected collumns and only for industry branches	
CREATE OR REPLACE VIEW v_veronika_kvasnickova_industry AS
SELECT DISTINCT -- so AS TO SHOW ONLY one average_payroll per industry per YEAR, because OF groceries IN the PRIMARY table
	year, 
	industry_code, 
	industry_branch, 
	average_payroll
FROM t_veronika_kvasnickova_project_SQL_primary_final;

-- B)
-- creates a table with two collumns of average payroll
CREATE OR REPLACE VIEW v_veronika_kvasnickova_payroll_dif AS
SELECT 
	ind1.year, 
	ind1.industry_code,
	ind1.industry_branch, 
	ind1.average_payroll,	
	ind2.year AS 'year2',
	ind2.industry_code AS 'industry_code2',
	ind2.average_payroll AS 'average_payroll2', 
	ind2.average_payroll - ind1.average_payroll AS 'difference_in_payroll' -- creates NEW collumn WITH difference
FROM v_veronika_kvasnickova_industry AS ind1
LEFT JOIN v_veronika_kvasnickova_industry AS ind2
	ON ind1.year + 1  = ind2.year 
	AND ind1.industry_code = ind2.industry_code  
WHERE ind2.year IS NOT NULL -- so AS NOT TO see YEAR 2021 which has NO CORRESPONDING (2022) YEAR IN the PRIMARY TABLE
	 AND ind2.average_payroll - ind1.average_payroll  <0; -- shows ONLY negative numbers = decrease IN payroll

-- C)
-- creates a final table for TASK 1
SELECT 
	industry_code,  
	industry_branch, 
	count(industry_code) AS 'number_of_decreases_in_payroll' -- how many years that the payroll decreases
FROM v_veronika_kvasnickova_payroll_dif
GROUP BY industry_code
ORDER BY number_of_decreases_in_payroll DESC;
-- end of TASK ONE