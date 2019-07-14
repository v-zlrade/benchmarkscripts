import pyodbc
import uuid
import datetime
from retry import retry


"""
Tracer class
"""
class Tracer(object):
    def __init__(self,
                 server,
                 database,
                 username,
                 password,
                 environment):
        self.environment = environment
        self.connectionString = "DRIVER={0};SERVER={1};DATABASE={2};UID={3};PWD={4}".format(
            "{ODBC Driver 13 for SQL Server}",
            server,
            database,
            username,
            password
        )
        self.correlationId = str(uuid.uuid4())

    """
    Informational trace
    """
    def TraceInfo(self, event_name, event_message):
        print("timestamp: %s, event_name: %s, event_message: %s" % (str(datetime.datetime.utcnow().strftime("%d.%m.%Y %H:%M:%S")), event_name, event_message))

        try:
            self.__TraceWithRetries__(3, event_name, event_message)
        except Exception as e:
            print("Failed to log message. Error %s" % (str(e)))

    """
    Error tracing
    """
    def TraceException(self, event_name, event_message, stack_trace):
        print("timestamp: %s, event_name: %s, event_message: %s, stack_trace: %s" % (str(datetime.datetime.utcnow().strftime("%d.%m.%Y %H:%M:%S")), event_name, event_message, stack_trace))

        try:
            self.__TraceWithRetries__(1, event_name, event_message, stack_trace)
        except Exception as e:
            print("Failed to log message. Error %s" % (str(e)))

    """
    Tracing with retries
    """
    @retry(tries=3, delay=1)
    def __TraceWithRetries__(self,
                             level,
                             event_name,
                             event_message,
                             stack_trace=None):
        connection = pyodbc.connect(self.connectionString)
        cursor = connection.cursor()
        cursor.execute(
            ("EXEC trace "
             "@level = ?, "
             "@event_name = ?, "
             "@event_message = ?, "
             "@correlation_id = ?, "
             "@vm_name = ?, "
             "@stack_trace = ?"),
            level,
            event_name,
            event_message,
            self.correlationId,
            self.environment,
            stack_trace)

        connection.commit()
        cursor.close()
        connection.close()



"""
Tracer class
"""
class TestTracer(object):
    """
    Informational trace
    """
    def TraceInfo(self, event_name, event_message):
        print("timestamp: %s, event_name: %s, event_message: %s" % (str(datetime.datetime.utcnow().strftime("%d.%m.%Y %H:%M:%S")), event_name, event_message))

    """
    Error tracing
    """
    def TraceException(self, event_name, event_message, stack_trace):
        print("timestamp: %s, event_name: %s, event_message: %s, stack_trace: %s" % (str(datetime.datetime.utcnow().strftime("%d.%m.%Y %H:%M:%S")), event_name, event_message, stack_trace))
