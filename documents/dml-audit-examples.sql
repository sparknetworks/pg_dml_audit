--
-- install audit schema with code in dml-audit-test.sql.
-- set up test tables with auditdb-example sql.

SET ROLE ckoch;
SET LOG_MIN_MESSAGES TO DEBUG;
SET search_path TO public, pg_catalog;
SET ROLE edarling;

-- show current status of dml-audit and activate audit on test-tables
-- SELECT * FROM _pg_dml_audit_api.active_tables();
SELECT _pg_dml_audit_api.ignore_table('dml_audit_test_a');
SELECT _pg_dml_audit_api.ignore_table('dml_audit_test_b');
SELECT _pg_dml_audit_api.ignore_table('dml_audit_test_c');

-- TRUNCATE _pg_dml_audit_model.events;
TRUNCATE dml_audit_test_a CASCADE;
TRUNCATE dml_audit_test_b;
TRUNCATE dml_audit_test_c;

INSERT INTO dml_audit_test_a (a_text, a_number, a_decimal) VALUES ('Lorem', 382, 223.93992);
INSERT INTO dml_audit_test_a (a_text, a_number, a_decimal) VALUES ('ipsum', 50, 621);


SELECT _pg_dml_audit_api.watch_table('dml_audit_test_a');
SELECT _pg_dml_audit_api.watch_table('dml_audit_test_b');
SELECT _pg_dml_audit_api.watch_table('dml_audit_test_c');

INSERT INTO dml_audit_test_a (a_text, a_number, a_decimal) VALUES ('dolor', 479, 934.924255611);
INSERT INTO dml_audit_test_a (a_text, a_number, a_decimal) VALUES ('sit', 722, 63.491);
INSERT INTO dml_audit_test_a (a_text, a_number, a_decimal) VALUES ('amet.', 173, 649.2900000);

-- SELECT * FROM _pg_dml_audit_api.report_events() order by trans_ts;

SELECT _pg_dml_audit_api.ignore_table('dml_audit_test_a');

INSERT INTO dml_audit_test_b (a_text, a_date, a_time) VALUES
  ('dolor', '2013-08-08' :: DATE, '12:15' :: TIME),
  ('ipsum', '1945-01-02' :: DATE, '09:57' :: TIME),
  ('Lorem', '1984-06-17' :: DATE, '09:34' :: TIME),
  ('ipsum', '2008-08-05' :: DATE, '11:37' :: TIME),
  ('sit', '1944-07-16' :: DATE, '02:11' :: TIME),
  ('Lorem', '1966-05-13' :: DATE, '09:19' :: TIME),
  ('ipsum', '1986-10-24' :: DATE, '04:42' :: TIME),
  ('amet.', '1961-11-16' :: DATE, '04:48' :: TIME),
  ('sit', '1973-10-22' :: DATE, '18:12' :: TIME),
  ('ipsum', '1934-01-11' :: DATE, '03:55' :: TIME);

-- trunc
TRUNCATE dml_audit_test_b;

INSERT INTO dml_audit_test_b (a_text, a_date, a_time) VALUES
  ('dolor', '2013-08-08' :: DATE, '12:15' :: TIME),
  ('ipsum', '1945-01-02' :: DATE, '09:57' :: TIME),
  ('Lorem', '1984-06-17' :: DATE, '09:34' :: TIME),
  ('ipsum', '2008-08-05' :: DATE, '11:37' :: TIME),
  ('sit', '1944-07-16' :: DATE, '02:11' :: TIME),
  ('Lorem', '1966-05-13' :: DATE, '09:19' :: TIME),
  ('ipsum', '1986-10-24' :: DATE, '04:42' :: TIME),
  ('amet.', '1961-11-16' :: DATE, '04:48' :: TIME),
  ('sit', '1973-10-22' :: DATE, '18:12' :: TIME),
  ('ipsum', '1934-01-11' :: DATE, '03:55' :: TIME);

TRUNCATE public.dml_audit_test_c; -- truncate empty tabel results in event entry with no rows

INSERT INTO public.dml_audit_test_c (test_key, test_value) VALUES
  ('d0ccb29413dc0dda46a58cd68b601349', 'Lorem ipsum dolor sit amet,   '),
  ('306dba61ebc32ab098a9d4adc38a3a7d', 'consectetur adipiscing elit.  '),
  ('498de31b4b9fbe3bdb16247ce8859ef4', 'Sed et tempor erat.           '),
  ('92dcc301ec35ed74eaaf68978fc56b94', 'Nulla posuere urna magna,     '),
  ('e10245b88f65b19a1243aaea98e12441', 'et vestibulum leo interdum eu.'),
  ('d5e9a73ab35d7506510960eb37af563b', 'Pellentesque imperdiet.       '),
  ('d2b4d8a219a32e444b9fc0cce5c1685e', 'consectetur adipiscing elit.  '),
  ('d75b9066192929d86983fc46ccff0125', 'Sed et tempor erat.           '),
  ('614e8c8587e96a751d8b02dfcd602fe2', 'Nulla posuere urna magna,     '),
  ('83c409b15efa02e49774f83bc782d002', 'et vestibulum leo interdum eu.');

UPDATE public.dml_audit_test_c
SET test_key = 'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee'
WHERE test_key = 'd75b9066192929d86983fc46ccff0125';

DELETE FROM public.dml_audit_test_c
WHERE test_key = '92dcc301ec35ed74eaaf68978fc56b94';

DELETE FROM public.dml_audit_test_c;


-- tests
SELECT _pg_dml_audit_api.ignore_table('dml_audit_test_c');
SELECT _pg_dml_audit_api.ignore_table('dml_audit_test_b');

SELECT * FROM _pg_dml_audit_api.active_tables();                                                        -- all test tables inactove
SELECT * FROM _pg_dml_audit_model.events;                                                               -- 50 rows
SELECT * FROM _pg_dml_audit_api.report_events('[2016-04-26,2016-04-26]' :: DATERANGE);                  -- 50 rows
SELECT * FROM _pg_dml_audit_api.report_events('dml_audit_test_c','[2016-04-04,2016-04-04]'::DATERANGE); -- 0 rows
SELECT * FROM _pg_dml_audit_api.report_events();                                                        --  50 rows
SELECT * FROM _pg_dml_audit_api.report_attribute('a_text:ipsum');                                       --  14 rows
SELECT * FROM _pg_dml_audit_api.report_attribute('a_text:ipsum', 'dml_audit_test_a');                   --   2 rows
SELECT * FROM _pg_dml_audit_api.report_attribute('a_date:1973-10-22');                                  --   3 rows
scr;