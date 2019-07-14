-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: exec_and_verify_get_next_action.sql
--
-- @Owner: v-milast
--
-- Purpose:
-- Helper functions that executes and verifies results of get_next_action SP
--
-- *********************************************************************
CREATE PROCEDURE [dbo].[exec_and_verify_get_next_action]
    @available_resources INT,
    @expect_results BIT,
    @expected_action_name NVARCHAR(64) = NULL,
    @expected_processor_count INT = NULL,
    @expected_hardware_generation NVARCHAR(64) = NULL,
    @expected_is_bc BIT = NULL,
    @expected_should_restore BIT = NULL,
    @expected_worker_number INT = NULL,
    @expected_benchmark_scaling_argument INT = NULL,
    @expected_scaled_down BIT = NULL,
    @expected_server_name NVARCHAR(1000) = NULL,
    @expected_database_name NVARCHAR(128) = NULL,
    @expected_warmup_timespan_minutes INT = NULL,
    @expected_run_timespan_minutes INT = NULL,
    @expected_custom_master_tsql_query NVARCHAR(MAX) = NULL,
    @expected_required_processor_count INT = NULL
AS
BEGIN
    DECLARE @exception_message NVARCHAR(MAX);
    DECLARE @actual_action_name NVARCHAR(64) = NULL;
    DECLARE @actual_processor_count INT = NULL;
    DECLARE @actual_hardware_generation NVARCHAR(64) = NULL;
    DECLARE @actual_is_bc BIT = NULL;
    DECLARE @actual_should_restore BIT = NULL;
    DECLARE @actual_priority INT = NULL;
    DECLARE @actual_worker_number INT = NULL;
    DECLARE @actual_benchmark_scaling_argument INT = NULL;
    DECLARE @actual_scaled_down BIT = NULL;
    DECLARE @actual_server_name NVARCHAR(1000) = NULL;
    DECLARE @actual_database_name NVARCHAR(128) = NULL;
    DECLARE @actual_warmup_timespan_minutes INT = NULL;
    DECLARE @actual_run_timespan_minutes INT = NULL;
    DECLARE @actual_custom_master_tsql_query NVARCHAR(MAX) = NULL;
    DECLARE @actual_required_processor_count INT = NULL;

    DECLARE @tmptable AS TABLE
    (
        [scheduled_benchmark_id] INT,
        [benchmark_name] NVARCHAR(128),
        [processor_count] INT,
        [is_bc] BIT,
        [hardware_generation] NVARCHAR(64),
        [worker_number] INT,
        [benchmark_scaling_argument] INT,
        [scaled_down] BIT,
        [server_name] NVARCHAR(1000),
        [database_name] NVARCHAR(128),
        [warmup_timespan_minutes] INT,
        [run_timespan_minutes] INT,
        [custom_master_tsql_query] NVARCHAR(MAX),
        [should_restore] BIT,
        [required_processor_count] INT,
        [correlation_id] UNIQUEIDENTIFIER
    )

    INSERT INTO @tmptable
    EXEC get_next_action
        @available_cores = @available_resources,
        @environment = 'UnitTest'

    SELECT
         @actual_action_name = [benchmark_name],
         @actual_processor_count = [processor_count],
         @actual_is_bc = [is_bc],
         @actual_hardware_generation = [hardware_generation],
         @actual_worker_number = [worker_number],
         @actual_benchmark_scaling_argument = [benchmark_scaling_argument],
         @actual_scaled_down = [scaled_down],
         @actual_server_name = [server_name],
         @actual_database_name = [database_name],
         @actual_warmup_timespan_minutes = [warmup_timespan_minutes],
         @actual_run_timespan_minutes = [run_timespan_minutes],
         @actual_should_restore = [should_restore],
         @actual_custom_master_tsql_query = [custom_master_tsql_query],
         @actual_required_processor_count = [required_processor_count]
    FROM
        @tmptable

    IF @expect_results = 1
    BEGIN
        IF (@actual_action_name <> @expected_action_name OR
            @actual_processor_count <> @expected_processor_count OR
            @actual_hardware_generation <> @expected_hardware_generation OR
            @actual_is_bc <> @expected_is_bc OR
            @actual_should_restore <> @expected_should_restore OR
            @actual_worker_number <> @expected_worker_number OR
            @actual_benchmark_scaling_argument <> @expected_benchmark_scaling_argument OR
            @actual_scaled_down <> @expected_scaled_down OR
            @actual_server_name <> @expected_server_name OR
            @actual_database_name <> @expected_database_name OR
            @actual_warmup_timespan_minutes <> @expected_warmup_timespan_minutes OR
            @actual_run_timespan_minutes <> @expected_run_timespan_minutes OR
            @actual_required_processor_count <> @expected_required_processor_count OR
            COALESCE(@actual_custom_master_tsql_query, '') <> COALESCE(@expected_custom_master_tsql_query, ''))
        BEGIN
            SET @exception_message = CONCAT('Values dont match: (actual, expected) pairs: ',
                '(', @actual_action_name, ', ', @expected_action_name, '),',
                '(', @actual_processor_count, ', ', @expected_processor_count, '),',
                '(', @actual_hardware_generation, ', ', @expected_hardware_generation, '),',
                '(', @actual_is_bc, ', ', @expected_is_bc, '),',
                '(', @actual_should_restore, ', ', @expected_should_restore, '),',
                '(', @actual_worker_number, ', ', @expected_worker_number, '),',
                '(', @actual_benchmark_scaling_argument, ', ', @expected_benchmark_scaling_argument, '),',
                '(', @actual_scaled_down, ', ', @expected_scaled_down, '),',
                '(', @actual_server_name, ', ', @expected_server_name, '),',
                '(', @actual_database_name, ', ', @expected_database_name, '),',
                '(', @actual_warmup_timespan_minutes, ', ', @expected_warmup_timespan_minutes, '),',
                '(', @actual_run_timespan_minutes, ', ', @expected_run_timespan_minutes, '), ',
                '(', @actual_required_processor_count, ', ', @expected_required_processor_count, '), ',
                '(', @actual_custom_master_tsql_query, ', ', @expected_custom_master_tsql_query, ')');
            THROW 50001, @exception_message, 1
        END
    END
    ELSE
    BEGIN
        IF @actual_action_name IS NOT NULL
        BEGIN;
            SET @exception_message = CONCAT('Expected no values but got (',
                @actual_action_name, ', ',
                @actual_processor_count, ', ',
                @actual_hardware_generation, ', ',
                @actual_is_bc, ', ',
                @actual_should_restore, ', ',
                @actual_worker_number, ', ',
                @actual_benchmark_scaling_argument, ', ',
                @actual_scaled_down, ', ',
                @actual_server_name, ', ',
                @actual_database_name, ', ',
                @actual_warmup_timespan_minutes, ', ',
                @actual_run_timespan_minutes, ', ',
                @actual_required_processor_count, ')');

            THROW 50002, @exception_message, 1
        END
    END
END
