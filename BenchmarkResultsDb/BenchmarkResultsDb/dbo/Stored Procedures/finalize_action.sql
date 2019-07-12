-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: finalize_action.sql
--
-- @Owner: v-milast
--
-- Purpose:
-- This stored procedure is used to finalize actions on instance.
-- It returns run_id
--
-- *********************************************************************
CREATE PROCEDURE [dbo].[finalize_action]
    @server_name NVARCHAR(1000)
AS
BEGIN
    EXEC [upsert_instance]
        @instance_name = @server_name,
        @state = 'Ready'
END