-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: job_definitions.sql
--
-- @Owner: v-dukut
--
-- Purpose: Introducing concept of Job: Job is set of benchmarks, each
--				with their own configuration: benchmark configuration and instance configuration overrides
--				(config params, database settings, slo property bag, trace flags)
--				TBD: Add desired actions to benchmark runs + maybe add custom t-sql query as independent override
--
--				Column configs store benchmark configurations in json format
--				Column description is human understandable job description 
--				If some argument is not specified default value is taken for that SLO
--
--
-- configs column: 
--
--{"Benchmarks":  [
--    {
--      "InstanceConfiguration":
--      {
--        "ConfigParamOverrides": {"ConfigNames":"", "ConfigValues":""}, 
--        "InstanceSettingsOverrides":  "<InstanceSettingsXML>" ,
--        "DatabaseSettingsOverrides": "<DatabaseSettingsXML>",
--        "SloPropertyBagOverrides": "<SloPropertyBagXML>",
--        "TraceFlags": ""
--      },
--      "BenchmarkConfigs": {...}
--    },
--    {
--      "InstanceConfiguration":
--      {
--        "ConfigParamOverrides": {"ConfigNames":"", "ConfigValues":""},
--        "InstanceSettingsOverrides":  "<InstanceSettingsXML>" ,
--        "DatabaseSettingsOverrides": "<DatabaseSettingsXML>",
--        "SloPropertyBagOverrides": "<SloPropertyBagXML>",
--        "TraceFlags": ""
--      },
--      "BenchmarkConfigs": {...}
--    }
--  ]
--}
--	
-- *********************************************************************

CREATE TABLE [dbo].[job_definitions]
(
	[id] INT IDENTITY(1, 1) NOT NULL,
	[name] NVARCHAR(450) NOT NULL UNIQUE,
	[configs] NVARCHAR(MAX) NULL,
	[description] NVARCHAR(MAX) NULL,

	CONSTRAINT [pk_job_definition] PRIMARY KEY CLUSTERED ([id] ASC)
)
