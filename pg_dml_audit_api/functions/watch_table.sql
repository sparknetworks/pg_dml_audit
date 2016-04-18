--
-- save full tabel as json-array
set search_path to _pg_dml_audit_api;
--

CREATE OR REPLACE FUNCTION watch_table(target_table REGCLASS)
    RETURNS VOID AS $body$
DECLARE
    query_text TEXT;

BEGIN
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_row ON ' || target_table;
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_stm ON ' || target_table;

    query_text = 'CREATE TRIGGER audit_trigger_row AFTER INSERT OR UPDATE OR DELETE ON ' || target_table ||
                 ' FOR EACH ROW EXECUTE PROCEDURE _pg_dml_audit_api.if_modified_func();';
    RAISE DEBUG '%', query_text;
    EXECUTE query_text;

    query_text = 'CREATE TRIGGER audit_trigger_stm BEFORE TRUNCATE ON ' || target_table ||
                 ' FOR EACH STATEMENT EXECUTE PROCEDURE _pg_dml_audit_api.if_modified_func();';
    RAISE DEBUG '%', query_text;
    EXECUTE query_text;

    PERFORM _pg_dml_audit_api.take_snapshot(target_table);

END;
$body$
LANGUAGE 'plpgsql';

COMMENT ON FUNCTION watch_table(REGCLASS) IS $body$
Add auditing triggers to a table and take a initial snapshot.

Arguments:
   target_table:     Table name, schema qualified if not on search_path
$body$;
