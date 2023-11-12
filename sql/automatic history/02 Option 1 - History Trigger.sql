/*
    Option 1:
        Create or update the trigger to insert into StudentHistory.
        This trigger will copy the current value to the history table, update the DateModified value of the base table and insert the old values into the history table.
*/

CREATE OR ALTER TRIGGER [dbo].[trg_Student_Update]
ON [dbo].[Student]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [audit].StudentHistory (id, FirstName, LastName, FavouriteColour, Active, DateModified)
    SELECT 
        d.id,
        d.FirstName,
        d.LastName,
        d.FavouriteColour,
        d.Active,
        d.DateModified
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

ALTER TABLE [dbo].[Student] ENABLE TRIGGER [trg_Student_Update]
GO