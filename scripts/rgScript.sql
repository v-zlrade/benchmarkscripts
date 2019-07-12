-- This script should be executed everytime new managed instance is created
use master
go

ALTER RESOURCE GOVERNOR WITH (CLASSIFIER_FUNCTION = NULL)
GO
ALTER RESOURCE GOVERNOR DISABLE
GO

CREATE FUNCTION dbo.OAClassifier()
RETURNS SYSNAME
    WITH SCHEMABINDING
AS
BEGIN
        DECLARE @WorkloadGroup SYSNAME = IIF (SUSER_NAME() = 'clperf', 'gOLTPQueryStream', 'default')
        RETURN @WorkloadGroup
END
GO

ALTER RESOURCE GOVERNOR WITH ( CLASSIFIER_FUNCTION = dbo.OAClassifier )
GO

ALTER RESOURCE GOVERNOR RECONFIGURE
GO

--- Create or Alter pOLTPDWQueries Resource Pool
IF EXISTS ( SELECT name FROM sys.resource_governor_resource_pools WHERE name = 'pOLTPQueries' )
    ALTER RESOURCE POOL pOLTPQueries WITH(
                min_cpu_percent=0,
                max_cpu_percent=100,
                min_memory_percent=0,
                max_memory_percent=100,
                cap_cpu_percent=100,
                AFFINITY SCHEDULER = (0 TO 3))
ELSE
        CREATE RESOURCE POOL pOLTPQueries WITH(
                min_cpu_percent=0,
                max_cpu_percent=100,
                min_memory_percent=0,
                max_memory_percent=100,
                AFFINITY SCHEDULER = (0 TO 3))
GO

ALTER RESOURCE GOVERNOR RECONFIGURE;
GO

--- Create or Alter gOLTPQueryStream Workload Group
IF EXISTS ( SELECT name FROM sys.resource_governor_workload_groups WHERE name = 'gOLTPQueryStream' )
        ALTER WORKLOAD GROUP gOLTPQueryStream WITH(IMPORTANCE =High) USING pOLTPQueries
ELSE
        CREATE WORKLOAD GROUP gOLTPQueryStream WITH(IMPORTANCE =High) USING pOLTPQueries
GO

ALTER RESOURCE GOVERNOR RECONFIGURE;
GO
