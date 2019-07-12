namespace SuchGreatDiskTestingTool.Configuration
{
    public class JobConfig
    {
        public int NumberOfCores { get; set; }
        public int BandwithLimitMb { get; set; }
        public int OutstandingIOPerCpu { get; set; }
        public bool SequentialIO { get; set; }
        public int IOSizeKb { get; set; }
        public int WritePercentage { get; set; }
        public string Name { get; set; }

        public string TargetFile { get; set; }
    }
}
