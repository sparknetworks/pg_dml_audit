--
-- set up tables and a trigger in schema public for
-- testing dml_audit
--

SET LOG_MIN_MESSAGES TO DEBUG;

SET ROLE edarling;


-- remove all test ddl (the test makes permanent changes to your events-tabel!)

DROP TRIGGER IF EXISTS dml_audit_test_before ON public.dml_audit_test_c;
DROP FUNCTION IF EXISTS public.dml_audit_test_before();
DROP TABLE IF EXISTS public.dml_audit_test_c;
DROP TABLE IF EXISTS public.dml_audit_test_b;
DROP TABLE IF EXISTS public.dml_audit_test_a;


-- set up three tables

CREATE TABLE public.dml_audit_test_a (                     -- plain simple table
  a_text    TEXT PRIMARY KEY,
  a_number  INTEGER,
  a_decimal DECIMAL
);


CREATE TABLE public.dml_audit_test_b (                     -- one with foreign key
  a_serial SERIAL PRIMARY KEY,
  a_text   TEXT NOT NULL  REFERENCES public.dml_audit_test_a (a_text) ON UPDATE CASCADE ON DELETE RESTRICT,
  a_date   DATE,
  a_time   TIME
);


CREATE TABLE public.dml_audit_test_c (                     -- with trigger but  no primary key
  test_key         CHARACTER VARYING(128) NOT NULL,
  test_value       TEXT,
  last_modified    TIMESTAMPTZ,
  last_modified_by NAME                   NOT NULL
);

-- simple trigger function  for testing
CREATE FUNCTION public.dml_audit_test_before()
  RETURNS TRIGGER AS $BODY$
DECLARE
BEGIN
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE'
  THEN
    NEW.last_modified    := clock_timestamp();
    NEW.last_modified_by := current_user;
  END IF;
  RETURN NEW;
END $BODY$ LANGUAGE plpgsql;

-- activate triigger
CREATE TRIGGER dml_audit_test_before BEFORE INSERT OR UPDATE  ON public.dml_audit_test_c
  FOR EACH ROW EXECUTE PROCEDURE public.dml_audit_test_before();

--
-- TODO: add more data types to the test tables
--


