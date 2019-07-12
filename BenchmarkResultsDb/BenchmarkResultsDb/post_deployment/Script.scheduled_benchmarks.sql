SET XACT_ABORT ON

BEGIN TRANSACTION INIT_SLO_BENCH

DECLARE @scheduled_benchmarks_tmp TABLE
(
    [processor_count] INT NOT NULL,
	[parallel_exec_cnt] INT NOT NULL,
    [hardware_generation] NVARCHAR(128) NOT NULL,
    [is_bc] BIT NOT NULL,
    [benchmark_name] NVARCHAR(128) NOT NULL,
    [environment]  NVARCHAR(50) NOT NULL,
    [is_picked_up] BIT NOT NULL
)

INSERT INTO @scheduled_benchmarks_tmp
(
    [processor_count],
	[parallel_exec_cnt],
    [hardware_generation],
    [is_bc],
    [benchmark_name],
    [environment],
    [is_picked_up]
)
VALUES
        (8, 1, 'Gen4', 1 , 'CDB', 'ProdG4', 0),
        (16, 1, 'Gen4', 1 , 'CDB', 'ProdG4', 0),
        (24, 1, 'Gen4', 1 , 'CDB', 'ProdG4', 0),
        (8, 1, 'Gen4', 0 , 'CDB', 'ProdG4', 0),
        (16, 1, 'Gen4', 0 , 'CDB', 'ProdG4', 0),
        (24, 1, 'Gen4', 0 , 'CDB', 'ProdG4', 0),
        (8, 1, 'Gen4', 1 , 'TPCC', 'ProdG4', 0),
        (16, 1, 'Gen4', 1 , 'TPCC', 'ProdG4', 0),
        (24, 1, 'Gen4', 1 , 'TPCC', 'ProdG4', 0),
        (8, 1, 'Gen4', 0 , 'TPCC', 'ProdG4', 0),
        (16, 1, 'Gen4', 0 , 'TPCC', 'ProdG4', 0),
        (24, 1, 'Gen4', 0 , 'TPCC', 'ProdG4', 0),
        (8, 1, 'Gen5', 1 , 'CDB', 'ProdG5', 0),
        (16, 1, 'Gen5', 1 , 'CDB', 'ProdG5', 0),
        (24, 1, 'Gen5', 1 , 'CDB', 'ProdG5', 0),
        (32, 1, 'Gen5', 1 , 'CDB', 'ProdG5', 0),
        (40, 1, 'Gen5', 1 , 'CDB', 'ProdG5', 0),
        (64, 1, 'Gen5', 1 , 'CDB', 'ProdG5', 0),
        (80, 1, 'Gen5', 1 , 'CDB', 'ProdG5', 0),
        (8, 1, 'Gen5', 0 , 'CDB', 'ProdG5', 0),
        (16, 1, 'Gen5', 0 , 'CDB', 'ProdG5', 0),
        (24, 1, 'Gen5', 0 , 'CDB', 'ProdG5', 0),
        (32, 1, 'Gen5', 0 , 'CDB', 'ProdG5', 0),
        (40, 1, 'Gen5', 0 , 'CDB', 'ProdG5', 0),
        (64, 1, 'Gen5', 0 , 'CDB', 'ProdG5', 0),
        (80, 1, 'Gen5', 0 , 'CDB', 'ProdG5', 0),
        (8, 1, 'Gen5', 1 , 'TPCC', 'ProdG5', 0),
        (16, 1, 'Gen5', 1 , 'TPCC', 'ProdG5', 0),
        (24, 1, 'Gen5', 1 , 'TPCC', 'ProdG5', 0),
        (32, 1, 'Gen5', 1 , 'TPCC', 'ProdG5', 0),
        (40, 1, 'Gen5', 1 , 'TPCC', 'ProdG5', 0),
        (64, 1, 'Gen5', 1 , 'TPCC', 'ProdG5', 0),
        (80, 1, 'Gen5', 1 , 'TPCC', 'ProdG5', 0),
        (8, 1, 'Gen5', 0 , 'TPCC', 'ProdG5', 0),
        (16, 1, 'Gen5', 0 , 'TPCC', 'ProdG5', 0),
        (24, 1, 'Gen5', 0 , 'TPCC', 'ProdG5', 0),
        (32, 1, 'Gen5', 0 , 'TPCC', 'ProdG5', 0),
        (40, 1, 'Gen5', 0 , 'TPCC', 'ProdG5', 0),
        (64, 1, 'Gen5', 0 , 'TPCC', 'ProdG5', 0),
        (80, 1, 'Gen5', 0 , 'TPCC', 'ProdG5', 0),
        (8, 1, 'Gen4', 1 , 'CDB', 'Stage', 0),
        (16, 1, 'Gen4', 1 , 'CDB', 'Stage', 0),
        (24, 1, 'Gen4', 1 , 'CDB', 'Stage', 0),
        (8, 1, 'Gen4', 0 , 'CDB', 'Stage', 0),
        (16, 1, 'Gen4', 0 , 'CDB', 'Stage', 0),
        (24, 1, 'Gen4', 0 , 'CDB', 'Stage', 0),
        (8, 1, 'Gen4', 1 , 'TPCC', 'Stage', 0),
        (16, 1, 'Gen4', 1 , 'TPCC', 'Stage', 0),
        (24, 1, 'Gen4', 1 , 'TPCC', 'Stage', 0),
        (8, 1, 'Gen4', 0 , 'TPCC', 'Stage', 0),
        (16, 1, 'Gen4', 0 , 'TPCC', 'Stage', 0),
        (24, 1, 'Gen4', 0 , 'TPCC', 'Stage', 0),
        (4, 1, 'SVMLoose', 1 , 'CDB', 'SVMStage', 0),
        (8, 1, 'SVMLoose', 1 , 'CDB', 'SVMStage', 0),
        (24, 1, 'SVMLoose', 1 , 'CDB', 'SVMStage', 0),
        (40, 1, 'SVMLoose', 1 , 'CDB', 'SVMStage', 0),
        (4, 1, 'SVMLoose', 1 , 'TPCC', 'SVMStage', 0),
        (8, 1, 'SVMLoose', 1 , 'TPCC', 'SVMStage', 0),
        (24, 1, 'SVMLoose', 1 , 'TPCC', 'SVMStage', 0),
        (40, 1, 'SVMLoose', 1 , 'TPCC', 'SVMStage', 0),
        (4, 1, 'SVMTight', 1 , 'CDB', 'SVMStage', 0),
        (8, 1, 'SVMTight', 1 , 'CDB', 'SVMStage', 0),
        (24, 1, 'SVMTight', 1 , 'CDB', 'SVMStage', 0),
        (40, 1, 'SVMTight', 1 , 'CDB', 'SVMStage', 0),
        (4, 1, 'SVMTight', 0 , 'CDB', 'SVMStage', 0),
        (8, 1, 'SVMTight', 0 , 'CDB', 'SVMStage', 0),
        (16, 1, 'SVMTight', 0 , 'CDB', 'SVMStage', 0),
        (24, 1, 'SVMTight', 0 , 'CDB', 'SVMStage', 0),
        (32, 1, 'SVMTight', 0 , 'CDB', 'SVMStage', 0),
        (40, 1, 'SVMTight', 0 , 'CDB', 'SVMStage', 0),
        (64, 1, 'SVMTight', 0 , 'CDB', 'SVMStage', 0),
        (4, 1, 'SVMTight', 1 , 'TPCC', 'SVMStage', 0),
        (8, 1, 'SVMTight', 1 , 'TPCC', 'SVMStage', 0),
        (24, 1, 'SVMTight', 1 , 'TPCC', 'SVMStage', 0),
        (40, 1, 'SVMTight', 1 , 'TPCC', 'SVMStage', 0),
        (4, 1, 'SVMTight', 0 , 'TPCC', 'SVMStage', 0),
        (8, 1, 'SVMTight', 0 , 'TPCC', 'SVMStage', 0),
        (16, 1, 'SVMTight', 0 , 'TPCC', 'SVMStage', 0),
        (24, 1, 'SVMTight', 0 , 'TPCC', 'SVMStage', 0),
        (32, 1, 'SVMTight', 0 , 'TPCC', 'SVMStage', 0),
        (40, 1, 'SVMTight', 0 , 'TPCC', 'SVMStage', 0),
        (64, 1, 'SVMTight', 0 , 'TPCC', 'SVMStage', 0)

MERGE [scheduled_benchmarks] AS [target]
USING @scheduled_benchmarks_tmp AS source
ON (target.[processor_count] = source.[processor_count]
	AND target.[parallel_exec_cnt] = source.[parallel_exec_cnt]
    AND target.[hardware_generation] = source.[hardware_generation]
    AND target.[is_bc] = source.[is_bc]
    AND target.[benchmark_name] = source.[benchmark_name]
    AND target.[environment] = source.[environment])
WHEN NOT MATCHED THEN
        INSERT
        (
                [processor_count],
				[parallel_exec_cnt],
                [hardware_generation],
                [is_bc],
                [benchmark_name],
                [environment],
                [is_picked_up],
                [is_adhoc_run]
        ) VALUES
        (
                [source].[processor_count],
				[source].[parallel_exec_cnt],
                [source].[hardware_generation],
                [source].[is_bc],
                [source].[benchmark_name],
                [source].[environment],
                [source].[is_picked_up],
                0
        );
COMMIT TRANSACTION INIT_SLO_BENCH