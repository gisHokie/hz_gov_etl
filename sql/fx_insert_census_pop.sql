-- FUNCTION: public.fx_insert_census_pop(numeric, character varying, character varying, character varying)

-- DROP FUNCTION public.fx_insert_census_pop(numeric, character varying, character varying, character varying);

CREATE OR REPLACE FUNCTION public.fx_insert_census_pop(
	population numeric,
	state_fip character varying,
	county_fip character varying,
	census_year character varying)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
	INSERT INTO public.census_population(
		population,
		state_fip,
		county_fip,
		census_year
	)
	VALUES(population,
		  state_fip,
		  county_fip
		  , census_year);
END;
$BODY$;

ALTER FUNCTION public.fx_insert_census_pop(numeric, character varying, character varying, character varying)
    OWNER TO postgres;

