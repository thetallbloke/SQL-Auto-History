## Temporal Tables

SQL Server 2016 introduces support for temporal tables. Temporal tables are a type of user table designed to keep a full history of data changes and allow easy point in time analysis.
Temporal tables are designed to work with system-versioned tables, which are special user tables that have a corresponding history table. The history table contains the previous versions
of the rows for each record in the system-versioned table. The system-versioned table and the history table are always part of the same Transact-SQL statement batch.

The really handy thing is that you don't need to join tables to get the data at a specific point in time.  You can just query the table as if it were a normal single table and SQL Server will return the data you need.
No need for triggers or additional sprocs or views to get the data you need.

### Examples

* Create a new table with system versioning enabled, add some data, and then add a new column to the table.

``` create-a-versioned-table.sql

* Delete data from a versioned table.  We may receive a request by someone to delete their personal data which we will need to comply with, or we may need to delete the data because we can only keep it for a certain amount of time.

``` delete-data.sql

* Create a new table with system versioning enabled, add some data, and then select the data from the table at a specific point in time.

``` new-table.sql

* Take an existing table and add system versioning to it.

``` existing-table.sql