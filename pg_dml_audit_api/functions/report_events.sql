--
-- return selected rows from events-table as tabel or json object
-- SET search_path TO _pg_dml_audit_api, pg_catalog;
--

CREATE OR REPLACE FUNCTION report_events(tableident REGCLASS DEFAULT NULL, timeframe DATERANGE DEFAULT NULL)
  RETURNS SETOF _pg_dml_audit_model.events AS $body$
DECLARE
  query_text TEXT;
  event_row  _pg_dml_audit_model.events;
  l_nspname  TEXT;
  l_relname  TEXT;
  retrow     RECORD;
BEGIN
  query_text := 'SELECT * FROM _pg_dml_audit_model.events WHERE TRUE ';

  IF timeframe IS NOT NULL
  THEN
    query_text := query_text || ' AND trans_ts::date <@  ' || quote_literal(timeframe) || '::daterange ';
  END IF;

  IF tableident IS NOT NULL
  THEN
    l_nspname := (SELECT nspname
                  FROM pg_namespace
                  WHERE OID = (SELECT relnamespace
                               FROM pg_class
                               WHERE OID = tableident::REGCLASS));
    l_relname := (SELECT relname
                  FROM pg_class
                  WHERE OID = tableident::REGCLASS);

    query_text :=query_text || 'AND _pg_dml_audit_model.events.nspname = ' || quote_literal(l_nspname) ||
                 ' AND _pg_dml_audit_model.events.relname =  ' || quote_literal(l_relname);
  END IF;

  RETURN QUERY EXECUTE query_text || ' order by trans_ts desc,  trans_id asc,  trans_sq asc';

END;
$body$
LANGUAGE 'plpgsql';

COMMENT ON FUNCTION report_events(REGCLASS, DATERANGE) IS $$
Return (filtered) audit-trail as table.

Arguments:
   tablename:     text with schema if ambiguos
   timeframe:     limit query to given range of dates
$$;


CREATE OR REPLACE FUNCTION report_events(timeframe DATERANGE, tableident REGCLASS DEFAULT NULL)
  RETURNS SETOF _pg_dml_audit_model.events AS $body$

SELECT *
FROM _pg_dml_audit_api.report_events(tableident, timeframe)

$body$
LANGUAGE 'sql';

COMMENT ON FUNCTION report_events(DATERANGE, REGCLASS) IS $$
Reverse arguments wrapper for report_events(TEXT, DATERANGE)
$$;


