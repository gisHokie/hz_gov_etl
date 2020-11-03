-- Table: public.unemploy

-- DROP TABLE public.unemploy;

CREATE TABLE public.unemploy
(
    admin_type character varying COLLATE pg_catalog."default",
    admin_name character varying COLLATE pg_catalog."default",
    unemploy_value numeric,
    unemploy_rate numeric,
    unemploy_year character varying COLLATE pg_catalog."default",
    unemploy_month character varying COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE public.unemploy
    OWNER to postgres;
