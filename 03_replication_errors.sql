/*
    03_replication_errors.sql
    Run on: the distributor.
    Part 1: error count per hour, to see when a problem started.
    Part 2: recent rows from MSrepl_errors, newest first, with a short hint for
    the error numbers that cause most replication incidents.
*/
USE distribution;
GO
SET NOCOUNT ON;

DECLARE @HoursBack int = 24;   -- same name and unit (hours) as 06 and 07

SELECT  DATEADD(HOUR, DATEDIFF(HOUR, 0, e.time), 0) AS error_hour,
        e.error_code,
        COUNT(*) AS error_count
FROM dbo.MSrepl_errors AS e
WHERE e.time >= DATEADD(HOUR, -@HoursBack, GETDATE())
GROUP BY DATEADD(HOUR, DATEDIFF(HOUR, 0, e.time), 0), e.error_code
ORDER BY error_hour DESC, error_count DESC;

SELECT TOP (200)
        e.id,
        e.time AS error_time,
        e.source_name,
        e.error_code,
        CASE e.error_code
             WHEN N'20598' THEN N'Row not found at the Subscriber (MSSQL_REPL20598). Find the command, then fix or skip the row.'
             WHEN N'2627'  THEN N'Primary key violation at the Subscriber. Row already exists.'
             WHEN N'2601'  THEN N'Duplicate key in a unique index at the Subscriber.'
             WHEN N'547'   THEN N'Foreign key or CHECK constraint conflict at the Subscriber.'
             WHEN N'2812'  THEN N'Stored procedure missing at the Subscriber (sp_MSins_/upd_/del_ procs).'
             WHEN N'18456' THEN N'Login failed. Check the agent login or proxy account.'
             WHEN N'4060'  THEN N'Cannot open the database requested by the login.'
             WHEN N'1205'  THEN N'Deadlock victim while applying commands. Usually retries by itself.'
             WHEN N'1105'  THEN N'Filegroup full at the Subscriber.'
             WHEN N'9002'  THEN N'Transaction log full. Check log_reuse_wait_desc (REPLICATION means the log reader is behind).'
             WHEN N'14151' THEN N'Agent job step failed. Look at the preceding rows for the cause.'
             WHEN N'20084' THEN N'Agent could not connect to the Distributor.'
             ELSE N''
        END AS hint,
        e.error_text,
        CONVERT(varchar(22), e.xact_seqno, 1) AS xact_seqno,
        e.command_id
FROM dbo.MSrepl_errors AS e
WHERE e.time >= DATEADD(HOUR, -@HoursBack, GETDATE())
ORDER BY e.time DESC;
