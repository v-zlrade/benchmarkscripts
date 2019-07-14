function Invoke-BcpIn
{
    <#
.SYNOPSIS
Runs bcp in

.DESCRIPTION
Runs bcp in

.EXAMPLE
Invoke-BcpIn -CorrelationId $correlationid -SourceFileName $sourceFile -TargetTableName $targetTableName `
  -Server $server -DatabaseName $dbName -Username $user -Password $pass -BatchSize $batchSize
#>
    Param(
        [Parameter(Mandatory=$True, HelpMessage="Correlation id")]
        [string]
        $CorrelationId,

        [Parameter(Mandatory=$True, HelpMessage="Container name")]
        [String]
        $SourceFileName,

        [Parameter(Mandatory=$True, HelpMessage="Blob name")]
        [String]
        $TargetTableName,

        [Parameter(Mandatory=$True, HelpMessage="Server name")]
        [String]
        $ServerName,

        [Parameter(Mandatory=$True, HelpMessage="Database name")]
        [String]
        $DatabaseName,

        [Parameter(Mandatory=$True, HelpMessage="Username")]
        [String]
        $Username,

        [Parameter(Mandatory=$True, HelpMessage="Password")]
        [String]
        $Password,

        [Parameter(Mandatory=$True, HelpMessage="Password")]
        [Int]
        $BatchSize
    )

   ."$($PSScriptRoot)\\clPerfCommon.ps1"

   TraceToClPerfDb -Level "Info" `
   -CorrelationId $CorrelationId `
   -EventName "pre" `
   -EventMessage "precheck"


    TraceToClPerfDb -Level "Info" `
      -CorrelationId $CorrelationId `
      -EventName "start_bcp" `
      -EventMessage "bcp $TargetTableName IN $SourceFileName -S $ServerName -d $DatabaseName -U $Username -P $Password -b $BatchSize -e '.\$TargetTableName$([guid]::NewGuid()).err' -o '.\$TargetTableName$([guid]::NewGuid()).out' -n"

      
   TraceToClPerfDb -Level "Info" `
   -CorrelationId $CorrelationId `
   -EventName "post" `
   -EventMessage "postcheck"

    bcp $TargetTableName IN $SourceFileName -S $ServerName -d $DatabaseName -U $Username -P $Password -b $BatchSize -e ".\$TargetTableName$([guid]::NewGuid()).err" -o ".\$TargetTableName$([guid]::NewGuid()).out" -n

    TraceToClPerfDb -Level "Info" `
      -CorrelationId $CorrelationId `
      -EventName "end_bcp" `
      -EventMessage "FileName: $SourceFileName, DatabaseName $DatabaseName, TargetTable $TargetTableName"
}

function InitializeDatabaseForBcp
{
    <#
.SYNOPSIS
Initializes database for bcp in

.DESCRIPTION
Initializes database for bcp in

.EXAMPLE
InitializeDatabaseForBcp -CorrelationId $correlationid -ServerName $ServerName -DatabaseName $databaseName -InstanceCredentials $instanceCredentials -WorkerNumber $workerNumber -ScaleFactor $ScaleFactor
#>
    Param(
        [Parameter(Mandatory=$True, HelpMessage="Correlation id")]
        [string]
        $CorrelationId,

        [Parameter(Mandatory=$True, HelpMessage="Server name")]
        [String]
        $ServerName,

        [Parameter(Mandatory=$True, HelpMessage="Database name")]
        [String]
        $DatabaseName,

        [Parameter(Mandatory=$False, HelpMessage="Instance credentials")]
        [System.Management.Automation.PSCredential]
        $InstanceCredentials,

        [Parameter(Mandatory=$True, HelpMessage="Password")]
        [Int]
        $WorkerNumber,

        [Parameter(Mandatory=$True, HelpMessage="Scale factor, should be max 8k")]
        [Int]
        $ScaleFactor
    )

    $createDatabaseQuery = "CREATE DATABASE [$DatabaseName]"
    $createTableTemplateQuery = "
create table bcpTest{0}
(
  [id] integer not null,
  [bin] binary($ScaleFactor) not null,
)
"
   ."$($PSScriptRoot)\\clPerfCommon.ps1"

    TraceToClPerfDb -Level "Info" `
      -CorrelationId $CorrelationId `
      -EventName "bcp_create_database"

    ExecuteSqlQueryWithRetry -ServerInstance $ServerName -DatabaseName "master" -InstanceCredentials $InstanceCredentials -Query $createDatabaseQuery -RetryDelayInSeconds 10 -NumberOfRetries 5

    TraceToClPerfDb -Level "Info" `
      -CorrelationId $CorrelationId `
      -EventName "bcp_create_tables"

    $range = 1..$WorkerNumber
    $range | % { [string]::Format($createTableTemplateQuery, $_) } | % { ExecuteSqlQueryWithRetry -ServerInstance $ServerName -DatabaseName $DatabaseName -InstanceCredentials $InstanceCredentials -Query $_ -RetryDelayInSeconds 10 -NumberOfRetries 5 }
}
