using Newtonsoft.Json;
using SuchGreatDiskTestingTool.Configuration;
using System.IO;

namespace SuchGreatDiskTestingTool
{
    public class ConfigurationManager
    {
        private static ConfigurationManager _instance;

        public static ConfigurationManager Instance
        {
            get
            {
                if (_instance == null)
                {
                    _instance = new ConfigurationManager();
                }

                return _instance;
            }
        }

        private ConfigurationManager()
        {
            //
        }

        public JobsConfig ParseJobsConfig(string configPath)
        {
            return JsonConvert.DeserializeObject<JobsConfig>(File.ReadAllText(configPath));
        }
    }
}
