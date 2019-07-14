-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: run_tests.sql
--
-- @Owner: v-milast
--
-- Purpose:
-- Runs all tests
--
-- *********************************************************************
CREATE PROCEDURE [dbo].[run_tests]
AS
BEGIN
    BEGIN TRY
        EXEC test_cleanup;

        EXEC test_get_next_action;
        EXEC test_benchmark_actions;

        EXEC test_cleanup;
    END TRY
    BEGIN CATCH
        EXEC test_cleanup;
        THROW;
    END CATCH
END
