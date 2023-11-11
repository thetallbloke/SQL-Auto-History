# Automatic History

We have a couple of use cases to solve:
1. the need to keep all history of a record, who did it and when.  This POC doesn't contain the data for who, just the when at this stage, but it could be added later if the POC proves to be the right direction to go.
2. the data then needs to be easily retrievable for now (current data), yesterday, or some ultra specific point in time,		
3. the data retrieval need to be performant				
4. the reports generated can either be generated at the point in time and stored as a PDF snapshot, or the data can be retrieved and the report generated on the fly.  If we store the PDF, we have to secure them. If we generate them on the fly, we need to have the resources to handle the load.

## The Proposed Solution

1. Main table - ```<Table Name>``` - Student
2. History table - ```<Table Name>History``` - StudentHistory
3. Trigger to copy all changes from Main table to History table
4. Stored Procedure to pull out the data at a point in time for all records or a specific record based on key or ID, etc.

## Considerations
Here are some things to take into consideration given this proposed solution... maybe

1. Scaffolding of tables and sprocs
2. What happens when a new field is added and the associated maintenance work - Can this be automated as part of the build pipelines
3. What happens when a field is removed
4. What happens when a field is renamed
5. What happens when a field is changed from one type to another
6. Indexing of the history table and optimisation of the SPROCS
7. What happens if there are multiple WHERE clauses that are required?  This may not be an issue.

## Why not do this in the application?
We want to take the responsibility from the developer and put it into the database.  If it were left in the application, the developer may forget to update the history table, or maybe there will be inconsistencies between the different devs.  Doing it this way will ensure that the history table is always up to date in a consistent manner.

## Complimentary database View of the data too?
I'm still deciding if we also need a view of the data that joins the two tables.  This might be a requirement for the application to use specifically when listing out the changes for a specific record.  This would be a simple join on the two tables and would be a read only view.

## Now what?
We'd like feedback on this solution.  Will it work? Suggestions to make it better? Other considerations?