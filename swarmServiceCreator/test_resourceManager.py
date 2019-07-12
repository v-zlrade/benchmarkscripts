import dockerWrapper
import resourceManager


def test_getMaxFreeCPU():
    testSet = [
        (
            # n1 4 CPUs 1 Occupied, n2 2 CPUs 0 Occupied, n3 22 CPUS 15 Occupied, n4 22 CPUs 11 Occupied
            [dockerWrapper.ClusterNode('worker', 4, 'n1', 'ready'),
             dockerWrapper.ClusterNode('worker', 2, 'n2', 'ready'),
             dockerWrapper.ClusterNode('worker', 22, 'n3', 'ready'),
             dockerWrapper.ClusterNode('worker', 22, 'n4', 'ready')],
            [dockerWrapper.ClusterService('s1', 1, 'n1', 'ready', lambda: None, {'dummyLabel':'dummyLabelValue'}),
             dockerWrapper.ClusterService('s2', 2, 'n4', 'complete', lambda: None, {'dummyLabel':'dummyLabelValue'}),
             dockerWrapper.ClusterService('s3', 15, 'n3', 'ready', lambda: None, {'dummyLabel':'dummyLabelValue'}),
             dockerWrapper.ClusterService('s4', 3, 'n4', 'ready', lambda: None, {'dummyLabel':'dummyLabelValue'}),
             dockerWrapper.ClusterService('s5', 6, 'n4', 'complete', lambda: None, {'dummyLabel':'dummyLabelValue'})],
            0.8,
            6,
            'n4'
        ),
        # No nodes exist - should return 0
        (
            [],
            [dockerWrapper.ClusterService('s1', 1, 'n1', 'ready', lambda: None, {'dummyLabel':'dummyLabelValue'}),
             dockerWrapper.ClusterService('s2', 2, 'n1', 'complete', lambda: None, {'dummyLabel':'dummyLabelValue'}),
             dockerWrapper.ClusterService('s3', 15, 'n1', 'ready', lambda: None, {'dummyLabel':'dummyLabelValue'}),
             dockerWrapper.ClusterService('s4', 3, 'n1', 'ready', lambda: None, {'dummyLabel':'dummyLabelValue'}),
             dockerWrapper.ClusterService('s5', 6, 'n1', 'complete', lambda: None, {'dummyLabel':'dummyLabelValue'})],
            0.3,
            0,
            ''
        ),
        # All nodes have 7 CPUs and only one node has no service assigned - check if we will fetch it
        (
            [dockerWrapper.ClusterNode('worker', 7, 'n1', 'ready'),
             dockerWrapper.ClusterNode('worker', 7, 'n2', 'ready'),
             dockerWrapper.ClusterNode('worker', 7, 'n3', 'ready'),
             dockerWrapper.ClusterNode('worker', 7, 'n4', 'ready')],
            [dockerWrapper.ClusterService('s1', 1, 'n1', 'ready', lambda: None, {'dummyLabel':'dummyLabelValue'}),
             dockerWrapper.ClusterService('s2', 2, 'n2', 'complete', lambda: None, {'dummyLabel':'dummyLabelValue'}),
             dockerWrapper.ClusterService('s3', 2, 'n3', 'ready', lambda: None, {'dummyLabel':'dummyLabelValue'})],
            0.4,
            2,
            'n4'
        )
    ]

    for testExample in testSet:
        retVals = resourceManager.getMaxFreeCPU(testExample[0], testExample[1], testExample[2])
        freeCPU = retVals[0]
        selectedNodeID = retVals[1]

        assert freeCPU == testExample[3]
        assert selectedNodeID == testExample[4]