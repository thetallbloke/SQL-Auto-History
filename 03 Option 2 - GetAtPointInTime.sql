/*
    This sproc will return the data for a given student at a given point in time.
    If the @Id parameter is not supplied, then the data for all students will be returned.
*/

CREATE OR ALTER PROCEDURE usp_Student_GetAtPointInTime
    @GivenDate DATETIME,
    @Id NUMERIC(18, 0) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    WITH RankedStudentHistory AS (
        SELECT
            sh.id,
            sh.FirstName,
            sh.LastName,
            sh.FavouriteColour,
            sh.Active,
            sh.DateModified,
            ROW_NUMBER() OVER (PARTITION BY sh.Id ORDER BY sh.DateModified DESC) AS RowNum
        FROM
            audit.StudentHistory sh
        WHERE sh.DateModified <= @GivenDate
          AND (@Id IS NULL OR sh.Id = @Id)
    )
    SELECT
        id,
        FirstName,
        LastName,
        FavouriteColour,
        Active,
        DateModified
    FROM
        RankedStudentHistory
    WHERE
        RowNum = 1;
END;
