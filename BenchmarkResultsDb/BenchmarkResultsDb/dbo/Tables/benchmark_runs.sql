-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: benchmark_runs.sql
--
-- @Owner: v-milast
--
-- Purpose:
-- This table contains information about benchmark runs.
--
-- *********************************************************************
CREATE TABLE [dbo].[benchmark_runs] (
    [run_id]                BIGINT        IDENTITY (1, 1) NOT NULL,
    [scheduled_benchmark_id] BIGINT NULL, -- NULLs allowed only to support old runs already in the table
    [correlation_id]        UNIQUEIDENTIFIER NULL,
    [instance_id]           INT NULL,
    [start_time]            DATETIME2 (0) NOT NULL,
    [end_time]              DATETIME2 (0) NULL,
    [benchmark_name]        VARCHAR (128) NOT NULL,
    [processor_count]       INT           NOT NULL,
	[parallel_exec_cnt]   INT			  NOT NULL,
    [hardware_generation]   VARCHAR(128)  NOT NULL,
    [is_bc]                 BIT           NOT NULL,
    [environment]           VARCHAR(128)  NULL,
    [comment]               NVARCHAR(MAX) NULL,
    [mail_sent]             BIT NULL,

    CONSTRAINT [pk_benchmark_runs] PRIMARY KEY CLUSTERED ([run_id] ASC),
    CONSTRAINT [fk_instance_id_instance_state] FOREIGN KEY ([instance_id]) REFERENCES [dbo].[instance_state] ([instance_id])
);
GO

CREATE NONCLUSTERED INDEX [nci_benchmark_runs_start_time]
    ON [dbo].[benchmark_runs]([start_time] DESC);
GO

CREATE NONCLUSTERED INDEX [nci_benchmark_runs_end_time_mail_sent]
    ON [dbo].[benchmark_runs]([scheduled_benchmark_id], [run_id], [mail_sent]);
GO
