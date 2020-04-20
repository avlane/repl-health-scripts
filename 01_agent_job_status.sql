/*
    01_agent_job_status.sql
    Run on: the distributor (or any server that hosts replication agent jobs).
    Lists replication agent jobs and whether each one is running right now.
*/
SET NOCOUNT ON;

DECLARE @session_id int = (SELECT MAX(session_id) FROM msdb.dbo.syssessions);

SELECT  c.name AS category,
        j.name AS job_name,
        j.enabled,
        CASE WHEN ja.start_execution_date IS NOT NULL AND ja.stop_execution_date IS NULL
             THEN N'Running' ELSE N'Not running' END AS current_state,
        ja.start_execution_date
FROM msdb.dbo.sysjobs AS j
JOIN msdb.dbo.syscategories AS c ON c.category_id = j.category_id
LEFT JOIN msdb.dbo.sysjobactivity AS ja
       ON ja.job_id = j.job_id
      AND ja.session_id = @session_id
WHERE c.name LIKE N'REPL-%'
ORDER BY c.name, j.name;
