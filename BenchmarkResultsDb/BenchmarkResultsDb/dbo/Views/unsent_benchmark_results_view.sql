-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: unsent_benchmark_results_view.sql
--
-- @Owner: v-milast
--
-- Purpose:
-- View used to see what emails with results were not sent
--
-- *********************************************************************
CREATE VIEW [dbo].[unsent_benchmark_results_view]
    AS
        SELECT
        b.run_id,
        b.start_time,
        b.end_time,
        b.environment,
        b.is_bc,
        b.processor_count,
        b.hardware_generation,
        b.benchmark_name,
        s.benchmark_scaling_argument,
        s.server_name,
        s.database_name,
        s.worker_number,
        s.scheduled_by,
        s.run_timespan_minutes,
        CONCAT('{', STRING_AGG(CONCAT('"', br.metric_name, '":', br.metric_value), ','), '}') AS metric_values
    FROM benchmark_runs b
    INNER JOIN scheduled_benchmarks_view s on s.id = b.scheduled_benchmark_id
    INNER join benchmark_results br on b.run_id = br.run_id
    WHERE b.mail_sent = 0
    GROUP BY
        b.run_id,
        b.start_time,
        b.end_time,
        b.environment,
        b.is_bc,
        b.processor_count,
        b.hardware_generation,
        b.benchmark_name,
        s.benchmark_scaling_argument,
        s.server_name,
        s.database_name,
        s.worker_number,
        s.scheduled_by,
        s.run_timespan_minutes