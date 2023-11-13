# Automatic History

## The Problem

1. For auditing purposes we need to keep all history of a record, who did it and when.  For now the POC has the when, but extra data can be added as required.
2. The data then needs to be easily retrievable for now (current data), yesterday, or some ultra specific point in time,		
3. The data retrieval needs to be performant
4. Capture everything that happens to the configured tables, and not rely on the developer to remember to update the history table

## The Proposed Solution

1. Base table - ```<Table Name>``` - Student
2. History table - ```<Table Name>History``` - StudentHistory
3. Trigger to copy all changes from the base table to history table	
4. Stored Procedure to pull out the data at a point in time for all records or a specific record based on key or ID, etc.

### History Tracking Methodologies

#### Option 1 -
- Insert new record into the base table
- Copy the data from the base table to the history table
- Update the base table record including the configured DateModified field

This method means that we have the base table with the latest version of the data, and the history table with the previous version of the data.  This method means that there is no duplication of the current/latest record between base and history table.

**Data Extraction** - to pull the data out we need to join the base table with the matching history table to get the complete picture

#### Option 2 -
- Insert a record into the base table
- Update the configured DateModified field to the current date and time
- Immediately copy the data from the base table to the history table

This method means that we have the latest/current record in both the base and history table.

**Data Extraction** - pull the data from the history table only

## How To Use The Scripts

Create a blank database.  Run the scripts in numeric order; 01, 02, and 03.

### 01 Setup.sql
1. creates an 'audit' schema
2. creates a 'WebsiteUser' role
3. revokes UPDATE permissions on the 'audit' schema from the 'WebsiteUser' role
4. creates a 'sysAutoHistoryTables' table to hold the list of tables that will be automatically audited
5. creates a trigger on the sysAutoHistoryTables table to set some default values
6. creates a single configuration data row in the table for the POC to handle the [Student] table
7. creates a POC [Student] table

### 02 SyncHistoryTables.sql
1. creates a stored procedure to sync the table structure of the history tables to match the base tables

### 03 GenerateHistoryTables.sql
Depending on which option you want to use, run the appropriate script; Option 1 or Option 2.
1. creates a stored procedure to create the relevant triggers on the base tables to perform the history tracking; Option 1 or Option 2.

As part of the sysAutoHistoryTables table, you can specify the name of the schema to use for the history tables.  This is defaulted to 'audit' in the script.

### 04 GetAtPointInTime.sql
This script is a POC to show how to get the data at a point in time.  Pick the correct script based on the option you chose in step 3.
The plan is to create a stored procedure that will do this for you, but for now there is just a script for the current version of the [Student] table.

## Considerations
Here are some things to take into consideration given this proposed solution... maybe

1. Scaffolding of tables and sprocs
2. What happens when a new field is added and the associated maintenance work
3. What happens when a field is removed
4. What happens when a field is renamed					
5. What happens when a field is changed from one type to another - ??? Haven't tested this yet
6. Indexing of the history table and optimisation of the SPROCS - ??? Haven't tested this yet
7. What happens if there are multiple WHERE clauses that are required?  This may not be an issue.

A number of the above can be done for you by running the SyncHistoryTables and GenerateTriggers stored procedures.
Run the two scripts above as part of the build and/or deployment pipelines to keep your database in sync. 

## Why not just do this in the application?
We want to take the responsibility for history away from the developer and put it into the database.  It's not something that the application developer needs to worry about and they may accidentally forget to update the history table, miss a field, or maybe there will be inconsistencies between the different devs.  Doing it this way will ensure that the history table is always up to date in a consistent manner.

## Complimentary database View of the data too?
There is still debate if we also need a view of the data that just joins the two tables (in the case of Option 1).  This might be a requirement for the application to use specifically when listing out the changes for a specific record.

## Now what?
We'd like feedback on this solution.  Will it work? Suggestions to make it better? Other considerations?
