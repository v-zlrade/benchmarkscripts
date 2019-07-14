-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: benchmark_runs_view.sql
--
-- @Owner: anjov
--
-- Purpose:
-- View over benchmark runs, incorporating data from scheduled_benchmarks and benchmark_results.
--
-- *********************************************************************
CREATE VIEW dbo.benchmark_runs_view
AS
    SELECT 
        br.run_id,
        br.instance_id,
        br.start_time,
        br.end_time,
        sbv.id,
        sbv.job_id,
        sbv.benchmark_name,
        benchmark_environment = sbv.environment,
        ist.instance_environment,
        ist.region,
        sbv.hardware_generation,
        sbv.server_name,
        sbv.[database_name],
        sbv.processor_count,
		sbv.parallel_exec_cnt,
        sbv.is_bc,
        sbv.is_picked_up,
        sbv.is_adhoc_run,
        sbv.benchmark_scaling_argument,
        sbv.correlation_id,
        sbv.custom_master_tsql_query,
        sbv.[priority],
        required_processor_count,
        scaled_down ,
        worker_number,
        scheduled_by,
        should_restore,
        warmup_timespan_minutes,
        run_timespan_minutes,
        instance_state = ist.[state],
        executed_actions = ( 
            SELECT a.action_type, ae.executed_time_utc 
            FROM scheduled_benchmark_actions a INNER JOIN benchmark_action_executions ae ON ae.action_id = a.action_id
            WHERE ae.run_id = br.run_id AND ae.executed_time_utc IS NOT NULL
            FOR JSON AUTO),
        benchmark_results = 
            (SELECT metric_name, metric_value FROM benchmark_results WHERE run_id = br.run_id FOR JSON AUTO)
		
    FROM 
        benchmark_runs br
            INNER JOIN
        scheduled_benchmarks_view sbv
            ON br.scheduled_benchmark_id = sbv.id
            INNER JOIN
        instance_state ist
            ON br.instance_id = ist.instance_id
GO