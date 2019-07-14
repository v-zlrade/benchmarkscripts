Param(
    [Parameter(Mandatory=$True, HelpMessage="Name of benchmark to run")]
    [ValidateSet(
         "CDB",
         "TPCC"
     )]
    [String]
    $Benchmark,

    [Parameter(Mandatory=$True, HelpMessage="Path where we should store reports from benchmark")]
    [string]
    $ReportPath,

    # DEVNOTE: This ID is mapping to run in database where we store results
    [Parameter(Mandatory=$True, HelpMessage="Id of current run")]
    [Int]
    $RunId,

    [Parameter(Mandatory=$True, HelpMessage="Name of instance where we store benchmark results")]
    [String]
    $LoggingServerName,

    [Parameter(Mandatory=$True, HelpMessage="Name of database where we store benchmark results")]
    [String]
    $LoggingDatabaseName,

    [Parameter(Mandatory=$False, HelpMessage="Logging database credentials")]
    [System.Management.Automation.PSCredential]
    $LoggingCredentials
)

# Include common scripts
."$($PSScriptRoot)\\clPerfCommon.ps1"


# This script is supposed to parse reports
# For report formats please check examples folder

function IsDateTime ($Value)
{
    Try
    {
        Get-Date $Value
        return $true
    }
    Catch
    {
        return $false
    }
}

function GenerateSumFromArray ([String[]]$array, [int]$startingIndex, [int]$step)
{
    [double]$sum = 0;
    For ($i=$startingIndex; $i -le $array.Length; $i = $i + $step) {
        $sum = $sum + [double]$array[$i]
    }

    return $sum
}

if ($LoggingCredentials -eq $null)
{
    $LoggingCredentials = Get-Credential -Message "Logging database credentials" -UserName $LoggingUserName
}

TraceToClPerfDb -Level "Info" `
  -CorrelationId $CorrelationId `
  -EventName "start_parse_report"

# Report metric query template
$ReportingQueryTemplate = "
INSERT INTO benchmark_results
(
    [run_id],
    [metric_name],
    [metric_value]
)
VALUES
(
    $($RunId),
    '{0}',
    {1}
)
"
# Step report query template
$StepReportingQueryTemplate = "
INSERT INTO benchmark_step_reports
(
    [run_id],
    [timestamp],
    [metric_name],
    [metric_value]
)
VALUES
(
    $($RunId),
    CONVERT(DATETIME2(0), '{0}'),
    '{1}',
    {2}
)
"

if ($Benchmark -eq "CDB")
{
    # Each line of reports represents a row in table that has metrics for different query types of benchmark
    # Last line contains summarized reports and we only care about that
    # This line starts with keyword 'All'
    $lines = Get-Content $ReportPath\SummarizedReport
    $totalTxnPerSec = 0
    $maxResponseTime = 0
    $startAggregating = $false
    foreach($line in $lines) {
        $lineWords = $line.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)
        # We only care about values between two
        # -------------------------
        # something
        # -------------------------
        if($line.StartsWith('----')) {
            $startAggregating = -not $startAggregating
            continue
        }

        # Do not use All row as it calculations are wrong
        if($lineWords[0] -eq 'All') {
            break;
        }

        if ($startAggregating) {
            $numbers = [regex]::matches($line, "((\d+)(\.(\d+))?)").Value
            $totalTxnPerSec += [double]$numbers[1]
            $maxResponseTime = [Math]::max([double]$numbers[9], $maxResponseTime)
        }
    }
    # Transactions per second is second column for CDB benchmark
    $tpsQuery = [string]::Format($ReportingQueryTemplate, 'Transactions per second', $totalTxnPerSec);
    # 95th percentilize is tenth column for CDB benchmark
    $95thPercentileQuery = [string]::Format($ReportingQueryTemplate, '95th percentile', $maxResponseTime);

    Invoke-Sqlcmd -ServerInstance $LoggingServerName -Database $LoggingDatabaseName -Credential $LoggingCredentials `
      -Query $tpsQuery
    Invoke-Sqlcmd -ServerInstance $LoggingServerName -Database $LoggingDatabaseName -Credential $LoggingCredentials `
      -Query $95thPercentileQuery

    # For CDB we care about all transactions
    foreach($line in Get-Content $ReportPath\StepTransactionReport) {
        $lineWords = $line.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)

        # Check if line starts with timestamp - ex 2018-08-02 22:56:00
        # Those are lines that cointain results from benchmarks
        $dateString = "$($lineWords[0]) $($lineWords[1])"
        if (IsDateTime -Value $dateString)
        {
            $transactionCount = GenerateSumFromArray -array $lineWords -startingIndex 2 -step 4
            # We sum response time of all transaction types and then divide by transaction type count since this is average RT
            $responseTime = (GenerateSumFromArray -array $lineWords -startingIndex 4 -step 4) / 9
            $queryTxn = [string]::Format($StepReportingQueryTemplate, $dateString, "transactionStepCount", $transactionCount)
            $queryRT = [string]::Format($StepReportingQueryTemplate, $dateString, "responseTimeAvg", $responseTime)

            Invoke-Sqlcmd -ServerInstance $LoggingServerName -Database $LoggingDatabaseName -Credential $LoggingCredentials `
             -Query $queryTxn
            Invoke-Sqlcmd -ServerInstance $LoggingServerName -Database $LoggingDatabaseName -Credential $LoggingCredentials `
              -Query $queryRT
        }
    }
}
elseif ($Benchmark -eq "TPCC")
{
    # Each line of reports represents a row in table that has metrics for different query types of benchmark
    # For TPCC benchmark we only care about transactions per minute of New Order transactions
    # So only parse New Order row
    foreach($line in Get-Content $ReportPath\SummarizedReport) {
        $lineWords = $line.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)

        # Duration    :    3600.0
        if ($lineWords[0] -eq 'Duration')
        {
            $duration = [double]$lineWords[2]
        }
        # New Order $count $errors .. etc
        elseif ($lineWords[0] -eq 'New') {
            # Get columns from line
            $metrics = $lineWords;
            break;
        }
    }

    # Transactions per minute is fourth column for TPCC benchmark
    $transactionsPerMinuteQuery = [string]::Format($ReportingQueryTemplate, 'Transactions per minute', [double]$metrics[2] / $duration * 60);
    # 90th percentilize is tenth column for TPCC benchmark
    $90thPercentileQuery = [string]::Format($ReportingQueryTemplate, '90th percentile', [double]$metrics[10]);

    Invoke-Sqlcmd -ServerInstance $LoggingServerName -Database $LoggingDatabaseName -Credential $LoggingCredentials `
      -Query $transactionsPerMinuteQuery
    Invoke-Sqlcmd -ServerInstance $LoggingServerName -Database $LoggingDatabaseName -Credential $LoggingCredentials `
      -Query $90thPercentileQuery

    # For TPCC we care only about New Order txn
    foreach($line in Get-Content $ReportPath\StepTransactionReport) {
        [String[]]$lineWords = $line.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)

        # Check if line starts with timestamp - ex 2018-08-02 22:56:00
        # Those are lines that cointain results from benchmarks
        $dateString = "$($lineWords[0]) $($lineWords[1])"
        if (IsDateTime $dateString)
        {
            $newOrderTransactionCount = $lineWords[2];
            $newOrderAvgRT = $lineWords[4];

            $queryTxn = [string]::Format($StepReportingQueryTemplate, $dateString, "transactionStepCount", $newOrderTransactionCount)
            $queryRT = [string]::Format($StepReportingQueryTemplate, $dateString, "responseTimeAvg", $newOrderAvgRT)

           Invoke-Sqlcmd -ServerInstance $LoggingServerName -Database $LoggingDatabaseName -Credential $LoggingCredentials `
              -Query $queryTxn
           Invoke-Sqlcmd -ServerInstance $LoggingServerName -Database $LoggingDatabaseName -Credential $LoggingCredentials `
              -Query $queryRT
        }
    }
}

TraceToClPerfDb -Level "Info" `
  -CorrelationId $CorrelationId `
  -EventName "end_parse_report"
