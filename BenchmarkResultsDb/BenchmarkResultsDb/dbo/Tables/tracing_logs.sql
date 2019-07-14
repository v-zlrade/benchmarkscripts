-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: tracing_logs.sql
--
-- @Owner: stlazi
--
-- Purpose:
-- Table that holds tracing logs for the last x days (currently x is 7)
--
-- *********************************************************************
CREATE TABLE [dbo].[tracing_logs] (
    [tracing_log_id] BIGINT IDENTITY (0, 1) NOT NULL,
    [timestamp] DATETIME NOT NULL,
    [level] INT NOT NULL,
    [event_name] NVARCHAR(128) NOT NULL,
    [event_message] NVARCHAR(MAX) NULL,
    [stack_trace] NVARCHAR(MAX) NULL,
    [correlation_id] UNIQUEIDENTIFIER NOT NULL,
    [vm_name] NVARCHAR(128) NULL,
    [server_name] NVARCHAR(128) NULL,
    [database_name] NVARCHAR(128) NULL,
    [partition_number] AS (datediff(day,CONVERT([datetime],(0)),[timestamp])%(9)+(1)) PERSISTED NOT NULL,
    CONSTRAINT [pk_tracing_logs] PRIMARY KEY CLUSTERED ([tracing_log_id] ASC, [partition_number] ASC) ON [week_partition_scheme] ([partition_number]),
    CONSTRAINT [tracing_logs_level_check] CHECK ([level] >= 1 AND [level] <= 3)
);
GO

CREATE NONCLUSTERED INDEX [nci_tracing_logs_correlation_id_event_name]
    ON [dbo].[tracing_logs]([correlation_id], [event_name])
    ON [week_partition_scheme] ([partition_number]);
GO

CREATE NONCLUSTERED INDEX [nci_tracing_logs_event_name]
    ON [dbo].[tracing_logs]([event_name], [timestamp] ASC)
    ON [week_partition_scheme] ([partition_number]);
GO

CREATE NONCLUSTERED INDEX [nci_tracing_logs_server_database_name]
    ON [dbo].[tracing_logs]([server_name], [database_name], [timestamp] ASC)
    ON [week_partition_scheme] ([partition_number]);
GO