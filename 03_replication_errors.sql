/*
    03_replication_errors.sql
    Run on: the distributor.
    Recent rows from MSrepl_errors, newest first.
*/
USE distribution;
GO
SET NOCOUNT ON;

DECLARE @HoursBack int = 24;

SELECT TOP (200)
        e.id,
        e.time AS error_time,
        e.source_name,
        e.error_code,
        e.error_text,
        CONVERT(varchar(22), e.xact_seqno, 1) AS xact_seqno,
        e.command_id
FROM dbo.MSrepl_errors AS e
WHERE e.time >= DATEADD(HOUR, -@HoursBack, GETDATE())
ORDER BY e.time DESC;
