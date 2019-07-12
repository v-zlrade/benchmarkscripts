from jobs import Job, Benchmark_run
import brain
import CLperfDB
import time

SLEEP_FOR_RESULTS = 1
NUMBER_OF_JOBS = 1 #I suppose this won't be convergence condition

if __name__== "__main__":
   
    connection = CLperfDB.connect()

    with open("first_job.json","r+") as starting_job_file:
        starting_job_configs = starting_job_file.read()
        
        job = Job(connection, "Dummy job", starting_job_configs, "First job scheduled from Python")

        number_of_finished_jobs = 0
        job_results = []

        while number_of_finished_jobs < NUMBER_OF_JOBS: #I suppose this won't be convergence condition

            CLperfDB.schedule_job(job)
            next_job = brain.decide_for_next_job(connection, job, job_results) #maybe this will decide for list of jobs, not one job...

            while not CLperfDB.is_job_finished(job):
                time.sleep(SLEEP_FOR_RESULTS)

            number_of_finished_jobs += 1

            job_results = CLperfDB.read_results_with_benchmarks_id(job)         
            job = next_job
