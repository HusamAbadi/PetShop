-- Create Pet table
-- This table stores information about pets available for adoption
CREATE TABLE Pet (
  pet_id NUMBER PRIMARY KEY, --(primary key)
  pet_name VARCHAR2(50) NOT NULL, --
  pet_type VARCHAR2(50) NOT NULL, -- Type of pet (e.g., Dog, Cat, Rabbit)
  pet_age NUMBER,
  available_for_adoption CHAR(1) DEFAULT 'Y' -- Flag indicating whether the pet is available for adoption (default 'Y')
);

-- Create Customer table
-- This table stores information about potential adopters
CREATE TABLE Customer (
  customer_id NUMBER PRIMARY KEY, --(primary key)
  customer_name VARCHAR2(50) NOT NULL,
  contact_number VARCHAR2(20) NOT NULL
);

-- Create Adoption table
-- This table records successful pet adoptions
CREATE TABLE Adoption (
  adoption_id NUMBER PRIMARY KEY, -- (primary key)
  pet_id NUMBER, -- Foreign key 
  customer_id NUMBER, -- Foreign key
  adoption_date DATE,
  Customer_Discount NUMBER,
  CONSTRAINT fk_pet FOREIGN KEY (pet_id) REFERENCES Pet(pet_id), -- Foreign key constraint for pet_id
  CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES Customer(customer_id) -- Foreign key constraint for customer_id
);


-- Modifying the tables
ALTER table Customer
ADD (number_of_adoption VARCHAR2(20));

Update customer
SET number_of_adoption = 0;

ALTER table Adoption
DROP (Customer_Discount);


-- Insert sample data into Pet table
INSERT INTO Pet (pet_id, pet_name, pet_type, pet_age) VALUES (1, 'Buddy', 'Dog', 2);
INSERT INTO Pet (pet_id, pet_name, pet_type, pet_age) VALUES (2, 'Whiskers', 'Cat', 1);
INSERT INTO Pet (pet_id, pet_name, pet_type, pet_age) VALUES (3, 'Fluffy', 'Rabbit', 3);
INSERT INTO Pet (pet_id, pet_name, pet_type, pet_age) VALUES (4, 'Max', 'Dog', 3);
INSERT INTO Pet (pet_id, pet_name, pet_type, pet_age) VALUES (5, 'Mittens', 'Cat', 2);

-- Insert sample data into Customer table
INSERT INTO Customer (customer_id, customer_name, contact_number) VALUES (1, 'John Doe', '123-456-7890');
INSERT INTO Customer (customer_id, customer_name, contact_number) VALUES (2, 'Jane Smith', '987-654-3210');
INSERT INTO Customer (customer_id, customer_name, contact_number) VALUES (3, 'Alice Johnson', '555-1234-5678');
INSERT INTO Customer (customer_id, customer_name, contact_number) VALUES (4, 'Bob Miller', '555-9876-5432');


-- TRIGGER
-- Create a trigger to increase pet's number of adoption after
CREATE OR REPLACE TRIGGER trgg_PetNumberOfAdoption
AFTER INSERT ON Adoption
FOR EACH ROW
BEGIN
    -- Update pet's number of adoption after each adoption
    UPDATE Customer
    SET number_of_adoption = number_of_adoption + 1
    WHERE Customer_id = :NEW.Customer_id;

END trgg_PetNumberOfAdoption;

-- Trigger Testing
INSERT INTO Adoption (adoption_id, pet_id, customer_id, adoption_date) VALUES (1, 1, 1, TO_DATE('2023-07-30', 'YYYY-MM-DD'));
INSERT INTO Adoption (adoption_id, pet_id, customer_id, adoption_date) VALUES (2, 2, 1, TO_DATE('2023-07-30', 'YYYY-MM-DD'));
INSERT INTO Adoption (adoption_id, pet_id, customer_id, adoption_date) VALUES (3, 3, 2, TO_DATE('2023-07-30', 'YYYY-MM-DD'));
INSERT INTO Adoption (adoption_id, pet_id, customer_id, adoption_date) VALUES (4, 4, 3, TO_DATE('2023-07-30', 'YYYY-MM-DD'));
INSERT INTO Adoption (adoption_id, pet_id, customer_id, adoption_date) VALUES (5, 5, 4, TO_DATE('2023-07-30', 'YYYY-MM-DD'));
INSERT INTO Adoption (adoption_id, pet_id, customer_id, adoption_date) VALUES (6, 1, 4, TO_DATE('2023-07-30', 'YYYY-MM-DD'));

--FUNCTION
-- A function to get the total number of pets adopted by a customer
CREATE OR REPLACE FUNCTION GetTotalPetsAdoptedByCustomer(
    p_customer_id NUMBER
) RETURN NUMBER AS
    v_total_pets NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_total_pets
    FROM Adoption
    WHERE customer_id = p_customer_id;

    RETURN v_total_pets;
END GetTotalPetsAdoptedByCustomer;

-- FUNCTION TESTING
DECLARE
    v_customer_id NUMBER := 1;
    v_result NUMBER;

BEGIN
    v_result := GetTotalPetsAdoptedByCustomer(v_customer_id);

    -- Display the result
    DBMS_OUTPUT.PUT_LINE('The Customer with id: ' || v_customer_id ||
                        ' has ' || v_result || ' Adoption Records' );
END;

-- PROCEDURE
CREATE OR REPLACE PROCEDURE AdoptPet(
  p_pet_id NUMBER,
  p_customer_id NUMBER
)
AS
  v_total_pets_adopted NUMBER; -- Variable to store the total number of adopted pets by the customer
  v_available_for_adoption CHAR(1); -- Variable to store the availability status of the pet
BEGIN
  -- Check if the pet is available for adoption
  SELECT available_for_adoption
  INTO v_available_for_adoption
  FROM Pet
  WHERE pet_id = p_pet_id;

  IF v_available_for_adoption = 'Y' THEN
    -- Insert adoption record
    INSERT INTO Adoption (adoption_id, pet_id, customer_id, adoption_date)
      VALUES (adoption_seq.NEXTVAL, p_pet_id, p_customer_id, SYSDATE);

    -- Update pet availability status
    UPDATE Pet SET available_for_adoption = 'N' WHERE pet_id = p_pet_id;

    -- Calculate the total number of pets adopted by the customer 
    v_total_pets_adopted := GetTotalPetsAdoptedByCustomer(p_customer_id);

    COMMIT;
  ELSE
    DBMS_OUTPUT.PUT_LINE('Pet is not available for adoption.');
  END IF;
END AdoptPet;

DECLARE
    v_pet_id NUMBER := 1; -- Change to the desired pet ID
    v_customer_id NUMBER := 1; -- Change to the desired customer ID
BEGIN
    -- Call the AdoptPet procedure to adopt a pet
    AdoptPet(v_pet_id, v_customer_id);
END;


--Select Statements
--Retrieve a list of customers who adopted more than one pet:
SELECT
    c.customer_id,
    c.customer_name,
    c.contact_number,
    COUNT(a.pet_id) AS pets_adopted_count
FROM
    Customer c
JOIN
    Adoption a ON c.customer_id = a.customer_id
GROUP BY
    c.customer_id, c.customer_name, c.contact_number
HAVING
    COUNT(a.pet_id) > 1;

--List all pets that are available for adoption and their corresponding customer information if they have been adopted:
SQL
SELECT p.pet_name, p.pet_type, p.pet_age, c.customer_name, c.contact_number
FROM Pet p
JOIN Adoption a ON p.pet_id = a.pet_id
JOIN Customer c ON a.customer_id = c.customer_id
WHERE a.adoption_date IS NOT NULL AND p.available_for_adoption = 'Y';

--List the customer with the most adoptions and the number of times they have adopted:
SQL
SELECT c.customer_name, COUNT(DISTINCT a.adoption_id) AS adoption_count
FROM Customer c
JOIN Adoption a ON c.customer_id = a.customer_id
GROUP BY c.customer_name
ORDER BY adoption_count DESC;


-- Resetting DB

--Delete PROCEDURE, FUNCTION, TRIGGER
DROP PROCEDURE AdoptPet;
DROP FUNCTION GetTotalPetsAdoptedByCustomer;
DROP TRIGGER trgg_PetNumberOfAdoption;


-- Delete data from tables
TRUNCATE TABLE Pet;
TRUNCATE TABLE Customer;
TRUNCATE TABLE Adoption;

-- Drop tables with CASCADE CONSTRAINTS
DROP TABLE Pet CASCADE CONSTRAINTS;
DROP TABLE Customer CASCADE CONSTRAINTS;
DROP TABLE Adoption CASCADE CONSTRAINTS;



