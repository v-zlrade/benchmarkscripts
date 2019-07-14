import CLperfDB

connection = CLperfDB.connect()

print(CLperfDB.queries['benchmark_start_time'])

start_time = connection.cursor().execute(CLperfDB.queries['benchmark_start_time'], 4257).fetchval()

print(type(start_time))
print(start_time)
print(str(start_time))