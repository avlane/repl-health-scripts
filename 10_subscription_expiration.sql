/*
    10_subscription_expiration.sql
    Run on: the distributor.
    A transactional subscription expires (and must be reinitialized) when it has
    not synchronized within the publication retention period. MSpublications.retention
    is in HOURS for transactional publications; 0 means never expire.
*/
USE distribution;
GO
SET NOCOUNT ON;

DECLARE @WarnPct decimal(5, 1) = 50.0;     -- flag subscriptions past this share of retention

;WITH last_sync AS (
    SELECT  h.agent_id, MAX(h.time) AS last_sync_time
    FROM dbo.MSdistribution_history AS h
    WHERE h.runstatus IN (2, 3, 4)          -- succeed, in progress, idle
    GROUP BY h.agent_id
)
SELECT  da.publisher_db,
        da.publication,
        ISNULL(sub.name, N'(anonymous)') AS subscriber,
        da.subscriber_db,
        p.retention AS retention_hours,
        ls.last_sync_time,
        DATEDIFF(HOUR, ls.last_sync_time, GETDATE()) AS hours_since_sync,
        CASE WHEN p.retention > 0
             THEN CONVERT(decimal(5, 1), 100.0 * DATEDIFF(HOUR, ls.last_sync_time, GETDATE()) / p.retention)
        END AS pct_of_retention_used,
        CASE WHEN p.retention > 0
              AND 100.0 * DATEDIFF(HOUR, ls.last_sync_time, GETDATE()) / p.retention >= @WarnPct
             THEN N'WARN: approaching expiration' ELSE N'' END AS status
FROM dbo.MSdistribution_agents AS da
JOIN dbo.MSpublications AS p
  ON p.publisher_id = da.publisher_id
 AND p.publisher_db = da.publisher_db
 AND p.publication  = da.publication
LEFT JOIN master.sys.servers AS sub ON sub.server_id = da.subscriber_id
LEFT JOIN last_sync AS ls ON ls.agent_id = da.id
WHERE p.publication_type = 0               -- transactional
ORDER BY pct_of_retention_used DESC;
