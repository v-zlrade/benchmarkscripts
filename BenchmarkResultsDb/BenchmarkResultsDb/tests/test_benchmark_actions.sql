-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: test_benchmark_actions.sql
--
-- @Owner: anjov
--
-- Purpose:
-- Tests basic functionality for benchmark actions
--
-- *********************************************************************
CREATE PROCEDURE dbo.test_benchmark_actions
AS
BEGIN
    DECLARE @exception_message VARCHAR(500)

    -- Add some default configurations for UnitTest env
    INSERT INTO [slo_benchmark_config]
    (
        [processor_count],
        [hardware_generation],
        [is_bc],
        [benchmark_name],
        [worker_number],
        [benchmark_scaling_argument],
        [scaled_down],
        [server_name],
        [database_name],
        [warmup_timespan_minutes],
        [run_timespan_minutes],
        [environment],
        [custom_master_tsql_query],
        [required_processor_count]
    )
    VALUES
        (8, 'GEN4', 0, 'TPCC', 100, 4000, 0, 'unittestsvr', 'tpcc4000', 15, 120, 'UnitTest', 'SELECT TOP 1 1', 3)

    SET IDENTITY_INSERT [scheduled_benchmarks] ON

    -- Schedule runs
    INSERT INTO [scheduled_benchmarks]
    (
        [id],
        [processor_count],
        [hardware_generation],
        [is_bc],
        [benchmark_name],
        [environment],
        [is_picked_up],
        [is_adhoc_run]
    ) VALUES
        (1001, 8, 'GEN4', 0, 'TPCC', 'UnitTest', 0, 0)

    SET IDENTITY_INSERT [scheduled_benchmarks] OFF

    INSERT INTO instance_state
        (instance_environment, region, instance_name, [state])
    VALUES
        ('UnitTest', 'mockregion', 'unittestsvr', 'NotRunningBenchmark')

    INSERT INTO scheduled_benchmark_actions
        (scheduled_benchmark_id, action_type, required_benchmark_state, offset_seconds)
    VALUES
        (1001, 'Failover', 'RunningBenchmark', 0),
        (1001, 'MockAction', 'RunningBenchmark', 3600), -- action too far in the future
        (1001, 'MockAction', 'MockNonExistentState', 0) -- action in the wrong state

    EXEC start_scheduled_benchmark
        @scheduled_benchmark_id = 1001, @instance_dns_name = 'unittestsvr'

    DECLARE @action_execution_id BIGINT
    DECLARE @action VARCHAR(100)
    DECLARE @maximum_time_utc DATETIME2(0) = DATEADD(MINUTE, 30, GETUTCDATE())
    DECLARE @target_time_utc DATETIME2(0)

    SELECT @action = action_type FROM get_pending_benchmark_actions('UnitTest', 'mockregion', @target_time_utc)

    IF (@action IS NOT NULL)
    BEGIN
        SET @exception_message = CONCAT('Unexpected action: ', @action);
        THROW 50001, @exception_message, 1
    END

    EXEC upsert_instance
        @instance_name = 'unittestsvr', @state = 'RunningBenchmark'

    -- Make sure the target action time has arrived
    WAITFOR DELAY '00:00:01'

    SELECT @action_execution_id = action_execution_id, @action = action_type, @target_time_utc = target_time_utc
    FROM get_pending_benchmark_actions('UnitTest', 'mockregion', @maximum_time_utc)

    IF (NOT(@action = 'Failover' AND @target_time_utc < GETUTCDATE()))
    BEGIN
        SET @exception_message = CONCAT('Expected action not found. Actual: ', @action, ' at ', @target_time_utc);
        THROW 50001, @exception_message, 2
    END

    -- Simulate action execution
    UPDATE dbo.benchmark_action_executions
    SET executed_time_utc = GETUTCDATE()
    WHERE action_execution_id = @action_execution_id

    -- The other two actions still shouldn't be shown
    SET @action = NULL
    SELECT @action = action_type FROM get_pending_benchmark_actions('UnitTest', 'mockregion', @maximum_time_utc)

    IF (@action IS NOT NULL)
    BEGIN
        SET @exception_message = CONCAT('Unexpected action: ', @action);
        THROW 50001, @exception_message, 3
    END

    EXEC test_cleanup;
END
