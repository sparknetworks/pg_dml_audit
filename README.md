# pg_dml_audit

database audit addon to pgpm


## requirements

### explicit stated and extracted from use-cases

1. command to return a state of audited table at specific time
1. command to turn off/on table auditing for a specific table
1. track identity of user performing the change (who did it)
1. track reasons for changes performed (why -- to what ticket is it linked)
1. track time when change took place (when)
1. save state of coniguration before the change (how was it before)
1. allow users (developers) to see the development of a table over time
1. allow users (developers) to see the development of a specific configuration(*) over time

### preconditions and implicit assumptions

1. tables are relatively small
1. rows within these tables are effectively configuration values
1. must work without changing application code
1. must work with postgresql 9.4+
1. audit data must be self-contained (allow archived audit trails)
1. configuratins may comprise multiple rows in multiple tables
1. report current state of audit system
1. configuration updates occure in relatively low frequency


### functionality of first iteration 


#### watch_table() / ignore_table()

Auditing is activated and deactivate per table with this functions returning nothting on success.

`void watch_table(REGCLASS)` adds triggers to the given table and takes a snapshot of the current state. From now on every change to tis tabes is recorded.

`void ignore_table(REGCLASS)` removes this triggers. Already gathered change information is untouched and available for report.

exampels:
    select _pg_dml_audit_api.watch_table('edarling_app_data.psytest_configuration');
    select _pg_dml_audit_api.watch_table('affinitas_general_data.general_config');
    select _pg_dml_audit_api.watch_table('edarling_app_data.general_config');

 
- There is no safeguard on watch_table(). Make sure preconditions are met. 
- ignore_table() is not recorded as it should be.
- the trigger name is hardcoded to audit_trigger_row / audit_trigger_stm

  
#### active_tables()

This function scans data and active trigger to report for the current state of the audit system. 
- *tableident* names the table
- *audit_active* is true for all tables with audit_triggers set
- *evcount* is the number of change events recorded for the table 
- *firstev* timestamp of oldest entry for the given table
- *lastev* timestamp of latest entry/change for the given table


    # select * from _pg_dml_audit_api.active_tables();

                   tableident               | audit_active | evcount |     firstev      |      lastev      
    ----------------------------------------+--------------+---------+------------------+------------------
    edarling_app_data.psytest_configuration | t            |       1 | 2016-04-29 01:04 | 2016-04-29 01:04
    affinitas_general_data.general_config   | t            |       1 | 2016-04-29 11:04 | 2016-04-29 11:04
    edarling_app_data.general_config        | t            |       1 | 2016-04-29 01:04 | 2016-04-29 01:04
    edarling_newsletter.newsletter_types    | f            |       4 | 2016-04-26 03:04 | 2016-04-26 03:04


#### report_events()

Search for events based on timestamps and tablenames is doen with *report_events*.
Called without parameters it returns all recorded events; usage of some limits is recommended.
More of interest is selecting by  date or tablename. 
 
 
    SELECT * FROM _pg_dml_audit_api.report_events() limit 7;
    SELECT * FROM _pg_dml_audit_api.report_events('edarling_newsletter.newsletter_types', '[2016-04-26,2016-04-26]'::daterange);
    SELECT * FROM _pg_dml_audit_api.report_events('[2016-04-24,2016-04-29]'::daterange, 'dml_audit_test_b'  );
    SELECT * FROM _pg_dml_audit_api.report_events('[2016-04-24,2016-04-27]'::daterange, 'edarling_newsletter.newsletter_types') limit 7;


- when the schema is not 'public' you must provide the tabelname including namespace
- returns raw events-data including rowdata 


#### report_attribute()

When using report attribute also rowdata is searched for the give key-value pair. You siply 
prepend a string wit a simplified key-value pair to the parameters of report_events():
 
SELECT * FROM _pg_dml_audit_api.report_attribute('a_text:ipsum');
SELECT * FROM _pg_dml_audit_api.report_attribute('a_text:ipsum', 'dml_audit_test_a');   
SELECT * FROM _pg_dml_audit_api.report_attribute('a_date:1973-10-22');                  

 

### Data structure

#### events table


    CREATE TABLE IF NOT EXISTS events (
      nspname   TEXT        NOT NULL,
      relname   TEXT        NOT NULL,
      usename   TEXT        NOT NULL,
      trans_ts  TIMESTAMPTZ NOT NULL,
      trans_id  BIGINT      NOT NULL,
      trans_sq  INTEGER     NOT NULL,
      operation op_types    NOT NULL,
      rowdata   JSONB,
      CONSTRAINT events_pkey PRIMARY KEY (trans_ts, trans_id, trans_sq)
    );
    
    REVOKE ALL ON events FROM PUBLIC;
    
    COMMENT ON TABLE  events IS 'History of auditable actions on audited tables, from audit.if_modified_func()';
    COMMENT ON COLUMN events.nspname   IS 'database schema name of the audited table';
    COMMENT ON COLUMN events.relname   IS 'name of the table changed by this event';
    COMMENT ON COLUMN events.usename   IS 'Session user whose statement caused the audited event';
    COMMENT ON COLUMN events.trans_ts  IS 'Transaction timestamp for tx in which audited event occurred (PK)';
    COMMENT ON COLUMN events.trans_id  IS 'Identifier of transaction that made the change. (PK)';
    COMMENT ON COLUMN events.trans_sq  IS 'make multi-row-transactions unique. (PK)';
    COMMENT ON COLUMN events.operation IS 'event operation of type audit.op_types';
    COMMENT ON COLUMN events.rowdata   IS 'Old and new rows affected by this event';




#### trigger



### Options for next Iteration