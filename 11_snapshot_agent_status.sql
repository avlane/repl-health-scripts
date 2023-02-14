/*
    11_snapshot_agent_status.sql
    Run on: the distributor.
    Latest Snapshot Agent run per publication. History duration is in seconds.
    runstatus: 1 start, 2 succeed, 3 in progress, 4 idle, 5 retry, 6 fail.
*/
USE distribution;
GO
SET NOCOUNT ON;

;WITH h AS (
    SELECT  sa.name AS agent_name, sa.publisher_db, sa.publication,
            sh.start_time, sh.time, sh.runstatus, sh.duration,
            sh.delivered_commands, sh.comments,
            ROW_NUMBER() OVER (PARTITION BY sh.agent_id ORDER BY sh.time DESC, sh.timestamp DESC) AS rn
    FROM dbo.MSsnapshot_history AS sh
    JOIN dbo.MSsnapshot_agents  AS sa ON sa.id = sh.agent_id
)
SELECT  agent_name, publisher_db, publication, start_time, time AS last_update,
        CASE runstatus WHEN 1 THEN N'Start' WHEN 2 THEN N'Succeed' WHEN 3 THEN N'In progress'
                       WHEN 4 THEN N'Idle' WHEN 5 THEN N'Retry' WHEN 6 THEN N'Fail' END AS run_status,
        duration AS duration_seconds,
        comments
FROM h
WHERE rn = 1
ORDER BY publisher_db, publication;
