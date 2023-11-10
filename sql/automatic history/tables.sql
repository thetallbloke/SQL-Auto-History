/*  Main Student table. */
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

/*  Create or update the trigger to insert into StudentHistory. */

CREATE OR ALTER TRIGGER [dbo].[trg_Student_Update]
ON [dbo].[Student]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.StudentHistory (id, FirstName, LastName, FavouriteColour, Active, DateModified)
    SELECT 
        d.id,
        d.FirstName,
        d.LastName,
        d.FavouriteColour,
        d.Active,
        d.DateModified -- Current timestamp for DateModified in Student
    FROM
        deleted d
    JOIN
        inserted i ON d.id = i.id
    WHERE
        i.FirstName != d.FirstName OR
        i.LastName != d.LastName OR
        i.FavouriteColour != d.FavouriteColour OR
        i.Active != d.Active;

    UPDATE dbo.Student
    SET DateModified = GETDATE()
    FROM
        dbo.Student s
    JOIN
        inserted i ON s.id = i.id;
END;
GO

ALTER TABLE [dbo].[Student] ENABLE TRIGGER [trg_Student_Update]
GO

/*  Matching StudentHistory table.  */

CREATE TABLE [dbo].[StudentHistory](
	[id] [numeric](18, 0) NOT NULL,
	[FirstName] [varchar](50) NULL,
	[LastName] [varchar](50) NULL,
	[FavouriteColour] [varchar](50) NULL,
	[Active] [bit] NULL,
	[DateModified] [datetime] NULL
) ON [PRIMARY]
GO