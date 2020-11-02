-- Table: public.census_population

-- DROP TABLE public.census_population;

CREATE TABLE public.census_population
(
    population numeric,
    state_fip character varying COLLATE pg_catalog."default",
    county_fip character varying COLLATE pg_catalog."default",
    census_year character varying COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE public.census_population
    OWNER to postgres;
