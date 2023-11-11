CREATE OR ALTER PROCEDURE dbo.GenerateTriggers
AS
BEGIN
    DECLARE @TableName NVARCHAR(255);
    DECLARE @TriggerName NVARCHAR(255);
    DECLARE @SchemaName NVARCHAR(255);

    DECLARE trigger_cursor CURSOR FOR
        SELECT BaseTableName, HistoryTableName
        FROM dbo.sysAutoHistoryTables;

    OPEN trigger_cursor;
    FETCH NEXT FROM trigger_cursor INTO @TableName, @TriggerName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Drop existing trigger
        DECLARE @DropTriggerSql NVARCHAR(MAX);
        SET @DropTriggerSql = 'IF OBJECT_ID(''trg_' + @TableName + '_Update'', ''TR'') IS NOT NULL
                              DROP TRIGGER trg_' + @TableName + '_Update;';
        EXEC sp_executesql @DropTriggerSql;

        -- Get column names for the base table
        DECLARE @ColumnNames NVARCHAR(MAX);
        SELECT @ColumnNames = STRING_AGG(column_name, ', ')
        FROM information_schema.columns
        WHERE table_name = @TableName AND table_schema = @SchemaName;

        -- Create new trigger
        DECLARE @CreateTriggerSql NVARCHAR(MAX);
        SET @CreateTriggerSql = 'CREATE TRIGGER trg_' + @TableName + '_Update
                                ON ' + @SchemaName + '.' + @TableName + '
                                AFTER INSERT, UPDATE
                                AS
                                BEGIN
                                    SET NOCOUNT ON;

                                    INSERT INTO audit.' + @TriggerName + 'History (' + @ColumnNames + ', DateModified)
                                    SELECT 
                                        ' + @ColumnNames + ',
                                        GETDATE()
                                    FROM
                                        deleted d
                                    WHERE
                                        NOT EXISTS (
                                            SELECT 1
                                            FROM inserted i
                                            WHERE i.id = d.id
                                        );

                                    UPDATE ' + @SchemaName + '.' + @TableName + '
                                    SET DateModified = GETDATE()
                                    FROM
                                        ' + @SchemaName + '.' + @TableName + ' s
                                    JOIN
                                        inserted i ON s.id = i.id;
                                END;';
        EXEC sp_executesql @CreateTriggerSql;

        FETCH NEXT FROM trigger_cursor INTO @TableName, @TriggerName;
    END;

    CLOSE trigger_cursor;
    DEALLOCATE trigger_cursor;
END;
