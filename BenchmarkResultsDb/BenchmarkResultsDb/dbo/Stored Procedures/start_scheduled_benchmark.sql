-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: start_scheduled_benchmark.sql
--
-- @Owner: anjov
--
-- Purpose:
-- Starts a scheduled benchmark run, specified by its ID, on the given instance.
-- Also schedules any actions connected to the benchmark.
--
-- *********************************************************************
CREATE PROCEDURE [dbo].[start_scheduled_benchmark]
	@scheduled_benchmark_id INT,
	@instance_dns_name VARCHAR(1000),
	@comment NVARCHAR(MAX) = NULL,
	@correlation_id UNIQUEIDENTIFIER = NULL
AS
	DECLARE @benchmark_run_id INT
	DECLARE @instance_id INT

	SELECT
		@instance_id = [instance_id]
	FROM
		[instance_state]
	WHERE
		[instance_name] = @instance_dns_name

	INSERT INTO benchmark_runs
	(
		start_time,
		scheduled_benchmark_id,
		benchmark_name,
		instance_id,
		processor_count,
		parallel_exec_cnt,
		hardware_generation,
		environment,
		comment,
		correlation_id,
		is_bc
	)
	SELECT
		GETUTCDATE(),
		id,
		benchmark_name,
		@instance_id,
		processor_count,
		parallel_exec_cnt,
		hardware_generation,
		environment,
		@comment,
		@correlation_id,
		is_bc
	FROM
		scheduled_benchmarks
	WHERE
		id = @scheduled_benchmark_id

	SET @benchmark_run_id = SCOPE_IDENTITY()

	UPDATE benchmark_action_executions
	SET run_id = @benchmark_run_id
	WHERE action_id IN (
		SELECT action_id
		FROM scheduled_benchmark_actions
		WHERE scheduled_benchmark_id = @scheduled_benchmark_id)

	SELECT @benchmark_run_id AS [run_id]
