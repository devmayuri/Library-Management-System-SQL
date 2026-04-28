mysql>
mysql> -- STEP 1: Create Database
mysql> DROP DATABASE IF EXISTS LibraryDB;
Query OK, 6 rows affected (0.27 sec)

mysql> CREATE DATABASE LibraryDB;
Query OK, 1 row affected (0.01 sec)

mysql> USE LibraryDB;
Database changed
mysql>
mysql> -- ==============================================
mysql> -- STEP 2: Create Tables
mysql> -- ==============================================
mysql>
mysql> CREATE TABLE Authors (
    ->     AuthorID INT AUTO_INCREMENT PRIMARY KEY,
    ->     Name VARCHAR(100) NOT NULL,
    ->     Country VARCHAR(50)
    -> );
Query OK, 0 rows affected (0.03 sec)

mysql>
mysql> CREATE TABLE Books (
    ->     BookID INT AUTO_INCREMENT PRIMARY KEY,
    ->     Title VARCHAR(150) NOT NULL,
    ->     AuthorID INT NOT NULL,
    ->     Publisher VARCHAR(100),
    ->     PubYear YEAR,
    ->     TotalCopies INT NOT NULL,
    ->     AvailableCopies INT NOT NULL,
    ->     FOREIGN KEY (AuthorID) REFERENCES Authors(AuthorID),
    ->     CHECK (AvailableCopies <= TotalCopies AND AvailableCopies >= 0)
    -> );
Query OK, 0 rows affected (0.09 sec)

mysql>
mysql> CREATE TABLE Members (
    ->     MemberID INT AUTO_INCREMENT PRIMARY KEY,
    ->     Name VARCHAR(100) NOT NULL,
    ->     Email VARCHAR(120) UNIQUE,
    ->     Phone VARCHAR(15),
    ->     JoinDate DATE DEFAULT (CURRENT_DATE)
    -> );
Query OK, 0 rows affected (0.08 sec)

mysql>
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
Query OK, 0 rows affected (0.07 sec)

mysql>
mysql> -- ==============================================
mysql> -- STEP 3: Insert Data
mysql> -- ==============================================
mysql>
mysql> INSERT INTO Authors (Name, Country) VALUES
    -> ('J.K. Rowling','UK'),
    -> ('Chetan Bhagat','India'),
    -> ('George Orwell','UK');
Query OK, 3 rows affected (0.02 sec)
Records: 3  Duplicates: 0  Warnings: 0

mysql>
mysql> INSERT INTO Books (Title, AuthorID, Publisher, PubYear, TotalCopies, AvailableCopies) VALUES
    -> ('Harry Potter', 1, 'Bloomsbury', 1997, 5, 5),
    -> ('Five Point Someone', 2, 'Rupa', 2004, 3, 3),
    -> ('1984', 3, 'Secker & Warburg', 1949, 4, 4);
Query OK, 3 rows affected (0.01 sec)
Records: 3  Duplicates: 0  Warnings: 0

mysql>
mysql> INSERT INTO Members (Name, Email, Phone) VALUES
    -> ('Rahul Sharma','rahul@email.com','9876543210'),
    -> ('Priya Patel','priya@email.com','9876501234');
Query OK, 2 rows affected (0.01 sec)
Records: 2  Duplicates: 0  Warnings: 0

mysql>
mysql> INSERT INTO Borrowings (BookID, MemberID, BorrowDate, ReturnDate, Status) VALUES
    -> (1, 1, '2024-03-01', '2024-03-15', 'Returned'),
    -> (3, 2, '2024-03-05', NULL, 'Borrowed');
Query OK, 2 rows affected (0.01 sec)
Records: 2  Duplicates: 0  Warnings: 0

mysql>
mysql> -- ==============================================
mysql> -- STEP 4: Triggers (FIXED)
mysql> -- ==============================================
mysql>
mysql> DELIMITER $$
mysql>
mysql> CREATE TRIGGER trg_before_borrow
    -> BEFORE INSERT ON Borrowings
    -> FOR EACH ROW
    -> BEGIN
    ->   DECLARE avail INT;
    ->   SELECT AvailableCopies INTO avail FROM Books WHERE BookID = NEW.BookID;
    ->
    ->   IF avail <= 0 THEN
    ->     SIGNAL SQLSTATE '45000'
    ->     SET MESSAGE_TEXT = 'No copies available';
    ->   END IF;
    -> END$$
Query OK, 0 rows affected (0.02 sec)

mysql>
mysql> CREATE TRIGGER trg_after_borrow
    -> AFTER INSERT ON Borrowings
    -> FOR EACH ROW
    -> BEGIN
    ->   UPDATE Books
    ->   SET AvailableCopies = AvailableCopies - 1
    ->   WHERE BookID = NEW.BookID;
    -> END$$
Query OK, 0 rows affected (0.02 sec)

mysql>
mysql> -- FIXED TRIGGER
mysql> CREATE TRIGGER trg_after_return
    -> AFTER UPDATE ON Borrowings
    -> FOR EACH ROW
    -> BEGIN
    ->   IF OLD.Status = 'Borrowed' AND NEW.Status = 'Returned' THEN
    ->     UPDATE Books
    ->     SET AvailableCopies = LEAST(AvailableCopies + 1, TotalCopies)
    ->     WHERE BookID = NEW.BookID;
    ->   END IF;
    -> END$$
Query OK, 0 rows affected (0.01 sec)

mysql>
mysql> DELIMITER ;
mysql>
mysql> -- ==============================================
mysql> -- STEP 5: Stored Procedures
mysql> -- ==============================================
mysql>
mysql> DELIMITER $$
mysql>
mysql> CREATE PROCEDURE sp_borrow_book(IN p_member INT, IN p_book INT)
    -> BEGIN
    ->   INSERT INTO Borrowings (BookID, MemberID)
    ->   VALUES (p_book, p_member);
    -> END$$
Query OK, 0 rows affected (0.01 sec)

mysql>
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
mysql> -- STEP 6: Views
mysql> -- ==============================================
mysql>
mysql> CREATE VIEW v_current_loans AS
    -> SELECT br.BorrowID, m.Name AS Member, b.Title AS Book, br.BorrowDate, br.DueDate
    -> FROM Borrowings br
    -> JOIN Members m ON m.MemberID = br.MemberID
    -> JOIN Books b ON b.BookID = br.BookID
    -> WHERE br.Status = 'Borrowed';
Query OK, 0 rows affected (0.01 sec)

mysql>
mysql> CREATE VIEW v_member_history AS
    -> SELECT m.MemberID, m.Name, COUNT(br.BorrowID) AS TotalBorrows
    -> FROM Members m
    -> LEFT JOIN Borrowings br ON m.MemberID = br.MemberID
    -> GROUP BY m.MemberID, m.Name;
Query OK, 0 rows affected (0.01 sec)

mysql>
mysql> -- ==============================================
mysql> -- STEP 7: Data Fix
mysql> -- ==============================================
mysql>
mysql> UPDATE Books
    -> SET AvailableCopies = TotalCopies
    -> WHERE AvailableCopies > TotalCopies;
Query OK, 0 rows affected (0.00 sec)
Rows matched: 0  Changed: 0  Warnings: 0

mysql>
mysql> -- ==============================================
mysql> -- END
mysql> -- ==============================================
mysql> SELECT * FROM Books;
+--------+--------------------+----------+------------------+---------+-------------+-----------------+
| BookID | Title              | AuthorID | Publisher        | PubYear | TotalCopies | AvailableCopies |
+--------+--------------------+----------+------------------+---------+-------------+-----------------+
|      1 | Harry Potter       |        1 | Bloomsbury       |    1997 |           5 |               5 |
|      2 | Five Point Someone |        2 | Rupa             |    2004 |           3 |               3 |
|      3 | 1984               |        3 | Secker & Warburg |    1949 |           4 |               4 |
+--------+--------------------+----------+------------------+---------+-------------+-----------------+
3 rows in set (0.02 sec)
mysql> CALL sp_borrow_book(1,1);
Query OK, 1 row affected (0.02 sec)

mysql> SELECT * FROM Books;
+--------+--------------------+----------+------------------+---------+-------------+-----------------+
| BookID | Title              | AuthorID | Publisher        | PubYear | TotalCopies | AvailableCopies |
+--------+--------------------+----------+------------------+---------+-------------+-----------------+
|      1 | Harry Potter       |        1 | Bloomsbury       |    1997 |           5 |               4 |
|      2 | Five Point Someone |        2 | Rupa             |    2004 |           3 |               3 |
|      3 | 1984               |        3 | Secker & Warburg |    1949 |           4 |               4 |
+--------+--------------------+----------+------------------+---------+-------------+-----------------+
3 rows in set (0.00 sec)

mysql> CALL sp_return_book(1);
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT * FROM Books;
+--------+--------------------+----------+------------------+---------+-------------+-----------------+
| BookID | Title              | AuthorID | Publisher        | PubYear | TotalCopies | AvailableCopies |
+--------+--------------------+----------+------------------+---------+-------------+-----------------+
|      1 | Harry Potter       |        1 | Bloomsbury       |    1997 |           5 |               4 |
|      2 | Five Point Someone |        2 | Rupa             |    2004 |           3 |               3 |
|      3 | 1984               |        3 | Secker & Warburg |    1949 |           4 |               4 |
+--------+--------------------+----------+------------------+---------+-------------+-----------------+
3 rows in set (0.00 sec)
mysql> 
