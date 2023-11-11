/*
    Setup an audit schema for the database.
*/
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'audit')
BEGIN
    -- Drop the schema
    DROP SCHEMA [audit];
END
GO
CREATE SCHEMA [audit];
GO
/*
    Create a role for the website user.
    This will be locked down and only be able to write to certain schemas.
    It will be able to read from the audit schema but not write to it.
*/
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'WebsiteUser' AND type = 'R')
BEGIN
    -- Role exists, so drop it
    DROP ROLE WebsiteUser;
END
CREATE ROLE WebsiteUser;

-- WebsiteUser can read/write in the audit schema but not update it
GRANT INSERT ON SCHEMA::audit TO WebsiteUser;
GRANT SELECT ON SCHEMA::audit TO WebsiteUser;
REVOKE UPDATE ON SCHEMA::audit TO WebsiteUser;
GO

/*
    Create a table to store the tables that should have automatic history setup for them.
    These tables will be watched to:
     1. make sure the history table exists
     2. make sure the history table has all the correct fields matching the base table
     3. make sure the history table can be written to by the WebsiteUser role but not updated or deleted
*/
IF OBJECT_ID('dbo.sysAutoHistoryTables', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.sysAutoHistoryTables;
END
GO
CREATE TABLE [dbo].[sysAutoHistoryTables](
	[id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
    [BaseTableSchemaName] [varchar](255) NOT NULL DEFAULT('dbo'),
	[BaseTableName] [varchar](255) NOT NULL,
    [HistorySchemaName] [varchar](255) NOT NULL DEFAULT('audit'),
	[HistoryTableName] [varchar](255) NULL,
	[Active] [bit] NULL DEFAULT(1)
 CONSTRAINT [PK_sysAutoHistoryTables] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/*
    We will add a record for the Student table that will be created shortly.
*/
INSERT INTO sysAutoHistoryTables (BaseTableSchemaName, BaseTableName, Active)
VALUES ('dbo', 'Student', 1)


/*
    Create a trigger to automatically update the HistoryTableName field when a new row is inserted.
*/
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'trg_sysAutoHistoryTables_AfterInsert')
BEGIN
    -- Drop the trigger
    DROP TRIGGER dbo.trg_sysAutoHistoryTables_AfterInsert;
END
GO

CREATE TRIGGER trg_sysAutoHistoryTables_AfterInsert
ON dbo.sysAutoHistoryTables
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE h
    SET HistoryTableName = COALESCE(h.HistoryTableName, i.BaseTableName + 'History')
    FROM dbo.sysAutoHistoryTables h
    INNER JOIN inserted i ON h.id = i.id
    WHERE i.HistoryTableName IS NULL OR i.HistoryTableName = '';

END;
GO

/*  POC base table Student */
CREATE TABLE [dbo].[Student](
	[id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[FirstName] [varchar](50) NULL,
	[LastName] [varchar](50) NULL,
	[FavouriteColour] [varchar](50) NULL,
	[Active] [bit] NULL,
	[DateModified] [datetime] NULL
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Student] ADD  CONSTRAINT [DF_Student_DateModified]  DEFAULT (getdate()) FOR [DateModified]
GO

ALTER TABLE dbo.Student
ADD CONSTRAINT PK_Student
PRIMARY KEY (Id);

CREATE INDEX IX_Student_Id ON dbo.Student (Id);
CREATE INDEX IX_Student_DateModified ON dbo.Student (DateModified);

GO

/*
    POC history table StudentHistory  
    Here is the script to generate the table manually, but we will use the automatic history trigger to create it.
*/
/*
CREATE TABLE [audit].[StudentHistory](
	[id] [numeric](18, 0) NOT NULL,
	[FirstName] [varchar](50) NULL,
	[LastName] [varchar](50) NULL,
	[FavouriteColour] [varchar](50) NULL,
	[Active] [bit] NULL,
	[DateModified] [datetime] NULL
) ON [PRIMARY]
GO

ALTER TABLE [audit].StudentHistory
ADD CONSTRAINT FK_StudentHistory_Student
FOREIGN KEY (Id) REFERENCES dbo.Student(Id);

CREATE INDEX IX_StudentHistory_Id ON [audit].StudentHistory (Id);
CREATE INDEX IX_StudentHistory_DateModified ON [audit].StudentHistory (DateModified);
GO
*/