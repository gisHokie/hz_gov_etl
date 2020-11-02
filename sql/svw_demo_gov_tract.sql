-- View: public.demo_governors_tract

--DROP VIEW public.demo_governors_tract;

--CREATE OR REPLACE VIEW public.demo_governors_tract
-- AS
WITH tract_geom AS (
-- This query gets selected data from Tract
-- May or may not need the years or state, This was added to keep the query response time down
         SELECT ct.id,
            ct.statefp,
            ct.countyfp,
            ct.tractce,
            ct.geom
           FROM public.census_tract AS ct
           -- Get only tract that does not includes tracts that intersects census areas
          WHERE ct.id not in (SELECT census_tract.id 
	  			FROM public.census_tract, public.census_urban_area
	  			WHERE ST_Intersects(public.census_tract.geom::geometry, ST_SetSRID(census_urban_area.geom::geometry, 4269))
				  AND census_tract.census_year = '2018'
				  AND census_urban_area.census_year = '2018'
				  AND census_tract.statefp::text = '17'
				 )
AND ct.census_year = '2018'
AND ct.statefp::text = '17'
)
, national_unmeploy AS (
-- Gets the National Unemployment rate
-- A Subselect/Recursive statement can be made in main SELECT statement
-- This was made to keep the main SELECT less complicated
         SELECT unnat.unemploy_rate AS nat_unemploy_rate,
            unnat.unemploy_year AS nat_unemploy_year,
            unnat.unemploy_month AS nat_unemploy_month
           FROM unemploy unnat
          WHERE ((unnat.admin_name)::text = 'United States of America'::text)
        )
/*
* Author: Scott McDermott
* Date: 10/26/2020
* Summary: Get list of Census Tracts for the Governor's Designated Areas
* Criterias for the Governor's Designated Area:
* 1) Area will be a Census Tract, Census Tract are updated by the US Census once a year
* 2) Census Tract will NOT be in an Urbanized Area
* 3) Census Tract will be contained in a County with a population lesser than OR equal to 50,000
* 4) Census Tract will have an average unemployment rate 120% (or 1.2 rate) of the State's Unemployment OR National Unemployment
* 5) The MINIMUM Average Unemployment Rate will be used to determine if the 120% is met (Meaning the two averages both has to be Above 120%
* 
* List of Data Required
* 1) Census Tract for a a given year
* 2) Census Urban Areas for a given year
* 3) Census ACS Unemployment Rates for Tracts
* 4) Census Population by County for a given year
* 5) BLS State's Monthly Employment Rates
* 6) BLS National Monthly Employment Rates 

*/

-- MAIN SELECT STATEMENT
 SELECT 
    trt.id
    ,aea.est_total AS total_employ,
    aea.est_unemp_rate AS unemp_rate,
    aea.state_fip,
    aea.county_fip,
    aea.tract_code,
    fm.state_name,
	cnty.name
    ,un.unemploy_rate AS state_unemploy_rate,
	ROUND(aea.est_unemp_rate / un.unemploy_rate, 2) AS tract_state_ratio,
    ROUND(aea.est_unemp_rate / nat.nat_unemploy_rate,2) AS tract_national_ratio,
    cp.population,
    trt.geom,
	CASE
		WHEN ROUND(aea.est_unemp_rate / un.unemploy_rate, 2) < ROUND(aea.est_unemp_rate / nat.nat_unemploy_rate, 2)
		THEN ROUND(aea.est_unemp_rate / un.unemploy_rate, 2)
		ELSE ROUND(aea.est_unemp_rate / nat.nat_unemploy_rate, 2)
    END AS Min_Unemploy

   
   FROM acs_emp_all aea
     JOIN fips_mapping fm ON aea.state_fip::text = fm.fips::text
     JOIN unemploy un ON un.admin_name::text = fm.state_name::text
     JOIN census_population cp 
     	ON cp.state_fip = aea.state_fip 
     	AND cp.county_fip = aea.county_fip
     JOIN national_unmeploy nat ON nat.nat_unemploy_year::text = un.unemploy_year::text 
     	AND nat.nat_unemploy_month::text = un.unemploy_month::text
	JOIN census_county as cnty
		ON aea.state_fip = cnty.statefp
		AND aea.county_fip = cnty.countyfp
     JOIN tract_geom AS trt ON trt.tractce = aea.tract_code
	AND trt.countyfp = aea.county_fip
	AND trt.statefp = aea.state_fip
 
 WHERE aea.state_fip::text = '17'::text 
  AND un.unemploy_year::text = '2020'::text 
  AND un.unemploy_month::text = '09'::text 
  AND cp.population <= 50000
--  AND (ROUND(aea.est_unemp_rate / un.unemploy_rate, 2) >= 1.2
--  	OR ROUND(aea.est_unemp_rate / nat.nat_unemploy_rate, 2) >= 1.2)

ORDER BY state_fip, county_fip, tract_code

