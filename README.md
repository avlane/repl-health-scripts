# repl-health-scripts

T-SQL scripts for checking the health of SQL Server transactional replication.
Most scripts run on the distributor (in the `distribution` database); the tracer
token script runs on the publisher.

## Scripts

| script | what it does |
|---|---|
| `01_agent_job_status.sql` | replication agent jobs and their last outcome |

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
