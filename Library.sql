mysql> CREATE DATABASE LibraryDB;
Query OK, 1 row affected (0.01 sec)

mysql> USE LibraryDB;
Database changed
mysql> SHOW TABLES;
Empty set (0.04 sec)

mysql> ;
ERROR:
No query specified

mysql> -- ==============================================
mysql> -- STEP 1: Create Database
mysql> -- ==============================================
mysql> DROP DATABASE IF EXISTS LibraryDB;
Query OK, 0 rows affected (0.04 sec)

mysql> CREATE DATABASE LibraryDB;
Query OK, 1 row affected (0.01 sec)

mysql> USE LibraryDB;
Database changed
mysql>
mysql> -- ==============================================
mysql> -- STEP 2: Create Tables
mysql> -- ==============================================
mysql> -- Authors table
mysql> CREATE TABLE Authors (
    ->     AuthorID INT AUTO_INCREMENT PRIMARY KEY,
    ->     Name VARCHAR(100) NOT NULL,
    ->     Country VARCHAR(50)
    -> );
Query OK, 0 rows affected (0.03 sec)

mysql>
mysql> -- Books table
mysql> CREATE TABLE Books (
    ->     BookID INT AUTO_INCREMENT PRIMARY KEY,
    ->     Title VARCHAR(150) NOT NULL,
    ->     AuthorID INT NOT NULL,
    ->     Publisher VARCHAR(100),
    ->     PubYear YEAR,
    ->     TotalCopies INT NOT NULL,
    ->     AvailableCopies INT NOT NULL,
    ->     FOREIGN KEY (AuthorID) REFERENCES Authors(AuthorID)
    -> );
Query OK, 0 rows affected (0.05 sec)

mysql>
mysql> -- Members table
mysql> CREATE TABLE Members (
    ->     MemberID INT AUTO_INCREMENT PRIMARY KEY,
    ->     Name VARCHAR(100) NOT NULL,
    ->     Email VARCHAR(120) UNIQUE,
    ->     Phone VARCHAR(15),
    ->     JoinDate DATE DEFAULT (CURRENT_DATE)
    -> );
Query OK, 0 rows affected (0.05 sec)

mysql>
mysql> -- Borrowings table
mysql> CREATE TABLE Borrowings (
    ->     BorrowID INT AUTO_INCREMENT PRIMARY KEY,
    ->     BookID INT NOT NULL,
    ->     MemberID INT NOT NULL,
    ->     BorrowDate DATE DEFAULT (CURRENT_DATE),
    ->     DueDate DATE GENERATED ALWAYS AS (BorrowDate + INTERVAL 14 DAY) STORED,
    ->     ReturnDate DATE NULL,
    ->     Status ENUM('Borrowed','Returned') DEFAULT 'Borrowed',
    ->     FOREIGN KEY (BookID) REFERENCES Books(BookID),
    ->     FOREIGN KEY (MemberID) REFERENCES Members(MemberID)
    -> );
Query OK, 0 rows affected (0.06 sec)

mysql>
mysql> -- ==============================================
mysql> -- STEP 3: Insert Sample Data
mysql> -- ==============================================
mysql> -- Authors
mysql> INSERT INTO Authors (Name, Country) VALUES
    -> ('J.K. Rowling','UK'),
    -> ('Chetan Bhagat','India'),
    -> ('George Orwell','UK');
Query OK, 3 rows affected (0.01 sec)
Records: 3  Duplicates: 0  Warnings: 0

mysql>
mysql> -- Books
mysql> INSERT INTO Books (Title, AuthorID, Publisher, PubYear, TotalCopies, AvailableCopies) VALUES
    -> ('Harry Potter', 1, 'Bloomsbury', 1997, 5, 5),
    -> ('Five Point Someone', 2, 'Rupa', 2004, 3, 3),
    -> ('1984', 3, 'Secker & Warburg', 1949, 4, 4);
Query OK, 3 rows affected (0.01 sec)
Records: 3  Duplicates: 0  Warnings: 0

mysql>
mysql> -- Members
mysql> INSERT INTO Members (Name, Email, Phone) VALUES
    -> ('Rahul Sharma','rahul@email.com','9876543210'),
    -> ('Priya Patel','priya@email.com','9876501234');
Query OK, 2 rows affected (0.01 sec)
Records: 2  Duplicates: 0  Warnings: 0

mysql>
mysql> -- Borrowings
mysql> INSERT INTO Borrowings (BookID, MemberID, BorrowDate, ReturnDate, Status) VALUES
    -> (1, 1, '2024-03-01', '2024-03-15', 'Returned'),
    -> (3, 2, '2024-03-05', NULL, 'Borrowed');
Query OK, 2 rows affected (0.01 sec)
Records: 2  Duplicates: 0  Warnings: 0

mysql>
mysql> -- ==============================================
mysql> -- STEP 4: Triggers (Auto-update AvailableCopies)
mysql> -- ==============================================
mysql> DELIMITER $$
mysql>
mysql> -- Before borrowing: check availability
mysql> CREATE TRIGGER trg_before_borrow
    -> BEFORE INSERT ON Borrowings
    -> FOR EACH ROW
    -> BEGIN
    ->   DECLARE avail INT;
    ->   SELECT AvailableCopies INTO avail FROM Books WHERE BookID = NEW.BookID;
    ->   IF avail <= 0 THEN
    ->     SIGNAL SQLSTATE '45000'
    ->     SET MESSAGE_TEXT = 'No copies available to borrow';
    ->   END IF;
    -> END$$
Query OK, 0 rows affected (0.01 sec)

mysql>
mysql> -- After borrowing: decrease available copies
mysql> CREATE TRIGGER trg_after_borrow
    -> AFTER INSERT ON Borrowings
    -> FOR EACH ROW
    -> BEGIN
    ->   UPDATE Books SET AvailableCopies = AvailableCopies - 1 WHERE BookID = NEW.BookID;
    -> END$$
Query OK, 0 rows affected (0.01 sec)

mysql>
mysql> -- After returning: increase available copies
mysql> CREATE TRIGGER trg_after_return
    -> AFTER UPDATE ON Borrowings
    -> FOR EACH ROW
    -> BEGIN
    ->   IF OLD.Status = 'Borrowed' AND NEW.Status = 'Returned' THEN
    ->     UPDATE Books SET AvailableCopies = AvailableCopies + 1 WHERE BookID = NEW.BookID;
    ->   END IF;
    -> END$$
Query OK, 0 rows affected (0.01 sec)

mysql>
mysql> DELIMITER ;
mysql>
mysql> -- ==============================================
mysql> -- STEP 5: Stored Procedures
mysql> -- ==============================================
mysql> DELIMITER $$
mysql>
mysql> -- Borrow a book
mysql> CREATE PROCEDURE sp_borrow_book(IN p_member INT, IN p_book INT)
    -> BEGIN
    ->   INSERT INTO Borrowings (BookID, MemberID) VALUES (p_book, p_member);
    -> END$$
Query OK, 0 rows affected (0.01 sec)

mysql>
mysql> -- Return a book
mysql> CREATE PROCEDURE sp_return_book(IN p_borrow INT)
    -> BEGIN
    ->   UPDATE Borrowings
    ->   SET ReturnDate = CURRENT_DATE,
    ->       Status = 'Returned'
    ->   WHERE BorrowID = p_borrow AND Status = 'Borrowed';
    -> END$$
Query OK, 0 rows affected (0.01 sec)

mysql>
mysql> DELIMITER ;
mysql>
mysql> -- ==============================================
mysql> -- STEP 6: Views (Reports)
mysql> -- ==============================================
mysql> -- Currently borrowed books
mysql> CREATE VIEW v_current_loans AS
    -> SELECT br.BorrowID, m.Name AS Member, b.Title AS Book, br.BorrowDate, br.DueDate
    -> FROM Borrowings br
    -> JOIN Members m ON m.MemberID = br.MemberID
    -> JOIN Books b ON b.BookID = br.BookID
    -> WHERE br.Status = 'Borrowed';
Query OK, 0 rows affected (0.01 sec)

mysql>
mysql> -- Member borrowing history
mysql> CREATE VIEW v_member_history AS
    -> SELECT m.MemberID, m.Name, COUNT(br.BorrowID) AS TotalBorrows
    -> FROM Members m
    -> LEFT JOIN Borrowings br ON m.MemberID = br.MemberID
    -> GROUP BY m.MemberID, m.Name;
Query OK, 0 rows affected (0.01 sec)

mysql>
mysql> -- ==============================================
mysql> -- STEP 7: Example Queries
mysql> -- ==============================================
mysql> -- 1. List all borrowed books (not returned)
mysql> SELECT * FROM v_current_loans;
+----------+-------------+------+------------+------------+
| BorrowID | Member      | Book | BorrowDate | DueDate    |
+----------+-------------+------+------------+------------+
|        2 | Priya Patel | 1984 | 2024-03-05 | 2024-03-19 |
+----------+-------------+------+------------+------------+
1 row in set (0.00 sec)

mysql>
mysql> -- 2. Find the most borrowed book
mysql> SELECT b.Title, COUNT(*) AS BorrowCount
    -> FROM Borrowings br
    -> JOIN Books b ON br.BookID = b.BookID
    -> GROUP BY b.Title
    -> ORDER BY BorrowCount DESC
    -> LIMIT 1;
+--------------+-------------+
| Title        | BorrowCount |
+--------------+-------------+
| Harry Potter |           1 |
+--------------+-------------+
1 row in set (0.00 sec)

mysql>
mysql> -- 3. Members who borrowed more than 1 book
mysql> SELECT m.Name, COUNT(br.BookID) AS BooksBorrowed
    -> FROM Members m
    -> JOIN Borrowings br ON m.MemberID = br.MemberID
    -> GROUP BY m.Name
    -> HAVING COUNT(br.BookID) > 1;
Empty set (0.00 sec)

mysql>
mysql> -- 4. Overdue books (past due date, still borrowed)
mysql> SELECT m.Name, b.Title, br.BorrowDate, br.DueDate
    -> FROM Borrowings br
    -> JOIN Members m ON br.MemberID = m.MemberID
    -> JOIN Books b ON br.BookID = b.BookID
    -> WHERE br.Status = 'Borrowed' AND br.DueDate < CURRENT_DATE;
+-------------+-------+------------+------------+
| Name        | Title | BorrowDate | DueDate    |
+-------------+-------+------------+------------+
| Priya Patel | 1984  | 2024-03-05 | 2024-03-19 |
+-------------+-------+------------+------------+
1 row in set (0.00 sec)

mysql>
mysql> -- ==============================================
mysql> -- STEP 8: Test Procedures
mysql> -- ==============================================
mysql> -- Rahul borrows "Harry Potter"
mysql> CALL sp_borrow_book(1, 1);
Query OK, 1 row affected (0.01 sec)

mysql>
mysql> -- Priya returns her borrowed book
mysql> CALL sp_return_book(2);
Query OK, 1 row affected (0.01 sec)

mysql> SHOW TABLES;
+---------------------+
| Tables_in_librarydb |
+---------------------+
| authors             |
| books               |
| borrowings          |
| members             |
| v_current_loans     |
| v_member_history    |
+---------------------+
6 rows in set (0.00 sec)

mysql> SELECT * FROM Authors;
+----------+---------------+---------+
| AuthorID | Name          | Country |
+----------+---------------+---------+
|        1 | J.K. Rowling  | UK      |
|        2 | Chetan Bhagat | India   |
|        3 | George Orwell | UK      |
+----------+---------------+---------+
3 rows in set (0.00 sec)

mysql> SELECT * FROM Books;
+--------+--------------------+----------+------------------+---------+-------------+-----------------+
| BookID | Title              | AuthorID | Publisher        | PubYear | TotalCopies | AvailableCopies |
+--------+--------------------+----------+------------------+---------+-------------+-----------------+
|      1 | Harry Potter       |        1 | Bloomsbury       |    1997 |           5 |               4 |
|      2 | Five Point Someone |        2 | Rupa             |    2004 |           3 |               3 |
|      3 | 1984               |        3 | Secker & Warburg |    1949 |           4 |               5 |
+--------+--------------------+----------+------------------+---------+-------------+-----------------+
3 rows in set (0.00 sec)

mysql> SELECT * FROM Members;
+----------+--------------+-----------------+------------+------------+
| MemberID | Name         | Email           | Phone      | JoinDate   |
+----------+--------------+-----------------+------------+------------+
|        1 | Rahul Sharma | rahul@email.com | 9876543210 | 2025-08-31 |
|        2 | Priya Patel  | priya@email.com | 9876501234 | 2025-08-31 |
+----------+--------------+-----------------+------------+------------+
2 rows in set (0.00 sec)

mysql> SELECT * FROM Borrowings;
+----------+--------+----------+------------+------------+------------+----------+
| BorrowID | BookID | MemberID | BorrowDate | DueDate    | ReturnDate | Status   |
+----------+--------+----------+------------+------------+------------+----------+
|        1 |      1 |        1 | 2024-03-01 | 2024-03-15 | 2024-03-15 | Returned |
|        2 |      3 |        2 | 2024-03-05 | 2024-03-19 | 2025-08-31 | Returned |
|        3 |      1 |        1 | 2025-08-31 | 2025-09-14 | NULL       | Borrowed |
+----------+--------+----------+------------+------------+------------+----------+
3 rows in set (0.00 sec)

mysql> SELECT * FROM v_current_loans;
+----------+--------------+--------------+------------+------------+
| BorrowID | Member       | Book         | BorrowDate | DueDate    |
+----------+--------------+--------------+------------+------------+
|        3 | Rahul Sharma | Harry Potter | 2025-08-31 | 2025-09-14 |
+----------+--------------+--------------+------------+------------+
1 row in set (0.00 sec)

mysql> SELECT b.Title, COUNT(*) AS BorrowCount
    -> FROM Borrowings br
    -> JOIN Books b ON br.BookID = b.BookID
    -> GROUP BY b.Title
    -> ORDER BY BorrowCount DESC
    -> LIMIT 1;
+--------------+-------------+
| Title        | BorrowCount |
+--------------+-------------+
| Harry Potter |           2 |
+--------------+-------------+
1 row in set (0.00 sec)

mysql> CALL sp_borrow_book(1, 2);   -- Rahul borrows BookID=2
Query OK, 1 row affected (0.01 sec)

mysql> CALL sp_return_book(1);      -- Return BorrowID=1
Query OK, 0 rows affected (0.00 sec)

mysql>    SELECT m.Name, COUNT(br.BookID) AS BooksBorrowed
    ->    FROM Members m
    ->    JOIN Borrowings br ON m.MemberID = br.MemberID
    ->    GROUP BY m.Name
    ->    HAVING COUNT(br.BookID) > 1;
+--------------+---------------+
| Name         | BooksBorrowed |
+--------------+---------------+
| Rahul Sharma |             3 |
+--------------+---------------+
1 row in set (0.00 sec)