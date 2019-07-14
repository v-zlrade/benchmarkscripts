-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: mark_mail_sent.sql
--
-- @Owner: v-milast
--
-- Purpose:
-- SP used to mark that mail is sent for given benchmark run
--
-- *********************************************************************
CREATE PROCEDURE [dbo].[mark_mail_sent]
    @run_id BIGINT
AS
BEGIN
    UPDATE [benchmark_runs]
    SET [mail_sent] = 1
    WHERE [run_id] = @run_id
END
