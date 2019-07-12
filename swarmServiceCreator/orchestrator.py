import pyodbc
import dockerWrapper
import docker
from docker.types import ServiceMode, RestartPolicy, Resources
import json


"""
Orchestration class
"""
class Orchestrator(object):
    def __init__(self,
                 server,
                 database,
                 username,
                 password,
                 environment,
                 tracer):
        self.environment = environment
        self.connectionString = "DRIVER={0};SERVER={1};DATABASE={2};UID={3};PWD={4}".format(
            "{ODBC Driver 13 for SQL Server}",
            server,
            database,
            username,
            password
        )
        self.tracer = tracer

    """
    Gets next available task to execute based on available resources
    """
    def getNextTask(self, processorCount):
        connection = pyodbc.connect(self.connectionString)
        cursor = connection.cursor()
        cursor.execute("EXEC get_next_action @available_cores = ?, @environment = ?", processorCount, self.environment)

        try:
            row = cursor.fetchone()
        except pyodbc.ProgrammingError:
            row = None

        connection.commit()
        cursor.close()
        connection.close()

        return row

    """
    Create service
    """
    def createService(self, image, command, cpuRequirments, name, instance_name, selectedNodeId):
        self.tracer.TraceInfo(
            "create_service",
            "Command: {0}, CpuUsage: {1}".format(command, cpuRequirments))

        labels = {"instance_name": instance_name}
        dockerWrapper.createService(image, command, cpuRequirments, name, labels, selectedNodeId)

        self.tracer.TraceInfo(
            "node_cpu_allocation",
            json.dumps(dict(NodeId=selectedNodeId, CpuCount=cpuRequirments)))

    """
    Remove finished services
    """
    def removeFinishedServices(self, services):
        self.tracer.TraceInfo(
            "remove_finished_services",
            "Removing old services")

        servicesToRemove = [service for service in services
                            if service.state in ('complete', 'failed', 'shutdown', 'rejected', 'orphaned')]

        for serviceToRemove in servicesToRemove:
            serviceToRemove.remove()
            self.tracer.TraceInfo(
                "node_cpu_deallocation",
                json.dumps(dict(NodeId=serviceToRemove.nodeId, CpuCount=serviceToRemove.cpu, State=serviceToRemove.state)))

        return servicesToRemove

    """
    Updates instance states to ready
    """
    def updateInstanceStatesToReady(self, instance_names):
        self.tracer.TraceInfo(
            "update_instance_states_to_ready",
            "Updating " + str(len(instance_names)) + " instance states to ready")

        connection = pyodbc.connect(self.connectionString)
        cursor = connection.cursor()

        for instance_name in instance_names:
            cursor.execute("EXEC upsert_instance @instance_name = ?, @state = ?", instance_name, "Ready")

        connection.commit()
        cursor.close()
        connection.close()