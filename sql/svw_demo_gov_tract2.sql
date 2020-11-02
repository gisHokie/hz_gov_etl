-- View: public.demo_governors_tract

-- DROP VIEW public.demo_governors_tract;

--CREATE OR REPLACE VIEW public.demo_governors_tract
-- AS
 WITH tract_geom AS (
         SELECT ct.id,
            ct.statefp,
            ct.countyfp,
            ct.tractce,
            ct.geom
           FROM census_tract ct
          WHERE ct.id NOT IN ( SELECT census_tract.id
          FROM census_tract, census_urban_area
		  WHERE st_intersects(census_tract.geom, st_setsrid(census_urban_area.geom, 4269)) 
		  AND census_tract.census_year = '2018'
		  AND census_urban_area.census_year = '2018'
		  AND census_urban_area.uatyp10 = 'U'
		  AND census_tract.statefp = '17')
		  AND ct.census_year = '2018'
		  AND ct.statefp = '17'
		  ORDER BY ct.tractce
        )
, national_unmeploy AS (
 SELECT unnat.unemploy_rate AS nat_unemploy_rate,
    unnat.unemploy_year AS nat_unemploy_year,
    unnat.unemploy_month AS nat_unemploy_month
   FROM unemploy unnat
  WHERE unnat.admin_name = 'United States of America'
)
 SELECT trt.id,
    aea.est_total AS total_employ,
    aea.est_unemp_rate AS unemp_rate,
    aea.state_fip,
    aea.county_fip,
    aea.tract_code,
    fm.state_name,
    cnty.name,
    un.unemploy_rate AS state_unemploy_rate,
    nat.nat_unemploy_rate,
    round((aea.est_unemp_rate / un.unemploy_rate), 2) AS tract_state_ratio,
    round((aea.est_unemp_rate / nat.nat_unemploy_rate), 2) AS tract_national_ratio,
    cp.population,
    trt.geom,
        CASE
            WHEN (round((aea.est_unemp_rate / un.unemploy_rate), 2) < round((aea.est_unemp_rate / nat.nat_unemploy_rate), 2)) THEN round((aea.est_unemp_rate / un.unemploy_rate), 2)
            ELSE round((aea.est_unemp_rate / nat.nat_unemploy_rate), 2)
        END AS min_unemploy
   FROM acs_emp_all aea
     JOIN fips_mapping fm 
     	ON aea.state_fip = fm.fips
     JOIN unemploy un 
     	ON un.admin_name = fm.state_name
     JOIN census_population cp 
     	ON cp.state_fip = aea.state_fip 
     	AND cp.county_fip = aea.county_fip
     JOIN national_unmeploy nat 
     	ON nat.nat_unemploy_year = un.unemploy_year
     	AND nat.nat_unemploy_month = un.unemploy_month
     JOIN census_county cnty 
     	ON aea.state_fip = cnty.statefp AND aea.county_fip = cnty.countyfp
     JOIN tract_geom trt 
     	ON trt.tractce = aea.tract_code
     	AND trt.countyfp = aea.county_fip
     	AND trt.statefp = aea.state_fip
  WHERE aea.state_fip = '17' 
  AND un.unemploy_year = '2020' 
  AND un.unemploy_month = '09' 
  AND cp.population <= 50000 
  AND ((round((aea.est_unemp_rate / un.unemploy_rate), 2) >= 1.2) OR round((aea.est_unemp_rate / nat.nat_unemploy_rate), 2) >= 1.2)
  ORDER BY aea.state_fip, aea.county_fip, aea.tract_code;



-- REVISED --
-- View: public.demo_governors_tract

-- DROP VIEW public.demo_governors_tract;

--CREATE OR REPLACE VIEW public.demo_governors_tract
-- AS
 WITH tract_geom AS (
         SELECT ct.id,
            ct.statefp,
            ct.countyfp,
            ct.tractce,
            ct.geom
           FROM census_tract ct
          WHERE ct.id NOT IN ( SELECT census_tract.id
          FROM census_tract, census_urban_area
		  WHERE st_intersects(census_tract.geom, st_setsrid(census_urban_area.geom, 4269)) 
		  AND census_tract.census_year = '2018'
		  AND census_urban_area.census_year = '2018'
		  AND census_urban_area.uatyp10 = 'U'
		  AND census_tract.statefp = '17')
		  AND ct.census_year = '2018'
		  AND ct.statefp = '17'
		  ORDER BY ct.tractce
        )
, national_unmeploy AS (
 SELECT unnat.unemploy_rate AS nat_unemploy_rate,
    unnat.unemploy_year AS nat_unemploy_year,
    unnat.unemploy_month AS nat_unemploy_month
   FROM unemploy unnat
  WHERE unnat.admin_name = 'United States of America'
)
 SELECT trt.id,
    aea.est_total AS total_employ,
    aea.est_unemp_rate AS unemp_rate,
    aea.state_fip,
    aea.county_fip,
    aea.tract_code,
    fm.state_name,
    cnty.name,
    un.unemploy_rate AS state_unemploy_rate,
    nat.nat_unemploy_rate,
    round((aea.est_unemp_rate / un.unemploy_rate), 2) AS tract_state_ratio,
    round((aea.est_unemp_rate / nat.nat_unemploy_rate), 2) AS tract_national_ratio,
    cp.population,
    trt.geom,
        CASE
            WHEN (round((aea.est_unemp_rate / un.unemploy_rate), 2) < round((aea.est_unemp_rate / nat.nat_unemploy_rate), 2)) THEN round((aea.est_unemp_rate / un.unemploy_rate), 2)
            ELSE round((aea.est_unemp_rate / nat.nat_unemploy_rate), 2)
        END AS min_unemploy
  , CASE
  		WHEN trt.id is NULL THEN 'Tract Intersects an URBAN AREA'
		WHEN trt.id is NOT NULL THEN 'Tract Does Not Intersect an Urban Area'
		ELSE 'no tract id found'
  END as is_trt_in_ua
  , CASE
  		WHEN cp.population > 50000 THEN 'The County of Tract has population GREATER than 50,000'
		WHEN cp.population <= 50000 THEN 'The County of Tract has population LESS than or EQUAL to 50,000'
		ELSE 'No population found'
	END
, CASE
	WHEN  round((aea.est_unemp_rate / un.unemploy_rate), 2) >= 1.2 OR round((aea.est_unemp_rate / nat.nat_unemploy_rate), 2) >= 1.2
		THEN 'Tract State or National Unemployment Rates is GREATER than or EQUAL to 120%'
	WHEN round((aea.est_unemp_rate / un.unemploy_rate), 2) < 1.2 OR round((aea.est_unemp_rate / nat.nat_unemploy_rate), 2) < 1.2
  		THEN 'Tract State or National Unemployment Rates is LESS than 120%'
	ELSE 'No unemployment rates found'
  END,
  CASE
  WHEN  (round((aea.est_unemp_rate / un.unemploy_rate), 2) >= 1.2 OR round((aea.est_unemp_rate / nat.nat_unemploy_rate), 2) >= 1.2)
  	AND cp.population <= 50000
	AND trt.id is NOT NULL
	THEN 'QUALIFIES'
	ELSE 'NOT QUALIFIES'
  END
   FROM acs_emp_all aea
     JOIN fips_mapping fm 
     	ON aea.state_fip = fm.fips
     JOIN unemploy un 
     	ON un.admin_name = fm.state_name
     JOIN census_population cp 
     	ON cp.state_fip = aea.state_fip 
     	AND cp.county_fip = aea.county_fip
     JOIN national_unmeploy nat 
     	ON nat.nat_unemploy_year = un.unemploy_year
     	AND nat.nat_unemploy_month = un.unemploy_month
     JOIN census_county cnty 
     	ON aea.state_fip = cnty.statefp AND aea.county_fip = cnty.countyfp
     LEFT OUTER JOIN tract_geom trt 
     	ON trt.tractce = aea.tract_code
     	AND trt.countyfp = aea.county_fip
     	AND trt.statefp = aea.state_fip

  WHERE aea.state_fip = '17' 
  AND un.unemploy_year = '2020' 
  AND un.unemploy_month = '09' 
  --AND cp.population <= 50000 
  --AND ((round((aea.est_unemp_rate / un.unemploy_rate), 2) >= 1.2) OR round((aea.est_unemp_rate / nat.nat_unemploy_rate), 2) >= 1.2)
  ORDER BY 
	aea.state_fip, aea.county_fip, aea.tract_code



--- FOR ALL TRACTS 
-- View: public.demo_governors_tract

-- DROP VIEW public.demo_governors_tract;

--CREATE OR REPLACE VIEW public.demo_governors_tract
-- AS
 WITH tract_geom AS (
         SELECT ct.id,
            ct.statefp,
            ct.countyfp,
            ct.tractce,
            ct.geom
           FROM census_tract ct
          WHERE ct.id NOT IN ( SELECT census_tract.id
          FROM census_tract, census_urban_area
		  WHERE st_intersects(census_tract.geom, st_setsrid(census_urban_area.geom, 4269)) 
		  AND census_tract.census_year = '2018'
		  AND census_urban_area.census_year = '2018'
		  AND census_urban_area.uatyp10 = 'U'
		  --AND census_tract.statefp = '17'
		 )
		  AND ct.census_year = '2018'
		  --AND ct.statefp = '17'
		  ORDER BY ct.tractce
        )
, national_unmeploy AS (
 SELECT unnat.unemploy_rate AS nat_unemploy_rate,
    unnat.unemploy_year AS nat_unemploy_year,
    unnat.unemploy_month AS nat_unemploy_month
   FROM unemploy unnat
  WHERE unnat.admin_name = 'United States of America'
)
 SELECT trt.id,
    aea.est_total AS total_employ,
    aea.est_unemp_rate AS unemp_rate,
    aea.state_fip,
    aea.county_fip,
    aea.tract_code,
    fm.state_name,
    cnty.name,
    un.unemploy_rate AS state_unemploy_rate,
    nat.nat_unemploy_rate,
    round((aea.est_unemp_rate / un.unemploy_rate), 2) AS tract_state_ratio,
    round((aea.est_unemp_rate / nat.nat_unemploy_rate), 2) AS tract_national_ratio,
    cp.population,
    trt.geom,
        CASE
            WHEN (round((aea.est_unemp_rate / un.unemploy_rate), 2) < round((aea.est_unemp_rate / nat.nat_unemploy_rate), 2)) THEN round((aea.est_unemp_rate / un.unemploy_rate), 2)
            ELSE round((aea.est_unemp_rate / nat.nat_unemploy_rate), 2)
        END AS min_unemploy
  , CASE
  		WHEN trt.id is NULL THEN 'Tract Intersects an URBAN AREA'
		WHEN trt.id is NOT NULL THEN 'Tract Does Not Intersect an Urban Area'
		ELSE 'no tract id found'
  END as is_trt_in_ua
  , CASE
  		WHEN cp.population > 50000 THEN 'The County of Tract has population GREATER than 50,000'
		WHEN cp.population <= 50000 THEN 'The County of Tract has population LESS than or EQUAL to 50,000'
		ELSE 'No population found'
	END
, CASE
	WHEN  round((aea.est_unemp_rate / un.unemploy_rate), 2) >= 1.2 OR round((aea.est_unemp_rate / nat.nat_unemploy_rate), 2) >= 1.2
		THEN 'Tract State or National Unemployment Rates is GREATER than or EQUAL to 120%'
	WHEN round((aea.est_unemp_rate / un.unemploy_rate), 2) < 1.2 OR round((aea.est_unemp_rate / nat.nat_unemploy_rate), 2) < 1.2
  		THEN 'Tract State or National Unemployment Rates is LESS than 120%'
	ELSE 'No unemployment rates found'
  END,
  CASE
  WHEN  (round((aea.est_unemp_rate / un.unemploy_rate), 2) >= 1.2 OR round((aea.est_unemp_rate / nat.nat_unemploy_rate), 2) >= 1.2)
  	AND cp.population <= 50000
	AND trt.id is NOT NULL
	THEN 'QUALIFIES'
	ELSE 'NOT QUALIFIES'
  END
   FROM acs_emp_all aea
     JOIN fips_mapping fm 
     	ON aea.state_fip = fm.fips
     JOIN unemploy un 
     	ON un.admin_name = fm.state_name
     JOIN census_population cp 
     	ON cp.state_fip = aea.state_fip 
     	AND cp.county_fip = aea.county_fip
     JOIN national_unmeploy nat 
     	ON nat.nat_unemploy_year = un.unemploy_year
     	AND nat.nat_unemploy_month = un.unemploy_month
     JOIN census_county cnty 
     	ON aea.state_fip = cnty.statefp AND aea.county_fip = cnty.countyfp
     LEFT OUTER JOIN tract_geom trt 
     	ON trt.tractce = aea.tract_code
     	AND trt.countyfp = aea.county_fip
     	AND trt.statefp = aea.state_fip

  WHERE  un.unemploy_year = '2020' 
  AND un.unemploy_month = '09' 
  --AND aea.state_fip = '17' 
  --AND cp.population <= 50000 
  --AND ((round((aea.est_unemp_rate / un.unemploy_rate), 2) >= 1.2) OR round((aea.est_unemp_rate / nat.nat_unemploy_rate), 2) >= 1.2)
  ORDER BY 
	aea.state_fip, aea.county_fip, aea.tract_code

