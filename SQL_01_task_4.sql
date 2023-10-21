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



-- TASK FOUR 
-- A) zjištění průměrné mzdy za všechna odvětví v konkrétním roce
CREATE OR REPLACE VIEW v_veronika_kvasnickova_pay_year AS
SELECT DISTINCT -- so AS TO SHOW ONLY one average_payroll per industry per YEAR, because OF groceries IN the PRIMARY table
	year, 
    ROUND(AVG(average_payroll)) AS 'avg_pay' -- average pay WITHIN whole YEAR (for the whole industry)
FROM t_veronika_kvasnickova_project_SQL_primary_final
GROUP BY YEAR;


-- B
CREATE OR REPLACE VIEW v_veronika_kvasnickova_ind_dif AS
SELECT 
    pay1.year AS 'first_year',
    pay1.avg_pay AS 'first_average_pay',
    pay2.year AS 'second_year',
    pay2.avg_pay AS 'second_average_pay',
	ROUND(((pay2.avg_pay -  pay1.avg_pay) / pay1.avg_pay *100),2) AS 'dif'
FROM v_veronika_kvasnickova_pay_year AS pay1
LEFT JOIN v_veronika_kvasnickova_pay_year AS pay2
	ON pay1.year + 1 = pay2.YEAR
WHERE pay1.year IN ('2006', '2007', '2008', '2009', '2010', '2011', '2012', '2013', '2014', '2015','2016', '2017'); 


SELECT *
FROM v_veronika_kvasnickova_ind_dif


-- C) 
-- groceries - creates a view with only selected collumns and only for groceries
CREATE OR REPLACE VIEW v_veronika_kvasnickova_groceries_t4 AS
SELECT DISTINCT -- so AS TO SHOW ONLY one averagage price per grocery per YEAR, from the PRIMARY table
	year, 
	groceries_code, 
	groceries_name, 
	avg_groceries_price -- meaning WITHIN a YEAR - FROM the PRIMARY table
FROM t_veronika_kvasnickova_project_SQL_primary_final
WHERE groceries_code IS NOT NULL; -- so the VIEW doesn't shoe groceries IN 2000-2005 (which are NULL)
	

-- D)
-- creates a view with average groceries price in two subsequent years and counts the % price change
CREATE OR REPLACE VIEW v_veronika_kvasnickova_groceries_dift4 AS
SELECT 
	groc1t.year, 
	groc1t.groceries_name, 
	groc1t.avg_groceries_price AS 'first_year_price',
	groc2t.year AS 'next_year', 
	groc2t.avg_groceries_price AS 'next_year_price',
	ROUND(AVG((groc2t.avg_groceries_price - groc1t.avg_groceries_price)/ groc1t.avg_groceries_price * 100),2)  AS 'price_change'
FROM v_veronika_kvasnickova_groceries_t4 AS groc1t
LEFT JOIN v_veronika_kvasnickova_groceries_t4 AS groc2t
	ON groc1t.year + 1  = groc2t.year -- the +1 adds a YEAR
	AND groc1t.groceries_code = groc2t.groceries_code  
WHERE groc2t.year IS NOT NULL -- so AS NOT TO see YEAR 2018 which has NO CORRESPONDING (2019) YEAR IN the PRIMARY TABLE
GROUP BY groc1t.year, groceries_name;	

	
-- E)
CREATE OR REPLACE VIEW v_veronika_kvasnickova_groceries_difty AS
SELECT year, next_year, AVG(price_change) AS 'average_change'
FROM v_veronika_kvasnickova_groceries_dift4
GROUP BY YEAR;
	
	
-- F)	
-- connects two main tables:
/*
SELECT *
FROM v_veronika_kvasnickova_groceries_difty;

SELECT *
FROM v_veronika_kvasnickova_ind_dif;

-- just to get an idea: - connects two tables
SELECT 
	indt.first_year AS '1st_year',
	gro.next_year AS '2nd_year',
	indt.first_average_pay,
	indt.second_average_pay,
	indt.dif, 
	gro.average_change 
FROM v_veronika_kvasnickova_ind_dif AS indt
JOIN v_veronika_kvasnickova_groceries_difty AS gro
	ON indt.first_year = gro.year; 
*/
	
CREATE OR REPLACE VIEW v_veronika_kvasnickova_srov	AS
SELECT 
	indt.first_year AS '1st_year',
	gro.next_year AS '2nd_year',
	indt.dif AS 'payroll_change', 
	gro.average_change AS 'groceries_change',
	indt.dif * 1.1 AS '10%pluspayroll'
FROM v_veronika_kvasnickova_ind_dif AS indt
JOIN v_veronika_kvasnickova_groceries_difty AS gro
	ON indt.first_year = gro.YEAR; 


-- G
CREATE OR REPLACE VIEW v_veronika_kvasnickova_srov2 AS
SELECT *,
	CASE 
		WHEN  groceries_change > payroll_change THEN 'groceries'
		ELSE 'payroll'
		END	AS 'what_increases_more', 
	CASE 
		WHEN  groceries_change > (payroll_change* 1.1)THEN 'more than  10 % higher increase of groceries than payroll'
		ELSE '-'
		END	AS 'higher_increase',
	CASE 
		WHEN payroll_change < 0 THEN 'attention - negative payroll'
		ELSE 'ok'
		END AS 'is_10%_ok'
FROM v_veronika_kvasnickova_srov;


SELECT *
FROM v_veronika_kvasnickova_srov2;
-- END OF TASK FOUR