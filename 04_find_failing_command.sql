/*
    04_find_failing_command.sql
    Run on: the distributor.
    Shows the command(s) in the transaction a distribution agent is failing on.
    Take the xact_seqno from 03_replication_errors.sql (or the agent history) and
    paste it below. sp_browsereplcmds reads MSrepl_commands and decodes the
    binary command text, so always pass a narrow range: an open range scans
    the whole distribution database.
*/
USE distribution;
GO
SET NOCOUNT ON;

DECLARE @xact_seqno varchar(22) = '0x00000000000000000000';

IF @xact_seqno = '0x00000000000000000000'
    THROW 50001, 'Set @xact_seqno to the failing transaction sequence number first.', 1;

EXEC dbo.sp_browsereplcmds
     @xact_seqno_start = @xact_seqno,
     @xact_seqno_end   = @xact_seqno;
