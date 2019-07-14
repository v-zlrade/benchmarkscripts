-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: schedule_adhoc_benchmark.sql
--
-- @Owner: v-milast
--
-- Stored procedure used to schedule adhoc runs, with desired parameters set as override.
-- If some argument is not specified default value is taken for that SLO
--
-- *********************************************************************
CREATE PROCEDURE [dbo].[schedule_adhoc_benchmark]
    @action_name NVARCHAR(64),
    @processor_count INT,
    @hardware_generation NVARCHAR(64),
    @environment NVARCHAR(64),
    @is_bc BIT,
    @should_restore BIT = 1,
    @priority INT = 0,
    @worker_number INT = NULL,
    @benchmark_scaling_argument INT = NULL,
    @scaled_down BIT = NULL,
    @region VARCHAR(100) = NULL,
    @server_name NVARCHAR(1000) = NULL,
    @database_name NVARCHAR(128) = NULL,
    @warmup_timespan_minutes INT = NULL,
    @run_timespan_minutes INT = NULL,
    @custom_master_tsql_query NVARCHAR(MAX) = NULL,
    @required_processor_count INT = NULL,
	@parallel_exec_cnt INT = NULL, 
    @scheduled_by NVARCHAR(1024) = NULL,
    @comment NVARCHAR(MAX) = NULL,
    @scheduled_benchmark_id INT = NULL OUTPUT
AS
BEGIN
    SELECT
        @worker_number = COALESCE(@worker_number, [worker_number]),
        @benchmark_scaling_argument = COALESCE(@benchmark_scaling_argument, [benchmark_scaling_argument]),
        @scaled_down = COALESCE(@scaled_down, [scaled_down]),
        @region = COALESCE(@region, [region]),
        @server_name = COALESCE(@server_name, [server_name]),
        @database_name = COALESCE(@database_name, [database_name]),
        @warmup_timespan_minutes = COALESCE(@warmup_timespan_minutes, [warmup_timespan_minutes]),
        @run_timespan_minutes = COALESCE(@run_timespan_minutes, [run_timespan_minutes]),
        @custom_master_tsql_query = COALESCE(@custom_master_tsql_query, [custom_master_tsql_query]),
        @required_processor_count = COALESCE(@required_processor_count, [required_processor_count]),
		@parallel_exec_cnt  = COALESCE(@parallel_exec_cnt, [parallel_exec_cnt])
    FROM [slo_benchmark_config]
    WHERE [benchmark_name] = @action_name
    AND [environment] = @environment
    AND [processor_count] = @processor_count
    AND [hardware_generation] = @hardware_generation
    AND [is_bc] = @is_bc

    IF @scheduled_by IS NOT NULL
        SET @scheduled_by = CONCAT(@scheduled_by, '@microsoft.com')
    ELSE IF (CHARINDEX('@microsoft', SUSER_NAME()) > 0)
        SET @scheduled_by = SUSER_NAME()

    BEGIN TRANSACTION

        INSERT INTO [dbo].[scheduled_benchmarks]
            ([is_adhoc_run], [processor_count], [parallel_exec_cnt], [hardware_generation], [is_bc], [benchmark_name], [environment], [is_picked_up])
        VALUES
            (1, @processor_count, @parallel_exec_cnt, @hardware_generation, @is_bc, @action_name, @environment, 0)

        SET @scheduled_benchmark_id = SCOPE_IDENTITY()

        INSERT INTO [dbo].[adhoc_run_configs]
        (
            [id],
            [worker_number],
            [benchmark_scaling_argument],
            [scaled_down],
            [region],
            [server_name],
            [database_name],
            [warmup_timespan_minutes],
            [run_timespan_minutes],
            [custom_master_tsql_query],
            [required_processor_count],
			[parallel_exec_cnt],
            [priority],
            [should_restore],
            [correlation_id],
            [scheduled_by],
            [comment]
        ) VALUES
        (
            @scheduled_benchmark_id,
            @worker_number,
            @benchmark_scaling_argument,
            @scaled_down,
            @region,
            @server_name,
            @database_name,
            @warmup_timespan_minutes,
            @run_timespan_minutes,
            @custom_master_tsql_query,
            @required_processor_count,
			@parallel_exec_cnt,
            @priority,
            @should_restore,
            NEWID(),
            @scheduled_by,
            @comment
         )

     COMMIT TRANSACTION
END
