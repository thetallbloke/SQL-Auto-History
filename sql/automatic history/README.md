# Automatic History

We have the need to keep all history of a record, who did it and when.  This data then needs to be easily retrievable, so propose the following technique.

1. Main table - ```<Table Name>``` - Student
2. History table - ```<Table Name>History``` - StudentHistory
3. Trigger to copy all changes from Main table to History table
4. Stored Procedure to pull out the data at a point in time for all records or a specific record based on key or ID, etc.

There are some things to take into consideration that we need a solution for... maybe.

1. Scaffolding of tables and sprocs
2. What happens when a new field is added and the associated maintenance work - Can this be automated as part of the build pipelines
3. What happens when a field is removed
4. What happens when a field is renamed
5. What happens when a field is changed from one type to another
6. Indexing of the history table and optimisation of the SPROCS
7. What happens if there are multiple WHERE clauses that are required?  This may not be an issue.

## Why not do this in the application?
We want to take the responsibility from the developer and put it into the database.  If it were left in the application, the developer may forget to update the history table, or maybe there will be inconsistencies between the different devs.  Doing it this way will ensure that the history table is always up to date in a consistent manner.
