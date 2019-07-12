import pyodbc
import re

queries = {}

queries['schedule_job'] = """
                        declare @job_id int
                        exec schedule_job
                        @name = ?,
                        @configs = ?,
                        @description = ?,
                        @id = @job_id OUTPUT
                        select @job_id as job_id"""



queries['read_results'] = """
                        select metric_name, metric_value
                        from benchmark_results
                        where run_id = ?
                        for json auto"""

queries['job_definition'] = """
                        select * from job_definitions
                        where id = ?"""

queries['job_finished'] = """
                        select state
                        from jobs
                        where id = ?"""

queries['scheduled_benchmarks_ids'] = """
                                    select id
                                    from scheduled_benchmarks
                                    where job_id = ?"""


def connect():
    with open("connection_file.txt", "r+") as connection_file:
        connection_string_raw = connection_file.read()
        server = re.search(r"SERVER = (.*)\n", connection_string_raw).group(1)
        username = re.search(r"USERNAME = (.*)\n", connection_string_raw).group(1)
        password = re.search(r"PASSWORD = (.*)\n", connection_string_raw).group(1)
        database = re.search(r"DATABASE = (.*)\n", connection_string_raw).group(1)
        connection_string = "DRIVER={0};SERVER={1};DATABASE={2};UID={3};PWD={4}".format(
            "{ODBC Driver 13 for SQL Server}",
            server,
            database,
            username,
            password)
        return pyodbc.connect(connection_string)

def schedule_job(job):
    job.job_id = job.connection.cursor().execute(queries['schedule_job'], job.params).fetchval() 
    job.connection.commit()

    ids = job.connection.cursor().execute(queries['scheduled_benchmarks_ids'], job.job_id).fetchall()
    job.scheduling_ids = [id.id for id in ids]

    for i, benchmark_run in enumerate(job.benchmark_runs):
        benchmark_run.id = job.scheduling_ids[i]


def is_job_finished(job): 
    state = job.connection.cursor().execute(queries['job_finished'], job.job_id).fetchval()
    return state == 'Finished'
        

def read_results_with_benchmarks_id(job):
    job_results = {}
    for benchmark_run_id in job.scheduling_ids:
        job_results[benchmark_run_id] = job.connection.cursor().execute(queries['read_results'], benchmark_run_id).fetchval()
    return job_results
