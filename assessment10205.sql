CREATE TABLE app_tokens(
system_name VARCHAR2(50),
token VARCHAR2(50),
expiry_dt DATE
);


INSERT INTO app_tokens(system_name, token, expiry_dt)VALUES('A', 'TOKEN123A', SYSDATE +3);
INSERT INTO app_tokens(system_name, token, expiry_dt)VALUES('B', 'TOKEN123B', SYSDATE + 5);


CREATE OR REPLACE PROCEDURE validate_token(
    p_token IN VARCHAR2,
    token_status OUT VARCHAR2
) AS
checker NUMBER := 0;
BEGIN
  select count(token) into checker from app_tokens where token = p_token;
  if checker = 0 THEN
    token_status := 'Invalid Token';
  ELSE 
  token_status := 'Authenticated';
  END IF;

EXCEPTION
WHEN OTHERS THEN
DBMS_OUTPUT.PUT_LINE('Error is ' || SQLERRM);
END;


-- test procedure
DECLARE
  v_test VARCHAR2(50);
BEGIN
 VALIDATE_TOKEN('TOKEN123A', v_test);
 DBMS_OUTPUT.PUT_LINE(v_test);
 EXCEPTION
WHEN OTHERS THEN
DBMS_OUTPUT.PUT_LINE('Error is ' || SQLERRM);
END;


CREATE OR REPLACE PROCEDURE REPLACE_OLD_TOKENS(
    new_token app_tokens.token%TYPE
) AS

BEGIN
UPDATE app_tokens 
SET token = new_token
where  expiry_dt > SYSDATE; 

EXCEPTION 
WHEN OTHERS THEN
DBMS_OUTPUT.PUT_LINE('Error is' ||SQLERRM );
END;







