-- *********************************************************************
-- Copyright (c) Microsoft Corporation.
--
-- @File: trace.sql
--
-- @Owner: stlazi
--
-- Purpose:
-- This procedure store trace into a tracing table.
--
-- Parameters:
-- level :: 1/info; 2/warning; 3/error
-- event_name :: name of the event that is being traced
-- event_message :: basic message for the event that is being traced
-- correlation_id :: id that enables correlation between different traces that should be tracked together.
-- server_name :: server name
-- database_name :: database name
--
-- *********************************************************************

CREATE PROCEDURE [dbo].[trace]
(
	@level INT,
	@event_name NVARCHAR(128),
	@event_message NVARCHAR(MAX),
	@correlation_id UNIQUEIDENTIFIER,
	@vm_name NVARCHAR(128) = NULL,
	@server_name NVARCHAR(128) = NULL,
	@database_name NVARCHAR(128) = NULL,
	@stack_trace NVARCHAR(128) = NULL
)
WITH EXECUTE AS OWNER
AS
BEGIN
	INSERT INTO [dbo].[tracing_logs] ([timestamp], [level], [event_name], [event_message], [stack_trace], [correlation_id], [vm_name], [server_name], [database_name])
		VALUES (GETUTCDATE(), @level, @event_name, @event_message, @stack_trace, @correlation_id, @vm_name, @server_name, @database_name);
END
GO