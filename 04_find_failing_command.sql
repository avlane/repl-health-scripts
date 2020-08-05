/*
    04_find_failing_command.sql
    Run on: the distributor.
    Shows the command(s) in the transaction a distribution agent is failing on.
    By default it takes the most recent error that carries an xact_seqno from
    MSrepl_errors. Set @xact_seqno yourself to look at a different transaction.
    sp_browsereplcmds reads MSrepl_commands and decodes the binary command text,
    so always pass a narrow range: an open range scans the whole database.
*/
USE distribution;
GO
SET NOCOUNT ON;

DECLARE @xact_seqno varchar(22) = NULL;      -- e.g. '0x0000002A000001B80003'
DECLARE @command_id int = NULL;

IF @xact_seqno IS NULL
BEGIN
    SELECT TOP (1)
           @xact_seqno = CONVERT(varchar(22), CONVERT(varbinary(10), e.xact_seqno), 1),
           @command_id = e.command_id
    FROM dbo.MSrepl_errors AS e
    WHERE e.xact_seqno IS NOT NULL
      AND e.xact_seqno <> 0x00
    ORDER BY e.time DESC;
END

IF @xact_seqno IS NULL
    THROW 50001, 'No error with an xact_seqno found. Set @xact_seqno manually.', 1;

PRINT CONCAT(N'Browsing transaction ', @xact_seqno, N', command_id ', ISNULL(CONVERT(nvarchar(20), @command_id), N'(all)'));

EXEC dbo.sp_browsereplcmds
     @xact_seqno_start = @xact_seqno,
     @xact_seqno_end   = @xact_seqno,
     @command_id       = @command_id;
