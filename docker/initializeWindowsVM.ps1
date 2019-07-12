Param(
    [Parameter(Mandatory=$True, HelpMessage="Username of azure image hub")]
    [String]
    $Username,

    [Parameter(Mandatory=$True, HelpMessage="Password of azure image hub")]
    [String]
    $Password,

    [Parameter(Mandatory=$True, HelpMessage="Environment of benchmark")]
    [String]
    $Environment,

    [Parameter(Mandatory=$True, HelpMessage="Output from docker swarm init commmand")]
    [String]
    $SwarmJoinCommand
)
docker login clperftesting.azurecr.io -u $Username -p $Password
docker pull "clperftesting.azurecr.io/perftesting$($Environment.ToLower())"

Unregister-ScheduledTask -TaskName "Docker image refresh"
$loginArguments = "-command ""& {docker login clperftesting.azurecr.io -u $Username -p $Password >> C:\output}"""
$pullArguments = "-command ""& {docker pull clperftesting.azurecr.io/perftesting$($Environment.ToLower()) >> C:\output}"""
$principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$loginAction = New-ScheduledTaskAction -Execute 'Powershell.exe'  `
  -Argument $loginArguments
$pullAction = New-ScheduledTaskAction -Execute 'Powershell.exe'  `
  -Argument $pullArguments
$trigger = New-ScheduledTaskTrigger -Daily -At 1am
Register-ScheduledTask -Action @($loginAction, $pullAction) -Trigger $trigger -TaskName "Docker image refresh" -Description "Daily refresh of docker image"  -Principal $principal

Invoke-Expression $SwarmJoinCommand
