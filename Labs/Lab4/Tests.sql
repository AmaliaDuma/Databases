USE [Dead by daylight]
GO

--Create some tables for testing
--primary key 
CREATE TABLE BloodPoints(
	LogID INT PRIMARY KEY,
	Quantity INT,
	Overall_rank VARCHAR(15)
)

--primary key and foreign key
CREATE TABLE Player(
	PlayerID INT PRIMARY KEY,
	BpID INT FOREIGN KEY REFERENCES BloodPoints(LogID),
	Name_ VARCHAR(20),
	Experience INT
)

--multicolumn primary key
CREATE TABLE Charm(
	Name_ VARCHAR(20),
	EventName VARCHAR(20),
	Year_obtained INT,
	CONSTRAINT PK_Charms PRIMARY KEY(Name_, EventName)
)

GO

--Procedure to insert the name of tables which take part in a test into 'Tables'
CREATE OR ALTER PROCEDURE Add_to_Tables (@t_name VARCHAR(20)) AS
	--if the table doesn't exist
	IF NOT EXISTS (SELECT * FROM sys.tables WHERE name=@t_name)
	BEGIN
		PRINT 'TABLE ' + @t_name + ' does not exist.'
		RETURN
	END
	--if already inserted
	IF EXISTS (SELECT * FROM Tables T WHERE T.Name=@t_name)
	BEGIN
		PRINT 'TABLE ' + @t_name + ' already exists.'
		RETURN
	END
	--else insert into tables
	INSERT INTO Tables VALUES (@t_name)
GO

--insert the tables we want to test
EXEC Add_to_Tables 'BloodPoints'
EXEC Add_to_Tables 'Player'
EXEC Add_to_Tables 'Charm'
SELECT * FROM Tables
GO

--Procedure to create tests
CREATE OR ALTER PROCEDURE Create_tests (@t_name VARCHAR(20)) AS
	--if test already exists
	IF EXISTS (SELECT * FROM Tests T WHERE T.Name = @t_name)
	BEGIN
		PRINT 'Test ' + @t_name + ' already exists'
		RETURN
	END
	--else insert the test
	INSERT INTO Tests VALUES (@t_name)
GO

--insert a test to have it
EXEC Create_tests 'firstTest'
SELECT * FROM Tests
GO

--procedure to relate the tests and tables
CREATE OR ALTER PROCEDURE Associate_Test_Tables (@testN VARCHAR(20), @tableN VARCHAR(20), @pos INT, @rows INT) AS
	--check some params
	IF @pos < 0
	BEGIN
		PRINT 'Position should be > 0'
		RETURN
	END
	IF @rows < 0
	BEGIN
		PRINT 'Rows should be > 0'
		RETURN
	END

	--declare the variables we need to store de id's
	DECLARE @tableId INT, @testId INT
	SET @tableId = (SELECT T.TableID FROM Tables T WHERE T.Name = @tableN)
	SET @testId = (SELECT T1.TestID FROM Tests T1 WHERE T1.Name = @testN)
	--insert the values
	INSERT INTO TestTables VALUES (@testId, @tableId, @rows, @pos)
GO

--relate the test we have to the tables
EXEC Associate_Test_Tables 'firstTest', 'BloodPoints', 2, 10
EXEC Associate_Test_Tables 'firstTest', 'Player', 1, 10
EXEC Associate_Test_Tables 'firstTest', 'Charm', 3, 10
SELECT * FROM TestTables
DELETE FROM TestTables
GO

--create the views
--view with select on 1 table -> all bugs and their priority
CREATE OR ALTER VIEW AllBugs_Severity AS
	SELECT B.Bid, B.Severity FROM Bugs B
GO

SELECT * FROM AllBugs_Severity
GO

--view with select on 2 tables -> the devs id and name who are assigned to a bug with major severity
CREATE OR ALTER VIEW Devs_withBugs_Major AS
	SELECT D.Did, D.First_name FROM Developer D INNER JOIN Bugs B ON D.BugId=B.Bid AND B.Severity='Major'
GO

SELECT * FROM Devs_withBugs_Major
GO

--view with select on 2 tables with a group by clause -> the number of devs assigned to bugs on each severity
CREATE OR ALTER VIEW NrDevs_Severity AS
	SELECT B.Severity, COUNT(*) AS Nr_Bugs 
	FROM Bugs B INNER JOIN Developer D ON D.BugId=B.Bid
	GROUP BY B.Severity
GO

SELECT * FROM NrDevs_Severity
GO

--procedure to insert the view to the 'Views' table
--SELECT * FROM sys.all_views WHERE name = 'NrDevs_Severity'
CREATE OR ALTER PROCEDURE Add_to_Views (@v_name VARCHAR(20)) AS
	--check if view doesn't exists
	IF NOT EXISTS (SELECT * FROM sys.all_views WHERE name = @v_name)
	BEGIN
		PRINT 'View ' + @v_name + ' does not exist.'
		RETURN
	END
	--check if view already added
	IF EXISTS (SELECT * FROM Views V WHERE V.Name = @v_name)
	BEGIN
		PRINT 'View ' + @v_name + ' already exists.'
		RETURN
	END
	--else insert into views
	INSERT INTO Views VALUES (@v_name)
GO

--insert the views we have to test them
EXEC Add_to_Views 'AllBugs_Severity'
EXEC Add_to_Views 'Devs_withBugs_Major'
EXEC Add_to_Views 'NrDevs_Severity'
SELECT * FROM Views
GO

--relate the views and tests
CREATE OR ALTER PROCEDURE Associate_Views_Tests (@tname VARCHAR(20), @vname VARCHAR(20)) AS
	--declare the variables for id
	DECLARE @tid INT, @vid INT
	--check if test exists
	IF NOT EXISTS (SELECT * FROM Tests T WHERE T.Name=@tname)
	BEGIN
		PRINT 'Invalid test'
		RETURN
	END
	--check if view exists
	IF NOT EXISTS (SELECT * FROM Views V WHERE V.Name=@vname)
	BEGIN
		PRINT 'Invalid view'
		RETURN
	END
	--else insert into TestViews
	SET @tid = (SELECT T.TestID FROM Tests T WHERE T.Name = @tname)
	SET @vid = (SELECT V.ViewID FROM Views V WHERE V.Name = @vname)
	INSERT INTO TestViews VALUES (@tid, @vid)
GO

--relate the views to the tests
EXEC Associate_Views_Tests 'firstTest', 'AllBugs_Severity'
EXEC Associate_Views_Tests 'firstTest', 'Devs_withBugs_Major'
EXEC Associate_Views_Tests 'firstTest', 'NrDevs_Severity'
SELECT * FROM TestViews
SELECT * FROM Tests
SELECT * FROM Views

--HOW TO GET TYPE OF A COLUMN EXAMPLE
SELECT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'BloodPoints' AND COLUMN_NAME = 'LogID'

--HOW TO GET THE COLUMNS OF A TABLE EXAMPLE
SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Charm'

GO
--main procedure
CREATE OR ALTER PROCEDURE RunTest (@tname VARCHAR(20)) AS
	SET NOCOUNT ON
	--check if test exists
	IF NOT EXISTS (SELECT * FROM Tests T WHERE T.Name = @tname)
	BEGIN
		PRINT 'Test does not exist'
		RETURN
	END
	--take the test id
	DECLARE @testId INT, @testRunID INT, @test_stTime DATETIME2, @test_endTime DATETIME2
	SET @testId = (SELECT T.TestID FROM Tests T WHERE T.Name = @tname)
	PRINT 'Execution of test ' + @tname + ' with id: ' + CAST(@testId AS VARCHAR) + ' is starting...'

	SET @test_stTime = (SELECT SYSDATETIME())
	INSERT INTO TestRuns(Description, StartAt) VALUES (@tname, @test_stTime)
	SET @testRunID = CONVERT(INT, (SELECT last_value FROM sys.identity_columns WHERE name = 'TestRunID'))

	--we start with the delete
	--we need a cursor for the tables associated with the test in the order we need to delete from them
	DECLARE Del_Tables CURSOR FOR 
		SELECT Tb.TableID, Tb.Name FROM TestTables T INNER JOIN Tables Tb ON T.TableID = Tb.TableID
		WHERE T.TestID = @testId
		ORDER BY T.Position
	OPEN Del_Tables
	--declare some variables that we need
	DECLARE @tableName VARCHAR(20), @tableId INT, @command VARCHAR(50)

	FETCH FROM Del_Tables into @tableId, @tableName
	WHILE @@FETCH_STATUS = 0
	BEGIN
		PRINT 'Deleting from ' + @tableName + ' with id ' + CAST(@tableId AS VARCHAR)
		SET @command = 'DELETE FROM ' + @tableName
		EXEC(@command)
		FETCH FROM Del_Tables into @tableId, @tableName
	END
	--deallocate the cursor since we're done with the delete
	DEALLOCATE Del_Tables

	--we have the insert now 
	--declare the cursor for the tables in which we have to insert by the inverse order in which we delete
	DECLARE Ins_Tables CURSOR FOR 
		SELECT Tb.TableID, Tb.Name, T.NoOfRows FROM TestTables T INNER JOIN Tables Tb ON T.TableID = Tb.TableID
		WHERE T.TestID = @testId
		ORDER BY T.Position DESC
	OPEN Ins_Tables 
	--we some variables we need
	DECLARE @rows INT
	DECLARE @resultT TABLE (res INT)
	DECLARE @resultTc TABLE(res VARCHAR(5))
	DECLARE @stTime DATETIME2, @endTime DATETIME2

	FETCH FROM Ins_Tables INTO @tableId, @tableName, @rows
	WHILE @@FETCH_STATUS = 0
	BEGIN
		PRINT 'Inserting into ' + @tableName + ' ' + CAST(@rows AS VARCHAR) + ' rows...'
		DECLARE @col_name VARCHAR(20), @col_type VARCHAR(20), @constr_name VARCHAR(20), @random_nr INT, @random_ch VARCHAR(3), @nr INT
		--declare cursor for columns and types
		DECLARE Cols CURSOR FOR 
			SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @tableName
		SET @nr = 0
		SET @stTime = (SELECT SYSDATETIME ())

		WHILE @nr != @rows
		BEGIN
		--
		SET @command = 'INSERT INTO ' + @tableName + ' VALUES ('
		OPEN Cols
		FETCH FROM Cols INTO @col_name, @col_type
		WHILE @@FETCH_STATUS = 0
		BEGIN
			--we verify if we have a column with a foreign key
			SET @constr_name = (SELECT CONSTRAINT_NAME FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE WHERE COLUMN_NAME = @col_name)
			IF @constr_name LIKE 'FK%'
			BEGIN
				--get position of this table
				DECLARE @pos INT
				SET @pos = (SELECT Tb.Position FROM Tables T INNER JOIN TestTables Tb ON T.TableID=Tb.TableID WHERE T.Name = @tableName)
				--increment by one bcs we know that positions give us the order
				SET @pos = @pos +1
				--get the name of the column that gives us the key for our foreign
				DECLARE @tname_aux VARCHAR(20)
				SET @tname_aux = (SELECT T.Name FROM Tables T INNER JOIN TestTables Tb ON T.TableID=Tb.TableID WHERE Tb.Position=@pos)
				DECLARE @col_name_aux VARCHAR(20)
				SET @col_name_aux = (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE WHERE TABLE_NAME = @tname_aux AND CONSTRAINT_NAME LIKE 'PK%')
				DECLARE @col_type_aux VARCHAR(10)
				SET @col_type_aux = (SELECT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @tname_aux AND COLUMN_NAME = @col_name_aux)

				IF @col_type_aux = 'int'
				BEGIN
					DECLARE @aux_nr INT
					SET @aux_nr = @nr +1
					DECLARE @query VARCHAR (300)
					--we select the current row that we are at and take the pk value to be our fk
					SET @query = 'SELECT ' + @col_name_aux + ' FROM (SELECT ROW_NUMBER() OVER (ORDER BY ' + @col_name_aux + ' ASC) AS rownumber, ' + @col_name_aux + ' FROM '+ @tname_aux + ' ) AS foo WHERE rownumber = ' + CAST(@aux_nr AS VARCHAR)
					--we make a table which will hold our pk as a result of the above query
					INSERT INTO @resultT EXEC (@query)
					SET @random_nr = (SELECT * FROM @resultT)
					--add the result to our command
					SET @command = @command + CAST(@random_nr AS VARCHAR) + ','
					--we delete from the table where we keep our result because we want only one value at a time 
					DELETE FROM @resultT
				END
				ELSE
				BEGIN
					SET @aux_nr = @nr +1
					SET @query = 'SELECT ' + @col_name_aux + ' FROM (SELECT ROW_NUMBER() OVER (ORDER BY ' + @col_name_aux + ' ASC) AS rownumber, ' + @col_name_aux + ' FROM '+ @tname_aux + ' ) AS foo WHERE rownumber = ' + CAST(@aux_nr AS VARCHAR)
					INSERT INTO @resultTc EXEC (@query)
					SET @random_ch = (SELECT * FROM @resultTc)
					--add the result to our command 
					SET @command = @command + '''' + @random_ch + '''' + ','
					DELETE FROM @resultTc
				END
			END
			ELSE
			BEGIN
				--if we have no foreign key we're clear to insert some random generated values 
				IF @col_type = 'int'
				BEGIN
					SET @random_nr = (SELECT FLOOR(RAND() * 999 +1))
					SET @command = @command + CAST(@random_nr AS VARCHAR) + ','
				END
				ELSE
				BEGIN
					SET @random_ch = (select char(cast((90 - 65 )*rand() + 65 as integer)))
					SET @command = @command + '''' +@random_ch + '''' +','
				END
			END
			FETCH FROM Cols INTO @col_name, @col_type
		END
		--take the last ',' out of the command string, put the  ')' and execute it
		SET @command = (SELECT LEFT(@command, NULLIF(LEN(@command)-1,-1)))
		SET @command = @command + ')'
		print @command
		EXEC(@command)
		--increase the nr of current row we are at
		SET @nr = @nr +1 
		--close the cursor so we can open it again to do the same procedure
		CLOSE Cols
		--
		END
		--we're done with a table, deallocate cols and move to the next one
		DEALLOCATE Cols
		SET @endTime = (SELECT SYSDATETIME ())
		INSERT INTO TestRunTables VALUES (@testRunID, @tableId, @stTime, @endTime)
		FETCH FROM Ins_Tables INTO @tableId, @tableName, @rows
	END
	--deallocate the cursor since we're done with the insert
	DEALLOCATE Ins_Tables

	--the view selecting 
	--declare a cursor for the views name and id
	DECLARE ViewsS CURSOR FOR
		SELECT V.ViewID, V.Name FROM TestViews Tv INNER JOIN Views V ON V.ViewID = Tv.ViewID
	OPEN ViewsS
	--declare some variables we need
	DECLARE @v_id INT, @v_name VARCHAR(20)

	FETCH FROM ViewsS INTO @v_id, @v_name
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @stTime = (SELECT SYSDATETIME())
		PRINT 'Selecting the view: ' + @v_name + ' with id: ' + CAST(@v_id AS VARCHAR)
		SET @command = 'SELECT * FROM ' + @v_name
		EXEC(@command)
		SET @endTime = (SELECT SYSDATETIME())
		INSERT INTO TestRunViews VALUES (@testRunID, @v_id, @stTime, @endTime)
		FETCH FROM ViewsS INTO @v_id, @v_name
	END
	--we're done with the view, we deallocate the cursor
	DEALLOCATE ViewsS
	SET @test_endTime = (SELECT SYSDATETIME())
	UPDATE TestRuns
		SET EndAt = @test_endTime WHERE TestRunID = @testRunID
GO

EXEC RunTest 'firstTest'
SELECT * FROM Tables
SELECT * FROM TestTables
SELECT * FROM TestRuns
SELECT * FROM TestRunTables
SELECT * FROM TestRunViews
DELETE FROM TestRunTables
DELETE FROM TestRunViews
DELETE FROM TestRuns

--how to get the columns and the types of a table
SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Player'
--how to get the constraints of a column
SELECT * FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE WHERE TABLE_NAME = 'BloodPoints'
--how to get a random number
SELECT FLOOR(RAND() * 99 +1)
--how to get a random letter
select char(cast((90 - 65 )*rand() + 65 as integer))
