-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: add_action_to_scheduled_benchmark.sql
--
-- @Owner: anjov
--
-- *********************************************************************
CREATE PROCEDURE dbo.add_action_to_scheduled_benchmark
    @scheduled_benchmark_id INT,
    @action_type VARCHAR(100),
    @required_benchmark_state VARCHAR(100),
    @offset_seconds INT,
    @action_parameters_json NVARCHAR(MAX)
AS
    INSERT INTO dbo.scheduled_benchmark_actions
        (scheduled_benchmark_id, action_type, required_benchmark_state, offset_seconds, action_parameters)
    VALUES
        (@scheduled_benchmark_id, @action_type, @required_benchmark_state, @offset_seconds, @action_parameters_json)

    INSERT INTO benchmark_action_executions
            (run_id, action_id, executed_time_utc)
                SELECT NULL, action_id, NULL
                FROM scheduled_benchmark_actions
                WHERE scheduled_benchmark_id = @scheduled_benchmark_id
                AND action_type = @action_type
