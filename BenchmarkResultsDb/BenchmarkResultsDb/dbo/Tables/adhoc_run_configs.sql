-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: adhoc_run_configs.sql
--
-- @Owner: v-milast
--
-- Table that holds information about scheduled ad hoc runs
--
-- *********************************************************************
CREATE TABLE [dbo].[adhoc_run_configs]
(
    [id] INT NOT NULL,
    [worker_number] INT NOT NULL,
    [benchmark_scaling_argument] INT NOT NULL,
    [scaled_down] BIT NOT NULL,
    [region] VARCHAR(100) NULL,
    [server_name] NVARCHAR(1000) NOT NULL,
    [database_name] NVARCHAR(128) NOT NULL,
    [warmup_timespan_minutes] INT NOT NULL,
    [run_timespan_minutes] INT NOT NULL,
    [custom_master_tsql_query] NVARCHAR(MAX) NULL,
    [required_processor_count] INT NULL,
	[parallel_exec_cnt] INT NULL,
    [priority] INT NOT NULL,
    [should_restore] BIT NOT NULL,
    [correlation_id] UNIQUEIDENTIFIER NOT NULL,
    [scheduled_by] NVARCHAR(1024) NULL,
    [comment] NVARCHAR(MAX) NULL,
    CONSTRAINT [pk_adhoc_run_configs] PRIMARY KEY CLUSTERED (id ASC),
    CONSTRAINT [fk_scheduled_benchmarks] FOREIGN KEY ([id]) REFERENCES [dbo].[scheduled_benchmarks] ([id]) ON DELETE CASCADE ON UPDATE CASCADE
)
GO

CREATE NONCLUSTERED INDEX [nci_adhoc_run_configs_priority_id]
    ON [dbo].adhoc_run_configs([priority] DESC, [id] ASC)
GO