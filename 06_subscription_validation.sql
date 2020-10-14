/*
    06_subscription_validation.sql
    Part 1 (run on the PUBLISHER, publication database) requests validation.
    Part 2 (run on the DISTRIBUTOR) lists what the distribution agents reported.
    Validation is checked by the Distribution Agent the next time it runs, so
    results show up in the agent history, not in the output of part 1.
*/

/* ---- Part 1: request validation (uncomment, publisher side) ----
EXEC sys.sp_publication_validation
     @publication  = N'Pub_Sales',
     @rowcount_only = 1,        -- 1 = rowcount only, 2 = rowcount and checksum
     @full_or_fast  = 2,        -- 0 = full count, 1 = fast (metadata), 2 = fast, fall back to full if needed
     @shutdown_agent = 0;
*/

/* ---- Part 2: validation results (distributor side) ---- */
USE distribution;
GO
SET NOCOUNT ON;

DECLARE @HoursBack int = 72;

SELECT  da.name AS agent_name,
        da.publication,
        h.time AS reported_at,
        h.comments
FROM dbo.MSdistribution_history AS h
JOIN dbo.MSdistribution_agents AS da ON da.id = h.agent_id
WHERE h.time >= DATEADD(HOUR, -@HoursBack, GETDATE())
  AND (h.comments LIKE N'%validation%' OR h.comments LIKE N'%out of synchronization%')
ORDER BY h.time DESC;
