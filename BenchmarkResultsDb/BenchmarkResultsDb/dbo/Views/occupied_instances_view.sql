-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: occupied_instances_view.sql
--
-- @Owner: v-milast
--
-- Purpose:
-- View of occupied instances (that are currently running)
--
-- *********************************************************************
CREATE VIEW [dbo].[occupied_instances_view]
AS
    SELECT [instance_name]
    FROM [instance_state]
    WHERE [state] != 'Ready'
