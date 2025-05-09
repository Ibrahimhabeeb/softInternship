CREATE TABLE Accounts (
 account_id NUMBER NOT NULL,

balance NUMBER DEFAULT 0,
account_no VARCHAR2(60) NOT NULL,
 PRIMARY KEY(account_id)
);


CREATE SEQUENCE accounts_seq 
START WITH 1
INCREMENT BY 1;





CREATE OR REPLACE  TRIGGER accounts_trig
BEFORE INSERT ON Accounts
FOR EACH ROW
BEGIN

:NEW.account_id := accounts_seq.NEXTVAL;


END;


BEGIN 

INSERT INTO Accounts (balance, account_no ) VALUES(40000, 'Account B');
INSERT INTO Accounts (balance, account_no) VALUES(60000, 'Account C');
INSERT INTO Accounts (balance, account_no ) VALUES(80000, 'Account D');
COMMIT;
END;

select * from accounts;

-- 1. Procedure – Fund Transfer (20 Marks)
-- Write a procedure transfer_funds(p_from_acct IN VARCHAR2, p_to_acct IN VARCHAR2, p_amount IN
-- NUMBER) to transfer funds between two accounts. Ensure: - Validation: Both accounts exist. - Sufficient balance. - Atomic transaction 


CREATE OR REPLACE PROCEDURE transfer_funds(
p_from_account IN VARCHAR2,
p_to_account IN VARCHAR2,
p_amount IN NUMBER
) AS
sender_balance NUMBER;
insuf_balance EXCEPTION;
account_not_exist EXCEPTION;
checker NUMBER;
BEGIN

SELECT count(*)  into checker FROM Accounts
where account_no IN (p_from_account, p_to_account);

IF checker != 2 THEN 
RAISE account_not_exist;
END IF;




select balance into sender_balance  from Accounts
 where account_no = p_from_account;

 IF p_amount > sender_balance THEN

 RAISE insuf_balance;

 ELSE   
   UPDATE Accounts
   set balance = balance - p_amount
   where account_no = p_from_account;
   UPDATE Accounts
   set balance = balance + p_amount
   where account_no = p_to_account;
   COMMIT;

END IF;

EXCEPTION
WHEN account_not_exist THEN
DBMS_OUTPUT.PUT_LINE('Account doesnt exist');

WHEN insuf_balance THEN
DBMS_OUTPUT.PUT_LINE('Insufficient balance');

WHEN OTHERS THEN
DBMS_OUTPUT.PUT_LINE('Error occured ' || sqlerrm);
ROLLBACK;
END;



-- 2. Function – Account Summary (10 Marks)
-- Create a function get_account_summary(p_acct_no IN VARCHAR2) RETURN VARCHAR2 that returns a string
-- summary of account name and balance.

CREATE OR REPLACE FUNCTION get_account_summary(p_acct_no IN VARCHAR2) RETURN VARCHAR2
AS

p_account_summary VARCHAR2(255);
BEGIN

   select account_no || ' has balance ' || balance  into p_account_summary from Accounts
   where account_no = p_acct_no;
   COMMIT;

RETURN p_account_summary;

EXCEPTION

WHEN NO_DATA_FOUND THEN
DBMS_OUTPUT.PUT_LINE('NO DATA FOUND');

WHEN OTHERS THEN

DBMS_OUTPUT.PUT_LINE('Error occured' || SQLERRM);
ROLLBACK;
END;


-- 3. Cursor – Calculate Interest (15 Marks)
-- Use an explicit cursor to iterate through accounts and increase their balance by 5% interest. Use a FOR LOOP
-- and UPDATE statement

DECLARE

cursor all_accounts  is select * from Accounts;
BEGIN

for each_account in all_accounts  LOOP

UPDATE accounts
SET balance = balance + (5/100);

END LOOP;

END;


-- 4. Trigger – Audit Transactions (20 Marks)
-- Write a trigger trg_audit_transaction that captures any UPDATE on balance and inserts into a table
-- account_audit_log(account_number, old_balance, new_balance, modified_on)

CREATE TABLE account_audit_log(
account_number VARCHAR2(255), 
old_balance  NUMBER,
new_balance NUMBER, 
modified_on  DATE DEFAULT SYSDATE,
PRIMARY KEY (account_number)
);




CREATE OR REPLACE TRIGGER trg_audit_transaction 
AFTER UPDATE OF BALANCE ON Accounts
FOR EACH ROW
BEGIN
  

  INSERT INTO account_audit_log (account_number, old_balance, new_balance) VALUES(:NEW.account_no, :OLD.balance, :NEW.balance);


EXCEPTION

WHEN OTHERS THEN 

DBMS_OUTPUT.PUT_LINE('Error occured' || sqlerrm);


END;


-- 5. Exception Handling – Minimum Balance Check (15 Marks)
-- Write a procedure withdraw(p_account_no IN VARCHAR2, p_amount IN NUMBER) that throws a custom
-- exception if the remaining balance goes below 1000.
CREATE OR REPLACE  PROCEDURE withdraw(
p_account_no IN VARCHAR2, 
p_amount IN NUMBER) IS 
lt_thousand EXCEPTION;
v_balance NUMBER;
BEGIN
UPDATE Accounts
SET balance = balance - p_amount
where account_no = p_account_no;
COMMIT;

select balance  into v_balance from Accounts
where account_no = p_account_no;

IF v_balance < 1000 THEN
RAISE lt_thousand;
END IF;

EXCEPTION

when NO_DATA_FOUND THEN 
DBMS_OUTPUT.PUT_LINE('NO data found');
WHEN lt_thousand THEN
DBMS_OUTPUT.PUT_LINE('BALANCE IS less than 1000');

when others then 
DBMS_OUTPUT.PUT_LINE('Error occured' || sqlerrm);
ROLLBACK;
END;



-- TESTS

DECLARE 

p_account_summary VARCHAR2(255);
BEGIN
-- withdraw(
-- 'Account B',
-- 39500);

p_account_summary := get_account_summary('Account B');

transfer_funds(
'Account D',
'Account C',
3000
) ;
DBMS_OUTPUT.PUT_LINE(p_account_summary);


END;




-- -- 6) CONCEPTUAL QUESTIONS
-- difference between %ROWTYPE and %TYPE

-- %rowtype implements the type of each column in a record  e.g.  accounts%rowtype

-- %type  implements only the type of a specific column in a database table   e.g. accounts.account_id%type

-- allows to do changes in a separate  transaction without affecting the main session transaction.

-- savepoint is a point in a transaction that you can roll back to

-- rollback to a savepoint  will rollback a transaction back to a specified savepoint wihtout termination


-- -- in | out vs in out parameters

--  indicates whether the parameter passes data to a procedure,function (IN) or  returns data from it (OUT)  or does both (IN OUT)

