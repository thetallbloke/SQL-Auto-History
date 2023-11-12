/*
    This SPROC seems to work as expected.
    It hasn't been tested with every datatype yet, but it seems to work

    * Need to add code to check for a DateModified field and add if necessary.
    * 

    The basic premise of the script is to loop through the sysAutoHistoryTables table and check if the matching history table infrastructure (fields, triggers, etc) exist.
    The script would be executed after a deployment to make sure the history tables are up to date.  It wouldn't be executed on a timer or other schedule
    as it would be expected that the history tables exist and that the audit system is working correctly.
*/

CREATE OR ALTER PROCEDURE SyncHistoryTables
AS
BEGIN
    DECLARE @BaseTableSchemaName NVARCHAR(255);
    DECLARE @BaseTableName NVARCHAR(255);
    DECLARE @HistorySchemaName NVARCHAR(255);
    DECLARE @HistoryTableName NVARCHAR(255);
    DECLARE @DateModifiedColumn NVARCHAR(255);
    DECLARE @PrimaryKeyName NVARCHAR(255);
    DECLARE @ForeignKeyName NVARCHAR(255);
    DECLARE @ColumnName NVARCHAR(255);
    DECLARE @DataType NVARCHAR(255);
	DECLARE @MaxLength INT;
    DECLARE @IsNullable VARCHAR(5);
	DECLARE @strSQL VARCHAR(max);

    DECLARE table_cursor CURSOR FOR
    SELECT
        BaseTableSchemaName,
        BaseTableName,
        HistorySchemaName,
        HistoryTableName,
        DateModifiedColumn
    FROM
        sysAutoHistoryTables
    WHERE
        Active = 1;

    OPEN table_cursor;

    FETCH NEXT FROM table_cursor INTO @BaseTableSchemaName, @BaseTableName, @HistorySchemaName, @HistoryTableName, @DateModifiedColumn;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Check if DateModified column exists.  If it doesn't already exist, create it first.
        -- The base table must exists already anyway, so we can check it directly.
        IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @BaseTableSchemaName AND TABLE_NAME = @BaseTableName AND COLUMN_NAME = @DateModifiedColumn)
        BEGIN
            -- If DateModified column doesn't exist, create the column
            SET @strSQL = 'ALTER TABLE ' + QUOTENAME(@BaseTableSchemaName) + '.' + QUOTENAME(@BaseTableName) + ' ADD ' + QUOTENAME(@DateModifiedColumn) + ' DATETIME';
                
            PRINT (@strSQL);
            EXEC sp_executesql @strSQL;
        END

        -- Check if history table exists
        IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @HistorySchemaName AND TABLE_NAME = @HistoryTableName)
        BEGIN
            PRINT ('Creating history table ' + @HistorySchemaName + '.' + @HistoryTableName);

            -- Create history table if it doesn't exist.  Using the UNION ALL stops IDENTITY attributes of columns being created.  For the history tables, we don't want the IDENTITY attribute because
            -- it stops us from inserting rows into the history table because the IDENTITY column is likely to be the primary key and we need duplicates in this field in order to match the base table.
			SET @strSQL = 'SELECT * INTO ' + QUOTENAME(@HistorySchemaName) + '.' + QUOTENAME(@HistoryTableName) + ' FROM ' + QUOTENAME(@BaseTableSchemaName) + '.' + QUOTENAME(@BaseTableName) + ' WHERE 1 = 0
                           UNION ALL
                           SELECT * FROM ' + QUOTENAME(@BaseTableSchemaName) + '.' + QUOTENAME(@BaseTableName) + ' WHERE 1 = 0;';
            
            PRINT (@strSQL);
			EXEC(@strSQL);

            -- Add foreign key constraint
            SELECT @PrimaryKeyName = COLUMN_NAME
            FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
            WHERE OBJECT_NAME(OBJECT_ID(@BaseTableSchemaName + '.' + @BaseTableName, 'U')) = @BaseTableName
                AND CONSTRAINT_NAME LIKE 'PK%';

            SET @ForeignKeyName = 'FK_' + @HistoryTableName + '_' + @PrimaryKeyName;
			SET @strSQL = 'ALTER TABLE ' + QUOTENAME(@HistorySchemaName) + '.' + QUOTENAME(@HistoryTableName) + 'ADD CONSTRAINT ' + QUOTENAME(@ForeignKeyName) + ' FOREIGN KEY (' + QUOTENAME(@PrimaryKeyName) + ') REFERENCES ' + QUOTENAME(@BaseTableSchemaName) + '.' + QUOTENAME(@BaseTableName) + '(' + QUOTENAME(@PrimaryKeyName) + ');'
			PRINT (@strSQL);
            EXEC(@strSQL);
        END
        ELSE
        BEGIN
            PRINT ('History table ' + @HistorySchemaName + '.' + @HistoryTableName + ' already exists');

            -- Check and add missing columns in history table
            DECLARE column_cursor CURSOR FOR
            SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, CHARACTER_MAXIMUM_LENGTH
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = @BaseTableSchemaName AND TABLE_NAME = @BaseTableName;

            OPEN column_cursor;

            FETCH NEXT FROM column_cursor INTO @ColumnName, @DataType, @IsNullable, @MaxLength;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @HistorySchemaName AND TABLE_NAME = @HistoryTableName AND COLUMN_NAME = @ColumnName)
                BEGIN
					SET @strSQL = 'ALTER TABLE ' + QUOTENAME(@HistorySchemaName) + '.' + QUOTENAME(@HistoryTableName) + ' ADD ' + QUOTENAME(@ColumnName) + ' ' + (CASE WHEN @DataType = 'varchar' THEN CONCAT(@DataType, '(', @MaxLength, ')') ELSE @DataType END) + ' ' + (CASE WHEN @IsNullable = 'YES' THEN 'NULL' ELSE 'NOT NULL' END) + ';'
					PRINT (@strSQL);
					EXEC(@strSQL);
                END

                FETCH NEXT FROM column_cursor INTO @ColumnName, @DataType, @IsNullable, @MaxLength;
            END

            CLOSE column_cursor;
            DEALLOCATE column_cursor;
        END

        FETCH NEXT FROM table_cursor INTO @BaseTableSchemaName, @BaseTableName, @HistorySchemaName, @HistoryTableName, @DateModifiedColumn;
    END

    CLOSE table_cursor;
    DEALLOCATE table_cursor;
END;
