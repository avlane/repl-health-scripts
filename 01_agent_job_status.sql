/*
    01_agent_job_status.sql
    Run on: the distributor (or any server that hosts replication agent jobs).
    Lists replication agent jobs, whether each one is running right now, and
    how the last run ended. Duration is in seconds.
*/
SET NOCOUNT ON;

DECLARE @session_id int = (SELECT MAX(session_id) FROM msdb.dbo.syssessions);

SELECT  c.name AS category,
        j.name AS job_name,
        j.enabled,
        CASE WHEN ja.start_execution_date IS NOT NULL AND ja.stop_execution_date IS NULL
             THEN N'Running' ELSE N'Not running' END AS current_state,
        ja.start_execution_date,
        lr.last_run_time,
        CASE lr.run_status
             WHEN 0 THEN N'Failed'
             WHEN 1 THEN N'Succeeded'
             WHEN 2 THEN N'Retry'
             WHEN 3 THEN N'Canceled'
             WHEN 4 THEN N'In progress'
        END AS last_run_status,
        lr.last_run_seconds,
        CASE WHEN c.name IN (N'REPL-LogReader', N'REPL-Distribution', N'REPL-QueueReader')
                  AND NOT (ja.start_execution_date IS NOT NULL AND ja.stop_execution_date IS NULL)
             THEN N'CHECK: continuous agent is not running'
             WHEN lr.run_status = 0 THEN N'CHECK: last run failed'
             ELSE N''
        END AS needs_attention
FROM msdb.dbo.sysjobs AS j
JOIN msdb.dbo.syscategories AS c ON c.category_id = j.category_id
LEFT JOIN msdb.dbo.sysjobactivity AS ja
       ON ja.job_id = j.job_id
      AND ja.session_id = @session_id
OUTER APPLY (
    -- step_id 0 is the job outcome row; run_duration is encoded as hhmmss
    SELECT TOP (1)
           msdb.dbo.agent_datetime(h.run_date, h.run_time) AS last_run_time,
           h.run_status,
           (h.run_duration / 10000) * 3600
         + ((h.run_duration / 100) % 100) * 60
         + (h.run_duration % 100) AS last_run_seconds
    FROM msdb.dbo.sysjobhistory AS h
    WHERE h.job_id = j.job_id
      AND h.step_id = 0
    ORDER BY h.instance_id DESC
) AS lr
WHERE c.name LIKE N'REPL-%'
ORDER BY c.name, j.name;
