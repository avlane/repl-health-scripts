/*
    00_summary.sql
    Run on: the distributor.
    One-line health counters. Each row is a check and the number of things that
    need attention, so a quick glance shows where to look next.
*/
USE distribution;
GO
SET NOCOUNT ON;

DECLARE @HoursBack int = 24;
DECLARE @WarnCmds bigint = 100000;

SELECT N'Agents with a failed last run' AS check_name,
       COUNT(DISTINCT j.job_id) AS items
FROM msdb.dbo.sysjobs AS j
JOIN msdb.dbo.syscategories AS c ON c.category_id = j.category_id
CROSS APPLY (
    SELECT TOP (1) jh.run_status
    FROM msdb.dbo.sysjobhistory AS jh
    WHERE jh.job_id = j.job_id AND jh.step_id = 0
    ORDER BY jh.instance_id DESC
) AS lr
WHERE c.name LIKE N'REPL-%' AND j.enabled = 1 AND lr.run_status = 0
UNION ALL
SELECT N'Subscriptions with backlog >= ' + CONVERT(nvarchar(20), @WarnCmds),
       COUNT(*)
FROM (SELECT ds.agent_id
      FROM dbo.MSdistribution_status AS ds
      GROUP BY ds.agent_id
      HAVING SUM(ds.UndelivCmdsInDistDB) >= @WarnCmds) AS b
UNION ALL
SELECT N'Replication errors in the last ' + CONVERT(nvarchar(10), @HoursBack) + N' hours',
       COUNT(*)
FROM dbo.MSrepl_errors AS e
WHERE e.time >= DATEADD(HOUR, -@HoursBack, GETDATE())
UNION ALL
SELECT N'Distribution agents in retry or fail state',
       COUNT(*)
FROM (SELECT h.agent_id, h.runstatus,
             ROW_NUMBER() OVER (PARTITION BY h.agent_id ORDER BY h.time DESC, h.timestamp DESC) AS rn
      FROM dbo.MSdistribution_history AS h) AS x
WHERE x.rn = 1 AND x.runstatus IN (5, 6);
