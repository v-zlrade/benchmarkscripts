-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: pending_benchmark_actions_view.sql
--
-- @Owner: anjov
--
-- Purpose:
-- View over all types of scheduled benchmarks (regular and ad-hoc).
--
-- *********************************************************************
CREATE FUNCTION dbo.get_pending_benchmark_actions
(
	@environment VARCHAR(50),
	@region VARCHAR(100),
	@maximum_target_time_utc DATETIME2(0)
)
RETURNS TABLE
AS 
	RETURN SELECT
		ba.action_execution_id,
		ist.instance_name,
		sba.action_type,
		sba.action_parameters,
		target_time_utc = DATEADD(SECOND, sba.offset_seconds, ist.last_state_change_timestamp)
	FROM 
		dbo.benchmark_action_executions ba
			INNER JOIN
		dbo.scheduled_benchmark_actions sba
			ON ba.action_id = sba.action_id
			INNER JOIN
		dbo.scheduled_benchmarks_view sbv
			ON sba.scheduled_benchmark_id = sbv.id
			INNER JOIN
		dbo.instance_state ist
			ON ist.instance_name = sbv.server_name
	WHERE
		ist.instance_environment = @environment
		AND ist.region = @region
		AND ist.[state] = sba.required_benchmark_state
		AND sbv.is_picked_up = 1
		AND executed_time_utc IS NULL -- don't take already executed actions
		AND execution_result IS NULL
		AND DATEADD(SECOND, sba.offset_seconds, ist.last_state_change_timestamp) < @maximum_target_time_utc