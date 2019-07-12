Param(
    [Parameter(Mandatory=$True)]
    [ValidateSet(
         "CDB",
         "TPCC"
     )]
    [String]
    $Benchmark,

    [Parameter(Mandatory=$True)]
    [String]
    $ServerName,

    [Parameter(Mandatory=$True)]
    [String]
    $DatabaseName,

    [Parameter(Mandatory=$False, HelpMessage="Instance credentials")]
    [System.Management.Automation.PSCredential]
    $InstanceCredentials,

    [Parameter(Mandatory=$False)]
    [Int]
    $WarehouseNumber = -1,

    [Parameter(Mandatory=$False)]
    [Int]
    $ScaleFactor = -1,

    [Parameter(Mandatory=$True)]
    [String]
    $StorageAccountKey,

    [Parameter(Mandatory=$False)]
    [Switch]
    $BusinessCritical,

    [Parameter(Mandatory=$False)]
    [Switch]
    $ScaledDown
)

# Include common scripts
."$($PSScriptRoot)\\clPerfCommon.ps1"

if ($InstanceCredentials -eq $null)
{
    $InstanceCredentials = Get-Credential -Message "Instance credentials"
}

# Make up a correlation ID if we haven't got one already
if ($correlationId -eq $null)
{
    $correlationId = New-Guid
}

if ($global:clCred -ne $null)
{
    UpdateInstanceState `
      -InstanceName $ServerName `
      -State "Restoring"
}

# Name of containers in storage accounts
$ContainerNames= @{
    CDB40000="cdb40000"
    CDB30000="cdb30000"
    CDB15000="cdb15000"
    TPCC8500="tpcc8500"
    TPCC4000="tpcc4000"
    TPCC10500="tpcc10500"
    TPCC11000="tpcc11000"
    TPCC35000="tpcc35000"
    TPCC48000="tpcc48000"
    TPCC59500="tpcc59500"
    TPCC8500SD="tpcc8500sd"
    TPCC10500SD="tpcc10500sd"
    TPCC11000SD="tpcc11000sd"
    TPCC35000SD="tpcc35000sd"
    TPCC48000SD="tpcc48000sd"
    TPCC59500SD="tpcc59500sd"
    TPCC84000SD="tpcc84000sd"
    TPCC108500SD="tpcc108500sd"
}

# Storage account name
$StorageNames=@{
    CDB40000="benchmarkbackupstorage"
    CDB30000="benchmarkbackupstorage"
    CDB15000="benchmarkbackupstorage"
    TPCC4000="benchmarkbackupstorage"
    TPCC8500="benchmarkbackupstorage"
    TPCC10500="benchmarkbackupstorage"
    TPCC11000="benchmarkbackupstorage"
    TPCC35000="benchmarkbackupstorage"
    TPCC48000="benchmarkbackupstorage"
    TPCC59500="benchmarkbackupstorage"
    TPCC8500SD="benchmarkbackupstorage"
    TPCC10500SD="benchmarkbackupstorage"
    TPCC11000SD="benchmarkbackupstorage"
    TPCC35000SD="benchmarkbackupstorage"
    TPCC48000SD="benchmarkbackupstorage"
    TPCC59500SD="benchmarkbackupstorage"
    TPCC84000SD="benchmarkbackupstorage"
    TPCC108500SD="benchmarkbackupstorage"
}

# Validate input and construct benchmark name
if ($Benchmark -eq "CDB")
{
    if ($ScaleFactor -eq 0)
    {
        TraceToClPerfDb -Level "Warning" `
            -CorrelationId $correlationId `
            -EventName "restore_error" `
            -ServerName $ServerName `
            -DatabaseName $DatabaseName `
            -EventMessage "CDB restore requires ScaleFactor argument"

        return
    }

    $benchmarkName = "$($Benchmark)$($ScaleFactor)"
}
elseif ($Benchmark -eq "TPCC")
{
    if ($WarehouseNumber -eq 0)
    {
        TraceToClPerfDb -Level "Warning" `
            -CorrelationId $correlationId `
            -EventName "restore_error" `
            -ServerName $ServerName `
            -DatabaseName $DatabaseName `
            -EventMessage "TPCC restore requires WarehouseNumber argument"

        return
    }

    $benchmarkName = "$($Benchmark)$($WarehouseNumber)$(if ($ScaledDown.IsPresent) { "SD" } else { $null })"
}

# construct variables for to send to blob storage API
$storageName = $StorageNames[$benchmarkName]
$containerName = $ContainerNames[$benchmarkName]

# get blobs in container
$context = New-AzureStorageContext -StorageAccountName $storageName -StorageAccountKey $StorageAccountKey
$containerUrl = "$($context.BlobEndPoint)$($containerName)"
$blobUrlFormat = "$($containerUrl)/{0}"

$blobUrls = Get-AzureStorageBlob -Container $containerName -Context $context | % { [string]::Format($blobUrlFormat, $_.Name ) }

# Create SAS needed for TSQL restore
$sasToken = New-AzureStorageAccountSASToken -Service Blob,Queue,Table,File -ResourceType Service,Container,Object -Context $context -Permission rwdlacup -Protocol HttpsOnly -StartTime $(Get-Date) -ExpiryTime $((Get-Date).AddDays(1))
# Remove question mark from beggining of string
$sasToken = $sasToken.Substring(1)
$tsqlBlobUrls = $blobUrls | % { "URL = N'$($_)'"}

# Construct SQL queries
$restoreQuery = "
IF EXISTS  (select 1 from sys.credentials where name = '$($containerUrl)')
    drop credential [$($containerUrl)]

CREATE CREDENTIAL [$($containerUrl)]
WITH IDENTITY = 'SHARED ACCESS SIGNATURE',
SECRET = '$($sasToken)';

RESTORE DATABASE $($DatabaseName)
FROM
$([string]::Join(",`r`n", $tsqlBlobUrls))
"

# We need to modify files sizes because GP instances have IOPS limits based on file size
$modifyFileSizeQueryTemplate ="
DECLARE @names VARCHAR(MAX)

DECLARE files CURSOR FORWARD_ONLY READ_ONLY LOCAL
FOR
SELECT name
FROM sys.master_files
WHERE DB_NAME(database_id) = '{0}'
AND (
    physical_name like '%.mdf' OR
    physical_name like '%.ndf' OR
    physical_name like '%.ldf'
    )
-- We need more than 1TB for max IOPS
-- size is given in number of (8kb) pages so size*8/1024 is conversion to MB units.
AND size/128 < 1100 * 1024

OPEN files

FETCH NEXT
FROM files
INTO
        @names

DECLARE @queryToExecute NVARCHAR(MAX) = NULL
WHILE @@FETCH_STATUS = 0
BEGIN
        SET @queryToExecute = CONCAT (
        'ALTER DATABASE {0}
         MODIFY FILE
                (NAME = ', @names, ',
                SIZE = 1100GB);');

        EXEC sp_executesql
                @statement = @queryToExecute

        FETCH NEXT
        FROM files
        INTO
        @names
END

CLOSE files
DEALLOCATE files
"

Try
{
    TraceToClPerfDb -Level "Info" `
        -CorrelationId $correlationId `
        -EventName "restore_info" `
        -ServerName $ServerName `
        -DatabaseName $DatabaseName `
        -EventMessage "Dropping databases"

    DropAllDatabases -ServerName $ServerName -Credentials $InstanceCredentials

    TraceToClPerfDb -Level "Info" `
        -CorrelationId $correlationId `
        -EventName "restore_info" `
        -ServerName $ServerName `
        -DatabaseName $DatabaseName `
        -EventMessage "Restoring database $($DatabaseName)"

    Invoke-Sqlcmd -ServerInstance $ServerName -Database "master" -Query $restoreQuery -Credential $InstanceCredentials -QueryTimeout 0 -ConnectionTimeout 0 -ErrorAction Stop

    if (-not $BusinessCritical.IsPresent)
    {
        $modifyQuery = [string]::Format($modifyFileSizeQueryTemplate, $DatabaseName)

        TraceToClPerfDb -Level "Info" `
            -CorrelationId $correlationId `
            -EventName "restore_info" `
            -ServerName $ServerName `
            -DatabaseName $DatabaseName `
            -EventMessage "Increasing file sizes (.mdf and .ldf) of database $($DatabaseName)"

        Invoke-Sqlcmd -ServerInstance $ServerName -Database "master" -Query $modifyQuery -Credential $InstanceCredentials -QueryTimeout 0 -ConnectionTimeout 0 -ErrorAction Stop
    }
}
Catch
{
    TraceToClPerfDb -Level "Error" `
        -CorrelationId $correlationId `
        -EventName "restore_error" `
        -ServerName $ServerName `
        -DatabaseName $DatabaseName `
        -EventMessage "$($PSItem.ToString())" `
        -Stack "$($PSItem.ScriptStackTrace)"

    throw "Error in restore script: $($PSItem.Exception.Message)"
}
