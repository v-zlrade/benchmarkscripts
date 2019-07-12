-- ************************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: parse_job.sql
--
-- @Owner: v-dukut
--
-- Purpose: Parsing json column configs from jobs table
--			job -> table of benchmarks
--
-- ************************************************************************

CREATE FUNCTION [dbo].[parse_job]
(
	@job_id INT
)

RETURNS @runs TABLE
(
		config_names NVARCHAR(MAX) NULL,
		config_values NVARCHAR(MAX) NULL,
		instance_settings_overrides NVARCHAR(MAX) NULL,
		database_settings_overrides NVARCHAR(MAX) NULL,
		slo_property_bag_overrides NVARCHAR(MAX) NULL,
		trace_flags NVARCHAR(MAX) NULL, 

		benchmark_name NVARCHAR(64) NOT NULL, -- CDB|TPCC|DataLoading
		processor_count INT NOT NULL,
		is_bc BIT NOT NULL,
		hardware_generation NVARCHAR(64) NOT NULL, --G5|G4|SVMTight|SVMLoose
		environment  NVARCHAR(64) NOT NULL, --ProdG5|ProdG4|Stage|SVMTight|SVMLoose

		should_restore BIT NULL,
		priority_ INT NULL,
		worker_number INT NULL,
		benchmark_scaling_argument INT NULL,
		scaled_down BIT NULL,
		region VARCHAR(100) NULL,
		server_name NVARCHAR(1000) NULL,
		database_name_ NVARCHAR(128) NULL,
		warmup_timespan_minutes INT NULL,
		run_timespan_minutes INT NULL,
		custom_master_tsql_query NVARCHAR(MAX) NULL,
		required_processor_count INT NULL,
		scheduled_by NVARCHAR(1024) NULL,
		comment NVARCHAR(MAX) NULL
)
AS 
BEGIN
		DECLARE @job NVARCHAR(MAX) 
		SELECT @job = configs
		FROM jobs
		WHERE id = @job_id

		INSERT @runs
		SELECT *
		FROM OPENJSON (@job, '$.Benchmarks')
		WITH (
			config_names NVARCHAR(MAX) '$.InstanceConfigs.ConfigParamOverrides.ConfigNames',
			config_values NVARCHAR(MAX) '$.InstanceConfigs.ConfigParamOverrides.ConfigValues',
			instance_settings_overrides NVARCHAR(MAX) '$.InstanceConfigs.InstanceSettingsOverrides',
			database_settings_overrides NVARCHAR(MAX) '$.InstanceConfigs.DatabaseSettingsOverrides',
			slo_property_bag_overrides NVARCHAR(MAX) '$.InstanceConfigs.SloPropertyBagOverrides',
			trace_flags NVARCHAR(MAX) '$.InstanceConfigs.TraceFlags',

			benchmark_name NVARCHAR(64) '$.BenchmarkConfigs.BenchmarkName', 
			processor_count INT '$.BenchmarkConfigs.ProcessorCount',
			is_bc BIT '$.BenchmarkConfigs.IsBc',
			hardware_generation nvarchar(64) '$.BenchmarkConfigs.HardwareGeneration', 
			environment NVARCHAR(64) '$.BenchmarkConfigs.Environment',

			should_restore BIT '$.BenchmarkConfigs.ShouldRestore',
			priority_ INT '$.BenchmarkConfigs.Priority',
			worker_number INT '$.BenchmarkConfigs.WorkerNumber',
			benchmark_scaling_argument INT '$.BenchmarkConfigs.BenchmarkScalingArgument',
			scaled_down BIT '$.BenchmarkConfigs.ScaledDown',
			region VARCHAR(100) '$.BenchmarkConfigs.Region',
			server_name NVARCHAR(1000) '$.BenchmarkConfigs.ServerName',
			database_name_ NVARCHAR(128) '$.BenchmarkConfigs.DatabaseName',
			warmup_timespan_minutes INT '$.BenchmarkConfigs.WarmupTimespanMinutes',
			run_timespan_minutes INT '$.BenchmarkConfigs.RunTimespanMinutes',
			custom_master_tsql_query NVARCHAR(MAX) '$.BenchmarkConfigs.CustomMasterTSQLQuery',
			required_processor_count INT '$.BenchmarkConfigs.RequiredProcessorCount',
			scheduled_by NVARCHAR(1024) '$.BenchmarkConfigs.ScheduledBy',
			comment NVARCHAR(MAX) '$.BenchmarkConfigs.Comment'
			)

		UPDATE @runs SET priority_ = 0
		WHERE priority_ IS NULL

		UPDATE @runs SET should_restore = 1
		WHERE should_restore IS NULL

		

		RETURN
END


