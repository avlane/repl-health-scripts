/*
    12_replication_inventory.sql
    Run on: any publisher, subscriber or distributor.
    Which databases take part in replication on this instance, and whether a
    published database log is being held up by replication.
*/
SET NOCOUNT ON;

SELECT  d.name AS database_name,
        d.is_published       AS transactional_or_snapshot_publisher,
        d.is_merge_published AS merge_publisher,
        d.is_subscribed      AS subscriber,
        d.is_distributor     AS distribution_database,
        d.state_desc,
        d.recovery_model_desc,
        d.log_reuse_wait_desc,
        CASE WHEN d.log_reuse_wait_desc = N'REPLICATION'
             THEN N'CHECK: log is waiting on the Log Reader' ELSE N'' END AS needs_attention
FROM sys.databases AS d
WHERE d.is_published = 1 OR d.is_merge_published = 1
   OR d.is_subscribed = 1 OR d.is_distributor = 1
ORDER BY d.name;
