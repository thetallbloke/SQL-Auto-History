/*
	This script creates a table adds some data to it, and then enables system versioning.
*/

-- Create a new table without system versioning enabled.
CREATE TABLE [dbo].[Account](
	[ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED,
	[UserId] [varchar](50) NOT NULL,
	[FirstName] [varchar](50) NULL,
	[FavouriteColour] [varchar](50) NULL,
	
	[Active] [bit] NULL,
	
	[PublicId][uniqueidentifier] DEFAULT (NEWID()) NOT NULL
)

-- Add some data to the table.
INSERT INTO [Account] ([UserId], [FirstName], [FavouriteColour])
VALUES
	('fred.smith',	'Fred',		'Blue'),
	('betty.white',	'Betty',	'Pink'),
	('tom.jones',	'Tom',		'Yellow');

-- We wiat 5 seconds to make it easier to see the history records at a point in time
WAITFOR DELAY '00:00:05'; -- Pause for 5 seconds

-- Add the required fields for system versioning.
ALTER TABLE dbo.Account ADD
	[TimeStart] DATETIME2(0)  GENERATED ALWAYS AS ROW START NOT NULL CONSTRAINT DFT_Account_TimeStart DEFAULT ('19000101'),
	[TimeEnd] DATETIME2(0) GENERATED ALWAYS AS ROW END NOT NULL CONSTRAINT DFT_Account_TimeEnd DEFAULT ('99991231 23:59:59'),
	PERIOD FOR SYSTEM_TIME ([TimeStart], [TimeEnd]);

ALTER TABLE dbo.Account DROP CONSTRAINT DFT_Account_TimeStart, DFT_Account_TimeEnd;
ALTER TABLE dbo.Account  SET ( SYSTEM_VERSIONING = ON ( HISTORY_TABLE = dbo.AccountHistory ) );
GO

-- Now we can add a new LastName column to the table.
ALTER TABLE Account
ADD [LastName] [varchar](50) NULL

-- Update the new field with some data
UPDATE Account SET [LastName] = 'Smith' WHERE [UserId] = 'fred.smith';
UPDATE Account SET [LastName] = 'White' WHERE [UserId] = 'betty.white';
UPDATE Account SET [LastName] = 'Jones' WHERE [UserId] = 'tom.jones';

DECLARE @DataTime DATETIME2;
SET @DataTime = GETDATE();

WAITFOR DELAY '00:00:05'; -- Pause for 5 seconds

UPDATE Account SET [Active] = 1 WHERE [UserId] = 'fred.smith';
UPDATE Account SET [Active] = 1 WHERE [UserId] = 'betty.white';
UPDATE Account SET [Active] = 1 WHERE [UserId] = 'tom.jones';

WAITFOR DELAY '00:00:05'; -- Pause for 5 seconds

UPDATE Account SET [Active] = 0 WHERE [UserId] = 'fred.smith';
UPDATE Account SET [Active] = 0 WHERE [UserId] = 'betty.white';
UPDATE Account SET [Active] = 0 WHERE [UserId] = 'tom.jones';

SELECT @DataTime

SELECT * FROM Account;
SELECT * FROM AccountHistory;

SELECT * FROM Account FOR SYSTEM_TIME AS OF @DataTime;