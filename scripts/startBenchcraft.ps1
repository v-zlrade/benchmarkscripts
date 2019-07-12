Param(
    [Parameter(Mandatory=$True)]
    [String]
    $BCInstallDir,

    [Parameter(Mandatory=$True)]
    [String]
    $BCProfileFileName,

    [Parameter(Mandatory=$True)]
    [string]
    $PathToReports,

    [Parameter(Mandatory=$False)]
    [Int]
    $WarmUpTimeInSeconds = 1800, # 30min

    [Parameter(Mandatory=$False)]
    [Int]
    $SteadyStateTimeInSecs = 1800 # 30min
)

# Include common scripts
."$($PSScriptRoot)\\clPerfCommon.ps1"

echo "Current Dir = $pwd"

TraceToClPerfDb -Level "Info" `
    -CorrelationId $CorrelationId `
    -EventName "start_benchcraft"

$Agent = "Agent$(Get-Date -Format 'MMddyyyyHHmmss')"

Import-Module $BCInstallDir\BenchCraftPowerShell.psd1
New-BCAPIAgent -AgentName $Agent -AgentFile $BCInstallDir\BenchCraft.PSAgent.exe
Open-BCProfile -AgentName $Agent -Profile $BCProfileFileName
Launch-BCDrivers -AgentName $Agent

echo "Starting BenchCraft driver engine at: " (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Start-BCDrivers -AgentName $Agent

# warmup period
Start-Sleep -Seconds $WarmUpTimeInSeconds

# steady-state period; record the time before and after
$time_start = Get-Date -Format "s"
Start-Sleep -Seconds $SteadyStateTimeInSecs
$time_end = Get-Date -Format "s"

# add a small time buffer after the measurement interval and then stop the test
Start-Sleep -Seconds 5

echo "Stopping BenchCraft driver engine at: " (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Stop-BCDrivers -AgentName $Agent
Start-Sleep -Seconds 30

# get the txn log file names
$BCTxnLogs = Get-BCLogFile -AgentName $Agent -Drivers Driver1
$BCTxnLogs = $BCTxnLogs.Split(" ") | % { "$($HOME)\$($_)"}
echo "BCTxnLogs = $BCTxnLogs"

$BCTxnLogFullPath = (get-item $BCTxnLogs | Sort-Object LastWriteTime -Descending).FullName | Select-Object -First 1
# in case there is more than one log file (e.g., from previous runs), we are only interested in the most recent one
$BCTxnLog = (get-item $BCTxnLogs | Sort-Object LastWriteTime -Descending).Name | Select-Object -First 1
echo "BCTxnLog = $BCTxnLog"

# Adding try catch because benchcraft gets infinitely stuck if first of these commands fails
Try {
    Open-BCTxnLog -AgentName $Agent -LogName $BCTxnLog

    # Report ID 0 is the general info about the log file
    Get-BCReport -AgentName $Agent -ReportID 0 -Output "$($PathToReports)\LogReport"

    # Report ID 1 is the transaction report for the measurement interval
    Get-BCReport -AgentName $Agent -ReportID 1 -Output "$($PathToReports)\SummarizedReport" -StartTime $time_start -EndTime $time_end

    # Report ID 2 is the step report, showing throughput per minute; generate this for the entire test run,
    # not just the measurement interval
    Get-BCReport -AgentName $Agent -ReportID 2 -Output "$($PathToReports)\StepTransactionReport"

    # Report ID 3 is the response time percentile distribution report for the measurement interval
    Get-BCReport -AgentName $Agent -ReportID 3 -Output "$($PathToReports)\StepResponseReport" -StartTime $time_start -EndTime $time_end

    # Report ID 4 is the event report; generate this for the entire test run
    Get-BCReport -AgentName $Agent -ReportID 4 -Output "$($PathToReports)\EventReport"

}
Catch {
    Write-Error -Message "$($_.Exception.Message)"
}

# In the end copy logs to output directory for debugging purposes
# Generate eventlog file name from txnlog file name
$EventLogFullPath = ($BCTxnLogFullPath -replace "txnlog", "eventlog") -replace ".btl$", ".txt"
echo "PATH TO REPORTS: $($PathToReports)"
echo "BCTxnLog: $($BCTxnLog)"
echo "EventLogName: $($EventLogName)"

Copy-Item -Path $BCTxnLogFullPath -Destination $PathToReports
Copy-Item -Path $EventLogFullPath -Destination $PathToReports

Remove-BCAPIAgent -AgentName $Agent

TraceToClPerfDb -Level "Info" `
    -CorrelationId $CorrelationId `
    -EventName "end_benchcraft"
