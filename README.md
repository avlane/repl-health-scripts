# repl-health-scripts

T-SQL scripts for checking the health of SQL Server transactional replication.
Most scripts run on the distributor (in the `distribution` database); the tracer
token script runs on the publisher.

## Scripts

| script | what it does |
|---|---|
| `01_agent_job_status.sql` | replication agent jobs and their last outcome |
| `02_undistributed_commands.sql` | command backlog per subscription and estimated catch-up time |
| `03_replication_errors.sql` | recent `MSrepl_errors` rows with a hint for common error numbers |
| `04_find_failing_command.sql` | decode the command behind a failing `xact_seqno` with `sp_browsereplcmds` |
| `05_tracer_token_latency.sql` | tracer token latency per hop (publisher) |
| `06_subscription_validation.sql` | request validation and read the results from agent history |
| `07_agent_history_latency.sql` | latest Log Reader / Distribution Agent delivery rate and latency |
| `08_merge_identity_ranges.sql` | merge identity range sizes and data type headroom (publisher) |
| `09_distribution_cleanup_health.sql` | cleanup retention and table sizes in `distribution` |
| `10_subscription_expiration.sql` | share of the retention period each transactional subscription has used |
| `11_snapshot_agent_status.sql` | latest Snapshot Agent run per publication |
| `12_replication_inventory.sql` | databases that publish, subscribe or host distribution, and log reuse waits |
| `13_ag_publisher_redirect.sql` | publisher redirection and AG role for published databases |
| `00_summary.sql` | one-screen counters: failed agents, backlog, errors, retrying agents |
| `run_all.sql` | sqlcmd runner for the read-only distributor checks |

## Permissions

Run as a member of `sysadmin` where possible. The least you need:

* distributor: `db_datareader` on `distribution` plus execute on `sp_browsereplcmds`
  and `sp_replmonitorsubscriptionpendingcmds` (members of `replmonitor` can run the latter)
* `msdb`: `SQLAgentReaderRole` to read job history for every job
* publisher: `db_owner` on the published database for tracer tokens and validation

## Conventions

* Server names in examples are fictional (`SQLPROD01`, `DIST01`, `SQLDR02`).
* Scripts are read-only unless the header says otherwise.

## Sample output

`01_agent_job_status.sql`

```
category          job_name                                   enabled current_state last_run_status last_run_seconds needs_attention
----------------- ------------------------------------------ ------- ------------- --------------- ---------------- ------------------------------------
REPL-Distribution SQLPROD01-SalesDB-Pub_Sales-SQLDR02-7      1       Running       In progress     0
REPL-LogReader    SQLPROD01-SalesDB-1                        1       Not running   Failed          3                CHECK: continuous agent is not running
REPL-Snapshot     SQLPROD01-SalesDB-Pub_Sales-1              1       Not running   Succeeded       41
```

`05_tracer_token_latency.sql` (seconds)

```
publication tracer_token_id subscriber pub_to_dist_seconds dist_to_sub_seconds overall_seconds token_state
----------- --------------- ---------- ------------------- ------------------- --------------- ---------
Pub_Sales   -2147483640     SQLDR02    1                   2                   3               delivered
```

`10_subscription_expiration.sql`

```
publisher_db publication subscriber retention_hours last_sync_time        hours_since_sync pct_of_retention_used status
------------ ----------- ---------- --------------- -------------------- ---------------- --------------------- ----------------------------
SalesDB      Pub_Sales   SQLDR02    336             2022-11-30 06:14:02  190              56.5                  WARN: approaching expiration
SalesDB      Pub_Sales   SQLRPT03   336             2022-12-05 21:40:18  4                1.2
```

`13_ag_publisher_redirect.sql`, part 1

```
original_publisher publisher_db redirected_publisher
------------------ ------------ --------------------
SQLPROD01          SalesDB      SALESAGL
```
