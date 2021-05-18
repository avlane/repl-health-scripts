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


-- Age of the oldest transaction still stored. If this is much larger than the
-- maximum distribution retention, cleanup is not removing rows.
SELECT  MIN(t.entry_time) AS oldest_transaction,
        DATEDIFF(HOUR, MIN(t.entry_time), GETDATE()) AS oldest_transaction_age_hours
FROM dbo.MSrepl_transactions AS t;

-- Commands already delivered to every subscriber but not yet cleaned up.
SELECT  SUM(ds.DelivCmdsInDistDB)   AS delivered_cmds_awaiting_cleanup,
        SUM(ds.UndelivCmdsInDistDB) AS undelivered_cmds
FROM dbo.MSdistribution_status AS ds;
