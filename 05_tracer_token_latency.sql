/*
    05_tracer_token_latency.sql
    Run on: the PUBLISHER, in the publication database.
    Posts a tracer token, waits until every subscriber has reported (or the
    timeout is hit) and shows latency per hop. All latencies are in seconds.
        publisher -> distributor : distributor_latency
        distributor -> subscriber: subscriber_latency
        end to end               : overall_latency
    A NULL means the token has not reached that point yet.
*/
SET NOCOUNT ON;

DECLARE @publication sysname = N'Pub_Sales';
DECLARE @timeout_seconds int = 120;
DECLARE @tracer_token_id int;
DECLARE @waited int = 0;

IF OBJECT_ID(N'tempdb..#history') IS NOT NULL DROP TABLE #history;
CREATE TABLE #history (
    distributor_commit  datetime NULL,
    distributor_latency bigint   NULL,
    subscriber          sysname  NULL,
    subscriber_db       sysname  NULL,
    subscriber_commit   datetime NULL,
    subscriber_latency  bigint   NULL,
    overall_latency     bigint   NULL);

EXEC sys.sp_posttracertoken
     @publication = @publication,
     @tracer_token_id = @tracer_token_id OUTPUT;

-- A publication with no subscriptions never returns rows, so the loop is
-- bounded by @timeout_seconds instead of waiting for a result.
WHILE @waited <= @timeout_seconds
BEGIN
    WAITFOR DELAY '00:00:05';
    SET @waited += 5;

    TRUNCATE TABLE #history;
    INSERT INTO #history
    EXEC sys.sp_helptracertokenhistory
         @publication = @publication,
         @tracer_id   = @tracer_token_id;

    IF EXISTS (SELECT 1 FROM #history)
       AND NOT EXISTS (SELECT 1 FROM #history WHERE subscriber_commit IS NULL)
        BREAK;
END

IF NOT EXISTS (SELECT 1 FROM #history)
    PRINT N'No tracer token history returned. Does the publication have subscriptions and a running Log Reader?';

SELECT  @publication AS publication,
        @tracer_token_id AS tracer_token_id,
        subscriber, subscriber_db,
        distributor_latency   AS pub_to_dist_seconds,
        subscriber_latency    AS dist_to_sub_seconds,
        overall_latency       AS overall_seconds,
        CASE WHEN subscriber_commit IS NULL THEN N'not yet delivered' ELSE N'delivered' END AS token_state
FROM #history
ORDER BY subscriber, subscriber_db;
