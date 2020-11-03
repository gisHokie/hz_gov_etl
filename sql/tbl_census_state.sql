-- Table: public.census_state

-- DROP TABLE public.census_state;

CREATE TABLE public.census_state
(
    ogc_fid integer NOT NULL DEFAULT nextval('census_state_ogc_fid_seq'::regclass),
    region character varying(2) COLLATE pg_catalog."default",
    division character varying(2) COLLATE pg_catalog."default",
    statefp character varying(2) COLLATE pg_catalog."default",
    statens character varying(8) COLLATE pg_catalog."default",
    geoid character varying(2) COLLATE pg_catalog."default",
    stusps character varying(2) COLLATE pg_catalog."default",
    name character varying(100) COLLATE pg_catalog."default",
    lsad character varying(2) COLLATE pg_catalog."default",
    mtfcc character varying(5) COLLATE pg_catalog."default",
    funcstat character varying(1) COLLATE pg_catalog."default",
    aland numeric(14,0),
    awater numeric(14,0),
    intptlat character varying(11) COLLATE pg_catalog."default",
    intptlon character varying(12) COLLATE pg_catalog."default",
    wkb_geometry geometry(Geometry,4326),
    census_year character varying COLLATE pg_catalog."default",
    CONSTRAINT census_state_pkey PRIMARY KEY (ogc_fid)
)

TABLESPACE pg_default;

ALTER TABLE public.census_state
    OWNER to postgres;
-- Index: census_state_geom_idx

-- DROP INDEX public.census_state_geom_idx;

CREATE INDEX census_state_geom_idx
    ON public.census_state USING gist
    (wkb_geometry)
    TABLESPACE pg_default;
-- Index: census_state_wkb_geometry_geom_idx

-- DROP INDEX public.census_state_wkb_geometry_geom_idx;

CREATE INDEX census_state_wkb_geometry_geom_idx
    ON public.census_state USING gist
    (wkb_geometry)
    TABLESPACE pg_default;
