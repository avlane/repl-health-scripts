/*
    13_ag_publisher_redirect.sql
    Replication with a publisher database in an Availability Group.
    Part 1 (distributor): publishers that are redirected to an AG listener.
    Part 2 (each AG replica): published databases and whether this replica is primary.
*/

/* ---- Part 1: distributor ---- */
USE distribution;
GO
SELECT  rp.original_publisher,
        rp.publisher_db,
        rp.redirected_publisher
FROM dbo.MSredirected_publishers AS rp
ORDER BY rp.original_publisher, rp.publisher_db;
GO

/* ---- Part 2: run on every replica ---- */
SELECT  d.name AS database_name,
        ag.name AS availability_group,
        rs.role_desc AS local_role,
        d.is_published,
        d.is_merge_published
FROM sys.databases AS d
JOIN sys.availability_databases_cluster AS adc ON adc.database_name = d.name
JOIN sys.availability_groups AS ag ON ag.group_id = adc.group_id
LEFT JOIN sys.dm_hadr_availability_replica_states AS rs
       ON rs.group_id = ag.group_id AND rs.is_local = 1
WHERE d.is_published = 1 OR d.is_merge_published = 1
ORDER BY ag.name, d.name;


/*
    After a failover, check that every replica can act as the publisher.
    Run on the distributor (uncomment and edit the names):

    EXEC sys.sp_validate_replica_hosts_as_publishers
         @original_publisher  = N'SQLPROD01',
         @publisher_db        = N'SalesDB',
         @redirected_publisher = N'SALESAGL';

    It reports a row for each replica and raises an error if a replica cannot
    connect back to the distributor or is missing from sys.servers there.
*/
