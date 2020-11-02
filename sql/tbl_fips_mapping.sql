-- Table: public.fips_mapping

-- DROP TABLE public.fips_mapping;

CREATE TABLE public.fips_mapping
(
    state_name character varying COLLATE pg_catalog."default",
    stusab character varying COLLATE pg_catalog."default",
    fips character varying COLLATE pg_catalog."default",
    fip_year character varying COLLATE pg_catalog."default",
    gnis character varying COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE public.fips_mapping
    OWNER to postgres;
