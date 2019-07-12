-- ************************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: schedule_adhoc_benchmark_override.sql
--
-- @Owner: v-dukut
--
-- Purpose: Stored procedure used to schedule adhoc runs, with desired parameters set as override.
--			config overrides + instance, database and slo property bag overrides
--			If some argument is not specified default value is taken for that SLO
--			Behaves same as schedule_adhoc_benchmark procedure + job_id and config_override columns
--			(This isn't added in schedule_adhoc_benchmark procedure since only v-dukut uses it)
--
-- ************************************************************************

CREATE PROCEDURE [dbo].[schedule_adhoc_benchmark_override]
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

	@job_id INT = NULL,

	@config_names NVARCHAR(MAX) NULL,
	@config_values NVARCHAR(MAX) NULL,
	@instance_settings_overrides NVARCHAR(MAX) NULL,
	@database_settings_overrides NVARCHAR(MAX) NULL,
	@slo_property_bag_overrides NVARCHAR(MAX) NULL,
	@trace_flags NVARCHAR(MAX) NULL,

	@scheduled_benchmark_id INT = NULL OUTPUT
AS
BEGIN
		-- Python library for connecting to database doesn't works properly if
		-- anything is displayed in the message
		SET NOCOUNT ON;  

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
		@parallel_exec_cnt = COALESCE(@parallel_exec_cnt, [parallel_exec_cnt])
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
			([is_adhoc_run], [processor_count], [parallel_exec_cnt], [hardware_generation], [is_bc], [benchmark_name], [environment], [is_picked_up], [job_id])
		VALUES
			(1, @processor_count, @parallel_exec_cnt, @hardware_generation, @is_bc, @action_name, @environment, 0, @job_id)

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

		INSERT INTO [dbo].[config_override]
		(
		[id],
		[config_override],
		[config_names],
		[config_values],
		[instance_settings_overrides],
		[database_settings_overrides],
		[slo_property_bag_overrides],
		[trace_flags]

		) VALUES
		(
		@scheduled_benchmark_id,
		(SELECT @config_names AS ConfigNames, @config_values AS ConfigValues FOR JSON PATH),
		@config_names,
		@config_values,
		@instance_settings_overrides,
		@database_settings_overrides,
		@slo_property_bag_overrides,
		@trace_flags
		)

		DECLARE @config_action_parameters_json NVARCHAR(MAX),
				@property_action_parameters_json NVARCHAR(MAX)

		--action SetConfigOverride 
		SET @config_action_parameters_json = (SELECT config_names, config_values
											FROM config_override
											WHERE id = @scheduled_benchmark_id FOR JSON AUTO)

		EXEC add_action_to_scheduled_benchmark
			@scheduled_benchmark_id = @scheduled_benchmark_id,
			@action_type = 'SetConfigOverride',
			@required_benchmark_state = 'Setup',
			@offset_seconds = 0,
			@action_parameters_json = @config_action_parameters_json

		--action SetPropertyOverride	
		SET @property_action_parameters_json = (SELECT instance_settings_overrides, database_settings_overrides, slo_property_bag_overrides
										FROM config_override
										WHERE id = @scheduled_benchmark_id FOR JSON AUTO) 

		EXEC add_action_to_scheduled_benchmark
			@scheduled_benchmark_id = @scheduled_benchmark_id,
			@action_type = 'SetPropertyOverride',
			@required_benchmark_state = 'ConfigOverridesApplied',
			@offset_seconds = 0,
			@action_parameters_json = @property_action_parameters_json


		COMMIT TRANSACTION
END

