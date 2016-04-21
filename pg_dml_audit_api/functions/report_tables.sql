---
--- report on known tables
---
-- set search_path to _pg_dml_audit_api, pg_catalog;

CREATE OR REPLACE FUNCTION watched_tables()
  RETURNS JSON AS $body$
BEGIN
  RETURN (SELECT to_json(array_agg(DISTINCT nspname || '.' || relname))
          FROM pg_trigger
            JOIN pg_class ON tgrelid = pg_class.oid
            JOIN pg_namespace ON relnamespace = pg_namespace.oid
          WHERE tgname LIKE 'audit_trigger_%'); -- trigger naeme is hardcoced
END $body$ LANGUAGE 'plpgsql';

COMMENT ON FUNCTION watched_tables() IS $$
list all tables wit audit_trigger in place.
$$;


CREATE OR REPLACE FUNCTION active_tables()
  RETURNS TABLE(fullname TEXT, evcount INTEGER, firstev TEXT, lastev TEXT) AS $body$
SELECT
  nspname || '.' || relname                     AS fullname,
  count(nullif(trans_sq != 1, TRUE)) :: INTEGER AS evcount,
  to_char(min(trans_ts), 'yyyy-MM-dd HH:mm')    AS firstev,
  to_char(max(trans_ts), 'yyyy-MM-dd HH:mm')    AS lastev
FROM _pg_dml_audit_model.events
GROUP BY fullname
ORDER BY fullname DESC;
$body$
LANGUAGE 'sql';

COMMENT ON FUNCTION active_tables() IS $$
list tables and some stats from data gathered by audit triggers.
$$;
