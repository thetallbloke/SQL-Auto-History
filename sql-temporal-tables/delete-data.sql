/*
	This script shows how you can delete data from a temporal table.

	This might seem counter intuitive, but if we receive a request to delete personal data, we need to be able to do this.

*/

-- Create a new table with system versioning enabled.
CREATE TABLE [dbo].[Account](
	[ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED,
	[UserId] [varchar](50) NOT NULL,
	[FirstName] [varchar](50) NULL,
	[LastName] [varchar](50) NULL,
	[FavouriteColour] [varchar](50) NULL,
	
	[Active] [bit] NULL,
	
	[PublicId][uniqueidentifier] DEFAULT (NEWID()) NOT NULL,

	[TimeStart] datetime2 (2) GENERATED ALWAYS AS ROW START,
	[TimeEnd] datetime2 (2) GENERATED ALWAYS AS ROW END,
	PERIOD FOR SYSTEM_TIME (TimeStart, TimeEnd)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.AccountHistory));

-- Add some data to the table and update it to get some history records.
INSERT INTO [Account] ([UserId], [FirstName], [LastName], [FavouriteColour])
VALUES
	('fred.smith',	'Fred',		'Smith',		'Blue'),
	('betty.white',	'Betty',	'White',		'Pink'),
	('tom.jones',	'Tom',		'Jones',		'Yellow');

UPDATE Account SET [Active] = 1 WHERE [UserId] = 'fred.smith';
UPDATE Account SET [Active] = 1 WHERE [UserId] = 'betty.white';
UPDATE Account SET [Active] = 1 WHERE [UserId] = 'tom.jones';

UPDATE Account SET [Active] = 0 WHERE [UserId] = 'fred.smith';
UPDATE Account SET [Active] = 0 WHERE [UserId] = 'betty.white';
UPDATE Account SET [Active] = 0 WHERE [UserId] = 'tom.jones';

-- Show the data in the table and the history table.
SELECT * FROM Account;
SELECT * FROM AccountHistory;

-- Now delete the data from the table and the history table.

-- First we need to disable system versioning.
ALTER TABLE Account SET (SYSTEM_VERSIONING = OFF);
GO

-- Now we can delete the data.
DELETE FROM Account WHERE [UserId] = 'fred.smith';
DELETE FROM AccountHistory WHERE [UserId] = 'fred.smith';

-- Now we can re-enable system versioning.
ALTER TABLE Account SET (SYSTEM_VERSIONING = ON);

SELECT * FROM Account;
SELECT * FROM AccountHistory;