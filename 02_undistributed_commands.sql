/*
    02_undistributed_commands.sql
    Run on: the distributor.
    Commands waiting in the distribution database, per distribution agent.
    UndelivCmdsInDistDB   = commands not yet applied at the subscriber (the backlog)
    DelivCmdsInDistDB     = commands already applied, waiting for cleanup
*/
USE distribution;
GO
SET NOCOUNT ON;

SELECT  da.publisher_db,
        da.publication,
        ISNULL(sub.name, N'(anonymous)') AS subscriber,
        da.subscriber_db,
        SUM(ds.UndelivCmdsInDistDB) AS undelivered_cmds,
        SUM(ds.DelivCmdsInDistDB)   AS delivered_cmds_awaiting_cleanup
FROM dbo.MSdistribution_status AS ds
JOIN dbo.MSdistribution_agents AS da ON da.id = ds.agent_id
LEFT JOIN master.sys.servers AS sub ON sub.server_id = da.subscriber_id
GROUP BY da.publisher_db, da.publication, sub.name, da.subscriber_db
ORDER BY undelivered_cmds DESC;


/*
    Estimated catch-up time. sp_replmonitorsubscriptionpendingcmds returns
    pendingcmdcount (commands) and estimatedprocesstime (seconds) for one
    subscription, so loop over the push/pull agents.
*/
IF OBJECT_ID(N'tempdb..#pending') IS NOT NULL DROP TABLE #pending;
IF OBJECT_ID(N'tempdb..#catchup') IS NOT NULL DROP TABLE #catchup;

CREATE TABLE #pending (pendingcmdcount int NULL, estimatedprocesstime int NULL);
CREATE TABLE #catchup (
    publisher sysname, publisher_db sysname, publication sysname,
    subscriber sysname, subscriber_db sysname,
    pending_cmds int NULL, estimated_seconds int NULL);

DECLARE @publisher sysname, @publisher_db sysname, @publication sysname,
        @subscriber sysname, @subscriber_db sysname, @subscription_type int;

DECLARE agents CURSOR LOCAL FAST_FORWARD FOR
    SELECT pub.name, da.publisher_db, da.publication, sub.name, da.subscriber_db, da.subscription_type
    FROM dbo.MSdistribution_agents AS da
    JOIN master.sys.servers AS pub ON pub.server_id = da.publisher_id
    JOIN master.sys.servers AS sub ON sub.server_id = da.subscriber_id
    WHERE da.subscription_type IN (0, 1);   -- 0 = push, 1 = pull

OPEN agents;
FETCH NEXT FROM agents INTO @publisher, @publisher_db, @publication, @subscriber, @subscriber_db, @subscription_type;
WHILE @@FETCH_STATUS = 0
BEGIN
    TRUNCATE TABLE #pending;
    INSERT INTO #pending (pendingcmdcount, estimatedprocesstime)
    EXEC dbo.sp_replmonitorsubscriptionpendingcmds
         @publisher = @publisher, @publisher_db = @publisher_db, @publication = @publication,
         @subscriber = @subscriber, @subscriber_db = @subscriber_db,
         @subscription_type = @subscription_type;

    INSERT INTO #catchup
    SELECT @publisher, @publisher_db, @publication, @subscriber, @subscriber_db,
           pendingcmdcount, estimatedprocesstime
    FROM #pending;

    FETCH NEXT FROM agents INTO @publisher, @publisher_db, @publication, @subscriber, @subscriber_db, @subscription_type;
END
CLOSE agents;
DEALLOCATE agents;

SELECT  publication, subscriber, subscriber_db, pending_cmds, estimated_seconds,
        CONCAT(estimated_seconds / 3600, N'h ',
               (estimated_seconds / 60) % 60, N'm ',
               estimated_seconds % 60, N's') AS estimated_catch_up
FROM #catchup
ORDER BY estimated_seconds DESC;
