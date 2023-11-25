/*
	This script creates a new table with system versioning enabled, and adds a new column to the table.

	This will happen over time as new features are added to the applicaiton and new fields are required.
	How will the database handle this?
*/

DECLARE @DataTime DATETIME2;

-- Create a new table with system versioning enabled.
CREATE TABLE [dbo].[Account](
	[ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED,
	[UserId] [varchar](50) NOT NULL,
	[FirstName] [varchar](50) NULL,
	[FavouriteColour] [varchar](50) NULL,
	
	[Active] [bit] NULL,
	
	[PublicId][uniqueidentifier] DEFAULT (NEWID()) NOT NULL,

	[TimeStart] datetime2 (2) GENERATED ALWAYS AS ROW START,
	[TimeEnd] datetime2 (2) GENERATED ALWAYS AS ROW END,
	PERIOD FOR SYSTEM_TIME (TimeStart, TimeEnd)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.AccountHistory));

-- Add some data to the table and update it to get some history records.
-- Add some data to the table.
INSERT INTO [Account] ([UserId], [FirstName], [FavouriteColour])
VALUES
	('fred.smith',	'Fred',		'Blue'),
	('betty.white',	'Betty',	'Pink'),
	('tom.jones',	'Tom',		'Yellow');

-- Add the new field to the table
ALTER TABLE Account
ADD [LastName] [varchar](50) NULL

-- Update the new field with some data
UPDATE Account SET [LastName] = 'Smith' WHERE [UserId] = 'fred.smith';
UPDATE Account SET [LastName] = 'White' WHERE [UserId] = 'betty.white';
UPDATE Account SET [LastName] = 'Jones' WHERE [UserId] = 'tom.jones';

-- We wiat 5 seconds to make it easier to see the history records at a point in time
WAITFOR DELAY '00:00:05'; -- Pause for 5 seconds

UPDATE Account SET [Active] = 1 WHERE [UserId] = 'fred.smith';
UPDATE Account SET [Active] = 1 WHERE [UserId] = 'betty.white';
UPDATE Account SET [Active] = 1 WHERE [UserId] = 'tom.jones';

WAITFOR DELAY '00:00:05'; -- Pause for 5 seconds

-- Set a variable to the current date and time so we can query the table at a point in time at the end.
SET @DataTime = GETDATE();

UPDATE Account SET [Active] = 0 WHERE [UserId] = 'fred.smith';
UPDATE Account SET [Active] = 0 WHERE [UserId] = 'betty.white';
UPDATE Account SET [Active] = 0 WHERE [UserId] = 'tom.jones';

SELECT @DataTime AS [DataTime];

-- Show the data in the table and the history table.
SELECT * FROM Account;
SELECT * FROM AccountHistory;

-- Now we can query the table at a point in time.
SELECT * FROM Account FOR SYSTEM_TIME AS OF @DataTime;


