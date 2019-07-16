-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: slo_benchmark_config.sql
--
-- @Owner: v-milast
--
-- Purpose:
-- Per SLO benchmark configurations
--
-- *********************************************************************
CREATE TABLE [dbo].[slo_benchmark_config]
(
    [processor_count] INT NOT NULL,
    [hardware_generation] NVARCHAR(128) NOT NULL,
    [is_bc] BIT NOT NULL,
    [benchmark_name] NVARCHAR(128) NOT NULL,
    [worker_number] INT NOT NULL,
    [benchmark_scaling_argument] INT NOT NULL,
    [scaled_down] BIT NOT NULL,
    [server_name] NVARCHAR(1000) NOT NULL,
    [database_name] NVARCHAR(128) NOT NULL,
    [warmup_timespan_minutes] INT NOT NULL,
    [run_timespan_minutes] INT NOT NULL,
    [custom_master_tsql_query] NVARCHAR(MAX) NULL,
    [required_processor_count] INT NOT NULL,
    [parallel_exec_cnt] INT NOT NULL,
    [environment] NVARCHAR(50) NOT NULL,
    [region]      VARCHAR(100) NULL, -- TODO: change to NOT NULL after we've filled in the existing rows
    [email_address] NVARCHAR(512) NULL DEFAULT 'clperfdevs@service.microsoft.com',
    CONSTRAINT [PK_slo_benchmark_config] PRIMARY KEY ([processor_count], [hardware_generation], [is_bc], [benchmark_name], [environment])
)
GO
