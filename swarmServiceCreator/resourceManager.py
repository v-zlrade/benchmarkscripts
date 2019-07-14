import functools

"""
Gets maximum available CPU from all nodes
"""
def getMaxFreeCPU(nodes, services, allowedCPUratio):
    def __aggregateHelper__(aggregatedValue, currentValue):
        if currentValue['id'] in aggregatedValue:
            aggregatedValue[currentValue['id']] += currentValue['cpus']
        else:
            aggregatedValue[currentValue['id']] = currentValue['cpus']

        return aggregatedValue

    serviceMap = [{'id': service.nodeId, 'cpus': service.cpu}
                  for service in services]

    usedCPUsPerUsedNodeMap = functools.reduce(__aggregateHelper__, serviceMap, {})
    maxFreeCPU = 0
    selectedNodeId = ''

    for node in nodes:
        if allowedCPUratio * node.cpu - usedCPUsPerUsedNodeMap.get(node.id, 0) > maxFreeCPU:
            maxFreeCPU = allowedCPUratio * node.cpu - usedCPUsPerUsedNodeMap.get(node.id, 0)
            selectedNodeId = node.id

    return (int(maxFreeCPU), selectedNodeId)
