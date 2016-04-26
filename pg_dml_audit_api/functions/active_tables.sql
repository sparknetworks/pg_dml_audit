--
-- report on known tables
-- set search_path to _pg_dml_audit_api, pg_catalog;
--


CREATE OR REPLACE FUNCTION active_tables()
  RETURNS TABLE(tableident TEXT, audit_active BOOL, evcount INTEGER, firstev TEXT, lastev TEXT) AS $body$

WITH on_record AS (
    SELECT
      nspname || '.' || relname                     AS tableident,
      count(nullif(trans_sq != 1, TRUE)) :: INTEGER AS evcount,
      to_char(min(trans_ts), 'yyyy-MM-dd HH:mm')    AS firstev,
      to_char(max(trans_ts), 'yyyy-MM-dd HH:mm')    AS lastev
    FROM _pg_dml_audit_model.events
    GROUP BY tableident
), on_trigger AS ( SELECT DISTINCT
                     nspname || '.' || relname AS tableident,
                     TRUE                      AS audit_active
                   FROM pg_trigger
                     JOIN pg_class ON tgrelid = pg_class.oid
                     JOIN pg_namespace ON relnamespace = pg_namespace.oid
                   WHERE tgname LIKE 'audit_trigger_%'
)
SELECT
  tableident,
  coalesce(audit_active, FALSE),
  COALESCE(evcount, 0),
  COALESCE(firstev, ''),
  COALESCE(lastev, '')
FROM on_record
  FULL JOIN on_trigger USING (tableident);


$body$
LANGUAGE 'sql';

COMMENT ON FUNCTION active_tables() IS $$
list tables with audit status and some stats from data gathered by audit triggers.
$$;
