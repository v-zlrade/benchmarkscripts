Param(
    [Parameter(Mandatory=$False)]
    [Long]
    $RunId,

    [Parameter(Mandatory=$True, HelpMessage="Name of benchmark to run")]
    [ValidateSet(
         "CDB",
         "TPCC"
     )]
    [String]
    $Benchmark,

    [Parameter(Mandatory=$True, HelpMessage="Path where we benchmark reports are")]
    [string]
    $ReportPath,

    [Parameter(Mandatory=$True, HelpMessage="Benchmark start time")]
    [DateTime]
    $BenchmarkStartTime,

    [Parameter(Mandatory=$True, HelpMessage="Storage account key")]
    [String]
    $StorageAccountKey,

    [String]
    [Parameter(Mandatory=$True, HelpMessage="Generation of hardware where we are running this")]
    [String]
    $HardwareGeneration,

    [Parameter(Mandatory=$True, HelpMessage="Count of processor of instance under test")]
    [Int]
    $ProcessorCount,

    [Parameter(Mandatory=$False)]
    [String]
    $Environment,

    [Parameter(Mandatory=$False)]
    [Switch]
    $BusinessCritical,

    [Parameter(Mandatory=$False)]
    [String]
    $StorageAccountName = "benchmarkbackupstorage"
);

# Include common scripts
."$($PSScriptRoot)\\clPerfCommon.ps1"

TraceToClPerfDb -Level "Info" `
    -CorrelationId $CorrelationId `
    -EventName "start_upload_report"

$context = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
$containerName = "benchmarkreports"
$instanceConfigurationPrefix = "$($HardwareGeneration)_$(if ($BusinessCritical.IsPresent) { 'BC' } else { 'GP' })_$($ProcessorCount)"
$blobPrefix = "$($RunId)_$($instanceConfigurationPrefix)$($Benchmark)_$($Environment)_$($BenchmarkStartTime.ToString('MMddyyyyHHmmss'))"

foreach ($file in (Get-ChildItem -Path $ReportPath -File))
{
    Set-AzureStorageBlobContent -File $file.FullName -Container $containerName -Context $context -Blob "$($blobPrefix)/$($file.Name)" -Force -WarningAction SilentlyContinue
}

TraceToClPerfDb -Level "Info" `
    -CorrelationId $CorrelationId `
    -EventName "end_upload_report"
