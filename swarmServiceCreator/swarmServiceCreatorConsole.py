import argparse
import time
from benchmarkServiceGenerator import BenchmarkServiceGenerator


parser = argparse.ArgumentParser(description="Swarm service creator")

parser.add_argument("--instanceUsername",
                    "-U",
                    nargs='?',
                    type=str,
                    required=True,
                    help="SUT instance username")

parser.add_argument("--instancePassword",
                    "-P",
                    nargs='?',
                    type=str,
                    required=True,
                    help="SUT instance password")

parser.add_argument("--loggingPassword",
                    "-p",
                    nargs='?',
                    type=str,
                    required=True,
                    help="Logging database password")

parser.add_argument("--storageAccountKey",
                    "-s",
                    nargs='?',
                    type=str,
                    required=True,
                    help="Storage account key")

parser.add_argument("--environment",
                    "-e",
                    nargs='?',
                    type=str,
                    required=True,
                    help="Environment")

parser.add_argument("--loggingServer",
                    "-l",
                    nargs='?',
                    default="clperf.database.windows.net",
                    type=str,
                    required=False,
                    help="Full DNS name of loggging server")

parser.add_argument("--loggingDatabase",
                    "-d",
                    nargs='?',
                    default="clperftesting",
                    type=str,
                    required=False,
                    help="Logging database name")

parser.add_argument("--loggingUsername",
                    "-u",
                    nargs='?',
                    default="clperf",
                    type=str,
                    required=False,
                    help="Logging database username")

parser.add_argument("--image",
                    "-i",
                    nargs='?',
                    default="clperftesting.azurecr.io/perftesting",
                    type=str,
                    required=False,
                    help="docker image")


args = parser.parse_args()

loggingServer = args.loggingServer
loggingDatabase = args.loggingDatabase
loggingUsername = args.loggingUsername
loggingPassword = args.loggingPassword
instanceUsername = args.instanceUsername
instancePassword = args.instancePassword
storageAccountKey = args.storageAccountKey
environment = args.environment
image = args.image

benchmarkServiceGenerator = BenchmarkServiceGenerator(
    loggingServer,
    loggingDatabase,
    loggingUsername,
    loggingPassword,
    instanceUsername,
    instancePassword,
    storageAccountKey,
    environment
)

while True:
    try:
        removedServices = benchmarkServiceGenerator.tryDeleteServices()
        benchmarkServiceGenerator.updateInstanceStatesToReady(removedServices)
        benchmarkServiceGenerator.tryCreateService(image)
        time.sleep(60)
    except Exception as e:
        print("Exception happened: Error %s" % (str(e)))
