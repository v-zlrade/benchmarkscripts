-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: test_get_next_action.sql
--
-- @Owner: v-milast
--
-- Purpose:
-- Test for get_next_action SP
--
-- *********************************************************************
CREATE PROCEDURE [dbo].[test_get_next_action]
AS
BEGIN
    BEGIN TRY
        DECLARE @expected_action_name NVARCHAR(64);
        DECLARE @expected_processor_count INT;
        DECLARE @expected_hardware_generation NVARCHAR(64);
        DECLARE @expected_environment NVARCHAR(64);
        DECLARE @expected_is_bc BIT;
        DECLARE @expected_should_restore BIT = 1;
        DECLARE @expected_priority INT = 0;
        DECLARE @expected_worker_number INT = NULL;
        DECLARE @expected_benchmark_scaling_argument INT = NULL;
        DECLARE @expected_scaled_down BIT = NULL;
        DECLARE @expected_server_name NVARCHAR = NULL;
        DECLARE @expected_database_name NVARCHAR = NULL;
        DECLARE @expected_warmup_timespan_minutes INT = NULL;
        DECLARE @expected_run_timespan_minutes INT = NULL;

        -- Initialize test environment
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
            (8, 'GEN4', 0, 'TPCC', 100, 4000, 0, 'unittestsvr1', 'tpcc4000', 15, 120, 'UnitTest', 'SELECT TOP 100 * FROM BLABLA', 3),
            (8, 'GEN4', 1, 'CDB', 100, 15000, 0, 'unittestsvr1', 'cdb15000', 15, 60, 'UnitTest', NULL, 4),
            (16, 'GEN4', 1, 'CDB', 200, 15000, 0, 'unittestsvr2', 'cdb15000', 15, 60, 'UnitTest', NULL, 8)

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
            (1001, 8, 'GEN4', 0, 'TPCC', 'UnitTest', 0, 0),
            (1002, 8, 'GEN4', 1, 'CDB',  'UnitTest', 0, 0),
            (1003, 16, 'GEN4', 1, 'CDB', 'UnitTest', 0, 0),
            (1004, 8, 'GEN4', 0, 'TPCC', 'UnitTest', 0, 0)

        SET IDENTITY_INSERT [scheduled_benchmarks] OFF

        INSERT INTO instance_state
            (instance_environment, region, instance_name, [state])
        VALUES
            ('UnitTest', 'mockregion', 'unittestsvr1', 'Ready'),
            ('UnitTest', 'mockregion', 'unittestsvr2', 'Ready'),
            ('UnitTest', 'mockregion', 'unittestsvr3', 'Ready')



        -- Test when no resources available no results are returned
        EXEC [exec_and_verify_get_next_action]
             @available_resources = 0,
             @expect_results = 0;

        -- we first expect scheduled run with id 1003 as it requires the most resources
        EXEC [exec_and_verify_get_next_action]
            @available_resources = 1000,
            @expect_results = 1,
            @expected_action_name = 'CDB',
            @expected_processor_count = 16,
            @expected_hardware_generation = 'GEN4',
            @expected_is_bc = 1,
            @expected_should_restore = 1,
            @expected_worker_number = 200,
            @expected_benchmark_scaling_argument = 15000,
            @expected_scaled_down = 0,
            @expected_server_name = 'unittestsvr2',
            @expected_database_name = 'cdb15000',
            @expected_warmup_timespan_minutes = 15,
            @expected_run_timespan_minutes = 60,
            @expected_required_processor_count = 8

        -- we now expect run with id 1002
        EXEC [exec_and_verify_get_next_action]
            @available_resources = 1000,
            @expect_results = 1,
            @expected_action_name = 'CDB',
            @expected_processor_count = 8,
            @expected_hardware_generation = 'GEN4',
            @expected_is_bc = 1,
            @expected_should_restore = 1,
            @expected_worker_number = 100,
            @expected_benchmark_scaling_argument = 15000,
            @expected_scaled_down = 0,
            @expected_server_name = 'unittestsvr1',
            @expected_database_name = 'cdb15000',
            @expected_warmup_timespan_minutes = 15,
            @expected_run_timespan_minutes = 60,
            @expected_required_processor_count = 4

        -- There can be no more runs as all instances are occupied now
        EXEC [exec_and_verify_get_next_action]
            @available_resources = 1000,
            @expect_results = 0

        -- lets free resource (instance) that is associated with scheduled id 1001, so we can test if adhoc runs have priority
        EXEC [finalize_action]
             @server_name = 'unittestsvr1'
        EXEC [finalize_action]
             @server_name = 'unittestsvr2'

        -- lets now schedule adhoc runs
        -- one with default and lower priority
        EXEC [schedule_adhoc_benchmark]
            @action_name = 'CDB',
            @processor_count = 16,
            @hardware_generation = 'GEN4',
            @environment = 'UnitTest',
            @is_bc = 1,
            @should_restore = 1,
            @priority = 0,
            @worker_number = 1000,
            @benchmark_scaling_argument = 32,
            @scaled_down = 1,
            @server_name = 'unittestsvr3',
            @database_name = 'cdbdb',
            @warmup_timespan_minutes = 15,
            @run_timespan_minutes = 111,
            @custom_master_tsql_query = 'TestQuery1',
            @required_processor_count = 4

        -- schedule another on same server with higher priority
        EXEC [schedule_adhoc_benchmark]
            @action_name = 'TPCC',
            @processor_count = 8,
            @hardware_generation = 'GEN4',
            @environment = 'UnitTest',
            @is_bc = 0,
            @should_restore = 0,
            @priority = 1,
            @worker_number = 2000,
            @benchmark_scaling_argument = 32,
            @scaled_down = 1,
            @server_name = 'unittestsvr3',
            @database_name = 'tpccdb',
            @warmup_timespan_minutes = 15,
            @run_timespan_minutes = 111,
            @custom_master_tsql_query = 'TestQuery2',
            @required_processor_count = 4

        -- we now expect adhoc run with highest priority
        EXEC [exec_and_verify_get_next_action]
            @available_resources = 1000,
            @expect_results = 1,
            @expected_action_name = 'TPCC',
            @expected_processor_count = 8,
            @expected_hardware_generation = 'GEN4',
            @expected_is_bc = 0,
            @expected_should_restore = 0,
            @expected_worker_number = 2000,
            @expected_benchmark_scaling_argument = 32,
            @expected_scaled_down = 1,
            @expected_server_name = 'unittestsvr3',
            @expected_database_name = 'tpccdb',
            @expected_warmup_timespan_minutes = 15,
            @expected_run_timespan_minutes = 111,
            @expected_custom_master_tsql_query = 'TestQuery2',
            @expected_required_processor_count = 4

        -- since there is something scheduled on unittestsvr3, next adhoc run should not block regular scheduled runs
       -- We now expect run with id 1001
        EXEC [exec_and_verify_get_next_action]
            @available_resources = 1000,
            @expect_results = 1,
            @expected_action_name = 'TPCC',
            @expected_processor_count = 8,
            @expected_hardware_generation = 'GEN4',
            @expected_is_bc = 0,
            @expected_should_restore = 1,
            @expected_worker_number = 100,
            @expected_benchmark_scaling_argument = 4000,
            @expected_scaled_down = 0,
            @expected_server_name = 'unittestsvr1',
            @expected_database_name = 'tpcc4000',
            @expected_warmup_timespan_minutes = 15,
            @expected_run_timespan_minutes = 120,
            @expected_custom_master_tsql_query = 'SELECT TOP 100 * FROM BLABLA',
            @expected_required_processor_count = 3

        -- Nothing else can be executed - as next regular run is scheduled on occupied instance
        -- and next adhoc run is also on occupied instance
        EXEC [exec_and_verify_get_next_action]
            @available_resources = 1000,
            @expect_results = 0

        -- lets unblock both regular and adhoc instances
        EXEC [finalize_action]
             @server_name = 'unittestsvr3'
        EXEC [finalize_action]
             @server_name = 'unittestsvr1'

        -- test the case when we have enough resources for regular run but there is adhoc scheduled
        EXEC [exec_and_verify_get_next_action]
            @available_resources = 3, -- 3 is what unittestsvr1 needs, 4 is what unittestsvr3 needs
            @expect_results = 0

        -- we now expect adhoc run we scheduled first - with lower priority
        EXEC [exec_and_verify_get_next_action]
            @available_resources = 4,
            @expect_results = 1,
            @expected_action_name = 'CDB',
            @expected_processor_count = 16,
            @expected_hardware_generation = 'GEN4',
            @expected_is_bc = 1,
            @expected_should_restore = 1,
            @expected_worker_number = 1000,
            @expected_benchmark_scaling_argument = 32,
            @expected_scaled_down = 1,
            @expected_server_name = 'unittestsvr3',
            @expected_database_name = 'cdbdb',
            @expected_warmup_timespan_minutes = 15,
            @expected_run_timespan_minutes = 111,
            @expected_custom_master_tsql_query = 'TestQuery1',
            @expected_required_processor_count = 4

       -- Finally we exepect scheduled run with id 1004 as it is the only one left
        EXEC [exec_and_verify_get_next_action]
            @available_resources = 1000,
            @expect_results = 1,
            @expected_action_name = 'TPCC',
            @expected_processor_count = 8,
            @expected_hardware_generation = 'GEN4',
            @expected_is_bc = 0,
            @expected_should_restore = 1,
            @expected_worker_number = 100,
            @expected_benchmark_scaling_argument = 4000,
            @expected_scaled_down = 0,
            @expected_server_name = 'unittestsvr1',
            @expected_database_name = 'tpcc4000',
            @expected_warmup_timespan_minutes = 15,
            @expected_run_timespan_minutes = 120,
            @expected_custom_master_tsql_query = 'SELECT TOP 100 * FROM BLABLA',
            @expected_required_processor_count = 3

        -- all scheduled runs are now executed once, we expect is_picked_up to be reset to 0 for UnitTest env
        IF EXISTS (SELECT 1 FROM [scheduled_benchmarks] 
            WHERE [is_adhoc_run] = 0 AND [is_picked_up] = 1 AND [environment] = 'UnitTest')
        BEGIN;
            THROW 50002, 'Expecting is_picked_up to be set to 0 for UnitTest env', 1
        END

        EXEC [test_cleanup];
    END TRY
    BEGIN CATCH
        EXEC [test_cleanup];
        THROW;
    END CATCH
END
