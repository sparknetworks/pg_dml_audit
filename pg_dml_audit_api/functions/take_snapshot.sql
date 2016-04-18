--
-- save full tabel as json-array
set search_path to _pg_dml_audit_api;
--

CREATE OR REPLACE FUNCTION take_snapshot(target_table REGCLASS)
    RETURNS VOID AS $body$
DECLARE
    all_rows   JSON [] := '{}';
    anyrow     RECORD;
    audit_row  _pg_dml_audit_model.events;
    query_text TEXT;

BEGIN
    audit_row.nspname   := (SELECT nspname
                            FROM pg_namespace
                            WHERE OID = (SELECT relnamespace
                                         FROM pg_class
                                         WHERE OID = target_table));
    audit_row.relname   := (SELECT relname
                            FROM pg_class
                            WHERE OID = target_table);
    audit_row.usename   = session_user;
    audit_row.trans_ts  = transaction_timestamp();
    audit_row.trans_id  = txid_current();
    audit_row.trans_sq  = 1;
    audit_row.operation = 'SNAPSHOT';
    audit_row.rowdata   = NULL;

    query_text = 'SELECT *  FROM ' || quote_ident(audit_row.nspname) || '.' || quote_ident(audit_row.relname);
    FOR anyrow IN EXECUTE query_text LOOP
        all_rows =  all_rows || row_to_json(anyrow);
    END LOOP;
    audit_row.rowdata = array_to_json(all_rows);
    RAISE DEBUG 'take a snapshot';
    INSERT INTO _pg_dml_audit_model.events VALUES (audit_row.*);
END;
$body$
LANGUAGE 'plpgsql';

COMMENT ON FUNCTION take_snapshot(REGCLASS) IS $body$
Add one row to the audit events as operation SNAPSHOT saving all rows of the given table into rowdata.
Arguments:
   target_table:     Table name. must be schema qualified if not in  search_path;
Limitations:
   Maximum field size is 1TiByte.
$body$;

