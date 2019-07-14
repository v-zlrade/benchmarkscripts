Param(

    [Parameter(Mandatory=$False, HelpMessage="ID of the scheduled benchmark template in BenchmarkResultsDb")]
    [Int]
    $ScheduledBenchmarkId,

    [Parameter(Mandatory=$True, HelpMessage="Name of benchmark to run")]
    [ValidateSet(
         "CDB",
         "TPCC",
         "DataLoading"
     )]
    [String]
    $Benchmark,

    [Parameter(Mandatory=$True, HelpMessage="Generation of hardware where we are running this")]
    [String]
    $HardwareGeneration,

    [Parameter(Mandatory=$True, HelpMessage="Name of instance under test")]
    [String]
    $ServerName,

    [Parameter(Mandatory=$True, HelpMessage="Name of database under test")]
    [String]
    $DatabaseName,

    [Parameter(Mandatory=$True, HelpMessage="Number of threads that are used for running benchmark - This parameter is overriden for CDB benchmark")]
    [Int]
    $ThreadNumber,

    [Parameter(Mandatory=$True, HelpMessage="Count of processor of instance under test")]
    [Int]
    $ProcessorCount,

    [Parameter(Mandatory=$True, HelpMessage="Number of parallel benchmarks to be run")]
    [Int]
    $ParallelBenchmarksCount,

    [Parameter(Mandatory=$False, HelpMessage="Number of warehouses for TPCC test")]
    [Int]
    $WarehouseNumber,

    [Parameter(Mandatory=$False, HelpMessage="Scale factor for CDB benchmark")]
    [Int]
    $ScaleFactor,

    [Parameter(Mandatory=$False, HelpMessage="Number of customers for TPCE benchmark")]
    [Int]
    $NumberOfCustomers,

    [Parameter(Mandatory=$False, HelpMessage="Directory where benchcraft is installed")]
    [String]
    $BCInstallDir = "C:\Benchcraft",

    [Parameter(Mandatory=$False, HelpMessage="Switch for bussiness critical instances")]
    [Switch]
    $IsBusinessCritical,

    [Parameter(Mandatory=$False, HelpMessage="How long should benchmark run")]
    [Int]
    $BenchmarkRuntimeInMinutes,

    [Parameter(Mandatory=$False, HelpMessage="How long should benchmark warm up")]
    [Int]
    $BenchmarkWarmupInMinutes,

    [Parameter(Mandatory=$False, HelpMessage="Environment that the benchmark is running on")]
    [String]
    $Environment,

    [Parameter(Mandatory=$False, HelpMessage="Additional info about this run")]
    [String]
    $Comment,

    [Parameter(Mandatory=$False, HelpMessage="Logging server name")]
    [String]
    $LoggingServerName = "clperf.database.windows.net",

    [Parameter(Mandatory=$False, HelpMessage="Logging database name")]
    [String]
    $LoggingDatabaseName = "clperftesting",

    [Parameter(Mandatory=$False, HelpMessage="Logging database credentials")]
    [System.Management.Automation.PSCredential]
    $LoggingCredentials,

    [Parameter(Mandatory=$False, HelpMessage="Instance credentials")]
    [System.Management.Automation.PSCredential]
    $InstanceCredentials,

    [Parameter(Mandatory=$False, HelpMessage="Used for TPCC/TPCE benchmark to indicate whether we are using scaled down database for benchmark run")]
    [Switch]
    $ScaledDown,

    [Parameter(Mandatory=$False, HelpMessage="Storage account name where we will store reports")]
    [String]
    $ReportStorageAccountName = "benchmarkbackupstorage",

    [Parameter(Mandatory=$False, HelpMessage="Storage account key")]
    [String]
    $ReportStorageAccountKey = $null,

    [Parameter(Mandatory=$False, HelpMessage="Id used to correlate traces between varius scripts")]
    [String]
    $CorrelationId = $null,

    [Parameter(Mandatory=$False, HelpMessage="Skip Ping Job Switch")]
    [Switch]
    $SkipPingJobSwitch,

    [Parameter(Mandatory=$False, HelpMessage="Ping Job Ping Period In Seconds")]
    [int]
    $PingJobPingPeriodInSeconds = 15
)

# Include common scripts
."$($PSScriptRoot)\\clPerfCommon.ps1"

SetClPerfDb -Cred $LoggingCredentials -Server $LoggingServerName -Database $LoggingDatabaseName

UpdateInstanceState `
  -InstanceName $ServerName `
  -State "RunningBenchmark"

$LoggingUserName = "clperf"

# Get credentials
if ($LoggingCredentials -eq $null)
{
    $LoggingCredentials = Get-Credential -Message "Logging database credentials" -UserName $LoggingUserName
}
if ($InstanceCredentials -eq $null)
{
    $LoggingCredentials = Get-Credential -Message "Instance credentials"
}

if ($CorrelationId -eq $null)
{
    $CorrelationId = [guid]::NewGuid()
}

TraceToClPerfDb -Level "Info" `
    -CorrelationId $CorrelationId `
    -EventName "starting_benchmark" `
    -ServerName $ServerName `
    -DatabaseName $DatabaseName

TraceToClPerfDb -Level "Info" `
    -CorrelationId $correlationId `
    -EventName "benchmark_info" `
    -EventMessage "Install dir: $BCInstallDir; ID present: $($PSBoundParameters.ContainsKey('ScheduledBenchmarkId')); ID: $ScheduledBenchmarkId"

# Kill leftover exes from previous runs
$driverEngineProcess = Get-Process "Benchcraft.DriverEngine" -ErrorAction SilentlyContinue
if ($driverEngineProcess) {
    $driverEngineProcess | Stop-Process -Force
}

$psAgentProcess = Get-Process "Benchcraft.PSAgent" -ErrorAction SilentlyContinue
if ($psAgentProcess) {
    $psAgentProcess | Stop-Process -Force
}

# Appending the name of the Server to the comment field for extra information
# Create folder to store output paths
$benchmarkStartTime = Get-Date
$reportPathFolderName = "$($Benchmark)$(Get-Date -Format "yyyyMMddHHmm")"
mkdir $reportPathFolderName
$workingDirectory = "$($PWD)\$($reportPathFolderName)\"
# Switch to working directory
cd $workingDirectory

$Comment = ($Comment + '; SUT ServerName: ' + $ServerName)

# Start benchmark
if ($PSBoundParameters.ContainsKey('ScheduledBenchmarkId') -and ($ScheduledBenchmarkId -gt 0))
{
    $StartBenchmarkQuery = "
    EXEC [start_scheduled_benchmark]
        @scheduled_benchmark_id = $ScheduledBenchmarkId,
        @instance_dns_name = '$ServerName',
        @comment = '$Comment',
        @correlation_id = '$CorrelationId'
    "
}
else
{
    $StartBenchmarkQuery = "
    EXEC [start_benchmark]
        @benchmark_name = '$($Benchmark)',
        @processor_count = $($ProcessorCount),
        @is_bussiness_critical = $(if ($IsBusinessCritical.IsPresent) { 1 } else { 0 }),
        @hardware_generation = $($HardwareGeneration),
        @parallel_exec_cnt = $($ParallelBenchmarksCount)
        @environment = '$($Environment)',
        @comment = '$($Comment)',
        @correlation_id = '$($CorrelationId)'
    "
}

# Get run id
$run_id = [int](Invoke-Sqlcmd -ServerInstance $LoggingServerName -Database $LoggingDatabaseName -Credential $LoggingCredentials -Query $StartBenchmarkQuery)["run_id"]

# We are currently not supporting parallel benchmarks for TPCC and CDB 
if ($Benchmark -in @('CDB', 'TPCC'))
{
    $ParallelBenchmarksCount = 1
}

if (-not ($SkipPingJobSwitch.IsPresent))
{
    For($i=0; $i -lt $ParallelBenchmarksCount; $i++)
    {
        $DatabaseToPing = $DatabaseName + "_$i"

        # Start a job which will ping the database in order to collect telemetry
        $pingJob = Start-Job -ArgumentList ($PSScriptRoot,
                                            $CorrelationId,
                                            $run_id,
                                            $BenchmarkRuntimeInMinutes,
                                            $BenchmarkWarmupInMinutes,
                                            $ServerName,
                                            $DatabaseToPing,
                                            $InstanceCredentials,
                                            $LoggingServerName,
                                            $LoggingDatabaseName,
                                            $LoggingCredentials,
                                            $PingJobPingPeriodInSeconds) `
                                            -ScriptBlock {
            $PSScriptRoot = $args[0]
            $CorrelationId = $args[1]
            $run_id = $args[2]
            $BenchmarkRuntimeInMinutes = $args[3]
            $BenchmarkWarmupInMinutes = $args[4]
            $ServerName = $args[5]
            $DatabaseName = $args[6]
            $InstanceCredentials = $args[7]
            $LoggingServerName = $args[8]
            $LoggingDatabaseName = $args[9]
            $LoggingCredentials = $args[10]
            $PingJobPingPeriodInSeconds = $args[11]

            # Include common scripts
            ."$($PSScriptRoot)\\clPerfCommon.ps1"
            SetClPerfDb -Cred $LoggingCredentials -Server $LoggingServerName -Database $LoggingDatabaseName

            PingDiagnostics -CorrelationId $CorrelationId `
                            -run_id $run_id `
                            -BenchmarkRuntimeInMinutes $BenchmarkRuntimeInMinutes `
                            -BenchmarkWarmupInMinutes $BenchmarkWarmupInMinutes `
                            -ServerName $ServerName `
                            -DatabaseName $DatabaseName `
                            -InstanceCredentials $InstanceCredentials `
                            -LoggingServerName $LoggingServerName `
                            -LoggingDatabaseName $LoggingDatabaseName `
                            -LoggingCredentials $LoggingCredentials `
                            -PingJobPingPeriodInSeconds $PingJobPingPeriodInSeconds   
        }
    }
}

if ($Benchmark -ne "DataLoading")
{
    # If it is GP instance we want to initiate slowly otherwise IOPS are going to make problems due to throttling limits
    $ConnectRate = if ($IsBusinessCritical.IsPresent) { $ProcessorCount * 10 } else { 50 }

    $generatingResult =
    & "$($PSScriptRoot)\\generateProfile.ps1" `
      -Benchmark $Benchmark `
      -ServerName $ServerName `
      -DatabaseName $DatabaseName `
      -InstanceCredentials $InstanceCredentials `
      -ThreadNumber $ThreadNumber `
      -ConnectRate $ConnectRate `
      -WarehouseNumber $WarehouseNumber `
      -OutputPath $workingDirectory `
      -ScaleFactor $ScaleFactor `
      -NumberOfCustomers $NumberOfCustomers `
      -ScaledDown:($ScaledDown.IsPresent)

    if ($generatingResult[1] -eq -1)
    {
        echo $generatingResult[0]
        return;
    }

    & "$($PSScriptRoot)\\startBenchcraft.ps1" `
      -BCInstallDir $BCInstallDir `
      -BCProfileFileName "$($workingDirectory)\$($Benchmark)-Profile.bp" `
      -PathToReports $workingDirectory `
      -WarmUpTimeInSeconds ($BenchmarkWarmupInMinutes*60) `
      -SteadyStateTimeInSecs ($BenchmarkRuntimeInMinutes*60)

    # We only care about Report1
    & "$($PSScriptRoot)\\parseReports.ps1" `
      -Benchmark $Benchmark `
      -ReportPath $workingDirectory `
      -LoggingServerName $LoggingServerName `
      -LoggingDatabaseName $LoggingDatabaseName `
      -LoggingCredentials $LoggingCredentials `
      -RunId $run_id

    # upload to storage account if account key is provided
    if ($ReportStorageAccountKey -ne $null)
    {
        & "$($PSScriptRoot)\\uploadReportsToStorage.ps1" `
          -RunId $run_id `
          -Benchmark $Benchmark `
          -ReportPath $workingDirectory `
          -BenchmarkStartTime $benchmarkStartTime `
          -StorageAccountName $ReportStorageAccountName `
          -StorageAccountKey $ReportStorageAccountKey `
          -ProcessorCount $ProcessorCount `
          -HardwareGeneration $HardwareGeneration `
          -Environment $Environment `
          -BusinessCritical:($IsBusinessCritical.IsPresent)
    }
}
else
{
    ."$($PSScriptRoot)\\bcpHelperFunctions.ps1"

    $workingDirectory = "$($PSScriptRoot)\\BCPData"
    if (!(Test-Path $workingDirectory))
    {
        New-Item -ItemType Directory -Force -Path $workingDirectory
    }

    DownloadFileFromBlob -CorrelationId $Correlationid -DestinationFolder $workingDirectory -StorageAccountKey $ReportStorageAccountKey -StorageAccountName $ReportStorageAccountName -ContainerName "bcptables" -FileName "$ScaleFactor.bcp"

    
    TraceToClPerfDb -Level "Info" `
      -CorrelationId $CorrelationId `
      -EventName "bcp_drop_databases"

    DropAllDatabases -ServerName $ServerName -Credentials $InstanceCredentials 

    TraceToClPerfDb -Level  "Info" `
        -CorrelationId $CorrelationId `
        -EventName "dropped databases with success $ParallelBenchmarksCount"

    For($i=0; $i -lt $ParallelBenchmarksCount; $i++)
    {
        $DatabaseToRunBenchmarkOn = $DatabaseName + "_$i"
        TraceToClPerfDb -Level  "Info" `
        -CorrelationId $CorrelationId `
        -EventName "$DatabaseToRunBenchmarkOn"

        InitializeDatabaseForBcp -CorrelationId $CorrelationId -ServerName $ServerName -DatabaseName $DatabaseToRunBenchmarkOn -InstanceCredentials $InstanceCredentials -WorkerNumber $ThreadNumber -ScaleFactor $ScaleFactor
    }
    $bcpFilePath = "$workingDirectory\\$ScaleFactor.bcp"
    $bcpTables = 1..$ThreadNumber | % { "bcpTest$_" }

    TraceToClPerfDb -Level "Info" `
      -CorrelationId $CorrelationId `
      -EventName "starting_bcp" `
      -ServerName $ServerName

    $stopWatch = New-Object System.Diagnostics.Stopwatch
    $stopWatch.Reset()
    $stopWatch.Start()

    $jobs = @()
    For($i=0; $i -lt $ParallelBenchmarksCount; $i++)
    {
        # When running parallel benchmarks, database names should be separated by '_'
        $DatabaseToPing = $DatabaseName + "_$i"

        $jobs += $bcpTables | % {
            Start-Job -ScriptBlock {
                ."$($args[7])\\clPerfCommon.ps1"
                ."$($args[7])\\bcpHelperFunctions.ps1"

                SetClPerfDb -Cred $args[8] -Server $args[9] -Database $args[10]

                Invoke-BcpIn `
                -CorrelationId $args[0] `
                -SourceFileName $args[1] `
                -TargetTableName $args[2] `
                -ServerName $args[3] `
                -DatabaseName $args[4] `
                -Username $args[5] `
                -Password $args[6] `
                -BatchSize 10000
            } -ArgumentList @($CorrelationId,
                            $bcpFilePath,
                            $_,
                            $ServerName,
                            $DatabaseToRunBenchmarkOn,
                            $InstanceCredentials.GetNetworkCredential().UserName,
                            $InstanceCredentials.GetNetworkCredential().Password,
                            $PSScriptRoot,
                            $LoggingCredentials,
                            $LoggingServerName,
                            $LoggingDatabaseName)
        }
    } 
    
    $jobs| % {
        Wait-Job $_
        Stop-Job $_
        Receive-Job $_
    }

    $stopWatch.Stop()
    $elapsedS = $stopWatch.Elapsed.TotalMilliseconds / 1000

    ReportResultsToDatabase -RunId $run_id -MetricName "bcp_elapsed_time" -MetricValue $elapsedS

    Start-Sleep -s 3600
}

# end benchmark
$EndBenchmarkQuery = "
EXEC [end_benchmark]
    @run_id = $($run_id)
"

TraceToClPerfDb -Level "Info" `
    -CorrelationId $CorrelationId `
    -EventName "end_benchmark" `
    -ServerName $ServerName `
    -DatabaseName $DatabaseName

Invoke-Sqlcmd -ServerInstance $LoggingServerName -Database $LoggingDatabaseName -Credential $LoggingCredentials -Query $EndBenchmarkQuery
