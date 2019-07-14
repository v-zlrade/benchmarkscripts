using SuchGreatDiskStressTool;
using System;
using System.Diagnostics;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using SuchGreatDiskTestingTool.Configuration;
using System.IO;

namespace SuchGreatDiskTestingTool
{
    public class SuchGreatDiskTestingToolMain
    {
        static void Main(string[] args)
        {
            if (args.Length < 1)
            {
                throw new Exception("Need to pass path to configuration!");
            }

            Console.WriteLine("Parsing configuration from path: {0}", args[0]);

            JobsConfig jobs = ConfigurationManager.Instance.ParseJobsConfig(args[0]);

            Console.Write(string.Format(@"
                Test Name: {0},
                Test duration: {1},
                DiskSpd path: {2},
                FileSizePerCoreGb: {3},
                NumOfCpusPerGroup: {4},
                NumOfCpuGroups: {5},
                Output directory: {6}
            ", jobs.Name, jobs.TestDurationSeconds, jobs.DiskspdPath, jobs.FileSizePerCoreGb,
               jobs.NumOfCpusPerGroup, jobs.NumOfCpuGroups, jobs.OutputDirectory));

            DiskSpdManager diskSpdManager = new DiskSpdManager(jobs.NumOfCpuGroups, jobs.NumOfCpusPerGroup, jobs.DiskspdPath);

            // Create output folder if one does not exist
            if (!Directory.Exists(jobs.OutputDirectory))
            {
                Directory.CreateDirectory(jobs.OutputDirectory);
            }

            List<DiskSpdJob> diskSpdJobs = diskSpdManager.CreateDiskSpdArguments(jobs);

            foreach (var diskSpdJob in diskSpdJobs) { Console.WriteLine(diskSpdJob.Arguments); }

            DateTime currentTimestamp = DateTime.UtcNow;
                
            Parallel.ForEach(diskSpdJobs, new ParallelOptions() { MaxDegreeOfParallelism = diskSpdJobs.Count() },
                (job) =>
                {
                    using (var process = StartProcess(jobs.DiskspdPath, job.Arguments))
                    {
                        string standardOutput = process.StandardOutput.ReadToEnd();

                        File.AppendAllText($"{jobs.OutputDirectory}\\{job.Job.Name}-{currentTimestamp.ToString("yyyyMMddHHmm")}.xml", standardOutput);
                    }

                    diskSpdManager.Cleanup(job.Job);
                });

            // At the end noone is going to look at XML so convert to CSV
            diskSpdManager.ParseFilesToCsv(jobs.OutputDirectory, jobs.Name);
        }

        public static Process StartProcess(string processName, string arguments)
        {
            ProcessStartInfo startInfo = new ProcessStartInfo();
            startInfo.FileName = processName;
            startInfo.UseShellExecute = false;
            startInfo.CreateNoWindow = true;
            startInfo.RedirectStandardOutput = true;
            startInfo.Arguments = arguments;

            return Process.Start(startInfo);
        }
    }
}
