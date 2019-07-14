# --------------------------------------------------------------------------------------
# Script      : clPerfCommon.ps1                                                       -
# Description : Common functions like tracing which will be used in other scripts.     -
# Author      : stlazi                                                                 -
# Date        : 08-18-2018                                                             -
# Version     : V 1.0                                                                  -
# --------------------------------------------------------------------------------------

$global:clCred
$global:clServer
$global:clDatabase

function SetClPerfDb
{
    <#
        .SYNOPSIS
        Sets cl perf db info

        .DESCRIPTION
        Sets cl perf db info

        .EXAMPLE
        SetClPerfDbCred -Cred $cred -Server $server -Database $database
    #>

    Param(
        [Parameter(Mandatory=$True)]
        [System.Management.Automation.PSCredential]
        $Cred,

        [Parameter(Mandatory=$True)]
        [String]
        $Server,

        [Parameter(Mandatory=$True)]
        [String]
        $Database
    )

    Set-Variable -Name clCred -Value $Cred -Scope Global
    Set-Variable -Name clServer -Value $Server -Scope Global
    Set-Variable -Name clDatabase -Value $Database -Scope Global
}

function GetClPerfDbCred
{
    <#
        .SYNOPSIS
        Gets credentials for CL perf database

        .DESCRIPTION
        Gets ps credentials for CL perf database where benchmark run results are saved.

        .EXAMPLE
        $cred = GetClPerfDbCred
    #>

    return $global:clCred
}

function ExecuteSqlQueryWithRetry
{
    <#
        .SYNOPSIS
        Executes sql query with retry

        .DESCRIPTION
        Imlementation of retry logic using Invoke-Sqlcmd, with ability to specify retry count and delay between retries

        .EXAMPLE
        ExecuteSqlQueryWithRetry -ServerInstance "clperf.database.windows.net" -DatabaseName "clperftesting" -InstanceCredentials $cred -Query $traceQuery -RetryDelayInSeconds 10 -NumberOfRetries 5
    #>
Param(
    [Parameter(Mandatory=$True, HelpMessage="Server name")]
    [String]
    $ServerInstance,

    [Parameter(Mandatory=$True, HelpMessage="Database name")]
    [String]
    $DatabaseName,

    [Parameter(Mandatory=$False, HelpMessage="Instance credentials")]
    [System.Management.Automation.PSCredential]
    $InstanceCredentials,

    [Parameter(Mandatory=$True, HelpMessage="Query")]
    [String]
    $Query,

    [Parameter( HelpMessage="Number of retries")]
    [int]
    $NumberOfRetries = 5,

    [Parameter(HelpMessage="Delay in seconds between retries")]
    [int]
    $RetryDelayInSeconds = 10,

    [Parameter(HelpMessage="What to do in case of errors")]
    [String]
    $ErrAction = "Continue"
)

    while ($true)
    {
        try
        {
            $result = Invoke-Sqlcmd `
              -ServerInstance $ServerInstance `
              -Database $DatabaseName `
              -Username $InstanceCredentials.GetNetworkCredential().UserName `
              -Password $InstanceCredentials.GetNetworkCredential().Password `
              -Query $Query `
              -ErrorAction $ErrAction

            return $result
        }
        catch
        {
            Write-Host "Exception happened while querying database"
            Write-Error -Message "$($_.Exception.Message)"

            $NumberOfRetries--

            if ($NumberOfRetries -eq 0)
            {
                throw
            }

            Start-Sleep -Seconds $RetryDelayInSeconds
        }
    }
}

function TraceToClPerfDb
{
    <#
        .SYNOPSIS
        Trace to cl perf db

        .DESCRIPTION
        Trace functions which logs to cl perf db.

        .EXAMPLE
        TraceToClPerfDb -Level "Info" -CorrelationId $correlationId -EventName "iteration_info" -EventMessage "No tasks"
    #>
Param(
    [Parameter(Mandatory=$True, HelpMessage="Trace level")]
    [ValidateSet(
        "Info",
        "Warning",
        "Error"
    )]
    [String]
    $Level,

    [Parameter(Mandatory=$True, HelpMessage="Event name of trace")]
    [String]
    $EventName,

    [Parameter(Mandatory=$False, HelpMessage="Event message")]
    [String]
    $EventMessage = "",

    [Parameter(Mandatory=$False, HelpMessage="Event message")]
    [String]
    $Stack,

    [Parameter(Mandatory=$True, HelpMessage="CorrelationId which is used to identify traces in the same task iteration")]
    [String]
    $CorrelationId,

    [Parameter(Mandatory=$False, HelpMessage="Server name")]
    [String]
    $ServerName = "",

    [Parameter(Mandatory=$False, HelpMessage="Database name")]
    [String]
    $DatabaseName = ""
)
    $db_level = 0

    switch ($Level)
    {
        "Info"
        {
            $db_level = 3
        }
        "Warning"
        {
            $db_level = 2
        }
        "Error"
        {
            $db_level = 1
        }
    }

    $vmName = $env:computername

    # replace character " and ' because in event message because it can cause errors
    $EventMessage = $EventMessage.Replace("`"","")
    $EventMessage = $EventMessage.Replace("`'","")

    # replace character " and ' because in event message because it can cause errors
    $Stack = $Stack.Replace("`"","")
    $Stack = $Stack.Replace("`'","")

    $cred = GetClPerfDbCred
    $traceQuery = "
        EXEC [trace]
            @level = $($db_level),
            @event_name = '$($EventName)',
            @event_message = '$($EventMessage)',
            @correlation_id = '$($CorrelationId)',
            @vm_name = '$($vmName)',
            @server_name = '$($ServerName)',
            @database_name = '$($DatabaseName)'
        "

    if (-not [string]::IsNullOrEmpty($Stack))
    {
        $traceQuery = $traceQuery + " , @stack_trace = '$($Stack)'"
    }

    ExecuteSqlQueryWithRetry -ServerInstance $global:clServer -DatabaseName $global:clDatabase -InstanceCredentials $cred -Query $traceQuery -RetryDelayInSeconds 10 -NumberOfRetries 5
}

function WaitForBackupToFinish
{
    <#
        .SYNOPSIS
        Checks if backup is ongoing and waits until it completes

        .DESCRIPTION
        Implementation of logic that queries (TSQL) the database, checks if any backup is ongoing and waits until it completes.
        It reuses the ExecuteSqlQueryWithRetry so it has retry embedded.

        .EXAMPLE
        WaitForBackupToFinish -ServerInstance "clperf.database.windows.net" -DatabaseName "clperftesting" -InstanceCredentials $cred -Query $traceQuery -RetryDelayInSeconds 10 -NumberOfRetries 5
    #>
Param(
    [Parameter(Mandatory=$True, HelpMessage="CorrelationId which is used to identify traces in the same task iteration")]
    [String]
    $CorrelationId,

    [Parameter(Mandatory=$True, HelpMessage="Server name")]
    [String]
    $ServerInstance,

    [Parameter(Mandatory=$True, HelpMessage="Database name")]
    [String]
    $DatabaseName,

    [Parameter(Mandatory=$True, HelpMessage="Instance credentials")]
    [System.Management.Automation.PSCredential]
    $InstanceCredentials,

    [Parameter( HelpMessage="Number of retries")]
    [int]
    $NumberOfRetries = 5,

    [Parameter(HelpMessage="Delay in seconds between retries")]
    [int]
    $RetryDelayInSeconds = 10
)
    $waitForBackupQuery = "
SELECT 1 FROM sys.dm_exec_requests
WHERE command = 'BACKUP DATABASE'
"

    TraceToClPerfDb `
        -Level "Info" `
        -CorrelationId $CorrelationId `
        -EventName "sleep" `
        -ServerName $ServerInstance `
        -DatabaseName $DatabaseName `
        -EventMessage "Waiting for backup to start - sleeping 35 minutes."

    # After restore is finished sleep for 30 + 5 = 35 minutes so we avoid full backup
    Start-Sleep -Seconds (30 * 60)

    TraceToClPerfDb `
        -Level "Info" `
        -CorrelationId $CorrelationId `
        -EventName "backup_check_started" `
        -ServerName $ServerInstance `
        -DatabaseName $DatabaseName

    do
    {
        Start-Sleep -Seconds (5 * 60)
        $result = ExecuteSqlQueryWithRetry -ServerInstance $ServerInstance -DatabaseName $DatabaseName -InstanceCredentials $InstanceCredentials -Query $waitForBackupQuery -RetryDelayInSeconds 15 -NumberOfRetries 20
    }
    while ($result)

    TraceToClPerfDb `
        -Level "Info" `
        -CorrelationId $CorrelationId `
        -EventName "backup_check_complete" `
        -ServerName $ServerInstance `
        -DatabaseName $DatabaseName
}

function UpdateInstanceState
{
    <#
        .SYNOPSIS
        Updates state of instance

        .DESCRIPTION
        Update instance state based on benchmark

        .EXAMPLE
        UpdateInstanceState -StateServerName "clperf.database.windows.net" -StateDbName "clperftesting" -StateDbCredentials $cred -InstanceName "clperftesting-gen5-bc8-weu-01.weu14c689be44714.database.windows.net" -State Ready
    #>
Param(
    [Parameter(Mandatory=$True, HelpMessage="Name of instance whose state we are updating")]
    [String]
    $InstanceName,

    [Parameter(Mandatory=$True, HelpMessage="New state")]
    [String]
    $State,

    [Parameter(Mandatory=$False, HelpMessage="Name of the server where we store instance states")]
    [String]
    $StateServerName = $null,

    [Parameter(Mandatory=$False, HelpMessage="Name of the database where we store instance states")]
    [String]
    $StateDbName = $null,

    [Parameter(Mandatory=$False, HelpMessage="Credentials of the database where we store instance states")]
    [System.Management.Automation.PSCredential]
    $StateDbCredentials = $null
)
    $upsertQuery = "
EXEC [upsert_instance]
    @instance_name = '$($InstanceName)',
    @state = '$($State)'
"

    $StateServerName = if ($StateServerName) { $StateServerName } else { $global:clServer }
    $StateDbName = if ($StateDbName) { $StateDbName } else { $global:clDatabase }
    $StateDbCredentials = if ($StateDbCredentials) { $StateDbCredentials } else { $global:clCred }

    $result = ExecuteSqlQueryWithRetry `
      -ServerInstance $StateServerName `
      -DatabaseName $StateDbName `
      -InstanceCredentials $StateDbCredentials `
      -Query $upsertQuery `
      -RetryDelayInSeconds 10 `
      -NumberOfRetries 5 `
      -ErrAction Stop
}

function PingDiagnostics
{
    <#
        .SYNOPSIS
        Body of the ping job

        .DESCRIPTION
        Body of the ping job

        .EXAMPLE
        PingJobBody `
            -CorrelationId $CorrelationId -run_id $run_id `
            -BenchmarkRuntimeInMinutes $BenchmarkRuntimeInMinutes -BenchmarkWarmupInMinutes $BenchmarkWarmupInMinutes `
            -ServerName $ServerName -DatabaseName $DatabaseName -InstanceCredentials $InstanceCredentials `
            -LoggingServerName $LoggingServerName -LoggingDatabaseName $LoggingDatabaseName -LoggingCredentials $LoggingCredentials `
            -PingJobPingPeriodInSeconds $PingJobPingPeriodInSeconds
    #>

    Param(
        [Parameter(Mandatory=$True, HelpMessage="Id used to correlate traces between varius scripts")]
        [String]
        $CorrelationId,

        [Parameter(Mandatory=$True, HelpMessage="Id of the benchmark run")]
        [Int]
        $run_id,

        [Parameter(Mandatory=$True, HelpMessage="How long should benchmark run")]
        [Int]
        $BenchmarkRuntimeInMinutes,

        [Parameter(Mandatory=$True, HelpMessage="How long should benchmark warm up")]
        [Int]
        $BenchmarkWarmupInMinutes,

        [Parameter(Mandatory=$True, HelpMessage="Name of instance under test")]
        [String]
        $ServerName,

        [Parameter(Mandatory=$True, HelpMessage="Name of database under test")]
        [String]
        $DatabaseName,

        [Parameter(Mandatory=$True, HelpMessage="Instance credentials")]
        [System.Management.Automation.PSCredential]
        $InstanceCredentials,

        [Parameter(Mandatory=$True, HelpMessage="Logging server name")]
        [String]
        $LoggingServerName,

        [Parameter(Mandatory=$True, HelpMessage="Logging database name")]
        [String]
        $LoggingDatabaseName,

        [Parameter(Mandatory=$True, HelpMessage="Logging database credentials")]
        [System.Management.Automation.PSCredential]
        $LoggingCredentials,

        [Parameter(Mandatory=$True, HelpMessage="Ping Job Ping Period In Seconds")]
        [Int]
        $PingJobPingPeriodInSeconds
    )

    $queryValue = 42

    $stopWatch = New-Object System.Diagnostics.Stopwatch
    $pingCnt = 0
    $pingCntGoal = ($BenchmarkRuntimeInMinutes + $BenchmarkWarmupInMinutes) * 60 / $PingJobPingPeriodInSeconds

    $successfullPingTotalTime = 0
    $successfullPingCnt = 0

    TraceToClPerfDb -Level "Info" `
        -CorrelationId $CorrelationId `
        -EventName "starting_ping_thread" `
        -ServerName $ServerName `
        -DatabaseName $DatabaseName

    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = "Server=$ServerName;Database=$DatabaseName;User ID=clperf;Password={0};Trusted_Connection=False;" -f $InstanceCredentials.GetNetworkCredential().Password
    $SqlConnection.Open()

    while ($pingCnt -lt $pingCntGoal) {

        if ($SqlConnection.state -ne "Open") {
            $SqlConnection.Close()
            $SqlConnection.Open()
        }

        $startTimeStamp = $(Get-Date).toUniversalTime()
        $timeStampString = $($startTimeStamp.ToString('yyyy-MM-dd HH:mm:ss.fff'))

        $execute_query = New-Object System.Data.SqlClient.SqlCommand
        $execute_query.connection = $SqlConnection
        $execute_query.CommandText = "select $queryValue"

        try {
            $stopWatch.Reset()
            $stopWatch.Start()

            $retVal = -1
            $retVal = $execute_query.executescalar()

            $stopWatch.Stop()

            $elapsedMs = $stopWatch.Elapsed.TotalMilliseconds

            if ($retVal -ne $queryValue) {
                $elapsedMs = -1

                TraceToClPerfDb -Level "Error" `
                    -CorrelationId $CorrelationId `
                    -EventName "ping_failed_due_to_wrong_retVal" `
                    -ServerName $ServerName `
                    -DatabaseName $DatabaseName `
                    -EventMessage "Ping return value not as expected ($queryValue), but instead: $retVal"
            } else {
                $successfullPingTotalTime = $successfullPingTotalTime + $elapsedMs
                $successfullPingCnt = $successfullPingCnt + 1
            }

        } catch {
            $elapsedMs = -1

            TraceToClPerfDb -Level "Error" `
                -CorrelationId $CorrelationId `
                -EventName "ping_failed_due_to_exception" `
                -ServerName $ServerName `
                -DatabaseName $DatabaseName `
                -EventMessage "$($PSItem.ToString())" `
                -Stack "$($PSItem.ScriptStackTrace)"
        }

        $insertPingLogQuery = `
                "INSERT INTO benchmark_step_reports
                (
                    [run_id],
                    [timestamp],
                    [metric_name],
                    [metric_value]
                )
                VALUES
                (
                    $run_id,
                    '$($timeStampString)',
                    'pingTimeInMs',
                    $elapsedMs
                )"
        Invoke-Sqlcmd -ServerInstance $LoggingServerName -Database $LoggingDatabaseName -Credential $LoggingCredentials -Query $insertPingLogQuery

        Start-Sleep ($PingJobPingPeriodInSeconds)

        $pingCnt = $pingCnt + 1
    }

    $successfullPingAvgTime = -1
    if ($successfullPingCnt -ne 0) {
        $successfullPingAvgTime = $successfullPingTotalTime / $successfullPingCnt
    }

    $insertAvgSuccPingLogQuery = `
                "INSERT INTO benchmark_results
                (
                    [run_id],
                    [metric_name],
                    [metric_value]
                )
                VALUES
                (
                    $run_id,
                    'Avg Success Ping Time (ms)',
                    $successfullPingAvgTime
                )"
    Invoke-Sqlcmd -ServerInstance $LoggingServerName -Database $LoggingDatabaseName -Credential $LoggingCredentials -Query $insertAvgSuccPingLogQuery

    $SqlConnection.Close()

    TraceToClPerfDb -Level "Info" `
                -CorrelationId $CorrelationId `
                -EventName "ending_ping_thread" `
                -ServerName $ServerName `
                -DatabaseName $DatabaseName
}

function DownloadFileFromBlob
{
    <#
.SYNOPSIS
Downloads file from azure blob

.DESCRIPTION
Downloads file from azure blob

.EXAMPLE
DownloadFileFromBlob -CorrelationId $correlationid -DestinationFolder $dest -StorageAccountKey $accountKey -ContainerName $containerName -FileName $fileName -StorageAccountName $storageAccountName
#>
    Param(
        [Parameter(Mandatory=$True, HelpMessage="Correlation id")]
        [string]
        $CorrelationId,

        [Parameter(Mandatory=$True, HelpMessage="Destination where to download file from blob")]
        [string]
        $DestinationFolder,

        [Parameter(Mandatory=$True, HelpMessage="Storage account key")]
        [String]
        $StorageAccountKey,

        [Parameter(Mandatory=$True, HelpMessage="Container name")]
        [String]
        $ContainerName,

        [Parameter(Mandatory=$True, HelpMessage="File name")]
        [String]
        $FileName,

        [Parameter(Mandatory=$False, HelpMessage="Storage account from which we want to download")]
        [String]
        $StorageAccountName = "benchmarkbackupstorage"
    );

    TraceToClPerfDb -Level "Info" `
      -CorrelationId $CorrelationId `
      -EventName "start_download_file" `
      -EventMessage "Downloading file $($FileName) from container $($ContainerName) to folder $($DestinationFolder)."

    $context = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey -Environment Prod 
    Get-AzureStorageBlobContent -Container $ContainerName -Context $context -Blob $FileName -Force -WarningAction SilentlyContinue -Destination $DestinationFolder

    TraceToClPerfDb -Level "Info" `
    -CorrelationId $CorrelationId `
    -EventName "end_download_file"
}

function DropAllDatabases
{
    <#
.SYNOPSIS
Drops all databases from instance

.DESCRIPTION
Drops all databases from instance

.EXAMPLE
DropAllDatabases -ServerName $serverName -Credentials $cred
#>
    Param(
        [Parameter(Mandatory=$True, HelpMessage="Server name")]
        [string]
        $ServerName,

        [Parameter(Mandatory=$True, HelpMessage="Instance credentials")]
        [System.Management.Automation.PSCredential]
        $Credentials
    );

    $dropDatabases = "
DECLARE @db_name NVARCHAR(MAX)

DECLARE dbs CURSOR FORWARD_ONLY READ_ONLY LOCAL
FOR
SELECT name
FROM sys.databases
WHERE DB_NAME(database_id) NOT IN ('master', 'tempdb', 'model', 'msdb')

OPEN dbs

FETCH NEXT
FROM dbs
INTO @db_name

DECLARE @queryToExecute NVARCHAR(MAX) = NULL
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @queryToExecute = CONCAT('DROP DATABASE [', @db_name, ']')
    SELECT @queryToExecute

    EXEC sp_executesql
        @statement = @queryToExecute

    FETCH NEXT
    FROM dbs
    INTO @db_name
END

CLOSE dbs
DEALLOCATE dbs
"

    Invoke-Sqlcmd -ServerInstance $ServerName -Database "master" -Query $dropDatabases -Credential $InstanceCredentials -QueryTimeout 0 -ConnectionTimeout 0 -ErrorAction Stop

    # Wait for instance storage size refresh
    Start-Sleep -Seconds (60)
}

function ReportResultsToDatabase
{
    Param(
        [Parameter(Mandatory=$True, HelpMessage="Server name")]
        [string]
        $RunId,

        [Parameter(Mandatory=$True, HelpMessage="Metric name to report")]
        [string]
        $MetricName,

        [Parameter(Mandatory=$True, HelpMessage="Metric value to report ")]
        [double]
        $MetricValue
    )

    $ReportingQuery = "
INSERT INTO benchmark_results
(
    [run_id],
    [metric_name],
    [metric_value]
)
VALUES
(
    $RunId,
    '$MetricName',
    $MetricValue
)
"

    $cred = GetClPerfDbCred
    ExecuteSqlQueryWithRetry -ServerInstance $global:clServer -DatabaseName $global:clDatabase -InstanceCredentials $cred -Query $ReportingQuery -RetryDelayInSeconds 10 -NumberOfRetries 5
}

function SetupNeeded
{
    <#
        .SYNOPSIS
        checking is setup needed for this run 

        .DESCRIPTION
        Some benchmark actions require additional instance setup before benchmark run. Querying DB to check is setup needed for this run (now supported for SetPropertyOverride action type)

        .EXAMPLE
        SetupNeeded -ScheduledBenchmarkId $ScheduledBenchmarkId
    #>

    Param (
        [Parameter(Mandatory=$True, HelpMessage="Id of scheduled benchmark")]
        [Int]
        $ScheduledBenchmarkId,

        [Parameter(Mandatory=$False, HelpMessage="Name of the server where we store actions and runs")]
        [String]
        $StateServerName = $null,

        [Parameter(Mandatory=$False, HelpMessage="Name of the database where we store actions and runs")]
        [String]
        $StateDbName = $null,

        [Parameter(Mandatory=$False, HelpMessage="Credentials of the database where we store actions and runs")]
        [System.Management.Automation.PSCredential]
        $StateDbCredentials = $null
    )

    TraceToClPerfDb -Level "Info" -CorrelationId $CorrelationId -EventName "setup_needed_check" -EventMessage "Checking is setup needed"

    $queryCountActionsForSetup = "select count(*) as cnt
            from dbo.scheduled_benchmarks sb
            inner join dbo.scheduled_benchmark_actions ba
            on ba.scheduled_benchmark_id = sb.id
            where ba.scheduled_benchmark_id = $ScheduledBenchmarkId
            and action_type in ('SetPropertyOverride', 'SetConfigOverride')"

    $StateServerName = if ($StateServerName) { $StateServerName } else { $global:clServer }
    $StateDbName = if ($StateDbName) { $StateDbName } else { $global:clDatabase }
    $StateDbCredentials = if ($StateDbCredentials) { $StateDbCredentials } else { $global:clCred }

    $queryResult = ExecuteSqlQueryWithRetry `
            -ServerInstance $StateServerName `
            -DatabaseName $StateDbName `
            -InstanceCredentials $StateDbCredentials `
            -Query $queryCountActionsForSetup `
            -RetryDelayInSeconds 10 `
            -NumberOfRetries 5 `
            -ErrAction Stop

    $actions = $queryResult.cnt

    TraceToClPerfDb -Level "Info" -CorrelationId $CorrelationId -EventName "setup_needed_check" -EventMessage "Found $actions actions for setup"

    if ($actions -ne 0)
    {
        return $true
    }
    else
    {
        TraceToClPerfDb -Level "Info" -CorrelationId $CorrelationId -EventName "setup_needed_check" -EventMessage "No need for setup"
        return $false
    }
}

function WaitForInstanceState
{
    <#
        .SYNOPSIS
        checking instance state until required state is achieved

        .DESCRIPTION
        Querying DB to check instance state until required state is achieved. It is done every (interval time) minutes (interval counter) times 

        .EXAMPLE
        WaitForInstanceState -ServerName $ServerName -RequiredState "SetupDone" -IntervalTime  -IntervalCounter 10
    #>

    Param (
        [Parameter(Mandatory=$True, HelpMessage="Server that is waiting for state")]
        [string]
        $ServerName,

        [Parameter(Mandatory=$True, HelpMessage="Required state for given server")]
        [ValidateSet("SetupDone")]
        $RequiredState,

        [Parameter(Mandatory=$False, HelpMessage="Querying interval time for instance state (in minutes)")]
        [Int]
        $IntervalTime = 5,

        #maybe we should stop trying after this time 	
        [Parameter(Mandatory=$False, HelpMessage="Interval counter")]
        [Int]
        $IntervalCounter = 20,

        [Parameter(Mandatory=$False, HelpMessage="Name of the server where we store instance states")]
        [String]
        $StateServerName = $null,

        [Parameter(Mandatory=$False, HelpMessage="Name of the database where we store instance states")]
        [String]
        $StateDbName = $null,

        [Parameter(Mandatory=$False, HelpMessage="Credentials of the database where we store instance states")]
        [System.Management.Automation.PSCredential]
        $StateDbCredentials = $null
    )

    TraceToClPerfDb -Level "Info" -CorrelationId $CorrelationId -EventName "wait_for_state" -EventMessage "Waiting for instance state"

    $StateServerName = if ($StateServerName) { $StateServerName } else { $global:clServer }
    $StateDbName = if ($StateDbName) { $StateDbName } else { $global:clDatabase }
    $StateDbCredentials = if ($StateDbCredentials) { $StateDbCredentials } else { $global:clCred }

    $CurrentStateQuery = "select * 
    from instance_state
    where instance_name = '$ServerName'"

    while($IntervalCounter -ne 0)
    {
        $InstanceStateQueryResult = ExecuteSqlQueryWithRetry `
                -ServerInstance $StateServerName `
                -DatabaseName $StateDbName `
                -InstanceCredentials $StateDbCredentials `
                -Query $CurrentStateQuery `
                -RetryDelayInSeconds 10 `
                -NumberOfRetries 5 `
                -ErrAction Stop

        $CurrentState = $InstanceStateQueryResult.state

        TraceToClPerfDb -Level "Info" -CorrelationId $CorrelationId -EventName "wait_for_state" -EventMessage "$IntervalCounter Current instance state is $CurrentState"

        if($CurrentState -eq $RequiredState)
        {
            break
        }

        $IntervalCounter--

        Start-Sleep -Seconds (60*$IntervalTime)
    }

    if($IntervalCounter -eq 0)
    {
        TraceToClPerfDb -Level "Error" -CorrelationId $CorrelationId -EventName "wait_for_state" -EventMessage "SetupDone state is not acheived"
        throw "Server did not achieved required state"
    }
    
}