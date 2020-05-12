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
        sub.name AS subscriber,
        da.subscriber_db,
        SUM(ds.UndelivCmdsInDistDB) AS undelivered_cmds,
        SUM(ds.DelivCmdsInDistDB)   AS delivered_cmds_awaiting_cleanup
FROM dbo.MSdistribution_status AS ds
JOIN dbo.MSdistribution_agents AS da ON da.id = ds.agent_id
JOIN master.sys.servers AS sub ON sub.server_id = da.subscriber_id
GROUP BY da.publisher_db, da.publication, sub.name, da.subscriber_db
ORDER BY undelivered_cmds DESC;
