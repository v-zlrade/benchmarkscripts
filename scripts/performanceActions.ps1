Param(

    [Parameter(Mandatory=$True, ParameterSetName="ByID", HelpMessage="ID of the scheduled benchmark template in BenchmarkResultsDb")]
    [Int]
    $ScheduledBenchmarkId,

    [String]
    [Parameter(Mandatory=$True, ParameterSetName="ByBenchmarkSettings", HelpMessage="Generation of hardware where we are running this")]
    [String]
    $HardwareGeneration,

    [Parameter(Mandatory=$True, ParameterSetName="ByBenchmarkSettings", HelpMessage="Count of processor of instance under test")]
    [Int]
    $ProcessorCount,

    [Parameter(Mandatory=$True, ParameterSetName="ByBenchmarkSettings", HelpMessage="Number of parallel benchmarks to be run")]
    [Int]
    $ParallelBenchmarksCount,

    [Parameter(Mandatory=$True, ParameterSetName="ByBenchmarkSettings", HelpMessage="Environment that the benchmark is running on")]
    [String]
    $Environment,

    [Parameter(Mandatory=$True, HelpMessage="Action to execute")]
    [ValidateSet(
         "Restore",
         "RunBenchmark",
         "RunAllBenchmarks"
     )]
    $Action,

    [Parameter(Mandatory=$False, ParameterSetName="ByBenchmarkSettings", HelpMessage="Name of benchmark to run")]
    [ValidateSet(
         "CDB",
         "TPCC",
         "DataLoading"
    )]
    [String]
    $Benchmark,

    [Parameter(Mandatory=$False, ParameterSetName="ByBenchmarkSettings", HelpMessage="Switch for bussiness critical instances")]
    [Switch]
    $BusinessCritical,

    [Parameter(Mandatory=$False, HelpMessage="Directory where benchcraft is installed")]
    [String]
    $BCInstallDir = "C:\\Benchcraft\\",

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

    [Parameter(Mandatory=$False, HelpMessage="Storage account key")]
    [String]
    $StorageAccountKey = $null,

    [Parameter(Mandatory=$False, ParameterSetName="ByBenchmarkSettings", HelpMessage="SUT (System under test) server name")]
    [String]
    $ServerName = $null,

    [Parameter(Mandatory=$False, ParameterSetName="ByBenchmarkSettings", HelpMessage="SUT database name")]
    [String]
    $DatabaseName = $null,

    [Parameter(Mandatory=$False, ParameterSetName="ByBenchmarkSettings", HelpMessage="Thread number")]
    [Int]
    $ThreadNumber = $null,

    [Parameter(Mandatory=$False, ParameterSetName="ByBenchmarkSettings", HelpMessage="Scaling argument for benchmark")]
    [String]
    $BenchmarkScalingArgument = $null,

    [Parameter(Mandatory=$False, ParameterSetName="ByBenchmarkSettings", HelpMessage="Benchmark steady duration")]
    [Int]
    $BenchmarkRuntimeInMinutes = $null,

    [Parameter(Mandatory=$False, ParameterSetName="ByBenchmarkSettings", HelpMessage="Benchmark warmup duration")]
    [Int]
    $BenchmarkWarmupInMinutes = $null,

    [Parameter(Mandatory=$False, ParameterSetName="ByBenchmarkSettings", HelpMessage="Custom query to execute on master")]
    [String]
    $CustomMasterQuery = $null,

    [Parameter(Mandatory=$False, ParameterSetName="ByBenchmarkSettings", HelpMessage="Should restore")]
    [Switch]
    $SkipRestore = $null,

    [Parameter(Mandatory=$False, HelpMessage="Additional comment")]
    [String]
    $Comment = $null,

    [Parameter(Mandatory=$False, ParameterSetName="ByBenchmarkSettings", HelpMessage="is Scaled down")]
    [Switch]
    $ScaledDown,

    [Parameter(Mandatory=$False, ParameterSetName="ByBenchmarkSettings", HelpMessage="Correlation id for logging")]
    [String]
    $CorrelationId,

    [Parameter(Mandatory=$False, HelpMessage="Skip Ping Job Switch")]
    [Switch]
    $SkipPingJobSwitch,

    [Parameter(Mandatory=$False, HelpMessage="Ping Job Ping Period In Seconds")]
    [int]
    $PingJobPingPeriodInSeconds = 15
)

# Include common scripts
."$($PSScriptRoot)\\clPerfCommon.ps1"

function CalculateThreadNumber($benchmarkName, $processorCount, $hardwareGeneration, $businessCritical)
{
    $scalingThreadArg = 0

    if ($benchmarkName -eq 'CDB')
    {
        if ($hardwareGeneration -eq 'GEN4')
        {
            $scalingThreadArg = 140
        }
        elseif ($hardwareGeneration -eq 'GEN5')
        {
            $scalingThreadArg = 90
        }
    }
    elseif ($benchmarkName -eq 'TPCC')
    {
        if ($hardwareGeneration -eq 'GEN4')
        {
            $scalingThreadArg = 12.5
        }
        elseif ($hardwareGeneration -eq 'GEN5')
        {
            $scalingThreadArg = 12.5
        }
    }

    $threadCount = [int]($processorCount * $scalingThreadArg)

    # Capping the number of threads for CDB runs on GeneralPurpose instances due to remote storage throttling.
    if ($businessCritical -ne $true -and $benchmarkName -eq 'CDB' -and $threadCount -gt 1600)
    {
        $threadCount = 1600
    }

        TraceToClPerfDb `
            -Level "Info" `
            -CorrelationId $CorrelationId `
            -EventName "thread_count" `
            -EventMessage "$($threadCount)"

    return ($threadCount)
}

$resources=@{
    PRODBC8G4="clperftesting-gen4-bc8-wcus-01.wcus10d832431fca2.database.windows.net"
    PRODBC16G4="clperftesting-gen4-bc16-wcus-01.wcus10d832431fca2.database.windows.net"
    PRODBC24G4="clperftesting-gen4-bc24-wcus-01.wcus10d832431fca2.database.windows.net"
    PRODGP8G4="clperftestin02.wcus10d832431fca2.database.windows.net"
    PRODGP16G4="clperftesting01.wcus10d832431fca2.database.windows.net"
    PRODGP24G4="clperftesting03.wcus10d832431fca2.database.windows.net"
    PRODBC8G5="clperftesting-gen5-bc8-weu-01.weu14c689be44714.database.windows.net"
    PRODBC16G5="clperftesting-gen5-bc16-weu-01.weu14c689be44714.database.windows.net"
    PRODBC24G5="clperftesting-gen5-bc24-weu-01.weu14c689be44714.database.windows.net"
    PRODBC32G5="clperftesting-gen5-bc32-weu-01.weu14c689be44714.database.windows.net"
    PRODBC40G5="clperftesting-gen5-bc40-weu-01.weu14c689be44714.database.windows.net"
    PRODBC64G5="clperftesting-gen5-bc64-weu-01.weu14c689be44714.database.windows.net"
    PRODBC80G5="clperftesting-gen5-bc80-weu-01.weu14c689be44714.database.windows.net"
    PRODGP8G5="clperftesting-gen5-gp8-weu-01.weu14c689be44714.database.windows.net"
    PRODGP16G5="clperftesting-gen5-gp16-weu-01.weu14c689be44714.database.windows.net"
    PRODGP24G5="clperftesting-gen5-gp24-weu-01.weu14c689be44714.database.windows.net"
    PRODGP32G5="clperftesting-gen5-gp32-weu-01.weu14c689be44714.database.windows.net"
    PRODGP40G5="clperftesting-gen5-gp40-weu-01.weu14c689be44714.database.windows.net"
    PRODGP64G5="clperftesting-gen5-gp64-weu-01.weu14c689be44714.database.windows.net"
    PRODGP80G5="clperftesting-gen5-gp80-weu-01.weu14c689be44714.database.windows.net"
    STAGEGP8G4="clperftesting-gen4-gp8-sneu-01.neu1396d5828d931.sqltest-eg1.mscds.com"
    STAGEGP16G4="clperftesting-gen4-gp16-sneu-01.neu1396d5828d931.sqltest-eg1.mscds.com"
    STAGEGP24G4="clperftesting-gen4-gp24-sneu-01.neu1396d5828d931.sqltest-eg1.mscds.com"
    STAGEBC8G4="clperftesting-gen4-bc8-sneu-01.neu1396d5828d931.sqltest-eg1.mscds.com"
    STAGEBC16G4="clperftesting-gen4-bc16-sneu-01.neu1396d5828d931.sqltest-eg1.mscds.com"
    STAGEBC24G4="clperftesting-gen4-bc24-sneu-01.neu1396d5828d931.sqltest-eg1.mscds.com"
    LKGTGP8G4="clperftesting-gen4-gp8-lkgc-01.lkgt1144af9389d31.sqltest-eg1.mscds.com"
    LKGTGP16G4="clperftesting-gen4-gp16-lkgc-01.lkgt1144af9389d31.sqltest-eg1.mscds.com"
    LKGTGP24G4="clperftesting-gen4-gp24-lkgc-01.lkgt1144af9389d31.sqltest-eg1.mscds.com"
    LKGTBC8G4="clperftesting-gen4-bc8-lkgc-01.lkgt1144af9389d31.sqltest-eg1.mscds.com"
    LKGTBC16G4="clperftesting-gen4-bc16-lkgc-01.lkgt1144af9389d31.sqltest-eg1.mscds.com"
    LKGTBC24G4="clperftesting-gen4-bc24-lkgc-01.lkgt1144af9389d31.sqltest-eg1.mscds.com"
    SMALLVMSBC8G5="miradic.jaea1e5d400451cc3.gmplus3-jaea1-a.mscds.com"
    SMALLVMSBC24G5="mlpant.jaea1e5d400451cc3.gmplus3-jaea1-a.mscds.com"
    SMALLVMSBC32G5="vanjav.jaea1e5d400451cc3.gmplus3-jaea1-a.mscds.com"
    SMALLVMSBC40G5="miacim.jaea1e5d400451cc3.gmplus3-jaea1-a.mscds.com"
    SMALLVMSGP8G5="vlast.jaea1e5d400451cc3.gmplus3-jaea1-a.mscds.com"
    SMALLVMSGP24G5="rajako.jaea1e5d400451cc3.gmplus3-jaea1-a.mscds.com"
    SMALLVMSGP40G5="anatra.jaea1e5d400451cc3.gmplus3-jaea1-a.mscds.com"
    SMALLVMSGP32G5="masredic.jaea1e5d400451cc3.gmplus3-jaea1-a.mscds.com"
}

$benchmarkScalingArgumentMap=@{
    CDB8=15000
    CDB16=15000
    CDB24=30000
    CDB32=30000
    CDB40=30000
    CDB64=30000
    CDB80=40000
    TPCC8=4000
    TPCC16=4000
    TPCC24=4000
    TPCC32=4000
    TPCC40=4000
    TPCC64=4000
    TPCC80=8500
}

$benchmarkRuntime=@{
    CDB=60
    TPCC=120
}

if (-not ($CorrelationId))
{
    $CorrelationId = [guid]::NewGuid()
}

Write-Host "CorrelationId: $CorrelationId"

SetClPerfDb -Cred $LoggingCredentials -Server $LoggingServerName -Database $LoggingDatabaseName
TraceToClPerfDb -Level "Info" -CorrelationId $CorrelationId -EventName "start_performance_action"

try {
    # Do not compute configs if action is run all benchmarks - he knows what to do
    if ($Action -ne "RunAllBenchmarks")
    {
        if ($PsCmdlet.ParameterSetName -eq "ByID")
        {
            $getBenchmarkSettingsQuery = "SELECT * FROM scheduled_benchmarks_view WHERE id = $ScheduledBenchmarkId"
            $result = ExecuteSqlQueryWithRetry -ServerInstance $LoggingServerName -DatabaseName $LoggingDatabaseName -InstanceCredentials $LoggingCredentials -Query $getBenchmarkSettingsQuery

            $Benchmark = $result.benchmark_name
            $ProcessorCount = $result.processor_count
            $ParallelBenchmarksCount = $result.parallel_exec_cnt
            $HardwareGeneration = $result.hardware_generation
            $Environment = $result.environment
            $BusinessCritical = $result.is_bc
            $ServerName = $result.server_name
            $DatabaseName = $result.database_name
            $ThreadNumber = $result.worker_number
            $BenchmarkScalingArgument = $result.benchmark_scaling_argument
            $SkipRestore = -not $result.should_restore
            $BenchmarkRuntimeInMinutes = $result.run_timespan_minutes
            $BenchmarkWarmupInMinutes = $result.warmup_timespan_minutes
            $CustomMasterQuery = $result.custom_master_tsql_query
            $ScaledDown = $result.scaled_down
            $CorrelationId = $result.correlation_id

            # DEVNOTE: it's probably good idea to make sure that this value is always provided from db side
            if (-not ($CorrelationId))
            {
                $CorrelationId = [guid]::NewGuid()
            }
        }

        $SLO = "$(if ($BusinessCritical.IsPresent) { 'BC' } else { 'GP' })$($ProcessorCount)$(if ($HardwareGeneration -eq 'GEN4') { 'G4' } else { 'G5' })"
        $benchmarkScalingArgumentKey = "$($Benchmark)$($ProcessorCount)"
        $resourceKey = "$($Environment)$($SLO)"
        $Comment = if ($Comment) { $Comment } else { "Scheduled run from $($env:computername)" }
        $instanceName = if ($ServerName) { $ServerName } else { $resources[$resourceKey] }
        $databaseName = if ($DatabaseName) { $DatabaseName } else { "$($Benchmark.ToLower())$($scalingArgument)" }
        $scalingArgument = if ($BenchmarkScalingArgument) { $BenchmarkScalingArgument } else { $benchmarkScalingArgumentMap[$benchmarkScalingArgumentKey] }
        $BenchmarkRuntimeInMinutes = if ($BenchmarkRuntimeInMinutes) { $BenchmarkRuntimeInMinutes } else { $benchmarkRuntime[$Benchmark] }
        $BenchmarkWarmupInMinutes = if ($BenchmarkWarmupInMinutes) { $BenchmarkWarmupInMinutes } else { 15 }

        $ScaleFactor = -1
        $WarehouseNumber = -1
        
        if ($Benchmark -in @('CDB', 'DataLoading'))
        {
            $ScaleFactor = $scalingArgument
        }
        elseif ($Benchmark -eq 'TPCC')
        {
            $WarehouseNumber = $scalingArgument
        }
    }

    if ($Action -eq 'RunBenchmark')
    {
        TraceToClPerfDb -Level "Info" -CorrelationId $CorrelationId -EventName "start_action" -EventMessage 'RunBenchmark'

        $setup = SetupNeeded -ScheduledBenchmarkId $ScheduledBenchmarkId

        TraceToClPerfDb -Level "Info" -CorrelationId $CorrelationId -EventName "setup_needed_check" -EventMessage "Checked"

        if ($setup)
        {
            UpdateInstanceState -InstanceName $ServerName -State "Setup"
            TraceToClPerfDb -Level "Info" -CorrelationId $CorrelationId -EventName "wait_for_state" -EventMessage "Server is setting up"

            WaitForInstanceState -ServerName $ServerName -RequiredState "SetupDone"
            TraceToClPerfDb -Level "Info" -CorrelationId $CorrelationId -EventName "wait_for_state" -EventMessage "Setup is done, server is ready for benchmark run"
        }

        $ThreadNumber = if ($ThreadNumber) { $ThreadNumber } else { (CalculateThreadNumber -benchmarkName $Benchmark -processorCount $ProcessorCount -hardwareGeneration $HardwareGeneration -businessCritical $BusinessCritical.IsPresent) }

        if ($Benchmark -eq "DataLoading")
        {
             TraceToClPerfDb -Level "Info" -CorrelationId $CorrelationId -EventName "skip_restore_database" -EventMessage 'Automatically skipping restore for DataLoading benchmark'
        }

        # we do not run restores for bcpIn benchmarks
        if (-not ($SkipRestore.IsPresent) -and $Benchmark -ne "DataLoading")
        {
            TraceToClPerfDb -Level "Info" `
                -CorrelationId $CorrelationId `
                -EventName "start_restore_database" `
                -ServerName $instanceName `
                -DatabaseName $databaseName

            # First restore and then wait for backup to finish
            & "$($PSScriptRoot)\\restoreDatabase.ps1" -Benchmark $Benchmark `
              -BusinessCritical:($BusinessCritical.IsPresent) `
              -ServerName $instanceName `
              -DatabaseName $databaseName `
              -ScaleFactor $ScaleFactor `
              -WarehouseNumber $WarehouseNumber `
              -StorageAccountKey $StorageAccountKey `
              -InstanceCredentials $InstanceCredentials `
              -ScaledDown:($ScaledDown.IsPresent)

            TraceToClPerfDb -Level "Info" `
              -CorrelationId $CorrelationId `
              -EventName "end_restore_database" `
              -ServerName $instanceName `
              -DatabaseName $databaseName

            WaitForBackupToFinish `
              -CorrelationId $CorrelationId `
              -ServerInstance $instanceName `
              -DatabaseName $databaseName `
              -InstanceCredentials $InstanceCredentials
        }

        if ($CustomMasterQuery)
        {
            TraceToClPerfDb -Level "Info" `
              -CorrelationId $CorrelationId `
              -EventName "execute_query_on_master" `
              -EventMessage $CustomMasterQuery `
              -ServerName $ServerName `
              -DatabaseName $DatabaseName

            ExecuteSqlQueryWithRetry `
              -ServerInstance $ServerName `
              -DatabaseName "master" `
              -InstanceCredentials $InstanceCredentials `
              -Query $CustomMasterQuery `
              -ErrAction "Stop"
        }

        TraceToClPerfDb -Level "Info" `
            -CorrelationId $CorrelationId `
            -EventName "start_job" `
            -EventMessage "ID: $ScheduledBenchmarkId; Skip ping job: $SkipPingJobSwitch; Ping job period: $PingJobPingPeriodInSeconds" `
            -ServerName $instanceName `
            -DatabaseName $databaseName

        # Start executions as job because it is known to get infinitely stuck in some edge cases
        $job = Start-Job -ScriptBlock {
            & "$($args[0])\\executeBenchmark.ps1" `
              -ScheduledBenchmarkId $args[1] `
              -Benchmark $args[2] `
              -ServerName $args[3] `
              -DatabaseName $args[4] `
              -HardwareGeneration $args[5] `
              -ThreadNumber $args[6] `
              -ProcessorCount $args[7] `
              -ParallelBenchmarksCount $args[8] `
              -ScaleFactor $args[9] `
              -WarehouseNumber $args[10] `
              -BCInstallDir $args[11] `
              -BenchmarkRuntimeInMinutes $args[12] `
              -BenchmarkWarmupInMinutes $args[13] `
              -IsBusinessCritical:$args[14] `
              -Comment $args[15] `
              -LoggingServerName $args[16] `
              -LoggingDatabaseName $args[17] `
              -LoggingCredentials $args[18] `
              -InstanceCredentials $args[19] `
              -ReportStorageAccountKey $args[20] `
              -Environment $args[21] `
              -CorrelationId $args[22] `
              -SkipPingJobSwitch:$args[23] `
              -PingJobPingPeriodInSeconds $args[24] `
              -ScaledDown:$args[25]
        } -ArgumentList @($PSScriptRoot,
                          $ScheduledBenchmarkId,
                          $Benchmark,
                          $instanceName,
                          $databaseName,
                          $HardwareGeneration,
                          $ThreadNumber,
                          $ProcessorCount,
                          $ParallelBenchmarksCount,
                          $ScaleFactor,
                          $WarehouseNumber,
                          $BCInstallDir,
                          $BenchmarkRuntimeInMinutes,
                          $BenchmarkWarmupInMinutes,
                          ($BusinessCritical.IsPresent),
                          $Comment,
                          $LoggingServerName,
                          $LoggingDatabaseName,
                          $LoggingCredentials,
                          $InstanceCredentials,
                          $StorageAccountKey,
                          $Environment,
                          $CorrelationId,
                          ($SkipPingJobSwitch.IsPresent),
                          $PingJobPingPeriodInSeconds,
                          ($ScaledDown.IsPresent))

        Wait-Job $job -Timeout (($BenchmarkRuntimeInMinutes + $BenchmarkWarmupInMinutes + 15) * 60)
        Stop-Job $job
        $jobOutput = Receive-Job $job

        TraceToClPerfDb -Level "Info" `
          -CorrelationId $CorrelationId `
          -EventName "end_job" `
          -EventMessage "$($jobOutput)" `
          -ServerName $instanceName `
          -DatabaseName $databaseName
    }
    if ($Action -eq 'Restore')
    {
        TraceToClPerfDb -Level "Info" `
            -CorrelationId $CorrelationId `
            -EventName "start_action" `
            -EventMessage 'Restore'

        TraceToClPerfDb -Level "Info" `
            -CorrelationId $CorrelationId `
            -EventName "start_restore_database" `
            -ServerName $instanceName `
            -DatabaseName $databaseName

        & "$($PSScriptRoot)\\restoreDatabase.ps1" -Benchmark $Benchmark `
          -BusinessCritical:($BusinessCritical.IsPresent) `
          -ServerName $instanceName `
          -DatabaseName $databaseName `
          -ScaleFactor $ScaleFactor `
          -WarehouseNumber $WarehouseNumber `
          -StorageAccountKey $StorageAccountKey `
          -InstanceCredentials $InstanceCredentials `
          -ScaledDown:($ScaledDown.IsPresent)

        TraceToClPerfDb -Level "Info" `
          -CorrelationId $CorrelationId `
          -EventName "end_restore_database" `
          -ServerName $instanceName `
          -DatabaseName $databaseName
    }
    if ($Action -eq 'RunAllBenchmarks')
    {
        TraceToClPerfDb -Level "Info" -CorrelationId $CorrelationId -EventName "start_action" -EventMessage 'RunAllBenchmarks'

        # Compute variables for all benchmarks
        $ScaleFactor = $benchmarkScalingArgumentMap["CDB$($ProcessorCount)"]
        $WarehouseNumber = $benchmarkScalingArgumentMap["TPCC$($ProcessorCount)"]
        $cdbDatabaseName = "cdb$($ScaleFactor)"
        $tpccDatabaseName = "tpcc$($WarehouseNumber)"
        $cdbThreadNumber = CalculateThreadNumber -benchmarkName CDB -processorCount $ProcessorCount -hardwareGeneration $HardwareGeneration -businessCritical $BusinessCritical.IsPresent
        $tpccThreadNumber = CalculateThreadNumber -benchmarkName TPCC -processorCount $ProcessorCount -hardwareGeneration $HardwareGeneration -businessCritical $BusinessCritical.IsPresent

        TraceToClPerfDb -Level "Info" `
            -CorrelationId $CorrelationId `
            -EventName "start_restore_database" `
            -ServerName $instanceName `
            -DatabaseName $cdbDatabaseName

        # First restore and then execute CDB
        & "$($PSScriptRoot)\\restoreDatabase.ps1" `
          -Benchmark CDB `
          -BusinessCritical:($BusinessCritical.IsPresent) `
          -ServerName $instanceName `
          -DatabaseName $cdbDatabaseName `
          -ScaleFactor $ScaleFactor `
          -WarehouseNumber $WarehouseNumber `
          -StorageAccountKey $StorageAccountKey `
          -InstanceCredentials $InstanceCredentials

        TraceToClPerfDb -Level "Info" `
          -CorrelationId $CorrelationId `
          -EventName "end_restore_database" `
          -ServerName $instanceName `
          -DatabaseName $cdbDatabaseName

        WaitForBackupToFinish `
          -CorrelationId $CorrelationId `
          -ServerInstance $instanceName `
          -DatabaseName $cdbDatabaseName `
          -InstanceCredentials $InstanceCredentials

        TraceToClPerfDb -Level "Info" `
            -CorrelationId $CorrelationId `
            -EventName "start_job" `
            -ServerName $instanceName `
            -DatabaseName $cdbDatabaseName

        TraceToClPerfDb `
            -Level "Info" `
            -CorrelationId $CorrelationId `
            -EventName "run_info" `
            -EventMessage $BCInstallDir

        # Start executions as job because it is known to get infinitely stuck in some edge cases
        $cdbJob = Start-Job -ScriptBlock {
            & "$($args[0])\\executeBenchmark.ps1" -Benchmark CDB `
              -ServerName $args[1] `
              -DatabaseName $args[2] `
              -HardwareGeneration $args[3] `
              -ThreadNumber $args[4] `
              -ProcessorCount $args[5] `
              -ParallelBenchmarksCount $args[6] `
              -ScaleFactor $args[7] `
              -BCInstallDir $args[8] `
              -BenchmarkRuntimeInMinutes $args[9] `
              -IsBusinessCritical:$args[10] `
              -BenchmarkWarmupInMinutes 15 `
              -Comment $args[11] `
              -LoggingServerName $args[12] `
              -LoggingDatabaseName $args[13] `
              -LoggingCredentials $args[14] `
              -InstanceCredentials $args[15] `
              -ReportStorageAccountKey $args[16] `
              -Environment $args[17] `
              -CorrelationId $args[18] `
              -SkipPingJobSwitch:$args[19] `
              -PingJobPingPeriodInSeconds $args[20] `
              -ScaledDown:$args[21]
        } -ArgumentList @($PSScriptRoot,
                          $instanceName,
                          $cdbDatabaseName,
                          $HardwareGeneration,
                          $cdbThreadNumber,
                          $ProcessorCount,
                          $ParallelBenchmarksCount,
                          $ScaleFactor,
                          $BCInstallDir,
                          $benchmarkRuntime['CDB'],
                          ($BusinessCritical.IsPresent),
                          "Scheduled run from $($env:computername)",
                          $LoggingServerName,
                          $LoggingDatabaseName,
                          $LoggingCredentials,
                          $InstanceCredentials,
                          $StorageAccountKey,
                          $Environment,
                          $CorrelationId,
                          ($SkipPingJobSwitch.IsPresent),
                          $PingJobPingPeriodInSeconds,
                          ($ScaledDown.IsPresent))

        Wait-Job $cdbJob -Timeout (($benchmarkRuntime['CDB'] + 30) * 60)
        Stop-Job $cdbJob
        Receive-Job $cdbJob

        TraceToClPerfDb -Level "Info" `
            -CorrelationId $CorrelationId `
            -EventName "end_job" `
            -ServerName $instanceName `
            -DatabaseName $cdbDatabaseName

        TraceToClPerfDb -Level "Info" `
            -CorrelationId $CorrelationId `
            -EventName "start_restore_database" `
            -ServerName $instanceName `
            -DatabaseName $tpccDatabaseName

        # Execute TPCC
        & "$($PSScriptRoot)\\restoreDatabase.ps1" `
          -Benchmark TPCC `
          -BusinessCritical:($BusinessCritical.IsPresent) `
          -ServerName $instanceName `
          -DatabaseName $tpccDatabaseName `
          -ScaleFactor $ScaleFactor `
          -WarehouseNumber $WarehouseNumber `
          -StorageAccountKey $StorageAccountKey `
          -InstanceCredentials $InstanceCredentials `
          -ScaledDown:($ScaledDown.IsPresent)

        TraceToClPerfDb -Level "Info" `
          -CorrelationId $CorrelationId `
          -EventName "end_restore_database" `
          -ServerName $instanceName `
          -DatabaseName $tpccDatabaseName

        WaitForBackupToFinish `
          -CorrelationId $CorrelationId `
          -ServerInstance $instanceName `
          -DatabaseName $tpccDatabaseName `
          -InstanceCredentials $InstanceCredentials

        TraceToClPerfDb -Level "Info" `
            -CorrelationId $CorrelationId `
            -EventName "start_job" `
            -ServerName $instanceName `
            -DatabaseName $tpccDatabaseName

        $tpccJob = Start-Job -ScriptBlock {
            & "$($args[0])\\executeBenchmark.ps1" -Benchmark TPCC `
              -ServerName $args[1] `
              -DatabaseName $args[2] `
              -HardwareGeneration $args[3] `
              -ThreadNumber $args[4] `
              -ProcessorCount $args[5] `
              -ParallelBenchmarksCount $args[6] `
              -WarehouseNumber $args[7] `
              -BCInstallDir $args[8] `
              -BenchmarkRuntimeInMinutes $args[9] `
              -IsBusinessCritical:$args[10] `
              -BenchmarkWarmupInMinutes 15 `
              -Comment $args[11] `
              -LoggingServerName $args[12] `
              -LoggingDatabaseName $args[13] `
              -LoggingCredentials $args[14] `
              -InstanceCredentials $args[15] `
              -ReportStorageAccountKey $args[16] `
              -Environment $args[17] `
              -CorrelationId $args[18] `
              -SkipPingJobSwitch:$args[19] `
              -PingJobPingPeriodInSeconds $args[20] `
              -ScaledDown:$args[21]
        } -ArgumentList @($PSScriptRoot,
                          $instanceName,
                          $tpccDatabaseName,
                          $HardwareGeneration,
                          $tpccThreadNumber,
                          $ProcessorCount,
                          $ParallelBenchmarksCount,
                          $WarehouseNumber,
                          $BCInstallDir,
                          $benchmarkRuntime['TPCC'],
                          ($BusinessCritical.IsPresent),
                          "Scheduled run from $($env:computername)",
                          $LoggingServerName,
                          $LoggingDatabaseName,
                          $LoggingCredentials,
                          $InstanceCredentials,
                          $StorageAccountKey,
                          $Environment,
                          $CorrelationId,
                          ($SkipPingJobSwitch.IsPresent),
                          $PingJobPingPeriodInSeconds,
                          ($ScaledDown.IsPresent))

        Wait-Job $tpccJob -Timeout (($benchmarkRuntime['TPCC'] + 30) * 60)
        Stop-Job $tpccJob
        Receive-Job $tpccJob

        TraceToClPerfDb -Level "Info" `
            -CorrelationId $CorrelationId `
            -EventName "end_job" `
            -ServerName $instanceName `
            -DatabaseName $tpccDatabaseName
    }

    TraceToClPerfDb -Level "Info" -CorrelationId $CorrelationId -EventName "end_performance_action"
}
catch {
    TraceToClPerfDb `
        -Level "Error" `
        -CorrelationId $CorrelationId `
        -EventName "end_performance_action" `
        -EventMessage "$($PSItem.ToString())" `
        -Stack "$($PSItem.ScriptStackTrace)"
}
finally {
    UpdateInstanceState `
      -InstanceName $instanceName `
      -State "Ready"
}
