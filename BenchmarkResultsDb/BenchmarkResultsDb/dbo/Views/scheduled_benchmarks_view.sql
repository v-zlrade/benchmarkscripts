-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: scheduled_benchmarks_view.sql
--
-- @Owner: anjov
--
-- Purpose:
-- View over all types of scheduled benchmarks (regular and ad-hoc).
--
-- *********************************************************************
CREATE VIEW dbo.scheduled_benchmarks_view
WITH SCHEMABINDING
AS
    SELECT
        sb.id,
        sb.job_id,
        sb.benchmark_name,
        sb.environment,
        sb.hardware_generation,
        sb.processor_count,
		sb.parallel_exec_cnt,
        sb.is_bc,
        sb.is_picked_up,
        sb.is_adhoc_run,
        benchmark_scaling_argument = ISNULL(sar.benchmark_scaling_argument, sbc.benchmark_scaling_argument),
        sar.correlation_id,
        custom_master_tsql_query = ISNULL(sar.custom_master_tsql_query, sbc.custom_master_tsql_query),
        region = ISNULL(sar.region, sbc.region),
        server_name = ISNULL(sar.server_name, sbc.server_name),
        [database_name] = ISNULL(sar.[database_name], sbc.[database_name]),
        sar.[priority],
        required_processor_count = ISNULL(sar.required_processor_count, sbc.required_processor_count),
        scaled_down = ISNULL(sar.scaled_down, sbc.scaled_down),
        worker_number = ISNULL(sar.worker_number, sbc.worker_number),
        sar.scheduled_by,
        sar.should_restore,
        warmup_timespan_minutes = ISNULL(sar.warmup_timespan_minutes, sbc.warmup_timespan_minutes),
        run_timespan_minutes = ISNULL(sar.run_timespan_minutes, sbc.run_timespan_minutes),
        mail_to = ISNULL(sar.scheduled_by, sbc.email_address)
    FROM
        dbo.scheduled_benchmarks sb
            LEFT OUTER JOIN
        dbo.adhoc_run_configs sar
            ON sb.id = sar.id
            INNER JOIN
        dbo.slo_benchmark_config sbc
            ON sbc.benchmark_name = sb.benchmark_name
            AND sbc.environment = sb.environment
            AND sbc.processor_count = sb.processor_count
            AND sbc.hardware_generation = sb.hardware_generation
            AND sbc.is_bc = sb.is_bc

