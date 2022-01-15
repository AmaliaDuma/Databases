USE [Dead by daylight]
GO

--Insert data
INSERT INTO Bugs VALUES (411, 'Medium', 'P2','New'), (412, 'Major', 'P3','New'), (413, 'Medium', 'P1','Resolved'), (414, 'Low', 'P1','New');
INSERT INTO Developer VALUES (11, 'David', 25, 2, 4500, 414), (12, 'Lisa', 27, 4, 6000, 413), (13, 'Lana', 30, 5, 6550, 412), (14, 'Erick', 27, 5, 6400, 412);
INSERT INTO Map VALUES (1, 'Coal Tower', 'The MacMillan Estate', 'True', 8, 12, 8448), (2, 'Groaning Storehouse', 'The MacMillan Estate', 'True', 8, 14, 9984);
INSERT INTO Map VALUES (3, 'The Underground Complex', 'Hawkins National Laboratory', 'False', 14, 12, 8832)
INSERT INTO Game VALUES (911, 1, 0) , (912,2,0);
INSERT INTO Game VALUES (913, 14, 0) --for the point: "at least one statement should violate referential integrity constraints"
INSERT INTO Record VALUES (911, 413, 2)
INSERT INTO Killer(Kid, Terror_radius, Height, Realm, GameId) VALUES (1, 20, 165, 'Red Forest', 911); --to work the delete
INSERT INTO Killer VALUES (311, 'The Huntress', 20, 4.4, 180, 'Red Forest', 911), (312, 'The Trapper', 32, 4.6, 196, 'The MacMillan Estate', 912);
INSERT INTO Ability VALUES (61, 'Hunting Hatchets', 'True', 0, 'Normal', 311), (62, 'Bear Trap', 'False', 0, 'Normal', 312);
INSERT INTO Item VALUES (1, 'Flash Light', 'Common', 10),(2, 'Med-Kit', 'Rare', 16), (3, 'Map', 'Ultra Rare', 20), (4, 'Toolbox', 'Rare', 16);
INSERT INTO Item VALUES (5, 'Key', 'Very Rare', 5)
INSERT INTO Survivor VALUES (211, 'KENZI', 'Meg Thomas', 50, 5422, 'Third', 911), (212, 'Altair', 'Jake Park', 42, 5102, 'Third', 911), (213, 'Tigra', 'Nea Karlsson', 47, 5277, 'Second', 911);  
INSERT INTO Slot VALUES (211, 1), (212,2), (212,3), (213,5);
INSERT INTO Native_perks VALUES (511, 'Quick & Quiet', 'You do not make as much noise as others when quickly vaulting over obstacles or hiding in Lockers', 211)
INSERT INTO Native_perks VALUES (512, 'Sprint Burst', 'When starting to run, break into a sprint at 150 % of your normal Running Movement speed for 3 seconds', 211)
INSERT INTO Native_perks VALUES (513, 'Adrenaline', 'Once the Exit Gates are powered, instantly heal one Health State and sprint at 150 % of your normal Running Movement speed for 5 seconds.', 211)

--useful to delete everything in the db. Right order to not violate integrity constraints
DELETE FROM Slot;
DELETE FROM Item;
DELETE FROM Survivor;
DELETE FROM Ability;
DELETE FROM Killer;
DELETE FROM Record;
DELETE FROM Game;
DELETE FROM Map;
DELETE FROM Developer;
DELETE FROM Bugs;

--Update data
-- For the maps which have nr_pallets between 12 and 20 add 160 m^2 to the size
UPDATE Map 
SET Size = Size + 160
WHERE Nr_pallets BETWEEN 12 AND 20;

--For the devs with experience > 5 add 300 to their salary
UPDATE Developer
SET Salary = Salary + 300
WHERE Experience > 5;

--If the ability has 2 or 3 addons, add 1 to the effectiveness
UPDATE Ability
SET Effectiveness = Effectiveness+1
WHERE Nr_addons IN (2,3);

--Delete data
--Delete the entry where by mistake we left Speed for a Killer in Killer table null
DELETE FROM Killer WHERE Speed IS NULL;

--Delete the entries where the item has common rarity and duration >10
DELETE FROM Item WHERE Rarity LIKE'c%n' AND (NOT Duration<10);

--Queries

--Find the killers id who have a terrior radius bigger than 40m or have a ranged ability
--Union with 'UNION' -> point a)
SELECT K.Kid
FROM Killer K
WHERE K.Terror_radius > 40
UNION
SELECT A.KillerId
FROM Ability A
WHERE A.Ranged = 'True'

--Find the games id whose map has 10 pallets or 14 lockers.
--Union with 'OR' -> point a)
SELECT G.Gid
FROM Game G, Map M
WHERE G.MapId = M.MPid AND ( M.Nr_pallets = 10 OR M.Nr_lockers = 14)

--Find the ability name that coresponds to the killer with speed=4.4 and terror radius=20
--Intersect with 'INTERSECT' -> point b)
SELECT A.Name_
FROM Ability A, Killer K
WHERE K.Kid = A.KillerId AND K.Speed=4.4
INTERSECT
SELECT A2.Name_
FROM Ability A2, Killer K2
WHERE K2.Kid = A2.KillerId AND K2.Terror_radius=20

--Find the survivor username who has a Med-Kit and a Map
--Intersect with 'AND' -> point b)
SELECT Sv.Username
FROM Survivor Sv, Slot S1, Item I1, Slot S2, Item I2
WHERE (Sv.SVid = S1.SurvivorId AND S1.ItemId = I1.ITid AND I1.Itm_name = 'Med-Kit' ) AND (Sv.SVid = S2.SurvivorId AND S2.ItemId = I2.ITid AND I2.Itm_name = 'Map')

--Find the survivor username who has a Flash Light, but not a Map
--Difference with 'EXCEPT' -> point c)
SELECT Sv.Username
FROM Survivor Sv, Slot S1, Item I1
WHERE Sv.SVid = S1.SurvivorId AND S1.ItemId = I1.ITid AND I1.Itm_name = 'Flash Light'
EXCEPT
SELECT Sv2.Username
FROM Survivor Sv2, Slot S2, Item I2
WHERE Sv2.SVid = S2.SurvivorId AND S2.ItemId = I2.ITid AND I2.Itm_name = 'Map'

--Find the bugs id and the status whose dev have age > 25, but don't have an experience > 5
--Difference with 'NOT IN' -> point c)
SELECT B.Bid, B.Status_is
FROM Bugs B, Developer D
WHERE B.Bid = D.BugId AND D.Age > 25 AND
	B.Bid NOT IN (
	SELECT D1.BugId
	FROM Developer D1
	WHERE D1.Experience >= 5)

--Find all games id including the bugs presented and the devs name who are handling them, and the survivors username with their items name and rarity
--Inner Join -> point d)
--This joins two many-to-many relationships
SELECT D.First_name, B.Bid, B.BPriority, B.Severity, B.Status_is, G.Gid, S.Username, I.Itm_name, I.Rarity
FROM Developer D INNER JOIN Bugs B ON D.BugId = B.Bid INNER JOIN Record R ON B.Bid = R.BugId INNER JOIN Game G ON G.Gid = R.GameId
  INNER JOIN Survivor S ON S.GameId = G.Gid INNER JOIN Slot Sl ON Sl.SurvivorId = S.SVid  INNER JOIN Item I ON Sl.ItemId = I.ITid

--Find all bugs devs, include bugs with no devs
--Left (Outer) Join -> point d)
SELECT *
FROM Bugs B LEFT JOIN Developer D ON B.Bid = D.BugId

--Find all games and the maps they have. Include maps with no games
--Right (Outer) Join -> point d)
SELECT*
FROM Game G RIGHT JOIN Map M ON M.MPid = G.MapId

--Find all survivors items. Include survivor with no items and items who don't coresspond to any survivor
--Full (Outer) Join -> point d)
--This joins 3 tables
SELECT*
FROM Survivor S FULL JOIN Slot Sl on S.SVid = Sl.SurvivorId FULL JOIN Item I on Sl.ItemId = I.ITid

--Find the name and the rarity of the items used by survivors of level 50. Eliminate duplicates if any
--IN operator with a subquery that has a subquery in it's own WHERE clause. -> point e)
SELECT DISTINCT I.Itm_name, I.Rarity
FROM Item I
WHERE I.ITid IN (
	SELECT S.ItemId
	FROM Slot S
	WHERE S.SurvivorId IN
		(SELECT SV.SVid
		FROM Survivor SV
		WHERE SV.Lvl = 50))

--Find the developers first name who are assigned to a bug with severity "Major"
--IN operator with a subquery -> point e)
SELECT D.First_name
FROM Developer D
WHERE D.BugId IN (
	SELECT B.Bid
	FROM Bugs B
	WHERE B.Severity = 'Major')

--Find the first 2 bugs that have the status "New"
--EXISTS with subquery and TOP -> point f)
SELECT TOP 2 *
FROM Bugs B
WHERE EXISTS(
	SELECT *
	FROM Bugs B1
	WHERE B1.Bid = B.Bid AND B1.Status_is = 'New')

--Find top 3 oldest devs who have a salary bigger than 5000
--EXISTS with subquery and TOP -> point f)
SELECT TOP 3 *
FROM Developer D
WHERE EXISTS(
	SELECT *
	FROM Developer D1
	WHERE D1.Did = D.Did AND D1.Salary>5000)
ORDER BY D.Age DESC

--Find the developers name and age whose age is >= than the avg of all devs ages and order in ascending mode by name
--subquery in FROM and ORDER BY -> point g)
SELECT D.First_name, D.Age, AvgAge.average_age
FROM (SELECT AVG(D1.Age) as average_age FROM Developer D1) as AvgAge, Developer D
WHERE D.Age >= AvgAge.average_age
ORDER BY D.First_name

--Find the survivors username and level whose level is >= than the avg level of all survivors. Order descending by level
--subquery in FROM and ORDER BY -> point g)
SELECT S.Username, S.Lvl, AvgL.Average_lvl
FROM (SELECT AVG(S1.Lvl) as Average_lvl FROM Survivor S1) as AvgL, Survivor S
WHERE S.Lvl >= AvgL.Average_lvl
ORDER BY S.Lvl DESC

--Find the number of maps per realm. The realm should have at least one map.
--GROUP BY with HAVING -> point h)
SELECT COUNT(M.MPid) AS Nr_Maps, M.Realm
FROM Map M
GROUP BY M.Realm
HAVING COUNT(M.MPid) >= 1

--Find the average salaries per age that are > than the average of all salaries
--GROUP BY WITH HAVING and subquery in HAVING -> point h)
SELECT D.Age, AVG(D.Salary) AS Average_Salary
FROM Developer D
GROUP BY D.Age
HAVING AVG(D.Salary) > 
	(SELECT AVG(D1.Salary)
	FROM Developer D1)

--Find the min duration per item rarity that is > than the min of all items duration
--GROUP BY WITH HAVING and subquery in HAVING -> point h)
SELECT I.Rarity, MIN(I.Duration) AS Min_Duration
FROM Item I
GROUP BY I.Rarity
HAVING MIN(I.Duration) >
	(SELECT MIN(I1.Duration)
	FROM Item I1)

--FIND the number of bugs per severity
--GROUP BY -> point h)
SELECT B.Severity, COUNT(B.Bid) AS Nr_of_bugs
FROM Bugs B
GROUP BY B.Severity

--Find all survivors who don't have a native perk in the database
--ANY with subquery  -> point i)
SELECT *
FROM Survivor S
WHERE S.SVid != ANY(
	SELECT N.SurvivorId
	FROM Native_perks N)

--Find all survivors who don't have a native perk in the database
--The rewrite version of the one with ANY, now with NOT IN  -> point i)
SELECT *
FROM Survivor S
WHERE S.SVid NOT IN(
	SELECT N.SurvivorId
	FROM Native_perks N)

--Find all distinct realms whose map nr of lockers is equal to the nr of lockers of an outdoor map
--ANY with subquery  -> point i)
SELECT DISTINCT M.Realm
FROM Map M
WHERE M.Nr_lockers = ANY(
	SELECT M1.Nr_lockers
	FROM Map M1
	WHERE M1.Outdoor = 'True'
	)

--Find all distinct realms whose map nr of lockers is equal to the nr of lockers of an outdoor map
--The rewrite version of the one with ANY, now with IN  -> point i)
SELECT DISTINCT M.Realm
FROM Map M
WHERE M.Nr_lockers IN(
	SELECT M1.Nr_lockers
	FROM Map M1
	WHERE M1.Outdoor = 'True')

--Find the developer first name and salary whose salary is > than the highest salary of devs with experience=4
--ALL with subquery  -> point i)
SELECT D.First_name, D.Salary
FROM Developer D
WHERE D.Salary > ALL(
	SELECT D1.Salary
	FROM Developer D1
	WHERE D1.Experience = 4)

--Find the developer first name and salary whose salary is > than the highest salary of devs with experience=4
--The rewrite version of the one with ALL, now with MAX  -> point i)
SELECT D.First_name, D.Salary
FROM Developer D
WHERE D.Salary > (
	SELECT MAX(D1.Salary)
	FROM Developer D1
	WHERE D1.Experience = 4)

--Find all distinct item names whose duration is < than the smallest duration of items with rarity 'Rare' 
--ALL with subquery  -> point i)
SELECT DISTINCT I.Itm_name
FROM Item I
WHERE I.Duration < ALL(
	SELECT I1.Duration
	FROM Item I1
	WHERE I1.Rarity = 'Rare')

--Find all distinct item names whose duration is < than the smallest duration of items with rarity 'Rare' 
--The rewrite version of the one with ALL, now with MIN  -> point i)
SELECT DISTINCT I.Itm_name
FROM Item I
WHERE I.Duration < (
	SELECT MIN(I1.Duration)
	FROM Item I1
	WHERE I1.Rarity = 'Rare')

--Find the Christmas bonus for the devs that is calculated 20% of their salary
--Arithmetic expressions in the SELECT clause
SELECT D.First_name, D.Salary, (20*D.Salary/100) AS Christmas_Bonus
FROM Developer D

--Find the anual salary of the devs
--Arithmetic expressions in the SELECT clause
SELECT D.First_name, (D.Salary*12) AS Anual_Salary
FROM Developer D
WHERE D.Experience > 3

--Find the days played for each survivor
--Arithmetic expressions in the SELECT clause
SELECT S.Username, (S.Hours_played/24) AS Days_played
FROM Survivor S

--Useful for checking the data and if the query had the right answer
SELECT * FROM Bugs;
SELECT * FROM Developer;
SELECT * FROM Record;
SELECT * FROM Game;
SELECT * FROM Map;
SELECT * FROM Killer;
SELECT * FROM Ability;
SELECT * FROM Survivor;
SELECT * FROM Item;
SELECT * FROM Slot;
SELECT * FROM Native_perks;
