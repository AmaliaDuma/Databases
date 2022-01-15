USE [Dead by daylight]
GO

DROP TABLE dbo.Ability;
DROP TABLE dbo.Killer;
DROP TABLE dbo.Slot;
DROP TABLE dbo.Item;
DROP TABLE dbo.Native_perks;
DROP TABLE dbo.Survivor;
DROP TABLE dbo.Developer;
DROP TABLE dbo.Record;
DROP TABLE dbo.Bugs;
DROP TABLE dbo.Game;
DROP TABLE dbo.Map;



CREATE TABLE Bugs(
	Bid INT PRIMARY KEY,
	Severity VARCHAR(25),
	BPriority VARCHAR(10),
	Status_is VARCHAR(10) DEFAULT 'New'
)

/* A bug can be handled by many devs.
   A dev can handle 1 bug. 
   1:n relationship  so the Developer table holds as foreign key the bugId
*/

CREATE TABLE Developer(
	Did INT PRIMARY KEY,
	First_name VARCHAR(10),
	Age INT,
	Experience INT,
	Salary INT,
	BugId INT FOREIGN KEY REFERENCES Bugs(Bid) ON DELETE CASCADE 
)

CREATE TABLE Map(
	MPid INT PRIMARY KEY,
	Name_ VARCHAR(30),
	Realm VARCHAR(30),
	Outdoor VARCHAR(10) DEFAULT 'False',
	Nr_pallets INT,
	Nr_lockers INT,
	Size INT
)

CREATE TABLE Game(
	Gid INT PRIMARY KEY,
	MapId INT FOREIGN KEY REFERENCES Map(MPid),
	Nr_offerings INT DEFAULT 0
)

/* A map can be assigned to many games.
   A game can only have 1 map.
   1:n relationship  so the Game table holds as foreign key the MapId
*/

CREATE TABLE Record(
	GameId INT REFERENCES Game(Gid),
	BugId INT REFERENCES Bugs(Bid),
	PRIMARY KEY(GameId, BugId),
	Players_affected INT
)

/* A game can have many bugs.
   A bug can appear in many games.
   m:n so we have table "Record" for these 2.
*/

CREATE TABLE Killer(
	Kid INT PRIMARY KEY,
	Name_ VARCHAR(15),
	Terror_radius INT,
	Speed FLOAT(1),
	Height INT,
	Realm VARCHAR(20),
	GameId INT UNIQUE FOREIGN KEY REFERENCES Game(Gid)
)

/* In a game there is 1 killer.
   A killer can be in a game.
   1:1 relationship 
*/
CREATE TABLE Ability(
	Aid INT PRIMARY KEY,
	Name_ VARCHAR(30),
	Ranged VARCHAR(10) DEFAULT 'False',
	Nr_addons INT DEFAULT 0,
	Effectiveness VARCHAR(10),
	KillerId INT UNIQUE FOREIGN KEY REFERENCES Killer(Kid)
)

/* A killer can have 1 power.
   A power can corespond to 1 killer.
   1:1 relationship 
*/

CREATE TABLE Survivor(
	SVid INT PRIMARY KEY,
	Username VARCHAR(20),
	Character_name VARCHAR(20),
	Lvl INT,
	Hours_played INT,
	Prestige VARCHAR(10) DEFAULT 'None',
	GameId INT FOREIGN KEY REFERENCES Game(Gid) ON DELETE CASCADE
)

/* In a match there can be many survivors.
   A survivor can only be in a match.
   1:n relationship  so the Survivor table holds as foreign key the GameId
*/

CREATE TABLE Native_perks(
	PKid INT PRIMARY KEY,
	Name_ VARCHAR(20),
	Description_ VARCHAR(200),
	SurvivorId INT FOREIGN KEY REFERENCES Survivor(SVid) ON DELETE CASCADE
)

/* A survivor can have many native perks
   A native perk can coresspond to 1 survivor
   1:n relationship so the Native_perks holds as foreign key the SurvivorId
*/

CREATE TABLE Item(
	ITid INT PRIMARY KEY,
	Itm_name VARCHAR(20),
	Rarity VARCHAR(10),
	Duration INT
)

CREATE TABLE Slot(
	SurvivorId INT REFERENCES Survivor(SVid),
	ItemId INT REFERENCES Item(ITid),
	PRIMARY KEY(SurvivorId, ItemId)
)

/* A survivor can have many items.
   An item can be found in many survivors.
   m:n so we have table "Slot" for these 2.
*/
