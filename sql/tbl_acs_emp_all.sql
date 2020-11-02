-- Table: public.acs_emp_all

-- DROP TABLE public.acs_emp_all;

CREATE TABLE public.acs_emp_all
(
    obj_tract character varying COLLATE pg_catalog."default",
    est_total numeric,
    est_total_margin_err numeric,
    est_labor_rate numeric,
    est_labor_rate_margin_err numeric,
    est_emp_pop_ratio numeric,
    est_emp_pop_ratio_margin_err numeric,
    est_unemp_rate numeric,
    est_unemp_rate_margin_err numeric,
    state_fip character varying COLLATE pg_catalog."default",
    county_fip character varying COLLATE pg_catalog."default",
    tract_code character varying COLLATE pg_catalog."default",
    acs_year character varying COLLATE pg_catalog."default",
    pop_tract numeric
)

TABLESPACE pg_default;

ALTER TABLE public.acs_emp_all
    OWNER to postgres;
