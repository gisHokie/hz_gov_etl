-- Table: public.census_tract

-- DROP TABLE public.census_tract;

CREATE TABLE public.census_tract
(
    id integer NOT NULL DEFAULT nextval('tl_2018_51_tract_id_seq'::regclass),
    geom geometry(MultiPolygon,4269),
    statefp character varying(2) COLLATE pg_catalog."default",
    countyfp character varying(3) COLLATE pg_catalog."default",
    tractce character varying(6) COLLATE pg_catalog."default",
    geoid character varying(11) COLLATE pg_catalog."default",
    name character varying(7) COLLATE pg_catalog."default",
    namelsad character varying(20) COLLATE pg_catalog."default",
    mtfcc character varying(5) COLLATE pg_catalog."default",
    funcstat character varying(1) COLLATE pg_catalog."default",
    aland bigint,
    awater bigint,
    intptlat character varying(11) COLLATE pg_catalog."default",
    intptlon character varying(12) COLLATE pg_catalog."default",
    census_year character varying COLLATE pg_catalog."default",
    CONSTRAINT tl_2018_51_tract_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE public.census_tract
    OWNER to postgres;
-- Index: census_tracts_geom_idx

-- DROP INDEX public.census_tracts_geom_idx;

CREATE INDEX census_tracts_geom_idx
    ON public.census_tract USING gist
    (geom)
    TABLESPACE pg_default;
