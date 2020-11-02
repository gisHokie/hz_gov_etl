-- Table: public.census_urban_area

-- DROP TABLE public.census_urban_area;

CREATE TABLE public.census_urban_area
(
    gid integer,
    uace10 character varying(5) COLLATE pg_catalog."default",
    geoid10 character varying(5) COLLATE pg_catalog."default",
    name10 character varying(100) COLLATE pg_catalog."default",
    namelsad10 character varying(100) COLLATE pg_catalog."default",
    lsad10 character varying(2) COLLATE pg_catalog."default",
    mtfcc10 character varying(5) COLLATE pg_catalog."default",
    uatyp10 character varying(1) COLLATE pg_catalog."default",
    funcstat10 character varying(1) COLLATE pg_catalog."default",
    aland10 double precision,
    awater10 double precision,
    intptlat10 character varying(11) COLLATE pg_catalog."default",
    intptlon10 character varying(12) COLLATE pg_catalog."default",
    geom geometry(MultiPolygon),
    census_year character varying(4) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE public.census_urban_area
    OWNER to postgres;
-- Index: census_urban_area_geom_idx

-- DROP INDEX public.census_urban_area_geom_idx;

CREATE INDEX census_urban_area_geom_idx
    ON public.census_urban_area USING gist
    (geom)
    TABLESPACE pg_default;
