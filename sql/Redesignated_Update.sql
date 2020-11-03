SELECT gid
, tract_fips
, county
, state
, prior_status
, redesignation
, expires
, effective
, geom
, (EXTRACT MONTH from prior_status)
, (EXTRACT YEAR from priro_status)
FROM public.qct_r
LIMIT 5

--1919 records


SELECT 
 tract_fips
, county
, state
, prior_status
, redesignated
, expires
, effective
, SPLIT_PART(prior_status, ' ', 3) as red_MONTH
, SPLIT_PART(prior_status, ' ', 4) as red_YEAR
, TO_DATE(CONCAT(SPLIT_PART(prior_status, ' ', 3),' ', SPLIT_PART(prior_status, ' ', 4)), 'Mon YYYY' ) as mm_yyyy
, geom
,CASE
	WHEN TO_DATE(CONCAT(SPLIT_PART(prior_status, ' ', 3),' ', SPLIT_PART(prior_status, ' ', 4)), 'Mon YYYY' ) = '2018-03-01'
	THEN 'FLAG'
	WHEN TO_DATE(CONCAT(SPLIT_PART(prior_status, ' ', 3),' ', SPLIT_PART(prior_status, ' ', 4)), 'Mon YYYY' ) = '2018-04-01'
	THEN 'FLAG'
	WHEN TO_DATE(CONCAT(SPLIT_PART(prior_status, ' ', 3),' ', SPLIT_PART(prior_status, ' ', 4)), 'Mon YYYY' ) < '2018-03-01'
	THEN 'NO CHANGE'
	WHEN TO_DATE(CONCAT(SPLIT_PART(prior_status, ' ', 3),' ', SPLIT_PART(prior_status, ' ', 4)), 'Mon YYYY' ) > '2018-04-01'
	THEN 'QDA'
	ELSE	prior_status
END AS qda_review
FROM public.qct_r
WHERE prior_status LIKE '%Redesig%'
AND state = 'VA'



SELECT 
 county_fips
, county
, state
, july_2017_status_previous
, redesignated
, expires
, effective
, SPLIT_PART(july_2017_status_previous, ' ', 3) as red_MONTH
, SPLIT_PART(july_2017_status_previous, ' ', 4) as red_YEAR
, TO_DATE(CONCAT(SPLIT_PART(july_2017_status_previous, ' ', 3),' ', SPLIT_PART(july_2017_status_previous, ' ', 4)), 'Month YYYY' ) as mm_yyyy
, geom
,CASE
	WHEN TO_DATE(CONCAT(SPLIT_PART(july_2017_status_previous, ' ', 3),' ', SPLIT_PART(july_2017_status_previous, ' ', 4)), 'Month YYYY' ) = '2018-03-01'
	THEN 'FLAG'
	WHEN TO_DATE(CONCAT(SPLIT_PART(july_2017_status_previous, ' ', 3),' ', SPLIT_PART(july_2017_status_previous, ' ', 4)), 'Month YYYY' ) = '2018-04-01'
	THEN 'FLAG'
	WHEN TO_DATE(CONCAT(SPLIT_PART(july_2017_status_previous, ' ', 3),' ', SPLIT_PART(july_2017_status_previous, ' ', 4)), 'Month YYYY' ) < '2018-03-01'
	THEN 'NO CHANGE'
	WHEN TO_DATE(CONCAT(SPLIT_PART(july_2017_status_previous, ' ', 3),' ', SPLIT_PART(july_2017_status_previous, ' ', 4)), 'Month YYYY' ) > '2018-04-01'
	THEN 'QDA'
	ELSE	july_2017_status_previous
END AS qda_review
FROM public.qnmc
WHERE july_2017_status_previous LIKE '%Redesig%'
AND state = 'FL'
--AND TO_DATE(CONCAT(SPLIT_PART(prior_status, ' ', 3),' ', SPLIT_PART(prior_status, ' ', 4)), 'Mon YYYY' ) = '2018-04-01'
--LIMIT 100


--FOR TRACT
CREATE VIEW Redesignated_Tract_Update
AS
SELECT 
 tract_fips
, county
, state
, prior_status
, redesignated
, expires
, effective
, SPLIT_PART(prior_status, ' ', 3) as red_MONTH
, SPLIT_PART(prior_status, ' ', 4) as red_YEAR
, TO_DATE(CONCAT(SPLIT_PART(prior_status, ' ', 3),' ', SPLIT_PART(prior_status, ' ', 4)), 'Mon YYYY' ) as mm_yyyy
--, geom
,CASE
	WHEN TO_DATE(CONCAT(SPLIT_PART(prior_status, ' ', 3),' ', SPLIT_PART(prior_status, ' ', 4)), 'Mon YYYY' ) = '2018-03-01'
	THEN 'FLAG'
	WHEN TO_DATE(CONCAT(SPLIT_PART(prior_status, ' ', 3),' ', SPLIT_PART(prior_status, ' ', 4)), 'Mon YYYY' ) = '2018-04-01'
	THEN 'FLAG'
	WHEN TO_DATE(CONCAT(SPLIT_PART(prior_status, ' ', 3),' ', SPLIT_PART(prior_status, ' ', 4)), 'Mon YYYY' ) < '2018-03-01'
	THEN 'NO CHANGE'
	WHEN TO_DATE(CONCAT(SPLIT_PART(prior_status, ' ', 3),' ', SPLIT_PART(prior_status, ' ', 4)), 'Mon YYYY' ) > '2018-04-01'
	THEN 'QDA'
	ELSE	prior_status
END AS qda_review
FROM data.qct_2018_01_01
WHERE prior_status LIKE '%Redesig%'
--AND state = 'VA'


--FOR COUNTY
CREATE VIEW Redesignated_County_Update
AS
SELECT 
 county_fips
, county
, state
, july_2017_status_previous
, redesignated
, expires
, effective
, SPLIT_PART(july_2017_status_previous, ' ', 3) as red_MONTH
, SPLIT_PART(july_2017_status_previous, ' ', 4) as red_YEAR
, CASE 
	WHEN SPLIT_PART(july_2017_status_previous, ' ', 3) = 'Jan'
		THEN TO_DATE(CONCAT(SPLIT_PART(july_2017_status_previous, ' ', 3),' ', SPLIT_PART(july_2017_status_previous, ' ', 4)), 'Mon YYYY' )
	ELSE 
		TO_DATE(CONCAT(SPLIT_PART(july_2017_status_previous, ' ', 3),' ', SPLIT_PART(july_2017_status_previous, ' ', 4)), 'Month YYYY' )
   END  as mm_yyyy
--, geom
,CASE
	WHEN SPLIT_PART(july_2017_status_previous, ' ', 3) = 'Jan'
		AND TO_DATE(CONCAT(SPLIT_PART(july_2017_status_previous, ' ', 3),' ', SPLIT_PART(july_2017_status_previous, ' ', 4)), 'Mon YYYY' ) < '2018-03-01'
	THEN 'NO CHANGE'
	WHEN SPLIT_PART(july_2017_status_previous, ' ', 3) = 'Jan'
		AND TO_DATE(CONCAT(SPLIT_PART(july_2017_status_previous, ' ', 3),' ', SPLIT_PART(july_2017_status_previous, ' ', 4)), 'Mon YYYY' ) > '2018-04-01'
	THEN 'NO CHANGE'
	WHEN TO_DATE(CONCAT(SPLIT_PART(july_2017_status_previous, ' ', 3),' ', SPLIT_PART(july_2017_status_previous, ' ', 4)), 'Month YYYY' ) = '2018-03-01'
	THEN 'FLAG'
	WHEN TO_DATE(CONCAT(SPLIT_PART(july_2017_status_previous, ' ', 3),' ', SPLIT_PART(july_2017_status_previous, ' ', 4)), 'Month YYYY' ) = '2018-04-01'
	THEN 'FLAG'
	WHEN TO_DATE(CONCAT(SPLIT_PART(july_2017_status_previous, ' ', 3),' ', SPLIT_PART(july_2017_status_previous, ' ', 4)), 'Month YYYY' ) < '2018-03-01'
	THEN 'NO CHANGE'
	WHEN TO_DATE(CONCAT(SPLIT_PART(july_2017_status_previous, ' ', 3),' ', SPLIT_PART(july_2017_status_previous, ' ', 4)), 'Month YYYY' ) > '2018-04-01'
	THEN 'QDA or Something Else'
	ELSE	july_2017_status_previous
END AS qda_review
FROM data.qnmc_2018_01_01
WHERE july_2017_status_previous LIKE '%Redesig%'
--AND state = 'VA'
