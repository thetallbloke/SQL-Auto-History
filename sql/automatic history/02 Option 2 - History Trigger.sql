/*
    Option 2:
        Create a trigger to automatically insert into StudentHistory when a new row is inserted.
        This essentailly copies the new row into the history table while also keeping the DateModified value up to date.
        Option 2 needs to run on INSERT and UPDATE because otherwise the first record inserted will not have a DateModified value or be copied to the history table.

        Added in the @ActionTime variable to ensure that the DateModified value is the same for the base table and the history table.
*/

CREATE TRIGGER trg_Student_Update
ON dbo.Student
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ActionTime DATETIME = GETDATE();

    -- Update DateModified in Student table
    UPDATE s
    SET DateModified = @ActionTime
    FROM dbo.Student s
    INNER JOIN inserted i ON s.id = i.id;

    -- Insert updated values into StudentHistory table
    INSERT INTO audit.StudentHistory (id, FirstName, LastName, FavouriteColour, Active, DateModified)
    SELECT
        i.id,
        i.FirstName,
        i.LastName,
        i.FavouriteColour,
        i.Active,
        @ActionTime
    FROM
        inserted i;
END;

ALTER TABLE [dbo].[Student] ENABLE TRIGGER [trg_Student_Update]
GO