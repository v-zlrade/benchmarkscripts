-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: schedule_job.sql
--
-- @Owner: v-dukut
--
-- Purpose: Stored procedure used to schedule job, with desired parameters set as override.
--			Two options for scheduling are possible:
--				1. schedule and define job with new name and desired configs and description
--				2. schedule job with existent name (applying configs from its definition)
--
--			Column configs store benchmark configurations in json format 
--			(see job_definitions table for more details)
--
--			Column description is human understandable job description 
--			If some argument is not specified default value is taken for that SLO
--
--
-- *********************************************************************

CREATE PROCEDURE [dbo].[schedule_job]
	@name NVARCHAR(MAX),
	@configs NVARCHAR(MAX) = NULL,
	@description NVARCHAR(MAX) = NULL,
	@id INT = NULL OUTPUT
AS
BEGIN
	-- Python library for connecting to database doesn't work properly if
	-- anything is displayed in the message
	SET NOCOUNT ON

	DECLARE @name_exists BIT = 0

	IF EXISTS
			(SELECT *
			FROM job_definitions
			WHERE [name] = @name) 

		SET @name_exists = 1

	IF @name_exists = 0 OR @configs IS NULL

		BEGIN
			
			IF @configs IS NULL
				SET @configs = (SELECT configs
								FROM job_definitions
								WHERE [name] =@name)

			INSERT INTO [dbo].[jobs]
				([name], [configs], [description])
			VALUES
				(@name, @configs, @description)

			SET @id = SCOPE_IDENTITY()

			--scheduling benchmarks region
			DECLARE cursor_job CURSOR FOR
				SELECT benchmark_name, processor_count, hardware_generation, environment, is_bc, should_restore, priority_,
						worker_number, benchmark_scaling_argument, scaled_down, region, server_name, database_name_, warmup_timespan_minutes,
						run_timespan_minutes, custom_master_tsql_query, required_processor_count, scheduled_by, comment, config_names,
						config_values, instance_settings_overrides, database_settings_overrides, slo_property_bag_overrides, trace_flags
				FROM parse_job(@id)
	
			DECLARE @action_name NVARCHAR(64),
					@processor_count INT,
					@hardware_generation NVARCHAR(64),
					@environment NVARCHAR(64),
					@is_bc BIT,
					@should_restore BIT,
					@priority INT,
					@worker_number INT,
					@benchmark_scaling_argument INT,
					@scaled_down BIT,
					@region VARCHAR(10),
					@server_name NVARCHAR(1000),
					@database_name NVARCHAR(128),
					@warmup_timespan_minutes INT,
					@run_timespan_minutes INT,
					@custom_master_tsql_query NVARCHAR(MAX),
					@required_processor_count INT,
					@scheduled_by NVARCHAR(1024),
					@comment NVARCHAR(MAX),
					@config_names NVARCHAR(MAX),
					@config_values NVARCHAR(MAX),
					@instance_settings_overrides NVARCHAR(MAX),
					@database_settings_overrides NVARCHAR(MAX),
					@slo_property_bag_overrides NVARCHAR(MAX),
					@trace_flags NVARCHAR(MAX),
					@scheduled_benchmark_id NVARCHAR(MAX)
					

			OPEN cursor_job
			FETCH NEXT FROM cursor_job 
			INTO @action_name, 
				@processor_count,
				@hardware_generation,
				@environment,
				@is_bc,
				@should_restore,
				@priority,
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
				@scheduled_by,
				@comment,
				@config_names,
				@config_values,
				@instance_settings_overrides,
				@database_settings_overrides,
				@slo_property_bag_overrides,
				@trace_flags


			WHILE @@FETCH_STATUS = 0  
			BEGIN  
					EXEC schedule_adhoc_benchmark_override
						@action_name = @action_name,
						@processor_count = @processor_count ,
						@hardware_generation = @hardware_generation,
						@environment = @environment,
						@is_bc = @is_bc,
						@should_restore = @should_restore,
						@priority = @priority,
						@worker_number = @worker_number,
						@benchmark_scaling_argument = @benchmark_scaling_argument,
						@scaled_down = @scaled_down,
						@region = @region,
						@server_name = @server_name,
						@database_name = @database_name,
						@warmup_timespan_minutes = @warmup_timespan_minutes,
						@run_timespan_minutes = @run_timespan_minutes,
						@custom_master_tsql_query = @custom_master_tsql_query ,
						@required_processor_count = @required_processor_count,
						@scheduled_by = @scheduled_by,
						@comment = @comment,
						@config_names = @config_names,
						@config_values = @config_values,
						@instance_settings_overrides = @instance_settings_overrides,
						@database_settings_overrides = @database_settings_overrides,
						@slo_property_bag_overrides = @slo_property_bag_overrides,
						@trace_flags = @trace_flags,
						@job_id = @id,
						@scheduled_benchmark_id = @scheduled_benchmark_id OUTPUT
					

					FETCH NEXT FROM cursor_job
					INTO @action_name, 
						@processor_count,
						@hardware_generation,
						@environment,
						@is_bc,
						@should_restore,
						@priority,
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
						@scheduled_by,
						@comment,
						@config_names,
						@config_values,
						@instance_settings_overrides,
						@database_settings_overrides,
						@slo_property_bag_overrides,
						@trace_flags
			END

			CLOSE cursor_job  
			DEALLOCATE cursor_job
		END

	-- defining new job	
	IF @name_exists = 0
			
		INSERT INTO [dbo].[job_definitions]
			([name], [configs], [description])
		VALUES
			(@name, @configs, @description)

END
