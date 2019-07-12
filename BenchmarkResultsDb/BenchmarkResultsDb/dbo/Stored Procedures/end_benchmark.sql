-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: end_benchmark.sql
--
-- @Owner: v-milast
--
-- *********************************************************************
CREATE PROCEDURE [end_benchmark]
	@run_id BIGINT
AS
BEGIN
	UPDATE [benchmark_runs]
	SET end_time = GETUTCDATE()
	WHERE [run_id] = @run_id
END