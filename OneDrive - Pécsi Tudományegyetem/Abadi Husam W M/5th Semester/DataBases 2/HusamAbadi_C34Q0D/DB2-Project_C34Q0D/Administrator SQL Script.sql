-- Create The Manager User and The Staff Member User
CREATE USER manager IDENTIFIED BY MGR ACCOUNT UNLOCK;


-- Manage Privileges to the manager
GRANT ALL PRIVILEGES TO manager;
REVOKE REFERENCES ON PET FROM manager;

ALTER USER manager QUOTA 100M ON USERS;


-- Drop user
DROP USER manager CASCADE;
