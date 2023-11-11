select *
from Student

select *
from audit.StudentHistory
ORDER BY DateModified DESC

DECLARE @CurrentDateTime DATETIME = GETDATE();
SET @CurrentDateTime = '2023-11-12 10:22:21';

-- Test getting the latest record for a specific student for the given date
EXEC usp_Student_GetAtPointInTime @GivenDate = @CurrentDateTime, @Id = 1;

-- Test getting the latest record for all students for the given date
EXEC usp_Student_GetAtPointInTime @GivenDate = @CurrentDateTime;

/*

-- Create some test data.

	INSERT INTO Student (FirstName, LastName, FavouriteColour, Active) VALUES ('Tom', 'Jones', 'Blue', 1)
	INSERT INTO Student (FirstName, LastName, FavouriteColour, Active) VALUES ('Fred', 'Smith', 'Purple', 1)
	
-- Update the data a few times.
-- Run these with a few seconds between each one.

	UPDATE Student SET FavouriteColour = 'Pink' WHERE id = 2
	UPDATE Student SET FavouriteColour = 'Grey' WHERE id = 2
	UPDATE Student SET FavouriteColour = 'Red' WHERE id = 2
	UPDATE Student SET FavouriteColour = 'Yellow' WHERE id = 2

	UPDATE Student SET FavouriteColour = 'Yellow' WHERE id = 1
	UPDATE Student SET FavouriteColour = 'Red' WHERE id = 1
	UPDATE Student SET FavouriteColour = 'Grey' WHERE id = 1
	UPDATE Student SET FavouriteColour = 'Pink' WHERE id = 1

-- Clean up test data.

	TRUNCATE TABLE dbo.Student
	DROP TABLE audit.StudentHistory
	EXEC SyncHistoryTables

*/