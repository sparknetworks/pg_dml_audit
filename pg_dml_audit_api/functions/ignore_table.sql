CREATE OR REPLACE FUNCTION ignore_table(target_table REGCLASS)
    RETURNS VOID AS $body$
DECLARE
BEGIN
    -- PERFORM take_snapshot(target_table);  -- is it necessary?
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_row ON ' || target_table;
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_stm ON ' || target_table;
END;
$body$
LANGUAGE 'plpgsql';

COMMENT ON FUNCTION ignore_table(REGCLASS) IS $body$
Remove auditing triggers from a table and take a final snapshot.

Arguments:
   target_table:     Table name, schema qualified if not on search_path
$body$;
