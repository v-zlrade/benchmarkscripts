using System;
using System.Collections.Generic;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using SuchGreatDiskStressTool;

namespace SuchGreatDiskTestingToolTest
{
    [TestClass]
    public class DiskSpdManagerTest
    {
        [TestMethod]
        public void TestComputeAffinityParameters()
        {
            DiskSpdManager manager = new DiskSpdManager(1, 40);

            Assert.AreEqual("g0,0,1,2,3,4,5,6,7", manager.ComputeAffinityParameters(8, 0, 0, null));
            Assert.AreEqual("g0,32,33,34,35,36,37,38,39", manager.ComputeAffinityParameters(8, 0, 32, null));

            manager = new DiskSpdManager(10, 1);
            Assert.AreEqual("g0,0,g1,0,g2,0,g3,0,g4,0,g5,0,g6,0,g7,0", manager.ComputeAffinityParameters(8, 0, 0, null));
            Assert.AreEqual("g9,0", manager.ComputeAffinityParameters(1, 0, 9, null));

            manager = new DiskSpdManager(2, 5);
            Assert.AreEqual("g0,4,g1,0,1,2", manager.ComputeAffinityParameters(4, 0, 4, null));
        }

        [TestMethod]
        public void TestComputeOptionParameters()
        {
            // parameters dont really matter here
            DiskSpdManager manager = new DiskSpdManager(1, 40);

            Dictionary<string, string> expectedValue1 = new Dictionary<string, string>()
            {
                { "-w", "23" },
                { "-t", "1" },
                { "-g", manager.MBpsToBpms(101).ToString() },
                { "-d", "100" },
                { "-o", "12" },
                { "-si", "" },
                { "-b", "1024K" },
                { "-Sh", "" },
                { "-L", "" },
                { "-c", "55G" },
                { "-a", "g0,0,g1,2,g2,3" },
                { "-R", "xml" }
            };

            Dictionary<string, string> expectedValue2 = new Dictionary<string, string>()
            {
                { "-w", "22" },
                { "-t", "3" },
                { "-g", manager.MBpsToBpms(101).ToString() },
                { "-d", "123" },
                { "-o", "111" },
                { "-r", "" },
                { "-b", "10K" },
                { "-Sh", "" },
                { "-L", "" },
                { "-c", "165G" },
                { "-a", "g0,0,1,2,3" },
                { "-R", "xml" }
            };

            CompareDictionararies(expectedValue1, manager.ComputeOptionParameters(23, 101, 1, 100, 12, true, 1024, 55, "g0,0,g1,2,g2,3"));

            CompareDictionararies(expectedValue2, manager.ComputeOptionParameters(22, 303, 3, 123, 111, false, 10, 165, "g0,0,1,2,3"));
        }

        [TestMethod]
        public void TestMBpsToBpms()
        {
            // parameters dont really matter here
            DiskSpdManager manager = new DiskSpdManager(1, 40);

            long oneMBpsToBpms = Convert.ToInt64(1024.00 * 1024.00 / 1000);
            long twentyMBpsToBpms = Convert.ToInt64(20.00 * 1024 * 1024 / 1000);

            Assert.AreEqual(oneMBpsToBpms, manager.MBpsToBpms(1));
            Assert.AreEqual(twentyMBpsToBpms, manager.MBpsToBpms(20));
        }

        private void CompareDictionararies(Dictionary<string, string> expected, Dictionary<string, string> actual)
        {
            foreach (var entry in expected)
            {
                Assert.AreEqual(entry.Value, actual[entry.Key], string.Format("{0} key values don't match", entry.Key));
            }

            foreach (var entry in actual)
            {
                Assert.AreEqual(expected[entry.Key], entry.Value, string.Format("{0} key values don't match", entry.Key));
            }
        }
    }
}
