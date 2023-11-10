/*

    NOT YET TESTED.
    If this works, it will automatically add new columns to the History tables
	when they are added to the base tables.

*/

DECLARE @TableName NVARCHAR(100);
DECLARE @HistoryTableName NVARCHAR(100);

DECLARE table_cursor CURSOR FOR
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
AND TABLE_NAME LIKE '%History';

OPEN table_cursor;

FETCH NEXT FROM table_cursor INTO @HistoryTableName;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Extract the base table name (remove "History" suffix)
    SET @TableName = LEFT(@HistoryTableName, LEN(@HistoryTableName) - LEN('History'));

    -- Check if the base table exists
    IF OBJECT_ID(@TableName, 'U') IS NOT NULL
    BEGIN
        DECLARE @ColumnName NVARCHAR(100);

        DECLARE column_cursor CURSOR FOR
        SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = @TableName;

        OPEN column_cursor;

        FETCH NEXT FROM column_cursor INTO @ColumnName;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Check if the column exists in the History table
            IF NOT EXISTS (
                SELECT 1
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_NAME = @HistoryTableName
                AND COLUMN_NAME = @ColumnName
            )
            BEGIN
                -- If the column doesn't exist, add it to the History table
                DECLARE @DataType NVARCHAR(100);

                SELECT @DataType = DATA_TYPE
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_NAME = @TableName
                AND COLUMN_NAME = @ColumnName;

                DECLARE @DynamicSQL NVARCHAR(MAX);
                SET @DynamicSQL = 'ALTER TABLE ' + @HistoryTableName + ' ADD ' + @ColumnName + ' ' + @DataType;

                EXEC sp_executesql @DynamicSQL;
            END

            FETCH NEXT FROM column_cursor INTO @ColumnName;
        END

        CLOSE column_cursor;
        DEALLOCATE column_cursor;
    END

    FETCH NEXT FROM table_cursor INTO @HistoryTableName;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;
