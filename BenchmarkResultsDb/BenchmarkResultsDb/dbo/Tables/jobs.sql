-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: jobs.sql
--
-- @Owner: v-dukut
--
-- Purpose: Stores currently active jobs with their states
--			Column state: scheduled, started, succeeded, failed
--			See job_definitions table for more details
-- *********************************************************************

CREATE TABLE [dbo].[jobs]
(
	[id] INT IDENTITY(1, 1) NOT NULL,
	[name] NVARCHAR(MAX) NOT NULL,
	[configs] NVARCHAR(MAX) NULL,
	[description] NVARCHAR(MAX) NULL,
	[state] NVARCHAR(1024) NOT NULL DEFAULT 'Scheduled' -- scheduled, started, succeeded, failed

	CONSTRAINT [pk_jobs] PRIMARY KEY CLUSTERED ([id] ASC)
)
