using SuchGreatDiskTestingTool.Configuration;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml;

namespace SuchGreatDiskStressTool
{
    public class DiskSpdManager
    {
        private int totalOccupiedCpus;

        private readonly int groupCount;

        private readonly int cpusPerGroup;

        private readonly int totalAvailableCpus;

        private readonly string diskSpdPath;

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="groupCount">Number of NUMA nodes</param>
        /// <param name="cpusPerGroup">Number of CPUs per NUMA node</param>
        /// <param name="diskSpdPath">Path to diskspd executable</param>
        public DiskSpdManager(int groupCount, int cpusPerGroup, string diskSpdPath = "E:\\workspace\\diskspd\\bat\\diskspd.exe")
        {
            this.groupCount = groupCount;
            this.cpusPerGroup = cpusPerGroup;
            this.totalOccupiedCpus = 0;
            this.totalAvailableCpus = cpusPerGroup * groupCount;
            this.diskSpdPath = diskSpdPath;
        }

        /// <summary>
        /// Computes affinity parameters - recursive helper function
        /// </summary>
        /// <param name="cpuCount">Number of CPUs to allocate</param>
        /// <param name="groupNumber">Group to assigns CPUs to</param>
        /// <param name="occupiedCpus">Number of currently occupied CPUs</param>
        /// <param name="diskSpdAffinityParameter">Current affinization</param>
        /// <returns>Affinization as diskspd can understand it e.g. "g0,1,2,3,g1,0,1"</returns>
        public string ComputeAffinityParameters(int cpuCount, int groupNumber, int occupiedCpus, string diskSpdAffinityParameter)
        {
            // terminal condition for recursion
            // we have allocated all needed Cpus
            if (cpuCount <= 0)
            {
                return diskSpdAffinityParameter;
            }

            if (groupNumber >= groupCount)
            {
                throw new Exception("No CPUs available");
            }

            // we are occupying groups serialy so we can simply calculate remaining CPUs
            int occupiedCpusInGivenGroup = occupiedCpus - groupNumber * cpusPerGroup;
            int remainingCpusInGivenGroup = Math.Max(0, cpusPerGroup - occupiedCpusInGivenGroup);
            int cpusToOccupyInThisGroup = Math.Min(remainingCpusInGivenGroup, cpuCount);

            // try to fit to first available group
            if (cpusToOccupyInThisGroup > 0)
            {
                string cpusInThisGroup = String.Join(
                    ",", 
                    Enumerable.Range(occupiedCpusInGivenGroup, cpusToOccupyInThisGroup)
                        .Select(x => x.ToString()));

                string diskSpdInThisGroup = String.Format("g{0},{1}", groupNumber, cpusInThisGroup);

                // If this is first parameter we don't want to add comma
                if (string.IsNullOrWhiteSpace(diskSpdAffinityParameter))
                {
                    diskSpdAffinityParameter = diskSpdInThisGroup;
                }
                else
                {
                    diskSpdAffinityParameter = string.Format("{0},{1}", diskSpdAffinityParameter, diskSpdInThisGroup);
                }
            }
           
            return ComputeAffinityParameters(cpuCount - cpusToOccupyInThisGroup, groupNumber + 1, occupiedCpus + cpusToOccupyInThisGroup, diskSpdAffinityParameter);
        }

        /// <summary>
        /// Computes parameter for affinization
        /// </summary>
        /// <param name="cpuCount">Number of cores to allocate</param>
        /// <returns>DiskSpd formatted affinization parameter - e.b. "g0,1,2,3,g1,0,1"</returns>
        public string ComputeAffinityParameters(int cpuCount)
        {
            string result = ComputeAffinityParameters(cpuCount, 0, totalOccupiedCpus, "");
            totalOccupiedCpus += cpuCount;

            return result;
        }

        /// <summary>
        /// Computes DiskSpdParameters
        /// </summary>
        /// <param name="jobs">Jobs to convert to diskspd parameters</param>
        /// <returns>List of DiskSpdJobs with arguments and job reference</returns>
        public List<DiskSpdJob> CreateDiskSpdArguments(JobsConfig jobs)
        {
            return new List<DiskSpdJob>(jobs.Jobs.Select(job => 
                new DiskSpdJob(
                    job, 
                    ComputeDiskSpdParameters(job, jobs.TestDurationSeconds, jobs.FileSizePerCoreGb))));
        }

        /// <summary>
        /// Cleanup diskspd generated files
        /// </summary>
        /// <param name="job">Job to cleanup</param>
        public void Cleanup(JobConfig job)
        {
            File.Delete(job.TargetFile);
        }

        /// <summary>
        /// Computes diskspd parameters from job
        /// </summary>
        /// <param name="job">Job</param>
        /// <param name="duration">Duration of test</param>
        /// <param name="targetFile">Target file</param>
        /// <returns></returns>
        public string ComputeDiskSpdParameters(JobConfig job, int duration, int fileSizePerCore)
        {
            var optionsDictionary = ComputeOptionParameters(
                job.WritePercentage,
                job.BandwithLimitMb,
                job.NumberOfCores,
                duration,
                job.OutstandingIOPerCpu,
                job.SequentialIO,
                job.IOSizeKb,
                fileSizePerCore * job.NumberOfCores,
                ComputeAffinityParameters(job.NumberOfCores));

            string optionParameters = String.Join(" ", optionsDictionary.ToArray().Select(x => x.Key + x.Value));
            return string.Format("{0} {1}", optionParameters, job.TargetFile);
        }

        /// <summary>
        /// Generates string with parameters diskspd can understand
        /// </summary>
        /// <param name="writePercentage">What percentage of IO should be write</param>
        /// <param name="bandwithLimitMb">What should be maximum throughput achieved by this diskspd instance</param>
        /// <param name="numThreads">Number of threads of diskspd instance</param>
        /// <param name="duration">Duration of test</param>
        /// <param name="outstandingIoCount">Number of oustanding IOs per thread</param>
        /// <param name="serialAccess">Should access be serial ?</param>
        /// <param name="ioSizeKb">What is IO size ?</param>
        /// <param name="fileSizeGb">File size to target</param>
        /// <param name="diskSpdCpuAffinitization">
        /// Affinitization as diskspd can understand it
        ///  e.g. - g0,1,2,3,g1,0,1
        /// </param>
        /// <returns></returns>
        public Dictionary<string, string> ComputeOptionParameters(
            int writePercentage,
            long bandwithLimitMb,
            int numThreads,
            int duration,
            int outstandingIoCount,
            bool serialAccess,
            int ioSizeKb,
            int fileSizeGb,
            string diskSpdCpuAffinitization)
        {
            Dictionary<string, string> diskSpdParameters = new Dictionary<string, string>();

            // limit is in MiB/s and we need B/ms per thread
            long bytesPerMs = Convert.ToInt64(MBpsToBpms(bandwithLimitMb) / numThreads);

            diskSpdParameters["-g"] = bytesPerMs.ToString();
            diskSpdParameters["-d"] = duration.ToString();
            diskSpdParameters["-t"] = numThreads.ToString();
            diskSpdParameters["-o"] = outstandingIoCount.ToString();
            diskSpdParameters["-w"] = writePercentage.ToString();
            diskSpdParameters["-b"] = string.Format("{0}K", ioSizeKb);
            diskSpdParameters["-a"] = diskSpdCpuAffinitization;
            diskSpdParameters["-c"] = string.Format("{0}G", fileSizeGb);

            if (serialAccess)
            {
                diskSpdParameters["-si"] = "";
            }
            else
            {
                diskSpdParameters["-r"] = "";
            }

            // no software and hardware caching
            diskSpdParameters["-Sh"] = "";
            // TODO: Don't know what this parameters means update comment
            diskSpdParameters["-L"] = "";
            diskSpdParameters["-R"] = "xml";

            return diskSpdParameters;
        }

        public long MBpsToBpms(long MBps)
        {
            return Convert.ToInt64(1.0 * MBps * 1024 * 1024 / 1000);
        }

        /// <summary>
        /// Parses all diskspd output files in current folder
        /// and writes them to csv format
        /// </summary>
        /// <param name="folder">name of folder where files can be found</param>
        /// <param name="name">output file name</param>
        public void ParseFilesToCsv(string folder, string name)
        {
            StringBuilder sb = new StringBuilder();
            sb.AppendLine("File Path,File size GiB,Duration,Block size KiB,Write ratio, Is Sequential,Threads,Outstanding IO,Write MiB/s, Read MiB/s, Total MiB/s, Read IOPS, Write IOPS, Total IOPS, Average latency, Latency STDEV, 95th pc latency");

            foreach (var file in Directory.GetFiles(folder))
            {
                try
                {
                    XmlDocument doc = new XmlDocument();
                    doc.Load(file);
                    XmlElement root = doc.DocumentElement;

                    // info about test parameters
                    // we always have single target
                    string filePath = root.SelectSingleNode("//Targets/Target/Path").InnerText;
                    long fileSizeGiB = Int64.Parse(root.SelectSingleNode("//Targets/Target/FileSize").InnerText) / 1024 / 1024 / 1024;
                    int duration = Int32.Parse(root.SelectSingleNode("//Duration").InnerText);
                    long blockSizeKiB = Int64.Parse(root.SelectSingleNode("//Targets/Target/BlockSize").InnerText) / 1024;
                    int writeRatio = Int32.Parse(root.SelectSingleNode("//Targets/Target/WriteRatio").InnerText);
                    bool isSequentialIO = root.SelectSingleNode("//StrideSize") != null;
                    long threadsPerFile = Int64.Parse(root.SelectSingleNode("//Targets/Target/ThreadsPerFile").InnerText);
                    long outstandingIoCount = Int64.Parse(root.SelectSingleNode("//Targets/Target/RequestCount").InnerText);

                    // result parsing
                    double actualDuration = root.SelectNodes("//TestTimeSeconds").Cast<XmlNode>().Sum(x => double.Parse(x.InnerText));
                    long byteCount = root.SelectNodes("//BytesCount").Cast<XmlNode>().Sum(x => Int64.Parse(x.InnerText));
                    long writeBytes = root.SelectNodes("//WriteBytes").Cast<XmlNode>().Sum(x => Int64.Parse(x.InnerText));
                    long readBytes = root.SelectNodes("//ReadBytes").Cast<XmlNode>().Sum(x => Int64.Parse(x.InnerText));
                    long rioCount = root.SelectNodes("//ReadCount").Cast<XmlNode>().Sum(x => Int64.Parse(x.InnerText));
                    long wioCount = root.SelectNodes("//WriteCount").Cast<XmlNode>().Sum(x => Int64.Parse(x.InnerText));
                    long ioCount = root.SelectNodes("//IOCount").Cast<XmlNode>().Sum(x => Int64.Parse(x.InnerText));

                    double writeMiBps = writeBytes / 1024.00 / 1024.00 / actualDuration;
                    double readMiBps = readBytes / 1024.00 / 1024.00 / actualDuration;
                    double totalMiBps = byteCount / 1024.00 / 1024.00 / actualDuration;
                    double riops = rioCount / actualDuration;
                    double wiops = wioCount / actualDuration;
                    double iops = ioCount / actualDuration;
                    double latencyAverage = Double.Parse(root.SelectSingleNode("//Latency/AverageTotalMilliseconds").InnerText);
                    double latencyStdev = Double.Parse(root.SelectSingleNode("//Latency/LatencyStdev").InnerText);

                    var node95thPc = root
                        .SelectNodes("//Bucket/Percentile")
                        .Cast<XmlNode>()
                        .Where(x => x.InnerText == "95")
                        .First()
                        .ParentNode;

                    double latency95thPc =
                        Double.Parse(node95thPc
                            .ChildNodes
                            .Cast<XmlNode>()
                            .Where(x =>
                                x.Name.Equals("TotalMilliseconds", StringComparison.InvariantCultureIgnoreCase))
                            .First()
                            .InnerText);


                    sb.AppendLine($"{filePath},{fileSizeGiB},{duration},{blockSizeKiB},{writeRatio},{isSequentialIO},{threadsPerFile},{outstandingIoCount},{writeMiBps},{readMiBps},{totalMiBps},{riops},{wiops},{iops},{latencyAverage},{latencyStdev},{latency95thPc}");
                }
                catch (Exception ex)
                {

                }
            }

            File.AppendAllText($"{folder}\\{name}.csv", sb.ToString());
        }
    }

    /// <summary>
    /// Helper class
    /// </summary>
    public class DiskSpdJob
    {
        public JobConfig Job { get; set; }
         
        public string Arguments { get; set; }

        public DiskSpdJob(JobConfig job, string arguments)
        {
            Job = job;
            Arguments = arguments;
        }
    }
}
