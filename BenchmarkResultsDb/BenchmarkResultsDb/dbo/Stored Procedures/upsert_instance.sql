-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: upsert_instance.sql
--
-- @Owner: v-milast
--
-- Purpose:
-- This SP upserts information about instance.
--
-- *********************************************************************
CREATE PROCEDURE [dbo].[upsert_instance]
    @instance_name NVARCHAR(1000),
    @state NVARCHAR(128),
    @instance_environment VARCHAR(50) = NULL,
    @region VARCHAR(100) = NULL
AS
BEGIN
    MERGE [instance_state] AS target
    USING (
        SELECT
            @instance_name AS [instance_name],
            @instance_environment AS [instance_environment],
            @region AS [region],
            @state AS [state]
    ) AS source
    ON (target.[instance_name] = source.[instance_name])
        WHEN MATCHED THEN
        UPDATE SET
            [state] = [source].[state],
            [last_state_change_timestamp] = GETUTCDATE()
        WHEN NOT MATCHED THEN
        INSERT
        (
            [instance_name],
            [instance_environment],
            [region],
            [state],
            [last_state_change_timestamp]
        ) VALUES
        (
            [source].[instance_name],
            [source].[instance_environment],
            [source].[region],
            [source].[state],
            GETUTCDATE()
        );
END