/*
    09_distribution_cleanup_health.sql
    Run on: the distributor.
    Checks that distribution cleanup keeps up: retention configured on the
    "Distribution clean up" job and the size of the command/transaction tables.
*/
SET NOCOUNT ON;

-- Retention (hours) parsed from the cleanup job step.
SELECT  j.name AS job_name,
        j.enabled,
        js.database_name,
        js.command
FROM msdb.dbo.sysjobs AS j
JOIN msdb.dbo.sysjobsteps AS js ON js.job_id = j.job_id
WHERE j.name LIKE N'Distribution clean up:%';
GO

USE distribution;
GO
SELECT  OBJECT_NAME(ps.object_id) AS table_name,
        SUM(ps.row_count) AS row_count,
        SUM(ps.reserved_page_count) * 8 / 1024 AS reserved_mb
FROM sys.dm_db_partition_stats AS ps
WHERE ps.object_id IN (OBJECT_ID(N'dbo.MSrepl_commands'), OBJECT_ID(N'dbo.MSrepl_transactions'))
  AND ps.index_id IN (0, 1)
GROUP BY ps.object_id;
