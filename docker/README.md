# Docker documentation

## Provisioning new swarm cluster

To provision new swarm cluster you need to:

1. Create manager VM which needs to be ubuntu 16.04 - all scripts are written in such way that they expect clperf as VM username. If you want to change username you will have to modify scripts
2. Open ports (from portal during creation) TCP: 2376, 2377, 7946 & UDP: 4789, 7946
5. Copy folder $/SF/CLPerf/benchmarks/swarmServiceCreator & file $/SF/CLPerf/benchmarks/docker/initializeLinuxVM.sh to linux VM
3. Execute initializeLinuxVM.sh on linux VM
4. Restart linux VM
5. Run `docker swarm init`
6. Copy output of command and store it somewhere as it will be needed later
7. Active python virtual envionment `source ~/python-virtual-environments/swarmEnv/bin/activate`
8. Start swarmServiceCreator.
Example command:
`python3 swarmServiceCreatorConsole.py  --instanceUsername clperf --instancePassword {password} --loggingPassword {anotherPassword} --storageAccountKey "{storageAccountKey}" --environment Stage --loggingDatabase clperftesting --image "clperftesting.azurecr.io/perftestingstage:latest"`
9. Create as many workers nodes as you want - windows server VMs
10. Open ports (from portal during creation) TCP: 2376, 2377, 7946 & UDP: 4789, 7946
11. Execute `.\installDocker.ps1`. This will restart your VM
12. Reconnect to VM and execute `.\initializeWindowsVM.ps1`. Username and password here should be username and password of Container Hub where we store our images. In our case this is clperftesting hub. You can find it on Azure Portal. You will also need output of step 8. as argument here.

## Dockerfile
You can find [Dockerfile](https://docs.docker.com/engine/reference/builder/) syntax here.

To build image run `docker build $\SF\CLPerf\benchmarks\ -t clperftesting.azurecr.io/perftesting{environment} -f $\SF\CLPerf\benchmarks\docker\Dockerfile`

First parameter of this command is called context location. Whatever is referenced from docker file should have relative path to this context provided during build.

Image should be uploaded to azure image hub named clperftesting.azurecr.io.
To push new image you should first login:
`docker login clperftesting.azurecr.io -u clperftesting -p {hubPw}`
After that push image to hub by running:
`docker push clperftesting.azurecr.io/perftesting{environment}`

Note: I had troubles building image from my machine due to some CorpNet limitations - so just connect to random VM and do these steps if needed

Docker can build new images from existing images. You can find example of that in our Dockerfile where we are building image from windowsservercore.
More Microsoft images can be found [here] (https://hub.docker.com/r/microsoft/)

## Things we are currently not using but might be useful going forward

### Docker Compose
Docker compose lets you define your service in configuration YAML file.
It can also be helpful for services that need to communicate together.

We used this initially before we moved to db.

Problems with this:
 * If there is not enough resources in swarm cluster there is no prioritization of waiting tasks
 * Services that require more resources will be starved
Adventages:
 * Services defined in config file
 * Easy setup of common service network if need be

[Compose documentation](https://docs.docker.com/compose/overview/)

### Docker Machine
Docker Machine can help you manage your Swarm Nodes.
It has Azure integrated and should be able to create VM on provided subscription.
This has not been tested though.

[Documentation of Docker Machine](https://docs.docker.com/machine/)
[How to create AzureVM from Docker Machine](https://docs.docker.com/machine/drivers/azure/)
