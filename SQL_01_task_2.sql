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



-- TASK TWO

-- A
-- zjištění prvotního a posledního roku, ve kterém je info ke groceries: výsledek 2006 a 2018
SELECT MIN(year), MAX(year)
FROM t_veronika_kvasnickova_project_SQL_primary_final
WHERE groceries_code IS NOT NULL;

-- B
-- vyhledání mléka a chleba. Výsledek: mléko: 114201 a chléb: kód: 111301 
SELECT DISTINCT groceries_name, groceries_code
FROM t_veronika_kvasnickova_project_SQL_primary_final;

-- C
SELECT * -- pro ověření jednotek
FROM czechia_price_category cpc 
WHERE code IN ('114201', '111301');

-- D
-- vyselektování mléko: 114201 a chléb: kód: 111301 a jejich průměrných cen 
CREATE OR REPLACE VIEW v_veronika_kvasnickova_milk_and_bread AS
SELECT year, groceries_name, avg_groceries_price
FROM t_veronika_kvasnickova_project_SQL_primary_final
WHERE year IN ('2006','2018') 
	AND groceries_code IN ('114201','111301')
GROUP BY year, groceries_code;


-- E
-- zjištění průměrné mzdy za všechna odvětví za roky 2006  a 2018
CREATE OR REPLACE VIEW v_veronika_kvasnickova_average_pay_per_whole_industry AS
SELECT year, ROUND(AVG(average_payroll)) AS 'average_payroll_whole_industry' -- průměr za všechna odvětví A až S v daném roce
FROM t_veronika_kvasnickova_project_SQL_primary_final
WHERE year IN ('2006', '2018') 
GROUP BY YEAR;


-- F merges tables 
-- tab. for task II.
SELECT 
	v_mab.year, 
	v_mab.groceries_name, 
	v_mab.avg_groceries_price, 
	v_whole.average_payroll_whole_industry, 
	ROUND(v_whole.average_payroll_whole_industry / v_mab.avg_groceries_price) AS 'kg/l_groceries' -- počet kg chleba nebo l mléka, které lze za průměrnou mzdu koupit
FROM v_veronika_kvasnickova_milk_and_bread  AS v_mab
JOIN v_veronika_kvasnickova_average_pay_per_whole_industry AS v_whole
	ON v_whole.year = v_mab.YEAR;

	
-- END OF TASK TWO		