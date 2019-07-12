-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: scheduled_benchmarks.sql
--
-- @Owner: v-milast
--
-- Purpose:
-- Scheduled runs of benchmarks
--
-- *********************************************************************
CREATE TABLE [dbo].[scheduled_benchmarks]
(
    [id] INT IDENTITY(1,1) NOT NULL,
    [job_id] INT NULL,
    [is_adhoc_run] BIT NOT NULL DEFAULT(0),
    [processor_count] INT NOT NULL,
	[parallel_exec_cnt] INT NOT NULL,
    [hardware_generation] NVARCHAR(128) NOT NULL,
    [is_bc] BIT NOT NULL,
    [benchmark_name] NVARCHAR(128) NOT NULL,
    [environment]  NVARCHAR(50) NOT NULL,
    [is_picked_up] BIGINT NOT NULL

    CONSTRAINT [pk_scheduled_benchmarks] PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [fk_scheduled_benchmarks_slo_name_benchmark_name_environment]
        FOREIGN KEY ([processor_count], [hardware_generation], [is_bc], [benchmark_name], [environment])
        REFERENCES [dbo].[slo_benchmark_config] ([processor_count], [hardware_generation], [is_bc], [benchmark_name], [environment]) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT [fk_jobs]
		FOREIGN KEY ([job_id])
		REFERENCES [dbo].[jobs] ([id]) ON DELETE CASCADE ON UPDATE CASCADE
);
GO

CREATE NONCLUSTERED INDEX [nci_scheduled_benchmarks_environment_include_is_picked_up]
    ON [dbo].[scheduled_benchmarks] ([environment]) INCLUDE ([is_picked_up])
GO

