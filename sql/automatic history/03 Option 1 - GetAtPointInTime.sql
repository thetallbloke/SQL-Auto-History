/*
    This sproc will return the data for a given student at a given point in time.
    If the @Id parameter is not supplied, then the data for all students will be returned.
*/

CREATE OR ALTER PROCEDURE [dbo].[usp_Student_GetAtPointInTime]
    @GivenDate DATETIME,
    @Id NUMERIC(18, 0) = NULL
AS
BEGIN
    WITH CombinedData AS (
        SELECT
            'Student' AS SourceTable,
            id,
            FirstName,
            LastName,
            FavouriteColour,
            Active,
            DateModified
        FROM
            dbo.Student
        UNION ALL
        SELECT
            'StudentHistory' AS SourceTable,
            id,
            FirstName,
            LastName,
            FavouriteColour,
            Active,
            DateModified
        FROM
            dbo.StudentHistory
    )
    SELECT
        SourceTable,
        id,
        FirstName,
        LastName,
        FavouriteColour,
        Active,
        DateModified
    FROM
        (
            SELECT
                SourceTable,
                id,
                FirstName,
                LastName,
                FavouriteColour,
                Active,
                DateModified,
                ROW_NUMBER() OVER (PARTITION BY id ORDER BY DateModified DESC) AS RowNum
            FROM
                CombinedData
            WHERE
                (@Id IS NULL OR id = @Id) AND DateModified <= @GivenDate
        ) AS RankedData
    WHERE
        RowNum = 1;
END;
GO
