USE [Dead by daylight]
GO

----------create the tables that match the structure----------
CREATE TABLE Offerings( --Ta
	OId INT PRIMARY KEY,  --aid
	Log_code INT UNIQUE,  --a2
	Duration_inGames INT, --a3
	Name_ VARCHAR(20)
	)

CREATE TABLE Entity(  --Tb
	EId INT PRIMARY KEY, --bid
	Age INT, --b2
	Lvl INT
	)

CREATE TABLE Pairs( --Tc
	PId INT PRIMARY KEY, --cid
	OfferingId INT FOREIGN KEY REFERENCES Offerings(OId), --aid
	EntityId INT FOREIGN KEY REFERENCES Entity(EId)  --bid
	)

----------insert some data----------
INSERT INTO Offerings VALUES (1, 5541, 3,'A'), (2, 1174, 3, 'B'), (3, 5378, 1, 'C')
INSERT INTO Entity VALUES (1, 341, 30), (2, 115, 20), (3, 473, 35)
INSERT INTO Pairs VALUES (1, 1, 2), (2, 1, 3), (3, 2, 2)
SELECT * FROM Offerings
SELECT * FROM Entity
SELECT * FROM Pairs

DELETE FROM Pairs
DELETE FROM Offerings
DELETE FROM Entity

GO
CREATE OR ALTER PROCEDURE InsertInto_TaAndTb (@rows INT) AS
	WHILE @rows != 0
	BEGIN
		INSERT INTO Offerings VALUES ((SELECT FLOOR(RAND() * 99999 +1)), (SELECT FLOOR(RAND() * 99999 +1)), (SELECT FLOOR(RAND() * 30 +1)), (select char(cast((90 - 65 )*rand() + 65 as integer))))
		INSERT INTO Entity VALUES ((SELECT FLOOR(RAND() * 99999 +1)), (SELECT FLOOR(RAND() * 999 +1)), (SELECT FLOOR(RAND() * 30 +1)))
		SET @rows = @rows -1
	END
GO
EXEC InsertInto_TaAndTb 200
GO

CREATE OR ALTER PROCEDURE InsertInto_Tc (@rows INT) AS
	DECLARE Off_Ids CURSOR FOR
		SELECT O.OId FROM Offerings O
	DECLARE En_Ids CURSOR FOR
		SELECT E.EId FROM Entity E
	OPEN Off_Ids
	OPEN En_Ids
	DECLARE @oId INT, @eId INT
	FETCH FROM Off_Ids INTO @oId
	FETCH FROM En_Ids INTO @eId
	WHILE @rows != 0
	BEGIN
		INSERT INTO Pairs VALUES ((SELECT FLOOR(RAND() * 99999 +1)), @oId, @eId)
		SET @rows = @rows -1
		FETCH FROM Off_Ids INTO @oId
		FETCH FROM En_Ids INTO @eId
	END
	DEALLOCATE Off_Ids
	DEALLOCATE En_Ids 
GO
EXEC InsertInto_Tc 100
GO

/* 
We notice that by now:  
- We have a clustered index automatically created for the OId column from Offerings
- We have a nonclustered index automatically created for the Log_code column from Offerings
- We have a clustered index automatically created for the EId column from Entity
- We have a clustered index automatically created for the PId column from Pairs
*/


----------Point a----------
-----clustered index scan-----
SELECT * FROM Offerings O
--we scan the entire table

-----clustered index seek-----
SELECT * FROM Offerings O
WHERE O.OId >= 2
--we get a specific subset of rows from a clustered index

-----non clustered index scan-----
SELECT O.Log_code FROM Offerings O
ORDER BY O.Log_code
--we scan the entire nonclustered index

-----non clustered index seek-----
SELECT O.Log_code FROM Offerings O
WHERE O.Log_code BETWEEN 1 AND 1000
--we take a specific subset of rows from a nonclustered index

-----key lookup-----
SELECT O.Duration_inGames, O.Log_code FROM Offerings O
WHERE O.Log_code = 51937
--the data is found in a nonclustered index, but additional data is needed

----------Point b----------

SELECT E.Age FROM Entity E
WHERE E.Age = 115  

--Before creating a nonclustered index we have a clustered index scan with the cost: 0.003502
DROP INDEX IF EXISTS EntityIn_onAge ON Entity
CREATE NONCLUSTERED INDEX EntityIn_onAge ON Entity(Age)
--After creating the nonclustered index on Age, we have a noclustered index seek with the cost: 0.0032831

GO
----------Point c----------
CREATE OR ALTER VIEW Lab5View AS
	SELECT O.OId,E.EId,P.PId FROM Pairs P INNER JOIN Offerings O ON O.OId=P.OfferingId INNER JOIN Entity E ON E.EId=P.EntityId
	WHERE E.Age > 100 AND O.Duration_inGames < 40
GO
SELECT * FROM Lab5View

--With existing indexes(the automatically created ones + nonclustered index on Age): 0,0490282
--When adding a nonclustered index on Duration_inGames to the existing indexes: 0,0489322
--Without the nonclustered index on Age and the nonclustered index on Duration_inGames: 0.0490282
--Automatically created indexes + nonclustered index on Age + nonclustered index on Duration_inGames + nonclustered index on (OfferingId, EntityId) from Pairs: 0,0489037

DROP INDEX IF EXISTS OfferingIn_Duration ON Offerings
CREATE NONCLUSTERED INDEX OfferingIn_Duration ON Offerings(Duration_inGames)

DROP INDEX IF EXISTS PairsIndex ON Pairs
CREATE NONCLUSTERED INDEX PairsIndex ON Pairs(OfferingId, EntityId)
