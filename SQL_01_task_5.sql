-- PRIMARY table COPY
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


-- SECONDARY table COPY
CREATE OR REPLACE TABLE t_veronika_kvasnickova_project_SQL_secondary1 AS
SELECT 
	e.year, 
	e.country,	
	e.gdp,
	e.gini,
	e.population
FROM economies AS e
WHERE YEAR IN ( '2006', '2007', '2008', '2009', '2010', '2011', '2012', '2013','2014', '2015', '2016', '2017', '2018')
	AND e.country IN (
		SELECT DISTINCT c.country
		FROM countries c
		WHERE c.continent = 'Europe'
		);
	
		
CREATE OR REPLACE TABLE t_veronika_kvasnickova_project_SQL_secondary_final AS
SELECT 
	hdp1.country,
	hdp1.year AS 'first_year',
	hdp2.year AS 'second_year',
	hdp1.gdp AS 'gdp1',
	hdp2.gdp AS 'gdp2',
	ROUND( (hdp2.gdp - hdp1.gdp)/  hdp1.gdp *100,2  ) AS 'gdp_dif'
FROM t_veronika_kvasnickova_project_SQL_secondary1 AS hdp1
LEFT JOIN t_veronika_kvasnickova_project_SQL_secondary1 AS hdp2
	ON hdp1.year + 1 = hdp2.year
	AND hdp1.country =  hdp2.country;



-- TASK FIVE

-- A (copy from previus tasks), 
-- table for price changes - from task FOUR - copy
CREATE OR REPLACE VIEW v_veronika_kvasnickova_groceries_t4 AS
SELECT DISTINCT 
	year, 
	groceries_code, 
	groceries_name, 
	avg_groceries_price 
FROM t_veronika_kvasnickova_project_SQL_primary_final
WHERE groceries_code IS NOT NULL; 
	

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
	ON groc1t.year + 1  = groc2t.year 
	AND groc1t.groceries_code = groc2t.groceries_code  
WHERE groc2t.year IS NOT NULL 
GROUP BY groc1t.year, groceries_name;	


CREATE OR REPLACE VIEW v_veronika_kvasnickova_groceries_difty AS
SELECT year, next_year, AVG(price_change) AS 'average_change'
FROM v_veronika_kvasnickova_groceries_dift4
GROUP BY YEAR;




-- table for payroll changes - from task FOUR - copy
CREATE OR REPLACE VIEW v_veronika_kvasnickova_pay_year AS
SELECT DISTINCT -- so AS TO SHOW ONLY one average_payroll per industry per YEAR, because OF groceries IN the PRIMARY table
	year, 
    ROUND(AVG(average_payroll)) AS 'avg_pay' -- average pay WITHIN whole YEAR (for the whole industry)
FROM t_veronika_kvasnickova_project_SQL_primary_final
GROUP BY YEAR;


CREATE OR REPLACE VIEW v_veronika_kvasnickova_ind_dif AS
SELECT 
    pay1.year AS 'first_year',
    pay1.avg_pay AS 'first_average_pay',
    pay2.year AS 'second_year',
    pay2.avg_pay AS 'second_average_pay',
	ROUND(((pay2.avg_pay -  pay1.avg_pay) / pay1.avg_pay *100),2) AS 'dif'
FROM v_veronika_kvasnickova_pay_year AS pay1
LEFT JOIN v_veronika_kvasnickova_pay_year AS pay2
	ON pay1.year + 1 = pay2.year
WHERE 
	pay1.year IN ('2006', '2007', '2008', '2009', '2010', '2011', '2012', '2013', '2014', '2015','2016', '2017'); -- ONLY FOR years, that info FOR groceries IS AS well


-- NEW CODE:
-- B
-- selecting only Czech Republic from secondary table
CREATE OR REPLACE TABLE t_veronika_kvasnickova_gdpcz AS
SELECT country, first_year, second_year, GDP1, GDP2, GDP_dif 
FROM t_veronika_kvasnickova_project_SQL_secondary_final
WHERE country = 'Czech Republic'
	
-- conecting secondary table and price changes table and payroll changes table
CREATE OR REPLACE VIEW v_veronika_kvasnickova_t5 AS 
SELECT 
	sec.first_year  AS 'gdp_year',
-- 	sec.second_year AS 'gdp_next_year',
	-- industry.first_year AS 'industry_year',
	-- industry.second_year AS 'industry_next_year',
	-- grocer.YEAR AS 'grocery_year',
	-- grocer.next_year 'grocery_next_year',
	sec.gdp_dif AS 'GDP_change',
ROUND(grocer.average_change, 2) 'groceries',
	 industry.dif AS 'payroll', 
	ROUND(grocer2.average_change,2) AS 'groceries_next',
	industry2.dif AS 'payroll_next', 
	/*ROUND(sec.gdp_dif/ROUND(grocer.average_change, 2), 1) 'HDP/groceries',
	ROUND (	sec.gdp_dif/industry.dif, 1) AS 'HDP/payroll',
	ROUND (sec.gdp_dif/	ROUND(grocer2.average_change,2),1) AS 'HDP/groceries_next',
	ROUND(	sec.gdp_dif/industry2.dif, 1) AS 'HDP/payroll_next', 	*/
	CASE 
		WHEN sec.gdp_dif <= 0 THEN 'x'
		WHEN sec.gdp_dif >= 4 THEN 'xxxx'
		WHEN sec.gdp_dif >= 2 THEN 'xxx'
		WHEN sec.gdp_dif > 0 THEN 'xx'
	END AS 'GDP',	
	CASE 
		WHEN grocer.average_change <= 0 THEN 'x'
		WHEN grocer.average_change >= 7 THEN 'xxxx'
		WHEN grocer.average_change >= 4 THEN 'xxx'
		WHEN grocer.average_change > 0 THEN 'xx'
	END AS 'grocery',
	CASE 
		WHEN grocer2.average_change <= 0 THEN 'x'
		WHEN grocer2.average_change >= 7 THEN 'xxxx'
		WHEN grocer2.average_change >= 4 THEN 'xxx'
		WHEN grocer2.average_change > 0 THEN 'xx'
	END AS 'grocery_next',	 
	CASE 
		WHEN industry.dif <= 0 THEN 'x'
		WHEN industry.dif >= 6 THEN 'xxxx'
		WHEN industry.dif >= 3 THEN 'xxx'
		WHEN industry.dif > 0 THEN 'xx'
	END AS 'pay',	
	CASE 
		WHEN industry2.dif <= 0 THEN 'x'
		WHEN industry2.dif >= 6 THEN 'xxxx'
		WHEN industry2.dif >= 3 THEN 'xxx'
		WHEN industry2.dif > 0 THEN 'xx'
	END AS 'pay_next', 
	CASE  
		WHEN sec.gdp_dif <= 0 AND grocer2.average_change <= 4 THEN 1			
	    WHEN sec.gdp_dif >= 4 AND grocer2.average_change > 4  THEN 1	      
		WHEN sec.gdp_dif >= 2 AND sec.gdp_dif <= 4  AND grocer2.average_change <= 10  AND grocer2.average_change >= 0  THEN 1		
				WHEN sec.gdp_dif >  0 AND sec.gdp_dif <= 2  AND grocer2.average_change <= 7 THEN 1		
		ELSE '0'		
	END AS 'groceries_2'
FROM t_veronika_kvasnickova_gdpcz AS sec
LEFT JOIN v_veronika_kvasnickova_groceries_difty AS grocer
	ON sec.first_year = grocer.year
LEFT JOIN v_veronika_kvasnickova_ind_dif AS industry
	ON sec.first_year = industry.first_year
LEFT JOIN v_veronika_kvasnickova_groceries_difty AS grocer2
	ON sec.first_year + 1 = grocer2.year
LEFT JOIN v_veronika_kvasnickova_ind_dif AS industry2
	ON sec.first_year + 1 = industry2.first_year
WHERE sec.first_year !='2018';	

	
SELECT sum(groceries_2)
FROM v_veronika_kvasnickova_t5
GROUP BY groceries_2;

