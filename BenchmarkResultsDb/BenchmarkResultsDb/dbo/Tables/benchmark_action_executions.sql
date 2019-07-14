-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: benchmark_action_executions.sql
--
-- @Owner: anjov
--
-- Purpose:
-- Enumerates benchmark actions scheduled for execution, and logs already executed ones.
--
-- *********************************************************************
CREATE TABLE dbo.benchmark_action_executions
(
	action_execution_id BIGINT IDENTITY(1,1) NOT NULL,
	run_id BIGINT NULL,
	action_id INT NOT NULL,
	executed_time_utc DATETIME2(0),
	execution_result NVARCHAR(MAX),

	CONSTRAINT pk_benchmark_actions PRIMARY KEY CLUSTERED (action_execution_id ASC),

	CONSTRAINT fk_run_id_benchmark_runs FOREIGN KEY (run_id) 
		REFERENCES dbo.benchmark_runs (run_id) ON DELETE CASCADE ON UPDATE CASCADE,

	CONSTRAINT fk_action_id_scheduled_benchmark_actions FOREIGN KEY (action_id) 
		REFERENCES dbo.scheduled_benchmark_actions (action_id) ON DELETE CASCADE ON UPDATE CASCADE

)
