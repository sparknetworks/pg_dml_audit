--
--
-- SET SEARCH_PATH TO audit;

CREATE OR REPLACE FUNCTION watch_table(target_table REGCLASS)
    RETURNS VOID AS $body$
DECLARE
    query_text TEXT;

BEGIN
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_row ON ' || target_table;
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_stm ON ' || target_table;

    query_text = 'CREATE TRIGGER audit_trigger_row AFTER INSERT OR UPDATE OR DELETE ON ' || target_table ||
                 ' FOR EACH ROW EXECUTE PROCEDURE if_modified_func();';
    RAISE NOTICE '%', query_text;
    EXECUTE query_text;

    query_text = 'CREATE TRIGGER audit_trigger_stm BEFORE TRUNCATE ON ' || target_table ||
                 ' FOR EACH STATEMENT EXECUTE PROCEDURE if_modified_func();';
    RAISE NOTICE '%', query_text;
    EXECUTE query_text;

    PERFORM take_snapshot(target_table);

END;
$body$
LANGUAGE 'plpgsql';

COMMENT ON FUNCTION watch_table(REGCLASS) IS $body$
Add auditing triggers to a table and take a initial snapshot.

Arguments:
   target_table:     Table name, schema qualified if not on search_path
$body$;

