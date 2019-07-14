CREATE PARTITION SCHEME [week_partition_scheme]
    AS PARTITION [week_partition_function]
    ALL TO ([PRIMARY]);