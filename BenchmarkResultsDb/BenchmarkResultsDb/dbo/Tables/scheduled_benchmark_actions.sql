-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: scheduled_benchmark_actions.sql
--
-- @Owner: anjov
--
-- Purpose:
-- Description of actions that should be executed during benchmark runs.
--
-- *********************************************************************
CREATE TABLE [dbo].[scheduled_benchmark_actions]
(
    [action_id] INT IDENTITY(1,1) NOT NULL,
    [scheduled_benchmark_id] INT NOT NULL,
    [action_type] VARCHAR(100) NOT NULL,
    [required_benchmark_state] VARCHAR(100) NULL,
    [offset_seconds] INT NULL, -- should be executed after this amount of time in the state given above
    [action_parameters] NVARCHAR(MAX) NULL, -- JSON containing custom parameters: {"param1": "value1", ... }

    CONSTRAINT [pk_scheduled_benchmark_actions] PRIMARY KEY CLUSTERED (action_id ASC),

    CONSTRAINT [fk_scheduled_benchmark_id] FOREIGN KEY ([scheduled_benchmark_id])
        REFERENCES [dbo].[scheduled_benchmarks] ([id]) ON DELETE CASCADE ON UPDATE CASCADE
);
GO

CREATE NONCLUSTERED INDEX [nci_scheduled_benchmark_id] ON [dbo].[scheduled_benchmark_actions] ([scheduled_benchmark_id])
GO

