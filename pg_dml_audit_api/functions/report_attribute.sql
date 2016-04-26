--
-- select events based on recorded changes
--  set search_path to _pg_dml_audit_api, pg_catalog;
--

CREATE OR REPLACE FUNCTION report_attribute(kvlist    TEXT, tableident TEXT DEFAULT NULL,
                                            timeframe DATERANGE DEFAULT NULL)
  RETURNS SETOF _pg_dml_audit_model.events AS $body$
DECLARE
  query_text TEXT;
  event_row  _pg_dml_audit_model.events;
  l_nspname  TEXT;
  l_relname  TEXT;
BEGIN

  query_text := 'WITH subq AS (
                   SELECT nspname, relname, usename, trans_ts, trans_id, trans_sq, operation,
                          jsonb_array_elements(rowdata) AS singlerow
                   FROM _pg_dml_audit_model.events WHERE TRUE ';

  IF timeframe IS NOT NULL
  THEN
    query_text := query_text || ' AND trans_ts::date <@  ' || quote_literal(timeframe) || '::daterange ';
  END IF;

  IF tableident IS NOT NULL
  THEN
    IF strpos(tableident, '.') > 0
    THEN
      l_nspname := split_part(tableident, '.', 1);
      l_relname := split_part(tableident, '.', 2);
    ELSE
      l_nspname := 'public';
      l_relname := tableident;
    END IF;
    query_text := query_text || 'AND nspname = ' || quote_literal(l_nspname) || ' AND events.relname =  '
                  || quote_literal(l_relname);
  END IF;

  query_text := query_text || ') SELECT nspname, relname, usename, trans_ts, trans_id, trans_sq, operation' ||
                ', singlerow from subq WHERE TRUE ';

  IF kvlist IS NOT NULL
  THEN
    query_text := query_text || ' AND ( singlerow @> '
                  || quote_literal(json_build_object(split_part(kvlist, ':', 1), split_part(kvlist, ':', 2)))
                  || '::jsonb) ';
  END IF;

  RAISE DEBUG '%', query_text;
  RETURN QUERY EXECUTE query_text || ' order by trans_ts desc,  trans_id asc,  trans_sq asc';

END $body$ LANGUAGE 'plpgsql';

COMMENT ON FUNCTION report_attribute(TEXT, TEXT, DATERANGE) IS $$
Return changes filtered by Column/Value pairs.
Result is a tabel with all changes on rows containing the given pair of
column name and field value.

Arguments:
   attrdetail:    Columns and Value as single string divded by a colon like 'DynProp:TAX_FREE' (case sensitive)
   tablename:     name of table in question or schema and table divided by a dot like 'ed_data.my_table'
   timeframe:     limit query to given range of dates
$$;

