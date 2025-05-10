CREATE TABLE apex_bank_account(
account_no NUMBER NOT NULL,
account_name VARCHAR2(255),
balance NUMBER ,
PRIMARY KEY(account_no)
);


CREATE TABLE trx_log (
  trx_id       NUMBER,
  status_text  VARCHAR2(20),
  log_date     DATE DEFAULT SYSDATE
);


CREATE OR REPLACE procedure create_accounts_from_json(p_json IN CLOB) AS
l_count NUMBER;

BEGIN
APEX_JSON.parse(p_json);

l_count := APEX_JSON.GET_COUNT(p_path => '.');


FOR i in 1 .. l_count LOOP

  INSERT INTO apex_bank_account (account_no, account_name, balance)
    VALUES (
      APEX_JSON.GET_VARCHAR2(p_path => '[' || i || '].account_number'),
      APEX_JSON.GET_VARCHAR2(p_path => '[' || i || '].account_name'),
      APEX_JSON.GET_NUMBER(p_path => '[' || i || '].balance')
    );
END LOOP;


END;



CREATE OR REPLACE FUNCTION get_all_accounts_json 
RETURN CLOB 
AS
  l_json CLOB;
  cursor all_apex_bank_account is select * from  apex_bank_account;
BEGIN

  APEX_JSON.INITIALIZE_CLOB_OUTPUT;
  APEX_JSON.OPEN_OBJECT;  -- {
  
 
  APEX_JSON.WRITE('accounts');
  APEX_JSON.OPEN_ARRAY;   -- [

 
  FOR each_account  IN all_apex_bank_account LOOP
    APEX_JSON.OPEN_OBJECT; -- {
    APEX_JSON.WRITE('account_number', each_account.account_no
   );
    APEX_JSON.WRITE('account_name', each_account.account_name);
    APEX_JSON.WRITE('balance', each_account.balance);
    APEX_JSON.CLOSE_OBJECT; -- }
  END LOOP;

  APEX_JSON.CLOSE_ARRAY;  -- ]
  APEX_JSON.CLOSE_OBJECT; -- }


  l_json := APEX_JSON.GET_CLOB_OUTPUT;
  APEX_JSON.FREE_OUTPUT;

  RETURN l_json;



END;


CREATE OR REPLACE PROCEDURE log_response(p_json IN CLOB) IS
 v_trx_inserted  VARCHAR2(2000);
  v_trx_notinserted VARCHAR2(2000);

BEGIN
 APEX_JSON.PARSE(p_json);
  v_trx_inserted := APEX_JSON.GET_VARCHAR2(p_path => 'TrxInserted');
  v_trx_notinserted := APEX_JSON.GET_VARCHAR2(p_path => 'TrxNotInserted');

  FOR rec IN (SELECT REGEXP_SUBSTR(v_trx_inserted, '[^,]+', 1, LEVEL) AS trx_id
FROM dual
CONNECT BY REGEXP_SUBSTR(v_trx_inserted, '[^,]+', 1, LEVEL) IS NOT NULL) LOOP

 INSERT INTO trx_log (trx_id, status_text)
 VALUES (TO_NUMBER(rec.trx_id), 'Inserted');

  END LOOP;

 
  FOR rec IN (SELECT REGEXP_SUBSTR(v_trx_notinserted, '[^,]+', 1, LEVEL) AS trx_id
   FROM dual
 CONNECT BY REGEXP_SUBSTR(v_trx_notinserted, '[^,]+', 1, LEVEL) IS NOT NULL) LOOP


    INSERT INTO trx_log (trx_id, status_text)
    VALUES (TO_NUMBER(rec.trx_id), 'Not Inserted');

  END LOOP;

  COMMIT;


END;



DECLARE

  l_accounts_json CLOB;

  l_input_json CLOB := '[
    {"account_number": "1001", "account_name": "Dero softalliance", "balance": 5000},
    {"account_number": "1002", "account_name": "peter madueke", "balance": 3000}
  ]';

 
  l_log_json CLOB := '{
    "ResponseCode":200,
    "Message":"Success",
    "TotalRows":2,
    "RowsInserted":1,
    "TrxInserted":"1001",
    "RowsNotInserted":1,
    "TrxNotInserted":"1002"
  }';

BEGIN

  create_accounts_from_json(l_input_json);
  DBMS_OUTPUT.PUT_LINE('Accounts inserted.');

  
  l_accounts_json := get_all_accounts_json;
  DBMS_OUTPUT.PUT_LINE('Accounts JSON:');
  DBMS_OUTPUT.PUT_LINE(l_accounts_json);


  log_response(l_log_json);
  DBMS_OUTPUT.PUT_LINE('Transaction logs inserted.');

END;