CREATE OR ALTER PROCEDURE dbo.GenerateTriggers
AS
BEGIN
    DECLARE @TableName NVARCHAR(255);
    DECLARE @SchemaName NVARCHAR(255);
    DECLARE @HistoryTableName NVARCHAR(255);
    DECLARE @HistorySchemaName NVARCHAR(255);
    DECLARE @DateModifiedColumn NVARCHAR(255);
    DECLARE @PrimaryKeyColumn NVARCHAR(255);
    DECLARE @strSQL NVARCHAR(MAX);
    DECLARE @ColumnNames NVARCHAR(MAX);
	DECLARE @IColumnNames NVARCHAR(MAX);

    DECLARE trigger_cursor CURSOR FOR
        SELECT BaseTableName, [BaseTableSchemaName], HistoryTableName, HistorySchemaName, DateModifiedColumn, PrimaryKeyColumn
        FROM dbo.sysAutoHistoryTables;

    OPEN trigger_cursor;
    FETCH NEXT FROM trigger_cursor INTO @TableName, @SchemaName, @HistoryTableName, @HistorySchemaName, @DateModifiedColumn, @PrimaryKeyColumn;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Drop existing trigger
        SET @strSQL = 'IF OBJECT_ID(''trg_' + @TableName + '_Update'', ''TR'') IS NOT NULL DROP TRIGGER trg_' + @TableName + '_Update;';
        EXEC sp_executesql @strSQL;

        -- Get column names for the base table
        SELECT @ColumnNames = STRING_AGG(QUOTENAME(column_name), ', ') FROM information_schema.columns WHERE table_name = @TableName AND table_schema = @SchemaName;
		-- Need to get the same column names with the alias d. for the deleted table for use in the SELECT statement
        SELECT @IColumnNames = STRING_AGG('i.' + QUOTENAME(column_name), ', ') FROM information_schema.columns WHERE table_name = @TableName AND table_schema = @SchemaName;

        -- Create new trigger
        SET @strSQL =   'CREATE TRIGGER [trg_' + @TableName + '_Update] ' +
                        'ON ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ' ' +
                        'AFTER INSERT, UPDATE ' +
                        'AS ' +
                        'BEGIN ' +
                            'SET NOCOUNT ON; ' +
                            'DECLARE @ActionTime DATETIME = GETDATE(); ' +
                            'UPDATE s ' +
                            'SET ' + QUOTENAME(@DateModifiedColumn) + ' = @ActionTime ' +
                            'FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ' s ' +
                            'INNER JOIN inserted i ON s.' + QUOTENAME(@PrimaryKeyColumn) + ' = i.' + QUOTENAME(@PrimaryKeyColumn) + '; ' +
                            ' ' +
                            'INSERT INTO ' + QUOTENAME(@HistorySchemaName) + '.' + QUOTENAME(@HistoryTableName) + ' (' + @ColumnNames + ') ' +
                            'SELECT ' + REPLACE(@IColumnNames, 'i.' + QUOTENAME(@DateModifiedColumn), '@ActionTime') + ' ' +
                            'FROM ' +
                            '     inserted i ' +
                        'END;';
        EXEC sp_executesql @strSQL;

        FETCH NEXT FROM trigger_cursor INTO @TableName, @SchemaName, @HistoryTableName, @HistorySchemaName, @DateModifiedColumn, @PrimaryKeyColumn;
    END;

    CLOSE trigger_cursor;
    DEALLOCATE trigger_cursor;
END;
