-- View: public.svw_get_state_fips

-- DROP VIEW public.svw_get_state_fips;

CREATE OR REPLACE VIEW public.svw_get_all_years_acs_emp_all
 AS
 SELECT distinct(acs_year)
   FROM public.acs_emp_all
  ORDER BY acs_year;

