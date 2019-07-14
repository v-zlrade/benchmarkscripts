import docker
from docker.types import ServiceMode, RestartPolicy, Resources


"""
Docker service wrapper
"""
class ClusterService(object):
    def __init__(self,
                 name,
                 cpu,
                 nodeId,
                 state,
                 removalFunction,
                 labels):
        self.name = name
        self.removalFunction = removalFunction

        # Our services have only 1 replica = 1 task
        self.cpu = cpu
        self.nodeId = nodeId
        self.state = state
        self.labels = labels

    def remove(self):
        self.removalFunction()


"""
Docker node wrapper
"""
class ClusterNode(object):
    def __init__(self,
                 role,
                 cpu,
                 id,
                 state):
        self.role = role
        self.cpu = cpu
        self.id = id
        self.state = state


"""
Gets all services
"""
def getServices():
    """
    Convert docker service to our wrapper class
    """
    def __convertDockerService__(service):
        name = service.name

        tasks = service.tasks()

        # Our services have only 1 replica = 1 task
        cpu = tasks[0]['Spec']['Resources']['Reservations']['NanoCPUs'] / 1000000000
        nodeId = tasks[0]['NodeID'] if "NodeID" in tasks[0] else "-1"
        state = tasks[0]['Status']['State']
        labels = {"instance_name": service.attrs['Spec']['Labels']['instance_name']}

        return ClusterService(name, cpu, nodeId, state, service.remove, labels)

    client = docker.from_env()

    return list(map(__convertDockerService__, client.services.list()))


"""
Get nodes from our cluster
"""
def getNodes():
    client = docker.from_env()

    return [ClusterNode(node.attrs['Spec']['Role'],
                        node.attrs['Description']['Resources']['NanoCPUs'] / 1000000000,
                        node.attrs['ID'],
                        node.attrs['Status']['State'])
            for node in client.nodes.list()]


"""
Creates service in cluster
"""
def createService(image, command, cpuRequirments, name, labels, selectedNodeId):
    client = docker.from_env()
    cpuRequirmentsInNanoSeconds = cpuRequirments * 1000000000

    client.services.create(
        image,
        command,
        constraints=["node.role == worker", "node.id == " + selectedNodeId],
        mode=ServiceMode("replicated", 1),
        restart_policy=RestartPolicy(condition='none'),
        resources=Resources(cpu_reservation=cpuRequirmentsInNanoSeconds),
        name=name,
        labels = {"instance_name": labels.get("instance_name")},
        hostname = selectedNodeId
    )


"""
Remove service from cluster
"""
def removeService(service):
    service.remove()
