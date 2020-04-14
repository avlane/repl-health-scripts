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
