USE [Dead by daylight]
GO

----- a. Modify the type of a column -----

--modify
CREATE PROCEDURE ItemDuration_toFloat AS
	ALTER TABLE Item
	ALTER COLUMN Duration FLOAT;
GO

--reverse
CREATE PROCEDURE ItemDuration_backInt AS
	ALTER TABLE Item
	ALTER COLUMN Duration INT;
GO

--testing
EXEC ItemDuration_toFloat
SELECT * FROM Item
EXEC ItemDuration_backInt
GO

----- b. Add/remove a column -----

--add
CREATE PROCEDURE AddCountry_toSurvivor AS
	ALTER TABLE Survivor
	ADD Country VARCHAR(20);
GO

--remove
CREATE PROCEDURE DelCountry_fromSurvivor AS
	ALTER TABLE Survivor
	DROP COLUMN Country;
GO

--testing
EXEC AddCountry_toSurvivor
SELECT * FROM Survivor
EXEC DelCountry_fromSurvivor
Go

----- c. Add/remove a DEFAULT constraint -----

--add
CREATE PROCEDURE AddDef_MapSize AS
	ALTER TABLE Map
	ADD CONSTRAINT DefaultSizeC DEFAULT(0) FOR Size;
GO

--remove
CREATE PROCEDURE DelDef_MapSize AS
	ALTER TABLE Map
	DROP CONSTRAINT DefaultSizeC
GO

--testing
EXEC AddDef_MapSize
INSERT INTO Map(MPid,Name_,Realm,Nr_pallets,Nr_lockers) VALUES(1,'n','r',0,0)
SELECT * FROM Map
DELETE FROM Map
EXEC DelDef_MapSize
GO

----- d. Add/remove a primary key -----

--add
CREATE PROCEDURE AddNamePK_toCosmetics AS
	ALTER TABLE Cosmetics
	DROP CONSTRAINT IdPrimaryKey
	ALTER TABLE Cosmetics
	ADD CONSTRAINT IdNamePrimaryKey PRIMARY KEY(CId,Name_)
GO

--remove
CREATE PROCEDURE DelNamePK_fromCosmetics AS
	ALTER TABLE Cosmetics
	DROP CONSTRAINT IdNamePrimaryKey
	ALTER TABLE Cosmetics
	ADD CONSTRAINT IdPrimaryKey PRIMARY KEY(CId)
GO

--testing
EXEC AddNamePK_toCosmetics
EXEC DelNamePK_fromCosmetics
GO

----- e. Add/remove a candidate key -----

--add
CREATE PROCEDURE AddNameCandidate_toCosmetics AS
	ALTER TABLE Cosmetics
	ADD CONSTRAINT NameCandidateKey UNIQUE(Name_)
GO

--remove
CREATE PROCEDURE DelNameCandidate_fromCosmetics AS
	ALTER TABLE Cosmetics
	DROP CONSTRAINT NameCandidateKey
GO

--testing
EXEC AddNameCandidate_toCosmetics
EXEC DelNameCandidate_fromCosmetics
GO

----- f. Add/remove a foreign key -----

--add
CREATE PROCEDURE AddCosmeticsFK AS
	ALTER TABLE Cosmetics
	ADD CONSTRAINT KillerForeignKey FOREIGN KEY(KillerId) REFERENCES Killer(Kid)
GO

--remove
CREATE PROCEDURE DelCosmeticsFK AS
	ALTER TABLE Cosmetics
	DROP CONSTRAINT KillerForeignKey
GO

--testing
EXEC AddCosmeticsFK
EXEC DelCosmeticsFK

----- g. Create/drop a table -----

--create
CREATE PROCEDURE CreateCosmetics AS
	CREATE TABLE Cosmetics(
		CId INT CONSTRAINT IdPrimaryKey PRIMARY KEY,
		Name_ VARCHAR(30) NOT NULL,
		Rarity VARCHAR(15),
		Price INT,
		KillerId INT
	)
GO

--drop
CREATE PROCEDURE DropCosmetics AS
	DROP TABLE Cosmetics 
GO

--testing
EXEC CreateCosmetics
SELECT * FROM Cosmetics
EXEC DropCosmetics


--Create the version table
CREATE TABLE Version_DB(
	Version_ INT
)
--Insert version 0 since we are at the beggining
INSERT INTO Version_DB VALUES (0)

--Create the table for the procedures associated with a version
CREATE TABLE ProcedureTable(
	Version_ INT,
	Up VARCHAR(100),
	Down VARCHAR(100)
)
--Insert the names for the procedures
INSERT INTO ProcedureTable VALUES (1, 'ItemDuration_toFloat', 'ItemDuration_backInt'), (2, 'AddCountry_toSurvivor', 'DelCountry_fromSurvivor')
INSERT INTO ProcedureTable VALUES (3, 'AddDef_MapSize', 'DelDef_MapSize'), (4, 'CreateCosmetics', 'DropCosmetics')
INSERT INTO ProcedureTable VALUES (5, 'AddNamePK_toCosmetics', 'DelNamePK_fromCosmetics'), (6, 'AddNameCandidate_toCosmetics', 'DelNameCandidate_fromCosmetics')
INSERT INTO ProcedureTable VALUES (7, 'AddCosmeticsFK', 'DelCosmeticsFK')
SELECT * FROM ProcedureTable
GO

-----Procedure that gets a version and brings the db to that version
CREATE PROCEDURE GoToVersion(@Version INT) AS
	DECLARE @CrtVersion INT
	--declare the field that will hold the name of a proc
	DECLARE @proc_name VARCHAR(100)
	DECLARE @aux_ver INT
	DECLARE @check INT
	SET @check = 0
	SET @aux_ver = 0
	--get the current version
	SET @CrtVersion = (SELECT TOP 1 V.Version_
					   FROM Version_DB V)
	--declare cursors
	DECLARE UpCursor CURSOR
		FOR SELECT P.Up FROM ProcedureTable P
	OPEN UpCursor
	DECLARE DownCursor CURSOR SCROLL
		FOR SELECT P.Down FROM ProcedureTable P
	OPEN DownCursor

	--while we're not at the version required we start the loop
	WHILE @Version != @CrtVersion
	BEGIN
		IF @CrtVersion < @Version
		--if our current version is smaller we fetch the next row from UpCursor, we execute it and set the current = current+1
		BEGIN
			WHILE @aux_ver != @CrtVersion
			--we take and aux_ver to make the cursor point to the version we are right now, so if we are at 0 the cursor will stay here, but if we are at 2
			--we take the cursor to second rows in the procedures table and then we can fetch the next to increase our version
			BEGIN
				FETCH NEXT FROM UpCursor INTO @proc_name
				SET @aux_ver = @aux_ver +1
			END

			FETCH NEXT FROM UpCursor INTO @proc_name
			PRINT 'Executing ' + @proc_name
			EXEC @proc_name
			SET @CrtVersion = @CrtVersion + 1
			SET @aux_ver = @CrtVersion
			CONTINUE
		END
		IF @CrtVersion > @Version
		--if our current version is bigger we fetch the prior row from UpCursor, we execute it and set the current = current+1
		BEGIN
			WHILE @aux_ver != @CrtVersion
			--we take an aux_ver to put the cursor on the row coressponding to our current version so we can fetch prior to go down in version
			BEGIN
				FETCH NEXT FROM DownCursor INTO @proc_name
				SET @aux_ver = @aux_ver +1
				SET @check = 1
			END
			IF @check = 1
			BEGIN
				FETCH NEXT FROM DownCursor INTO @proc_name
			END

			FETCH PRIOR FROM DownCursor INTO @proc_name
			PRINT 'Executing ' + @proc_name
			EXEC @proc_name
			SET @CrtVersion = @CrtVersion - 1
			SET @aux_ver = @CrtVersion
			SET @check = 0
			CONTINUE
		END
	END
	--insert the new version
	DELETE FROM Version_DB
	INSERT INTO Version_DB VALUES (@CrtVersion)
	--deallocate cursors
	DEALLOCATE UpCursor
	DEALLOCATE DownCursor
GO

EXEC GoToVersion @Version=0
SELECT * FROM Version_DB
INSERT INTO Version_DB VALUES (0)
