-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: instance_state.sql
--
-- @Owner: v-milast
--
-- Purpose:
-- This table provides information about instance current state.
--
-- *********************************************************************
CREATE TABLE [dbo].[instance_state]
(
    [instance_id] INT IDENTITY(1,1) NOT NULL,
    [instance_environment] VARCHAR(50) NULL,
    [region] VARCHAR(100) NULL,
    -- Full DNS name
    [instance_name] NVARCHAR(1000) NOT NULL UNIQUE,
    [last_state_change_timestamp] DATETIME2(0),
    [state] NVARCHAR(128) NOT NULL,

    CONSTRAINT [pk_instance_state] PRIMARY KEY CLUSTERED ([instance_id])
)
