/*
    05_tracer_token_latency.sql
    Run on: the PUBLISHER, in the publication database.
    Posts a tracer token and reads back the latency once it has been seen.
    Latency values from sp_helptracertokenhistory are in seconds.
*/
SET NOCOUNT ON;

DECLARE @publication sysname = N'Pub_Sales';
DECLARE @tracer_token_id int;

EXEC sys.sp_posttracertoken
     @publication = @publication,
     @tracer_token_id = @tracer_token_id OUTPUT;

WAITFOR DELAY '00:00:10';

EXEC sys.sp_helptracertokenhistory
     @publication = @publication,
     @tracer_id   = @tracer_token_id;
