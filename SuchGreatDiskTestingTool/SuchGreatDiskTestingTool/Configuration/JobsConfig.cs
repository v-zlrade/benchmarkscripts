using System.Collections.Generic;

namespace SuchGreatDiskTestingTool.Configuration
{
    public class JobsConfig
    {
        public string Name;

        public int NumOfCpuGroups;

        public int NumOfCpusPerGroup;

        public string DiskspdPath;

        public int TestDurationSeconds;

        public int FileSizePerCoreGb;

        public string OutputDirectory;

        public IEnumerable<JobConfig> Jobs { get; set; }
    }
}
