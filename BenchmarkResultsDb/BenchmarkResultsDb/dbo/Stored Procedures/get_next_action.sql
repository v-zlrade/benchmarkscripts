-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: get_next_action.sql
--
-- @Owner: v-milast
--
-- Returns action to execute with parameters, based on available resources and environment
-- DEVNOTE: This SP is not thread safe for same environment provided as parameter
-- Different environments can operate at same time
-- It is not thread safe because it first READS and later on UPDATEs read values
--
-- *********************************************************************
CREATE PROCEDURE [dbo].[get_next_action]
    @available_cores INT,
    @environment NVARCHAR(64)
AS
BEGIN
    -- Python is getting confused if anything is displayed in messages
    SET NOCOUNT ON;

    DECLARE @benchmark_name NVARCHAR(128);
    DECLARE @processor_count INT = NULL;
    DECLARE @is_bc BIT = NULL;
    DECLARE @hardware_generation NVARCHAR(64) = NULL;
    DECLARE @worker_number INT = NULL;
    DECLARE @benchmark_scaling_argument INT = NULL;
    DECLARE @scaled_down BIT = NULL;
    DECLARE @server_name NVARCHAR(1000) = NULL;
    DECLARE @database_name NVARCHAR(128) = NULL;
    DECLARE @warmup_timespan_minutes INT = NULL;
    DECLARE @run_timespan_minutes INT = NULL;
    DECLARE @custom_master_tsql_query NVARCHAR(MAX) = NULL;
    DECLARE @required_processor_count INT = NULL;
	DECLARE @parallel_exec_cnt INT = NULL;
    DECLARE @id INT = NULL;
    DECLARE @scheduled_count INT = NULL;
    DECLARE @should_restore BIT;
    DECLARE @correlation_id UNIQUEIDENTIFIER;
    DECLARE @has_result BIT = 0;

    -- Auto rollback if exception happens
    SET XACT_ABORT ON

    -- DEVNOTE: We are blocking stage deployments with restore, so hard code to not work during update hours
    -- from 00:00AM to 11AM
    DECLARE @current_timestamp DATETIME2(0) = GETUTCDATE()
    DECLARE @stage_scheduled_runs_embargo BIT = 0
    IF ((@environment = 'Stage' OR @environment = 'SVMStage') AND DATEPART(HOUR, @current_timestamp) >= 0 AND DATEPART(HOUR, @current_timestamp) <= 11)
    BEGIN
        SET @stage_scheduled_runs_embargo = 1;
    END

    BEGIN TRANSACTION GET_NEXT_ACTION_TRAN
    -- Prioritizes ad hoc runs
    -- we cannot put instance_state in this query as we want scheduled with highest priority to be executed next, no matter whether instance is available or not
    SELECT TOP 1
        @id = [id],
        @benchmark_name = [benchmark_name],
        @processor_count = [processor_count],
        @is_bc = [is_bc],
        @hardware_generation = [hardware_generation],
        @worker_number = [worker_number],
        @benchmark_scaling_argument = [benchmark_scaling_argument],
        @scaled_down = [scaled_down],
        @server_name = [server_name],
        @database_name = [database_name],
        @warmup_timespan_minutes = [warmup_timespan_minutes],
        @run_timespan_minutes = [run_timespan_minutes],
        @custom_master_tsql_query = [custom_master_tsql_query],
        @required_processor_count = [required_processor_count],
		@parallel_exec_cnt = [parallel_exec_cnt],
        @should_restore = [should_restore],
        @correlation_id = [correlation_id]
    FROM [scheduled_benchmarks_view]
    WHERE 
        environment = @environment
        AND [is_adhoc_run] = 1
        AND [is_picked_up] = 0
        AND [server_name] NOT IN
        (
            SELECT [instance_name]
            FROM [occupied_instances_view]
        )
    ORDER BY [priority] DESC, [id] ASC

    -- if no ad hoc run scheduled get regular runs
    IF @server_name IS NULL
    BEGIN
        SELECT TOP 1
            @id = [id],
            @benchmark_name = [benchmark_name],
            @processor_count = [processor_count],
            @is_bc = [is_bc],
            @hardware_generation = [hardware_generation],
            @worker_number = [worker_number],
            @benchmark_scaling_argument = [benchmark_scaling_argument],
            @scaled_down = [scaled_down],
            @server_name = [server_name],
            @database_name = [database_name],
            @warmup_timespan_minutes = [warmup_timespan_minutes],
            @run_timespan_minutes = [run_timespan_minutes],
            @custom_master_tsql_query = [custom_master_tsql_query],
            @required_processor_count = [required_processor_count],
			@parallel_exec_cnt = [parallel_exec_cnt],
            @should_restore = 1,
            @correlation_id = NEWID()
        FROM [scheduled_benchmarks_view]
        WHERE [environment] = @environment
        AND [required_processor_count] <= @available_cores
        AND [server_name] NOT IN
        (
            SELECT [instance_name]
            FROM [occupied_instances_view]
        )
        AND [is_picked_up] = 0
		AND @stage_scheduled_runs_embargo = 0
        ORDER BY [required_processor_count] DESC, [id] ASC

        -- only update if we actually got some @server_name back
        IF (@server_name IS NOT NULL)
        BEGIN
            UPDATE [scheduled_benchmarks]
            SET [is_picked_up] = 1
            WHERE [id] = @id

            SET @has_result = 1;

            -- If all recurring benchmarks are already picked up, reset is_picked_up to 0, so we can start a new cycle.
            IF NOT EXISTS (
                SELECT 1 FROM [scheduled_benchmarks] 
                WHERE [environment] = @environment AND [is_adhoc_run] = 0 AND [is_picked_up] = 0
            )
            BEGIN
                UPDATE [scheduled_benchmarks]
                SET [is_picked_up] = 0
                WHERE [environment] = @environment AND [is_adhoc_run] = 0
            END
        END
    END
    ELSE
    BEGIN
        -- only update if there are enough resources to run and instance is available
        IF (@required_processor_count <= @available_cores)
        BEGIN
            UPDATE [scheduled_benchmarks]
            SET [is_picked_up] = 1
            WHERE [id] = @id

            SET @has_result = 1;
        END
    END

    -- return results only if there are enough resources
    IF @has_result = 1
    BEGIN
        -- upsert state of instance
        EXEC upsert_instance
            @instance_name = @server_name,
            @state = 'Occupied';

        SELECT
            @id as [scheduled_benchmark_id],
            @benchmark_name AS [benchmark_name],
            @processor_count AS [processor_count],
            @is_bc AS [is_bc],
            @hardware_generation AS [hardware_generation],
            @worker_number AS [worker_number],
            @benchmark_scaling_argument AS [benchmark_scaling_argument],
            @scaled_down AS [scaled_down],
            @server_name AS [server_name],
            @database_name AS [database_name],
            @warmup_timespan_minutes AS [warmup_timespan_minutes],
            @run_timespan_minutes AS [run_timespan_minutes],
            @custom_master_tsql_query AS [custom_master_tsql_query],
            @should_restore AS [should_restore],
            @required_processor_count AS [required_processor_count],
			@parallel_exec_cnt AS [parallel_exec_cnt],
            @correlation_id AS [correlation_id]
    END

    COMMIT TRANSACTION GET_NEXT_ACTION_TRAN
END
