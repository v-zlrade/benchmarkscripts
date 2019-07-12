-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: benchmark_step_reports.sql
--
-- @Owner: v-milast
--
-- Purpose:
-- This table contains benchmark results by minute.
--
-- *********************************************************************
CREATE TABLE [dbo].[benchmark_step_reports]
(
    [id]                    BIGINT          IDENTITY (1, 1) NOT NULL,
    [run_id]                BIGINT          NOT NULL,
    [timestamp]             DATETIME2(0)    NOT NULL,
    [metric_name]           NVARCHAR(128)   NOT NULL,
    [metric_value]          FLOAT           NOT NULL
)
GO

CREATE NONCLUSTERED INDEX [nci_benchmark_step_reports_run_id]
    ON [dbo].[benchmark_step_reports]([run_id], [timestamp]) INCLUDE ([metric_name], [metric_value])
GO
