-- FUNCTION: public.fx_insert_acs_emp_all(character varying, numeric, numeric, numeric, numeric, numeric, numeric, numeric, numeric, character varying, character varying, character varying, character varying)

-- DROP FUNCTION public.fx_insert_acs_emp_all(character varying, numeric, numeric, numeric, numeric, numeric, numeric, numeric, numeric, character varying, character varying, character varying, character varying);

CREATE OR REPLACE FUNCTION public.fx_insert_acs_emp_all(
	obj_tract character varying,
	est_total numeric,
	est_total_margin_err numeric,
	est_labor_rate numeric,
	est_labor_rate_margin_err numeric,
	est_emp_pop_ratio numeric,
	est_emp_pop_ratio_margin_err numeric,
	est_unemp_rate numeric,
	est_unemp_rate_margin_err numeric,
	state_fip character varying,
	county_fip character varying,
	tract_code character varying,
	acs_year character varying)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
        INSERT INTO public.acs_emp_all(obj_tract,
								est_total,
								est_total_margin_err,
								est_labor_rate,
								est_labor_rate_margin_err,
								est_emp_pop_ratio,
								est_emp_pop_ratio_margin_err,
								est_unemp_rate,
								est_unemp_rate_margin_err,
								state_fip,
								county_fip,
								tract_code,
								acs_year)
        VALUES(obj_tract,
				est_total,
				est_total_margin_err,
				est_labor_rate,
				est_labor_rate_margin_err,
				est_emp_pop_ratio,
				est_emp_pop_ratio_margin_err,
				est_unemp_rate,
				est_unemp_rate_margin_err,
				state_fip,
				county_fip,
				tract_code,
				acs_year);
      END;
$BODY$;

ALTER FUNCTION public.fx_insert_acs_emp_all(character varying, numeric, numeric, numeric, numeric, numeric, numeric, numeric, numeric, character varying, character varying, character varying, character varying)
    OWNER TO postgres;

