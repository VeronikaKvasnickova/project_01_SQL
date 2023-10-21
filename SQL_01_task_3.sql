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


-- TASK THREE 

-- A)
-- creates a view with only selected collumns and only for groceries
CREATE OR REPLACE VIEW v_veronika_kvasnickova_groceries AS
SELECT DISTINCT  -- so AS TO SHOW ONLY one average price per grocery per YEAR, from the PRIMARY table
	year, 
	groceries_code, 
	groceries_name, 
	avg_groceries_price
FROM t_veronika_kvasnickova_project_SQL_primary_final
WHERE groceries_code IS NOT NULL; 


-- B
-- creates a table with two collumns of average groceries price and counts the % price change
CREATE OR REPLACE VIEW v_veronika_kvasnickova_groceries_dif AS
SELECT 
	groc1.groceries_name, 
	ROUND(AVG((groc2.avg_groceries_price - groc1.avg_groceries_price)/ groc1.avg_groceries_price * 100),2)  AS 'price_change'-- creates NEW collumn WITH price CHANGE
FROM v_veronika_kvasnickova_groceries AS groc1
LEFT JOIN v_veronika_kvasnickova_groceries AS groc2
	ON groc1.year + 1  = groc2.year -- the +1 adds a YEAR
	AND groc1.groceries_code = groc2.groceries_code  
WHERE groc2.year IS NOT NULL -- so AS NOT TO see YEAR 2018 which has NO CORRESPONDING (2019) YEAR IN the PRIMARY TABLE
GROUP BY groceries_name	
ORDER BY price_change
LIMIT 5; -- pouze pro vybrání 5 nejnižších hodnot, lze vypustit a zjistí se všechny hodnoty

SELECT *
FROM v_veronika_kvasnickova_groceries_dif;
-- end of TASK THREE