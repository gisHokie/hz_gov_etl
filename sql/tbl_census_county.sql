-- Table: public.census_county

-- DROP TABLE public.census_county;

CREATE TABLE public.census_county
(
    ogc_fid integer NOT NULL DEFAULT nextval('census_county_ogc_fid_seq'::regclass),
    statefp character varying(2) COLLATE pg_catalog."default",
    countyfp character varying(3) COLLATE pg_catalog."default",
    countyns character varying(8) COLLATE pg_catalog."default",
    geoid character varying(5) COLLATE pg_catalog."default",
    name character varying(100) COLLATE pg_catalog."default",
    namelsad character varying(100) COLLATE pg_catalog."default",
    lsad character varying(2) COLLATE pg_catalog."default",
    classfp character varying(2) COLLATE pg_catalog."default",
    mtfcc character varying(5) COLLATE pg_catalog."default",
    csafp character varying(3) COLLATE pg_catalog."default",
    cbsafp character varying(5) COLLATE pg_catalog."default",
    metdivfp character varying(5) COLLATE pg_catalog."default",
    funcstat character varying(1) COLLATE pg_catalog."default",
    aland numeric(14,0),
    awater numeric(14,0),
    intptlat character varying(11) COLLATE pg_catalog."default",
    intptlon character varying(12) COLLATE pg_catalog."default",
    wkb_geometry geometry(Geometry,4326),
    census_year character varying COLLATE pg_catalog."default",
    CONSTRAINT census_county_pkey PRIMARY KEY (ogc_fid)
)

TABLESPACE pg_default;

ALTER TABLE public.census_county
    OWNER to postgres;
-- Index: census_county_geom_idx

-- DROP INDEX public.census_county_geom_idx;

CREATE INDEX census_county_geom_idx
    ON public.census_county USING gist
    (wkb_geometry)
    TABLESPACE pg_default;
-- Index: census_county_wkb_geometry_geom_idx

-- DROP INDEX public.census_county_wkb_geometry_geom_idx;

CREATE INDEX census_county_wkb_geometry_geom_idx
    ON public.census_county USING gist
    (wkb_geometry)
    TABLESPACE pg_default;
