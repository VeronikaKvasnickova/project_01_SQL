-- SECONDARY table

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
