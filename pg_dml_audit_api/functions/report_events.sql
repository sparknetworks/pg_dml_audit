--
-- return selected rows from events-table as tabel or json object
set search_path to _pg_dml_audit_api, pg_catalog;
--

CREATE OR REPLACE FUNCTION report_events_table(tablename TEXT DEFAULT NULL, timeframe DATERANGE DEFAULT NULL)
  RETURNS setof _pg_dml_audit_model.events AS $body$
DECLARE
  query_text TEXT;
  event_row  _pg_dml_audit_model.events;
  l_nspname TEXT;
  l_relname TEXT;
  retrow RECORD;
BEGIN
  query_text := 'SELECT * FROM _pg_dml_audit_model.events WHERE TRUE ';

  IF timeframe IS NOT NULL THEN
      query_text := query_text || ' AND trans_ts::date <@  ' || quote_literal(timeframe) || '::daterange ';
  END IF;

  IF tablename IS NOT NULL THEN
    l_nspname := (SELECT nspname
                  FROM pg_namespace
                  WHERE OID = (SELECT relnamespace
                               FROM pg_class
                               WHERE OID = tablename::REGCLASS));
    l_relname := (SELECT relname
                  FROM pg_class
                  WHERE OID = tablename::REGCLASS);

    query_text := query_text || 'AND _pg_dml_audit_model.events.nspname = ' || quote_literal(l_nspname) || ' AND _pg_dml_audit_model.events.relname =  ' || quote_literal(l_relname);
  END IF;

  RETURN query execute query_text || ' order by trans_ts desc,  trans_id asc,  trans_sq asc';

END;
$body$
LANGUAGE 'plpgsql';

COMMENT ON FUNCTION report_events_table(TEXT, DATERANGE) IS $$
Return (filtered) audit-trail as table.

Arguments:
   tablename:     text with schema if ambiguos
   timeframe:     limit query to given range of dates
$$;


DROP FUNCTION report_events_table( timeframe DATERANGE, tablename TEXT);
CREATE OR REPLACE FUNCTION report_events_table( timeframe DATERANGE, tablename TEXT DEFAULT NULL)
  RETURNS setof _pg_dml_audit_model.events AS $body$

  SELECT * from _pg_dml_audit_api.report_events_table(tablename, timeframe)

$body$
LANGUAGE 'sql';

COMMENT ON FUNCTION report_events_table(DATERANGE, TEXT) IS $$
Reverse arguments wrapper for report_events_table(TEXT, DATERANGE)
$$;


CREATE OR REPLACE FUNCTION report_events_json(tablename TEXT DEFAULT NULL, timeframe DATERANGE DEFAULT NULL)
  RETURNS JSON AS $body$
DECLARE
  event_row  _pg_dml_audit_model.events;
  result_set  JSON [] := '{}';
BEGIN
  FOR event_row IN select * from _pg_dml_audit_api.report_events_table(tablename, timeframe) LOOP
    result_set =  result_set || to_json(event_row);
  END LOOP;
  RETURN to_json(result_set);
END;
$body$
LANGUAGE 'plpgsql';

COMMENT ON FUNCTION report_events_json(TEXT, DATERANGE) IS $$
Return result of report_events_table(TEXT, DATERANGE) as json object
$$;


DROP FUNCTION report_events_json( timeframe DATERANGE, tablename TEXT);
CREATE OR REPLACE FUNCTION report_events_json( timeframe DATERANGE, tablename TEXT DEFAULT NULL)
  RETURNS JSON AS $body$

  SELECT * from _pg_dml_audit_api.report_events_json(tablename, timeframe)

$body$
LANGUAGE 'sql';

COMMENT ON FUNCTION report_events_json(DATERANGE, TEXT) IS $$
Reverse arguments wrapper for report_events_json(TEXT, DATERANGE)
$$;
