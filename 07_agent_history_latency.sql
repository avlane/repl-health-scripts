/*
    07_agent_history_latency.sql
    Run on: the distributor.
    Latest history row for each Log Reader and Distribution Agent.
    Latency columns in the history tables are in MILLISECONDS; delivery rate is
    commands per second. runstatus: 1 start, 2 succeed, 3 in progress, 4 idle,
    5 retry, 6 fail.
*/
USE distribution;
GO
SET NOCOUNT ON;

;WITH lr AS (
    SELECT  a.name AS agent_name, a.publisher_db,
            h.time, h.runstatus, h.delivery_rate, h.delivery_latency, h.delivered_commands, h.comments,
            ROW_NUMBER() OVER (PARTITION BY h.agent_id ORDER BY h.time DESC, h.timestamp DESC) AS rn
    FROM dbo.MSlogreader_history AS h
    JOIN dbo.MSlogreader_agents  AS a ON a.id = h.agent_id
)
SELECT  N'LogReader' AS agent_type, agent_name, publisher_db AS database_name, time, runstatus,
        delivery_rate AS cmds_per_sec,
        delivery_latency / 1000.0 AS latency_seconds,
        delivered_commands, comments
FROM lr
WHERE rn = 1;

;WITH dh AS (
    SELECT  a.name AS agent_name, a.subscriber_db,
            h.time, h.runstatus, h.current_delivery_rate, h.current_delivery_latency,
            h.delivered_commands, h.comments,
            ROW_NUMBER() OVER (PARTITION BY h.agent_id ORDER BY h.time DESC, h.timestamp DESC) AS rn
    FROM dbo.MSdistribution_history AS h
    JOIN dbo.MSdistribution_agents  AS a ON a.id = h.agent_id
)
SELECT  N'Distribution' AS agent_type, agent_name, subscriber_db AS database_name, time, runstatus,
        current_delivery_rate AS cmds_per_sec,
        current_delivery_latency / 1000.0 AS latency_seconds,
        delivered_commands, comments
FROM dh
WHERE rn = 1;

-- Retries and failures per agent over the look-back window.
DECLARE @HoursBack int = 24;

SELECT  a.name AS agent_name,
        SUM(CASE WHEN h.runstatus = 5 THEN 1 ELSE 0 END) AS retry_rows,
        SUM(CASE WHEN h.runstatus = 6 THEN 1 ELSE 0 END) AS fail_rows
FROM dbo.MSdistribution_history AS h
JOIN dbo.MSdistribution_agents  AS a ON a.id = h.agent_id
WHERE h.time >= DATEADD(HOUR, -@HoursBack, GETDATE())
GROUP BY a.name
HAVING SUM(CASE WHEN h.runstatus IN (5, 6) THEN 1 ELSE 0 END) > 0
ORDER BY fail_rows DESC, retry_rows DESC;
