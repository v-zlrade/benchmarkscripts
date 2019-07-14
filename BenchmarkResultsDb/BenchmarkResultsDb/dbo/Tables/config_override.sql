-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: config_override.sql
--
-- @Owner: v-dukut
--
-- Purpose: Table contains additional parameters for instance configuration
--			(it is not merged with scheduled_benchmarks table because 
--			only v-dukut runs have this property)
--
-- *********************************************************************

CREATE TABLE [dbo].[config_override]
(
	[id] INT NOT NULL,
	-- json format of config override
	[config_override] NVARCHAR(MAX) NULL,

	-- parsed config override (keeping both since I don't know which option is going to be used)
	[config_names] NVARCHAR(MAX) NULL,
	[config_values] NVARCHAR(MAX) NULL,

	[instance_settings_overrides] NVARCHAR(MAX) NULL,
	[database_settings_overrides] NVARCHAR(MAX) NULL,
	[slo_property_bag_overrides] NVARCHAR(MAX) NULL,
	[trace_flags] NVARCHAR(MAX) NULL

	CONSTRAINT [fk_config_override_id] FOREIGN KEY ([id]) 
		REFERENCES [dbo].[scheduled_benchmarks] ([id]) ON DELETE CASCADE ON UPDATE CASCADE,
)

