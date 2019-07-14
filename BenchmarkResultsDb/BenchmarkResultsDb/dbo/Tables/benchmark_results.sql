-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: benchmark_results.sql
--
-- @Owner: v-milast
--
-- Purpose:
-- This table contains results of benchmark run
-- 
-- *********************************************************************
CREATE TABLE [dbo].[benchmark_results] (
    [id]           BIGINT        IDENTITY (1, 1) NOT NULL,
    [run_id]       BIGINT        NOT NULL,
    [metric_name]  VARCHAR (128) NOT NULL,
    [metric_value] FLOAT (53)    NOT NULL,
    CONSTRAINT [pk_benchmark_results] PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [fk_benchmark_results_run_id] FOREIGN KEY ([run_id]) REFERENCES [dbo].[benchmark_runs] ([run_id]) ON DELETE CASCADE ON UPDATE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [nci_benchmark_results_run_id]
    ON [dbo].[benchmark_results]([run_id] ASC);

