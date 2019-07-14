Param(
    [Parameter(Mandatory=$True, HelpMessage="Name of benchmark to run")]
    [ValidateSet(
         "CDB",
         "TPCC"
     )]
    [String]
    $Benchmark,

    [Parameter(Mandatory=$True, HelpMessage="Name of instance under test")]
    [String]
    $ServerName,

    [Parameter(Mandatory=$True, HelpMessage="Name of database under test")]
    [String]
    $DatabaseName,

    [Parameter(Mandatory=$False, HelpMessage="Instance credentials")]
    [System.Management.Automation.PSCredential]
    $InstanceCredentials,

    [Parameter(Mandatory=$True, HelpMessage="Number of threads that are used for running benchmark - This parameter is overriden for CDB benchmark")]
    [Int]
    $ThreadNumber,

    [Parameter(Mandatory=$True, HelpMessage="Rate of which connections are opened when benchmark is initializing")]
    [Int]
    $ConnectRate,

    [Parameter(Mandatory=$False, HelpMessage="Folder where we should save generated profile")]
    [String]
    $OutputPath = $PWD,

    [Parameter(Mandatory=$False, HelpMessage="Number of warehouses for TPCC test")]
    [Int]
    $WarehouseNumber = -1,

    [Parameter(Mandatory=$False, HelpMessage="Scale factor for CDB benchmark")]
    [Int]
    $ScaleFactor =  -1,

    [Parameter(Mandatory=$False, HelpMessage="Number of customers for TPCE benchmark")]
    [Int]
    $NumberOfCustomers = -1,

    [Parameter(Mandatory=$False, HelpMessage="Used for TPCC/TPCE benchmark to indicate whether we are using scaled down database for benchmark run")]
    [Switch]
    $ScaledDown
)

if ($InstanceCredentials -eq $null)
{
    $InstanceCredentials = Get-Credential -Message "Instance credentials"
}

# Validate input
if ($Benchmark -eq "CDB")
{
    if ($ScaleFactor -eq 0)
    {
        Write-Output "CDB benchmark requires ScaleFactor argument"
        return -1
    }

    $profileTemplate = [IO.File]::ReadAllText("$($PSScriptRoot)\..\benchcraft_profiles\cdb_profile_template.xml")
    $profileString = [string]::Format(
        $profileTemplate,
        $ServerName,
        $DatabaseName,
        $InstanceCredentials.UserName,
        $InstanceCredentials.GetNetworkCredential().Password,
        $ScaleFactor,
        $ThreadNumber,
        $ConnectRate)

    Write-Output $PWD
    Write-Output $profileString | Out-File -FilePath "CDB-Profile.bp"
}
elseif ($Benchmark -eq "TPCC")
{
    if ($WarehouseNumber -eq 0)
    {
        echo "CDB benchmark requires WarehouseNumber argument"
        return -1
    }

    $isScaledDown = if ($ScaledDown.IsPresent) { "Y" } else { "N" }

    $profileTemplate = [IO.File]::ReadAllText("$($PSScriptRoot)\..\benchcraft_profiles\tpcc_profile_template.xml")
    $profileString = [string]::Format($profileTemplate,
        $ServerName,
        $DatabaseName,
        $InstanceCredentials.UserName,
        $InstanceCredentials.GetNetworkCredential().Password,
        $WarehouseNumber,
        $ThreadNumber,
        $ConnectRate,
        $isScaledDown)

    Write-Output $PWD
    Write-Output $profileString | Out-File -FilePath "$($OutputPath)\TPCC-Profile.bp"
}

return 0;
