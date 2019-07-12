import pyodbc, re, traceback, json

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

#tested
queries['instance_state'] = """
                            select state
                            from instance_state
                            where instance_name = ?"""


queries['is_picked_up'] = """
                            select is_picked_up
                            from scheduled_benchmarks_view
                            where id = ?"""

queries['pending_instance']= """
                            select is_picked_up
                            from scheduled_benchmarks_view
                            where server_name = ?
                            and is_picked_up = 0"""

queries['benchmark_start_time'] = """
                                select start_time
                                from benchmark_runs
                                where run_id = ?"""

queries['benchmark_end_time'] = """
                                select end_time
                                from benchmark_runs
                                where run_id = ?"""

queries['read_run_id']= """
                        select run_id
                        from benchmark_runs
                        where scheduled_benchmark_id = ?"""

queries['cancel_actions']= """
                        update benchmark_action_executions
                        set execution_result = 'Failed or Canceled from Python'
                        where action_id in (select action_id from scheduled_benchmark_actions where scheduled_benchmark_id = ?)"""

def connect():
    with open("Configurations/connection.json", "r+") as connection_file:
        connection_file_content = json.loads(connection_file.read())
        server = connection_file_content['server']
        username = connection_file_content['username']
        password = connection_file_content['password']
        database = connection_file_content['database']
        connection_string = "DRIVER={0};SERVER={1};DATABASE={2};UID={3};PWD={4}".format(
            "{ODBC Driver 13 for SQL Server}",
            server,
            database,
            username,
            password)
        return pyodbc.connect(connection_string)


"""
returns true if job is successfully scheduled
"""
def schedule_job(job):
    job.id = job.connection.cursor().execute(queries['schedule_job'], job.params).fetchval() 
    job.connection.commit()

    ids = job.connection.cursor().execute(queries['scheduled_benchmarks_ids'], job.id).fetchall()
    job.scheduling_ids = [id.id for id in ids]

    #scheduled already existing job or failed at scheduling
    if len(ids) != len(job.benchmark_runs):
        return False

    for i, benchmark_run in enumerate(job.benchmark_runs):
        benchmark_run.scheduled_benchmark_id = job.scheduling_ids[i]

    job.scheduled = 1
    return True

def is_benchmark_picked_up(benchmark_run):
    is_picked_up = benchmark_run.connection.cursor().execute(queries['is_picked_up'], benchmark_run.scheduled_benchmark_id).fetchval()
    benchmark_run.is_picked_up = is_picked_up
    return is_picked_up


def is_job_finished(job): 
    state = job.connection.cursor().execute(queries['job_finished'], job.job_id).fetchval()
    return state == 'Finished'
        

def read_results_benchmark(benchmark_run):
    metrics_json = benchmark_run.connection.cursor().execute(queries['read_results'], benchmark_run.run_id).fetchone()

    if metrics_json is None:
        return None

    metrics = json.loads(metrics_json[0])
    results = {}
    for metric in metrics:
        results[metric['metric_name']] = metric['metric_value']
    return results


def instance_state(connection, instance_name):
    state = connection.cursor().execute(queries['instance_state'], instance_name).fetchval()
    return str(state)

def is_instance_pending_for_benchmark(connection, instance_name):
    pending = connection.cursor().execute(queries['pending_instance'], instance_name).fetchone()

    if pending is not None:
        return True
    else:
        return False

def is_instance_available(connection, instance_info):
    instance_name = instance_info['instance_name']
    state = instance_state(connection, instance_name)
    pending_instance = is_instance_pending_for_benchmark(connection, instance_name)

    if state == 'Ready' and not pending_instance:
        return True
    return False

def available_instances(connection, instances):

    free_instances = []
    for instance_name in instances:
        state = instance_state(connection, instance_name)
        pending_instance = is_instance_pending_for_benchmark(connection, instance_name)

        print(instance_name + str(state) + ' ' + str(pending_instance))

        if state == 'Ready' and not pending_instance:
            free_instances.append(instance_name)
    
    return free_instances

def benchmark_start_time(benchmark_run):
    start_time = benchmark_run.connection.cursor().execute(queries['benchmark_start_time'], benchmark_run.run_id).fetchval()

    if start_time is not None:
        benchmark_run.start_time = str(start_time)
        return str(start_time) 
    benchmark_run.start_time = None
    return None


def benchmark_end_time(benchmark_run):
    end_time = benchmark_run.connection.cursor().execute(queries['benchmark_end_time'], benchmark_run.run_id).fetchval()
    
    if end_time is not None:
        benchmark_run.end_time = str(end_time)
        return str(end_time)
    benchmark_run.end_time = None
    return None

def set_run_id(benchmark_run):
    benchmark_run.run_id = benchmark_run.connection.cursor().execute(queries['read_run_id'], benchmark_run.scheduled_benchmark_id).fetchval()

def cancel_pending_actions_when_run_fails(benchmark_run):
    benchmark_run.connection.cursor().execute(queries['cancel_actions'], benchmark_run.scheduled_benchmark_id)
    benchmark_run.connection.commit()
    

