/*
    run_all.sql
    Runs the read-only distributor checks in one go. Use sqlcmd, from this folder:

        sqlcmd -S DIST01 -E -i run_all.sql -o health_report.out

    04 and 05 are left out on purpose: 04 needs a failing transaction and 05
    must run on the publisher.
*/
:r 01_agent_job_status.sql
:r 02_undistributed_commands.sql
:r 03_replication_errors.sql
:r 06_subscription_validation.sql
:r 07_agent_history_latency.sql
