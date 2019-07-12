-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: start_benchmark.sql
--
-- @Owner: v-milast
--
-- Purpose:
-- This stored procedure is used to initialize benchmark for runs.
-- It returns run_id
--
-- *********************************************************************
CREATE PROCEDURE [dbo].[start_benchmark]
	@benchmark_name VARCHAR(128),
	@processor_count INT,
	@hardware_generation VARCHAR(128),
	@parallel_exec_cnt INT = NULL,
	@environment VARCHAR(128) = NULL,
	@instance_dns_name VARCHAR(1000) = NULL,
	@comment NVARCHAR(MAX) = NULL,
	@correlation_id UNIQUEIDENTIFIER = NULL,
	@is_bussiness_critical BIT = 0
AS
BEGIN
	DECLARE @instance_id INT

	SELECT
		@instance_id = [instance_id]
	FROM
		[instance_state]
	WHERE
		[instance_name] = @instance_dns_name

	INSERT INTO [benchmark_runs]
	(
		[start_time],
		[benchmark_name],
		[instance_id],
		[processor_count],
		[parallel_exec_cnt],
		[hardware_generation],
		[environment],
		[comment],
		[correlation_id],
		[is_bc],
		[mail_sent]
	)
	OUTPUT [inserted].[run_id]
	VALUES
	(
		GETUTCDATE(),
		@benchmark_name,
		@instance_id,
		@processor_count,
		@parallel_exec_cnt,
		@hardware_generation,
		@environment,
		@comment,
		@correlation_id,
		@is_bussiness_critical,
		0
	)
END
