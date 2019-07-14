-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: test_cleanup.sql
--
-- @Owner: v-milast
--
-- Purpose:
-- Cleanup function for tests
--
-- *********************************************************************
CREATE PROCEDURE [dbo].[test_cleanup]
AS
BEGIN
    -- Delete everything from scheduled benchmarks
    DELETE FROM [scheduled_benchmarks]
    WHERE [environment] = 'UnitTest'

    DELETE FROM [benchmark_runs]
    WHERE [environment] = 'UnitTest'

    -- DELETE all test instances
    DELETE FROM [instance_state]
    WHERE [instance_name] LIKE 'unittestsvr%'

    -- Delete everything from default configs for UnitTest env
    DELETE FROM [slo_benchmark_config]
    WHERE [environment] = 'UnitTest'
END
