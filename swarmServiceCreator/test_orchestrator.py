from orchestrator import Orchestrator
from tracer import TestTracer
import dockerWrapper

def CounterWrapper(object):
    def __init__(self):
        self.counter = 0


def test_removeFinishedServices():
    orch = Orchestrator('svr', 'db', 'u', 'pw', 'test', TestTracer())

    counterWrapper = CounterWrapper

    def incrementCounter(counterWrapper):
        counterWrapper.counter = counterWrapper.counter + 1

    toRemove = {'instance_name':'instance name label of a service which should be removed'}
    notToRemove = {'instance_name':'instance name label of a service which should not be removed'}

    testExamples = [
        ([dockerWrapper.ClusterService('n1', 1, 'id1', 'ready', lambda: incrementCounter(counterWrapper), notToRemove),
          dockerWrapper.ClusterService('n1', 1, 'id1', 'complete', lambda: incrementCounter(counterWrapper), toRemove),
          dockerWrapper.ClusterService('n1', 1, 'id1', 'ready', lambda: incrementCounter(counterWrapper), notToRemove),
          dockerWrapper.ClusterService('n1', 1, 'id1', 'rejected', lambda: incrementCounter(counterWrapper), toRemove),
          dockerWrapper.ClusterService('n1', 1, 'id1', 'complete', lambda: incrementCounter(counterWrapper), toRemove),
          dockerWrapper.ClusterService('n1', 1, 'id1', 'orphaned', lambda: incrementCounter(counterWrapper), toRemove),
          dockerWrapper.ClusterService('n1', 1, 'id1', 'shutdown', lambda: incrementCounter(counterWrapper), toRemove),
          dockerWrapper.ClusterService('n1', 1, 'id1', 'failed', lambda: incrementCounter(counterWrapper), toRemove)],
         6),
        ([dockerWrapper.ClusterService('n1', 1, 'id1', 'ready', lambda: incrementCounter(counterWrapper), notToRemove),
          dockerWrapper.ClusterService('n1', 1, 'id1', 'ready', lambda: incrementCounter(counterWrapper), notToRemove),
          dockerWrapper.ClusterService('n1', 1, 'id1', 'ready', lambda: incrementCounter(counterWrapper), notToRemove),
          dockerWrapper.ClusterService('n1', 1, 'id1', 'ready', lambda: incrementCounter(counterWrapper), notToRemove),
          dockerWrapper.ClusterService('n1', 1, 'id1', 'ready', lambda: incrementCounter(counterWrapper), notToRemove)],
         0),
        ([dockerWrapper.ClusterService('n1', 1, 'id1', 'complete', lambda: incrementCounter(counterWrapper), toRemove),
          dockerWrapper.ClusterService('n1', 1, 'id1', 'complete', lambda: incrementCounter(counterWrapper), toRemove),
          dockerWrapper.ClusterService('n1', 1, 'id1', 'complete', lambda: incrementCounter(counterWrapper), toRemove),
          dockerWrapper.ClusterService('n1', 1, 'id1', 'complete', lambda: incrementCounter(counterWrapper), toRemove),
          dockerWrapper.ClusterService('n1', 1, 'id1', 'complete', lambda: incrementCounter(counterWrapper), toRemove)],
         5),
        ([], 0)
    ]

    for testExample in testExamples:
        counterWrapper.counter = 0
        removedServices = orch.removeFinishedServices(testExample[0])
        assert len(removedServices) == testExample[1]
        assert len(removedServices) == counterWrapper.counter
        for removedService in removedServices:
            assert removedService.labels.get('instance_name') == toRemove.get('instance_name')
