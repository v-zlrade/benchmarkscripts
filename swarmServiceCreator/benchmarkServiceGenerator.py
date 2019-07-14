import resourceManager
import dockerWrapper
from orchestrator import Orchestrator
from tracer import Tracer


"""
Class used for creating services
"""
class BenchmarkServiceGenerator(object):
    def __init__(self,
                 loggingServer,
                 loggingDb,
                 loggingUsername,
                 loggingPassword,
                 instanceUsername,
                 instancePassword,
                 storageAccountKey,
                 environment):
        self.loggingServerName = loggingServer
        self.loggingDatabaseName = loggingDb
        self.loggingUsername = loggingUsername
        self.loggingPassword = loggingPassword
        self.instanceUsername = instanceUsername
        self.instancePassword = instancePassword
        self.storageAccountKey = storageAccountKey
        self.environment = environment

        self.tracer = Tracer(
            loggingServer,
            loggingDb,
            loggingUsername,
            loggingPassword,
            environment
        )

        self.orch = Orchestrator(
            loggingServer,
            loggingDb,
            loggingUsername,
            loggingPassword,
            environment,
            self.tracer
        )

    """
    Generated input for docker command
    """
    @staticmethod
    def generateDockerCommand(task,
                              environment,
                              storageAccountKey,
                              loggingServerName,
                              loggingDatabaseName,
                              loggingUsername,
                              loggingPassword,
                              instanceUsername,
                              instancePassword):

        if hasattr(task, 'scheduled_benchmark_id') and task.scheduled_benchmark_id > 0:
            return ["powershell.exe",
                    "-Command",
                    BenchmarkServiceGenerator.generatePowershellCommandWithBenchmarkId(task.scheduled_benchmark_id,
                                                                                       storageAccountKey,
                                                                                       "C:\\BenchCraft\\",
                                                                                       "Swarm run: {0}".format(environment),
                                                                                       loggingServerName,
                                                                                       loggingDatabaseName,
                                                                                       loggingUsername,
                                                                                       loggingPassword,
                                                                                       instanceUsername,
                                                                                       instancePassword)
            ]

        # TODO: remove when all calls to get_next_action in the database return benchmark ID
        return ["powershell.exe",
                "-Command",
                BenchmarkServiceGenerator.generatePowershellCommandWithBenchmarkSettings(task.hardware_generation,
                                                                                         task.processor_count,
                                                                                         environment,
                                                                                         storageAccountKey,
                                                                                         task.benchmark_name,
                                                                                         task.is_bc,
                                                                                         task.server_name,
                                                                                         task.database_name,
                                                                                         task.worker_number,
                                                                                         task.benchmark_scaling_argument,
                                                                                         "C:\\BenchCraft\\",
                                                                                         task.run_timespan_minutes,
                                                                                         task.warmup_timespan_minutes,
                                                                                         task.custom_master_tsql_query,
                                                                                         task.should_restore,
                                                                                         "Swarm run: {0}".format(environment),
                                                                                         task.scaled_down,
                                                                                         task.correlation_id,
                                                                                         loggingServerName,
                                                                                         loggingDatabaseName,
                                                                                         loggingUsername,
                                                                                         loggingPassword,
                                                                                         instanceUsername,
                                                                                         instancePassword)
        ]

    """
    Generates powershell command that needs to be executed inside docker, for the case when a benchmark is given by its settings.
    """
    @staticmethod
    def generatePowershellCommandWithBenchmarkSettings(hardwareGeneration,
                                                       processorCount,
                                                       parallelBenchmarksCount,
                                                       environment,
                                                       storageAccountKey,
                                                       benchmark,
                                                       isBc,
                                                       instanceName,
                                                       dbName,
                                                       threadNumber,
                                                       benchmarkScalingArgument,
                                                       bcInstallDir,
                                                       runtimeInMinutes,
                                                       warmupInMinutes,
                                                       customMasterQuery,
                                                       shouldRestore,
                                                       comment,
                                                       scaledDown,
                                                       correlationId,
                                                       loggingServerName,
                                                       loggingDatabaseName,
                                                       loggingUsername,
                                                       loggingPassword,
                                                       instanceUsername,
                                                       instancePassword):
        return ("./scripts/performanceActions.ps1 "
                "-HardwareGeneration {hardwareGeneration} "
                "-ProcessorCount {processorCount} "
                "-ParallelBenchmarksCount {parallelBenchmarksCount}"
                "-Action RunBenchmark "
                "-Environment {env} "
                "-LoggingServerName '{loggingServerName}' "
                "-LoggingDatabaseName '{loggingDatabaseName}' "
                "-LoggingCredentials (New-Object System.Management.Automation.PSCredential ('{loggingUsername}', (echo '{loggingPassword}' | ConvertTo-SecureString -AsPlainText -Force))) "
                "-InstanceCredentials (New-Object System.Management.Automation.PSCredential ('{instanceUsername}', (echo '{instancePassword}' | ConvertTo-SecureString -AsPlainText -Force))) "
                "-StorageAccountKey '{storageAccountKey}' "
                "-Benchmark {benchmark} "
                "-BusinessCritical:${isBc} "
                "-ServerName '{instanceName}' "
                "-DatabaseName '{dbName}' "
                "-ThreadNumber {threadNumber} "
                "-BenchmarkScalingArgument {benchmarkScalingArgument} "
                "-BCInstallDir {bcInstallDir} "
                "-BenchmarkRuntimeInMinutes {runtimeInMinutes} "
                "-BenchmarkWarmupInMinutes {warmupInMinutes} "
                "-CustomMasterQuery {customMasterQuery} "
                "-SkipRestore:${skipRestore} "
                "-Comment '{comment}' "
                "-ScaledDown:${scaledDown} "
                "-CorrelationId '{correlationId}'").format(
                    hardwareGeneration=hardwareGeneration,
                    processorCount=processorCount,
                    parallelBenchmarksCount=parallelBenchmarksCount,
                    env=environment,
                    storageAccountKey=storageAccountKey,
                    benchmark=benchmark,
                    isBc=isBc,
                    instanceName=instanceName,
                    dbName=dbName,
                    threadNumber=threadNumber,
                    benchmarkScalingArgument=benchmarkScalingArgument,
                    bcInstallDir=bcInstallDir,
                    runtimeInMinutes=runtimeInMinutes,
                    warmupInMinutes=warmupInMinutes,
                    customMasterQuery="'{0}'".format(customMasterQuery) if customMasterQuery is not None else "$null",
                    skipRestore=not shouldRestore,
                    comment=comment,
                    scaledDown=scaledDown,
                    correlationId=correlationId,
                    loggingServerName=loggingServerName,
                    loggingDatabaseName=loggingDatabaseName,
                    loggingUsername=loggingUsername,
                    loggingPassword=loggingPassword,
                    instanceUsername=instanceUsername,
                    instancePassword=instancePassword
                )
    """
    Generates powershell command that needs to be executed inside docker, for the case when a benchmark is given by its ID.
    """
    @staticmethod
    def generatePowershellCommandWithBenchmarkId(scheduledBenchmarkId,
                                                 storageAccountKey,
                                                 bcInstallDir,
                                                 comment,
                                                 loggingServerName,
                                                 loggingDatabaseName,
                                                 loggingUsername,
                                                 loggingPassword,
                                                 instanceUsername,
                                                 instancePassword):
        return ("./scripts/performanceActions.ps1 "
                "-Action RunBenchmark "
                "-ScheduledBenchmarkId {scheduledBenchmarkId} "
                "-LoggingServerName '{loggingServerName}' "
                "-LoggingDatabaseName '{loggingDatabaseName}' "
                "-LoggingCredentials (New-Object System.Management.Automation.PSCredential ('{loggingUsername}', (echo '{loggingPassword}' | ConvertTo-SecureString -AsPlainText -Force))) "
                "-InstanceCredentials (New-Object System.Management.Automation.PSCredential ('{instanceUsername}', (echo '{instancePassword}' | ConvertTo-SecureString -AsPlainText -Force))) "
                "-StorageAccountKey '{storageAccountKey}' "
                "-BCInstallDir {bcInstallDir} "
                "-Comment '{comment}'").format(
                    scheduledBenchmarkId=scheduledBenchmarkId,
                    storageAccountKey=storageAccountKey,
                    bcInstallDir=bcInstallDir,
                    comment=comment,
                    loggingServerName=loggingServerName,
                    loggingDatabaseName=loggingDatabaseName,
                    loggingUsername=loggingUsername,
                    loggingPassword=loggingPassword,
                    instanceUsername=instanceUsername,
                    instancePassword=instancePassword
                )
    """
    Tries to create a service if there is enough resources
    """
    def tryCreateService(self, image):
        try:
            nodes = dockerWrapper.getNodes()
            services = dockerWrapper.getServices()

            # We only care about worker resources which are in ready state
            workerNodes = [node for node in nodes if node.role == "worker" and node.state == "ready"]

            # Rounding down the ammount of free CPU due to reservation of CPU. We allow 80% of CPU for the worker nodes.
            freeCPU, selectedNodeId = resourceManager.getMaxFreeCPU(workerNodes, services, 0.8)
            self.tracer.TraceInfo("available_cores", freeCPU)

            taskToExecute = self.orch.getNextTask(freeCPU)

            if taskToExecute is not None:
                self.tracer.TraceInfo(
                    "execute_task",
                    "Creating service: {0}".format(taskToExecute.required_processor_count))

                dockerCommand = BenchmarkServiceGenerator.generateDockerCommand(
                    taskToExecute,
                    self.environment,
                    self.storageAccountKey,
                    self.loggingServerName,
                    self.loggingDatabaseName,
                    self.loggingUsername,
                    self.loggingPassword,
                    self.instanceUsername,
                    self.instancePassword
                )

                # Services cannot contain dots
                serviceName=taskToExecute.server_name[:taskToExecute.server_name.index(".")]
                self.orch.createService(image,
                                        dockerCommand,
                                        taskToExecute.required_processor_count,
                                        serviceName,
                                        taskToExecute.server_name,
                                        selectedNodeId)
            else:
                self.tracer.TraceInfo("execute_task", "No task found")
        except Exception as e:
            self.tracer.TraceException("create_service_failure", "Failed to create service", str(e))
            if taskToExecute is not None:
                self.orch.updateInstanceStatesToReady([taskToExecute.server_name])

    """
    Tries to delete services if they are finished
    """
    def tryDeleteServices(self):
        try:
            services = dockerWrapper.getServices()
            return self.orch.removeFinishedServices(services)
        except Exception as e:
            self.tracer.TraceException("try_delete_services_failure", "Failed to delete services", str(e))

    """
    Updates instance states to ready (for services which are finished)
    """
    def updateInstanceStatesToReady(self, removedServices):
        if (removedServices is not None):
            try:
                instance_names = [removedService.labels.get("instance_name") for removedService in removedServices]
                self.orch.updateInstanceStatesToReady(instance_names)
            except Exception as e:
                self.tracer.TraceException("update_instance_states_to_ready_failure", "Failed to update instance states to ready", str(e))