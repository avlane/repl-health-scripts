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


-- Last outcome of the cleanup jobs (history cleanup and distribution cleanup).
SELECT  j.name AS job_name,
        msdb.dbo.agent_datetime(h.run_date, h.run_time) AS last_run_time,
        CASE h.run_status WHEN 0 THEN N'Failed' WHEN 1 THEN N'Succeeded' WHEN 2 THEN N'Retry'
                          WHEN 3 THEN N'Canceled' END AS last_run_status,
        (h.run_duration / 10000) * 3600 + ((h.run_duration / 100) % 100) * 60 + (h.run_duration % 100) AS duration_seconds
FROM msdb.dbo.sysjobs AS j
CROSS APPLY (
    SELECT TOP (1) jh.run_date, jh.run_time, jh.run_status, jh.run_duration
    FROM msdb.dbo.sysjobhistory AS jh
    WHERE jh.job_id = j.job_id AND jh.step_id = 0
    ORDER BY jh.instance_id DESC
) AS h
WHERE j.name LIKE N'Distribution clean up:%'
   OR j.name LIKE N'History clean up:%';
