from benchmarkServiceGenerator import BenchmarkServiceGenerator


def test_generatePowershellCommand():
    expectedValues = [
        ("./scripts/performanceActions.ps1 "
         "-HardwareGeneration GEN4 "
         "-ProcessorCount 32 "
         "-ParallelBenchmarksCount 2 "
         "-Action RunBenchmark "
         "-Environment Stage "
         "-LoggingServerName 'testLogSvr' "
         "-LoggingDatabaseName 'testLogDb' "
         "-LoggingCredentials (New-Object System.Management.Automation.PSCredential ('testUsername', (echo 'testPw' | ConvertTo-SecureString -AsPlainText -Force))) "
         "-InstanceCredentials (New-Object System.Management.Automation.PSCredential ('testUsername2', (echo 'testPw2' | ConvertTo-SecureString -AsPlainText -Force))) "
         "-StorageAccountKey 'testPw3' "
         "-Benchmark CDB "
         "-BusinessCritical:$False "
         "-ServerName 'clperftesting' "
         "-DatabaseName 'cdb15000' "
         "-ThreadNumber 1002 "
         "-BenchmarkScalingArgument 1001 "
         "-BCInstallDir bcInstallDir "
         "-BenchmarkRuntimeInMinutes 10 "
         "-BenchmarkWarmupInMinutes 5 "
         "-CustomMasterQuery 'SELECT TOP 10 * FROM 0' "
         "-SkipRestore:$False "
         "-Comment 'test comment' "
         "-ScaledDown:$True "
         "-CorrelationId 'guidhere'"),
        # When no custom query is provided
        ("./scripts/performanceActions.ps1 "
         "-HardwareGeneration GEN4 "
         "-ProcessorCount 32 "
         "-ParallelBenchmarksCount 2 "
         "-Action RunBenchmark "
         "-Environment Stage "
         "-LoggingServerName 'testLogSvr' "
         "-LoggingDatabaseName 'testLogDb' "
         "-LoggingCredentials (New-Object System.Management.Automation.PSCredential ('testUsername', (echo 'testPw' | ConvertTo-SecureString -AsPlainText -Force))) "
         "-InstanceCredentials (New-Object System.Management.Automation.PSCredential ('testUsername2', (echo 'testPw2' | ConvertTo-SecureString -AsPlainText -Force))) "
         "-StorageAccountKey 'testPw3' "
         "-Benchmark CDB "
         "-BusinessCritical:$False "
         "-ServerName 'clperftesting' "
         "-DatabaseName 'cdb15000' "
         "-ThreadNumber 1002 "
         "-BenchmarkScalingArgument 1001 "
         "-BCInstallDir bcInstallDir "
         "-BenchmarkRuntimeInMinutes 10 "
         "-BenchmarkWarmupInMinutes 5 "
         "-CustomMasterQuery $null "
         "-SkipRestore:$True "
         "-Comment 'test comment' "
         "-ScaledDown:$True "
         "-CorrelationId 'guidhere'"),
        # When generating script with a benchmark ID
        ("./scripts/performanceActions.ps1 "
         "-Action RunBenchmark "
         "-ScheduledBenchmarkId 1234 "
         "-LoggingServerName 'testLogSvr' "
         "-LoggingDatabaseName 'testLogDb' "
         "-LoggingCredentials (New-Object System.Management.Automation.PSCredential ('testUsername', (echo 'testPw' | ConvertTo-SecureString -AsPlainText -Force))) "
         "-InstanceCredentials (New-Object System.Management.Automation.PSCredential ('testUsername2', (echo 'testPw2' | ConvertTo-SecureString -AsPlainText -Force))) "
         "-StorageAccountKey 'testPw3' "
         "-BCInstallDir bcInstallDir "
         "-Comment 'test comment'")
    ]

    #
    actualValueWithQuery = BenchmarkServiceGenerator.generatePowershellCommandWithBenchmarkSettings(
        hardwareGeneration="GEN4",
        processorCount=32,
        parallelBenchmarksCount=2,
        environment="Stage",
        storageAccountKey="testPw3",
        benchmark="CDB",
        isBc=False,
        instanceName="clperftesting",
        dbName="cdb15000",
        threadNumber=1002,
        benchmarkScalingArgument=1001,
        bcInstallDir="bcInstallDir",
        runtimeInMinutes=10,
        warmupInMinutes=5,
        customMasterQuery="SELECT TOP 10 * FROM 0",
        shouldRestore=True,
        comment="test comment",
        scaledDown=True,
        correlationId="guidhere",
        loggingServerName="testLogSvr",
        loggingDatabaseName="testLogDb",
        loggingUsername="testUsername",
        loggingPassword="testPw",
        instanceUsername="testUsername2",
        instancePassword="testPw2"
    )

    assert actualValueWithQuery == expectedValues[0]

    actualValueWithoutQuery = BenchmarkServiceGenerator.generatePowershellCommandWithBenchmarkSettings(
        hardwareGeneration="GEN4",
        processorCount=32,
        parallelBenchmarksCount=2,
        environment="Stage",
        storageAccountKey="testPw3",
        benchmark="CDB",
        isBc=False,
        instanceName="clperftesting",
        dbName="cdb15000",
        threadNumber=1002,
        benchmarkScalingArgument=1001,
        bcInstallDir="bcInstallDir",
        runtimeInMinutes=10,
        warmupInMinutes=5,
        customMasterQuery=None,
        shouldRestore=False,
        comment="test comment",
        scaledDown=True,
        correlationId="guidhere",
        loggingServerName="testLogSvr",
        loggingDatabaseName="testLogDb",
        loggingUsername="testUsername",
        loggingPassword="testPw",
        instanceUsername="testUsername2",
        instancePassword="testPw2"
    )

    assert actualValueWithoutQuery == expectedValues[1]

    actualValueWithId = BenchmarkServiceGenerator.generatePowershellCommandWithBenchmarkId(
        scheduledBenchmarkId=1234,
        storageAccountKey="testPw3",
        bcInstallDir="bcInstallDir",
        comment="test comment",
        loggingServerName="testLogSvr",
        loggingDatabaseName="testLogDb",
        loggingUsername="testUsername",
        loggingPassword="testPw",
        instanceUsername="testUsername2",
        instancePassword="testPw2"
    )

    assert actualValueWithId == expectedValues[2]
