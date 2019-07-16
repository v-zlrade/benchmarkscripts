SET XACT_ABORT ON

BEGIN TRANSACTION INIT_SLO_BENCH

DECLARE @slo_benchmark_config_tmp TABLE
(
    [processor_count] INT NOT NULL,
    [parallel_exec_cnt] INT NOT NULL,
    [hardware_generation] NVARCHAR(128) NOT NULL,
    [is_bc] BIT NOT NULL,
    [benchmark_name] NVARCHAR(128) NOT NULL,
    [worker_number] INT NOT NULL,
    [benchmark_scaling_argument] INT NOT NULL,
    [scaled_down] BIT NOT NULL,
    [server_name] NVARCHAR(1000) NOT NULL,
    [database_name] NVARCHAR(128) NOT NULL,
    [warmup_timespan_minutes] INT NOT NULL,
    [run_timespan_minutes] INT NOT NULL,
    [custom_master_tsql_query] NVARCHAR(MAX) NULL,
    [required_processor_count] INT NOT NULL,
    [environment] NVARCHAR(50) NOT NULL
)

INSERT INTO @slo_benchmark_config_tmp
(
        [processor_count],
        [parallel_exec_cnt],
        [hardware_generation],
        [is_bc],
        [benchmark_name],
        [worker_number],
        [benchmark_scaling_argument],
        [scaled_down],
        [server_name],
        [database_name],
        [warmup_timespan_minutes],
        [run_timespan_minutes],
        [environment],
        [custom_master_tsql_query],
        [required_processor_count]
)
VALUES
        -- GEN 4 PROD
        (8, 1, 'GEN4', 0, 'CDB', 1120, 15000, 0, 'clperftestin02.wcus10d832431fca2.database.windows.net', 'cdb15000', 15, 60, 'ProdG4', NULL, 2),
        (16, 1, 'GEN4', 0, 'CDB', 1600, 15000, 0, 'clperftesting01.wcus10d832431fca2.database.windows.net', 'cdb15000', 15, 60, 'ProdG4', NULL, 3),
        (24, 1, 'GEN4', 0, 'CDB', 1600, 30000, 0, 'clperftesting03.wcus10d832431fca2.database.windows.net', 'cdb30000', 15, 60, 'ProdG4', NULL, 4),
        (8, 1, 'GEN4', 1, 'CDB', 1120, 15000, 0, 'clperftesting-gen4-bc8-wcus-01.wcus10d832431fca2.database.windows.net', 'cdb15000', 15, 60, 'ProdG4', NULL, 2),
        (16, 1, 'GEN4', 1, 'CDB', 2240, 15000, 0, 'clperftesting-gen4-bc16-wcus-01.wcus10d832431fca2.database.windows.net', 'cdb15000', 15, 60, 'ProdG4', NULL, 3),
        (24, 1, 'GEN4', 1, 'CDB', 3360, 30000, 0, 'clperftesting-gen4-bc24-wcus-01.wcus10d832431fca2.database.windows.net', 'cdb30000', 15, 60, 'ProdG4', NULL, 4),
        (8, 1, 'GEN4', 0, 'TPCC', 100, 4000, 0, 'clperftestin02.wcus10d832431fca2.database.windows.net', 'tpcc4000', 15, 120, 'ProdG4', NULL, 2),
        (16, 1, 'GEN4', 0, 'TPCC', 200, 4000, 0, 'clperftesting01.wcus10d832431fca2.database.windows.net', 'tpcc4000', 15, 120, 'ProdG4', NULL, 3),
        (24, 1, 'GEN4', 0, 'TPCC', 300, 4000, 0, 'clperftesting03.wcus10d832431fca2.database.windows.net', 'tpcc4000', 15, 120, 'ProdG4', NULL, 4),
        (8, 1, 'GEN4', 1, 'TPCC', 100, 4000, 0, 'clperftesting-gen4-bc8-wcus-01.wcus10d832431fca2.database.windows.net', 'tpcc4000', 15, 120, 'ProdG4', NULL, 2),
        (16, 1, 'GEN4', 1, 'TPCC', 200, 4000, 0, 'clperftesting-gen4-bc16-wcus-01.wcus10d832431fca2.database.windows.net', 'tpcc4000', 15, 120, 'ProdG4', NULL, 3),
        (24, 1, 'GEN4', 1, 'TPCC', 300, 4000, 0, 'clperftesting-gen4-bc24-wcus-01.wcus10d832431fca2.database.windows.net', 'tpcc4000', 15, 120, 'ProdG4', NULL, 4),
        -- GEN 5 PROD
        (8, 1, 'GEN5', 0, 'CDB', 720, 15000, 0, 'clperftesting-gen5-gp8-weu-01.weu14c689be44714.database.windows.net', 'cdb15000', 15, 60, 'ProdG5', NULL, 2),
        (16, 1, 'GEN5', 0, 'CDB', 1440, 15000, 0, 'clperftesting-gen5-gp16-weu-01.weu14c689be44714.database.windows.net', 'cdb15000', 15, 60, 'ProdG5', NULL, 3),
        (24, 1, 'GEN5', 0, 'CDB', 1600, 15000, 0, 'clperftesting-gen5-gp24-weu-01.weu14c689be44714.database.windows.net', 'cdb30000', 15, 60, 'ProdG5', NULL, 4),
        (32, 1, 'GEN5', 0, 'CDB', 1600, 30000, 0, 'clperftesting-gen5-gp32-weu-01.weu14c689be44714.database.windows.net', 'cdb30000', 15, 60, 'ProdG5', NULL, 5),
        (40, 1, 'GEN5', 0, 'CDB', 1600, 30000, 0, 'clperftesting-gen5-gp40-weu-01.weu14c689be44714.database.windows.net', 'cdb30000', 30, 60, 'ProdG5', NULL, 6),
        (64, 1, 'GEN5', 0, 'CDB', 1600, 30000, 0, 'clperftesting-gen5-gp64-weu-01.weu14c689be44714.database.windows.net', 'cdb30000', 30, 60, 'ProdG5', NULL, 7),
        (80, 1, 'GEN5', 0, 'CDB', 1600, 40000, 0, 'clperftesting-gen5-gp80-weu-01.weu14c689be44714.database.windows.net', 'cdb40000', 30, 60, 'ProdG5', NULL, 8),
        (8, 1, 'GEN5', 1, 'CDB', 720, 15000, 0, 'clperftesting-gen5-bc8-weu-01.weu14c689be44714.database.windows.net', 'cdb15000', 15, 60, 'ProdG5', NULL, 2),
        (16, 1, 'GEN5', 1, 'CDB', 1440, 15000, 0, 'clperftesting-gen5-bc16-weu-01.weu14c689be44714.database.windows.net', 'cdb15000', 15, 60, 'ProdG5', NULL, 3),
        (24, 1, 'GEN5', 1, 'CDB', 2160, 30000, 0, 'clperftesting-gen5-bc24-weu-01.weu14c689be44714.database.windows.net', 'cdb30000', 15, 60, 'ProdG5', NULL, 4),
        (32, 1, 'GEN5', 1, 'CDB', 2880, 30000, 0, 'clperftesting-gen5-bc32-weu-01.weu14c689be44714.database.windows.net', 'cdb30000', 15, 60, 'ProdG5', NULL, 5),
        (40, 1, 'GEN5', 1, 'CDB', 3600, 30000, 0, 'clperftesting-gen5-bc40-weu-01.weu14c689be44714.database.windows.net', 'cdb30000', 30, 60, 'ProdG5', NULL, 6),
        (64, 1, 'GEN5', 1, 'CDB', 5765, 30000, 0, 'clperftesting-gen5-bc64-weu-01.weu14c689be44714.database.windows.net', 'cdb30000', 30, 60, 'ProdG5', NULL, 7),
        (80, 1, 'GEN5', 1, 'CDB', 7200, 40000, 0, 'clperftesting-gen5-bc80-weu-01.weu14c689be44714.database.windows.net', 'cdb40000', 30, 60, 'ProdG5', NULL, 8),
        (8, 1, 'GEN5', 0, 'TPCC', 100, 4000, 0, 'clperftesting-gen5-gp8-weu-01.weu14c689be44714.database.windows.net', 'tpcc4000', 15, 120, 'ProdG5', NULL, 2),
        (16, 1, 'GEN5', 0, 'TPCC', 200, 4000, 0, 'clperftesting-gen5-gp16-weu-01.weu14c689be44714.database.windows.net', 'tpcc4000', 15, 120, 'ProdG5', NULL, 3),
        (24, 1, 'GEN5', 0, 'TPCC', 300, 4000, 0, 'clperftesting-gen5-gp24-weu-01.weu14c689be44714.database.windows.net', 'tpcc4000', 15, 120, 'ProdG5', NULL, 4),
        (32, 1, 'GEN5', 0, 'TPCC', 400, 4000, 0, 'clperftesting-gen5-gp32-weu-01.weu14c689be44714.database.windows.net', 'tpcc4000', 15, 120, 'ProdG5', NULL, 5),
        (40, 1, 'GEN5', 0, 'TPCC', 500, 4000, 0, 'clperftesting-gen5-gp40-weu-01.weu14c689be44714.database.windows.net', 'tpcc4000', 30, 120, 'ProdG5', NULL, 6),
        (64, 1, 'GEN5', 0, 'TPCC', 800, 4000, 0, 'clperftesting-gen5-gp64-weu-01.weu14c689be44714.database.windows.net', 'tpcc4000', 30, 120, 'ProdG5', NULL, 7),
        (80, 1, 'GEN5', 0, 'TPCC', 1000, 4000, 0, 'clperftesting-gen5-gp80-weu-01.weu14c689be44714.database.windows.net', 'tpcc4000', 30, 120, 'ProdG5', NULL, 8),
        (8, 1, 'GEN5', 1, 'TPCC', 100, 4000, 0, 'clperftesting-gen5-bc8-weu-01.weu14c689be44714.database.windows.net', 'tpcc4000', 15, 120, 'ProdG5', NULL, 2),
        (16, 1, 'GEN5', 1, 'TPCC', 200, 4000, 0, 'clperftesting-gen5-bc16-weu-01.weu14c689be44714.database.windows.net', 'tpcc4000', 15, 120, 'ProdG5', NULL, 3),
        (24, 1, 'GEN5', 1, 'TPCC', 300, 4000, 0, 'clperftesting-gen5-bc24-weu-01.weu14c689be44714.database.windows.net', 'tpcc4000', 15, 120, 'ProdG5', NULL, 4),
        (32, 1, 'GEN5', 1, 'TPCC', 400, 4000, 0, 'clperftesting-gen5-bc32-weu-01.weu14c689be44714.database.windows.net', 'tpcc4000', 15, 120, 'ProdG5', NULL, 5),
        (40, 1, 'GEN5', 1, 'TPCC', 500, 4000, 0, 'clperftesting-gen5-bc40-weu-01.weu14c689be44714.database.windows.net', 'tpcc4000', 30, 120, 'ProdG5', NULL, 6),
        (64, 1, 'GEN5', 1, 'TPCC', 800, 4000, 0, 'clperftesting-gen5-bc64-weu-01.weu14c689be44714.database.windows.net', 'tpcc4000', 30, 120, 'ProdG5', NULL, 7),
        (80, 1, 'GEN5', 1, 'TPCC', 1000, 4000, 0, 'clperftesting-gen5-bc80-weu-01.weu14c689be44714.database.windows.net', 'tpcc4000', 30, 120, 'ProdG5', NULL, 8),
        (8, 1, 'GEN5', 0, 'DataLoading', 1, 1024, 0, 'clperftesting-gen5-gp8-weu-01.weu14c689be44714.database.windows.net', 'cdb15000', 15, 99999, 'ProdG5', NULL, 4),
        (16, 1, 'GEN5', 0, 'DataLoading', 1, 1024, 0, 'clperftesting-gen5-gp16-weu-01.weu14c689be44714.database.windows.net', 'cdb15000', 15, 99999, 'ProdG5', NULL, 4),
        (24, 1, 'GEN5', 0, 'DataLoading', 1, 1024, 0, 'clperftesting-gen5-gp24-weu-01.weu14c689be44714.database.windows.net', 'cdb30000', 15, 99999, 'ProdG5', NULL, 4),
        (32, 1, 'GEN5', 0, 'DataLoading', 1, 1024, 0, 'clperftesting-gen5-gp32-weu-01.weu14c689be44714.database.windows.net', 'cdb30000', 15, 99999, 'ProdG5', NULL, 4),
        (40, 1, 'GEN5', 0, 'DataLoading', 1, 1024, 0, 'clperftesting-gen5-gp40-weu-01.weu14c689be44714.database.windows.net', 'cdb30000', 30, 99999, 'ProdG5', NULL, 4),
        (64, 1, 'GEN5', 0, 'DataLoading', 1, 1024, 0, 'clperftesting-gen5-gp64-weu-01.weu14c689be44714.database.windows.net', 'cdb30000', 30, 99999, 'ProdG5', NULL, 4),
        (80, 1, 'GEN5', 0, 'DataLoading', 1, 1024, 0, 'clperftesting-gen5-gp80-weu-01.weu14c689be44714.database.windows.net', 'cdb40000', 30, 99999, 'ProdG5', NULL, 4),
        (8, 1, 'GEN5', 1, 'DataLoading', 1, 1024, 0, 'clperftesting-gen5-bc8-weu-01.weu14c689be44714.database.windows.net', 'cdb15000', 15, 99999, 'ProdG5', NULL, 4),
        (16, 1, 'GEN5', 1, 'DataLoading', 1, 1024, 0, 'clperftesting-gen5-bc16-weu-01.weu14c689be44714.database.windows.net', 'cdb15000', 15, 99999, 'ProdG5', NULL, 4),
        (24, 1, 'GEN5', 1, 'DataLoading', 1, 1024, 0, 'clperftesting-gen5-bc24-weu-01.weu14c689be44714.database.windows.net', 'cdb30000', 15, 99999, 'ProdG5', NULL, 4),
        (32, 1, 'GEN5', 1, 'DataLoading', 1, 1024, 0, 'clperftesting-gen5-bc32-weu-01.weu14c689be44714.database.windows.net', 'cdb30000', 15, 99999, 'ProdG5', NULL, 4),
        (40, 1, 'GEN5', 1, 'DataLoading', 1, 1024, 0, 'clperftesting-gen5-bc40-weu-01.weu14c689be44714.database.windows.net', 'cdb30000', 15, 99999, 'ProdG5', NULL, 4),
        (64, 1, 'GEN5', 1, 'DataLoading', 1, 1024, 0, 'clperftesting-gen5-bc64-weu-01.weu14c689be44714.database.windows.net', 'cdb30000', 15, 99999, 'ProdG5', NULL, 4),
        (80, 1, 'GEN5', 1, 'DataLoading', 1, 1024, 0, 'clperftesting-gen5-bc80-weu-01.weu14c689be44714.database.windows.net', 'cdb40000', 15, 99999, 'ProdG5', NULL, 4),
        -- GEN 4 STAGE
        (8, 1, 'GEN4', 0, 'CDB', 1120, 15000, 0, 'clperftesting-gen4-gp8-sneu-01.neu1396d5828d931.sqltest-eg1.mscds.com', 'cdb15000', 15, 60, 'Stage', NULL, 2),
        (16, 1, 'GEN4', 0, 'CDB', 1600, 15000, 0, 'clperftesting-gen4-gp16-sneu-01.neu1396d5828d931.sqltest-eg1.mscds.com', 'cdb15000', 15, 60, 'Stage', NULL, 3),
        (24, 1, 'GEN4', 0, 'CDB', 1600, 30000, 0, 'clperftesting-gen4-gp24-sneu-01.neu1396d5828d931.sqltest-eg1.mscds.com', 'cdb30000', 15, 60, 'Stage', NULL, 3),
        (8, 1, 'GEN4', 1, 'CDB', 1120, 15000, 0, 'clperftesting-gen4-bc8-sneu-01.neu1396d5828d931.sqltest-eg1.mscds.com', 'cdb15000', 15, 60, 'Stage', NULL, 2),
        (16, 1, 'GEN4', 1, 'CDB', 2240, 15000, 0, 'clperftesting-gen4-bc16-sneu-01.neu1396d5828d931.sqltest-eg1.mscds.com', 'cdb15000', 15, 60, 'Stage', NULL, 3),
        (24, 1, 'GEN4', 1, 'CDB', 3360, 30000, 0, 'clperftesting-gen4-bc24-sneu-01.neu1396d5828d931.sqltest-eg1.mscds.com', 'cdb30000', 15, 60, 'Stage', NULL, 4),
        (8, 1, 'GEN4', 0, 'TPCC', 100, 4000, 0, 'clperftesting-gen4-gp8-sneu-01.neu1396d5828d931.sqltest-eg1.mscds.com', 'tpcc4000', 15, 120, 'Stage', NULL, 2),
        (16, 1, 'GEN4', 0, 'TPCC', 200, 4000, 0, 'clperftesting-gen4-gp16-sneu-01.neu1396d5828d931.sqltest-eg1.mscds.com', 'tpcc4000', 15, 120, 'Stage', NULL, 3),
        (24, 1, 'GEN4', 0, 'TPCC', 300, 4000, 0, 'clperftesting-gen4-gp24-sneu-01.neu1396d5828d931.sqltest-eg1.mscds.com', 'tpcc4000', 15, 120, 'Stage', NULL, 4),
        (8, 1, 'GEN4', 1, 'TPCC', 100, 4000, 0, 'clperftesting-gen4-bc8-sneu-01.neu1396d5828d931.sqltest-eg1.mscds.com', 'tpcc4000', 15, 120, 'Stage', NULL, 2),
        (16, 1, 'GEN4', 1, 'TPCC', 200, 4000, 0, 'clperftesting-gen4-bc16-sneu-01.neu1396d5828d931.sqltest-eg1.mscds.com', 'tpcc4000', 15, 120, 'Stage', NULL, 3),
        (24, 1, 'GEN4', 1, 'TPCC', 300, 4000, 0, 'clperftesting-gen4-bc24-sneu-01.neu1396d5828d931.sqltest-eg1.mscds.com', 'tpcc4000', 15, 120, 'Stage', NULL, 4),
        -- SVM Stage
        -- Loose
        (4, 1, 'SVMLoose', 1, 'CDB', 360, 15000, 0, 'clperftesting-gen5-bc4-loose-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'cdb15000', 15, 60, 'SVMStage', NULL, 1),
        (4, 1, 'SVMLoose', 1, 'CDB', 360, 15000, 0, 'clperftesting-gen5-gp4-loose-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'cdb15000', 15, 60, 'SVMProd', NULL, 1),
        (8, 1, 'SVMLoose', 1, 'CDB', 720, 15000, 0, 'clperftesting-gen5-bc8-loose-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'cdb15000', 15, 60, 'SVMStage', NULL, 2),
        (24, 1, 'SVMLoose', 1, 'CDB', 2160, 30000, 0, 'clperftesting-gen5-bc24-loose-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'cdb30000', 15, 60, 'SVMStage', NULL, 4),
        (40, 1, 'SVMLoose', 1, 'CDB', 3600, 30000, 0, 'clperftesting-gen5-bc40-loose-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'cdb30000', 30, 60, 'SVMStage', NULL, 24),
        (4, 1, 'SVMLoose', 1, 'TPCC', 50, 4000, 0, 'clperftesting-gen5-bc4-loose-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'tpcc4000', 15, 120, 'SVMStage', NULL, 1),
        (8, 1, 'SVMLoose', 1, 'TPCC', 100, 4000, 0, 'clperftesting-gen5-bc8-loose-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'tpcc4000', 15, 120, 'SVMStage', NULL, 2),
        (24, 1, 'SVMLoose', 1, 'TPCC', 300, 4000, 0, 'clperftesting-gen5-bc24-loose-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'tpcc4000', 15, 120, 'SVMStage', NULL, 4),
        (40, 1, 'SVMLoose', 1, 'TPCC', 500, 4000, 0, 'clperftesting-gen5-bc40-loose-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'tpcc4000', 30, 120, 'SVMStage', NULL, 24),
        -- Tight
        (4, 1, 'SVMTight', 0, 'CDB', 360, 15000, 0, 'clperftesting-gen5-gp4-tight-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'cdb15000', 15, 60, 'SVMStage', NULL, 1),
        (8, 1, 'SVMTight', 0, 'CDB', 720, 15000, 0, 'clperftesting-gen5-gp8-tight-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'cdb15000', 15, 60, 'SVMStage', NULL, 2),
        (16, 1, 'SVMTight', 0, 'CDB', 1440, 15000, 0, 'clperftesting-gen5-gp16-tight-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'cdb15000', 15, 60, 'SVMStage', NULL, 3),
        (24, 1, 'SVMTight', 0, 'CDB', 1600, 15000, 0, 'clperftesting-gen5-gp24-tight-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'cdb30000', 15, 60, 'SVMStage', NULL, 4),
        (32, 1, 'SVMTight', 0, 'CDB', 1600, 30000, 0, 'clperftesting-gen5-gp32-tight-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'cdb30000', 15, 60, 'SVMStage', NULL, 5),
        (40, 1, 'SVMTight', 0, 'CDB', 1600, 30000, 0, 'clperftesting-gen5-gp40-tight-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'cdb30000', 30, 60, 'SVMStage', NULL, 6),
        (64, 1, 'SVMTight', 0, 'CDB', 1600, 30000, 0, 'clperftesting-gen5-gp64-tight-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'cdb30000', 30, 60, 'SVMStage', NULL, 7),
        (80, 1, 'SVMTight', 0, 'CDB', 1600, 40000, 0, 'clperftesting-gen5-gp80-tight-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'cdb40000', 30, 60, 'SVMStage', NULL, 8),
        (4, 1, 'SVMTight', 1, 'CDB', 360, 15000, 0, 'clperftesting-gen5-bc4-tight-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'cdb15000', 15, 60, 'SVMStage', NULL, 1),
        (8, 1, 'SVMTight', 1, 'CDB', 720, 15000, 0, 'clperftesting-gen5-bc8-tight-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'cdb15000', 15, 60, 'SVMStage', NULL, 2),
        (24, 1, 'SVMTight', 1, 'CDB', 2160, 30000, 0, 'clperftesting-gen5-bc24-tight-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'cdb30000', 15, 60, 'SVMStage', NULL, 4),
        (40, 1, 'SVMTight', 1, 'CDB', 3600, 30000, 0, 'clperftesting-gen5-bc40-tight-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'cdb30000', 30, 60, 'SVMStage', NULL, 24),
        (4, 1, 'SVMTight', 0, 'TPCC', 50, 4000, 0, 'clperftesting-gen5-gp4-tight-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'tpcc4000', 15, 120, 'SVMStage', NULL, 1),
        (8, 1, 'SVMTight', 0, 'TPCC', 100, 4000, 0, 'clperftesting-gen5-gp8-tight-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'tpcc4000', 15, 120, 'SVMStage', NULL, 2),
        (16, 1, 'SVMTight', 0, 'TPCC', 200, 4000, 0, 'clperftesting-gen5-gp16-tight-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'tpcc4000', 15, 120, 'SVMStage', NULL, 3),
        (24, 1, 'SVMTight', 0, 'TPCC', 300, 4000, 0, 'clperftesting-gen5-gp24-tight-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'tpcc4000', 15, 120, 'SVMStage', NULL, 4),
        (32, 1, 'SVMTight', 0, 'TPCC', 400, 4000, 0, 'clperftesting-gen5-gp32-tight-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'tpcc4000', 15, 120, 'SVMStage', NULL, 5),
        (40, 1, 'SVMTight', 0, 'TPCC', 500, 4000, 0, 'clperftesting-gen5-gp40-tight-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'tpcc4000', 30, 120, 'SVMStage', NULL, 6),
        (64, 1, 'SVMTight', 0, 'TPCC', 800, 4000, 0, 'clperftesting-gen5-gp64-tight-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'tpcc4000', 30, 120, 'SVMStage', NULL, 7),
        (4, 1, 'SVMTight', 1, 'TPCC', 50, 4000, 0, 'clperftesting-gen5-bc4-tight-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'tpcc4000', 15, 120, 'SVMStage', NULL, 1),
        (8, 1, 'SVMTight', 1, 'TPCC', 100, 4000, 0, 'clperftesting-gen5-bc8-tight-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'tpcc4000', 15, 120, 'SVMStage', NULL, 2),
        (24, 1, 'SVMTight', 1, 'TPCC', 300, 4000, 0, 'clperftesting-gen5-bc24-tight-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'tpcc4000', 15, 120, 'SVMStage', NULL, 4),
        (40, 1, 'SVMTight', 1, 'TPCC', 500, 4000, 0, 'clperftesting-gen5-bc40-tight-neu-00.neu187d1a144a72d.sqltest-eg1.mscds.com', 'tpcc4000', 30, 120, 'SVMStage', NULL, 24)

MERGE [slo_benchmark_config] AS target
USING @slo_benchmark_config_tmp AS source
ON (target.[processor_count] = source.[processor_count]
    AND target.[parallel_exec_cnt] = source.[parallel_exec_cnt]
    AND target.[hardware_generation] = source.[hardware_generation]
    AND target.[is_bc] = source.[is_bc]
    AND target.[benchmark_name] = source.[benchmark_name]
    AND target.[environment] = source.[environment])
        WHEN MATCHED THEN
        UPDATE SET
                [worker_number] = [source].[worker_number],
                [benchmark_scaling_argument] = [source].[benchmark_scaling_argument],
                [scaled_down] = [source].[scaled_down],
                [server_name] = [source].[server_name],
                [database_name] = [source].[database_name],
                [warmup_timespan_minutes] = [source].[warmup_timespan_minutes],
                [run_timespan_minutes] = [source].[run_timespan_minutes],
                [custom_master_tsql_query] = [source].[custom_master_tsql_query],
                [required_processor_count] = [source].[required_processor_count]
        WHEN NOT MATCHED THEN
        INSERT
        (
                [processor_count],
                [parallel_exec_cnt],
                [hardware_generation],
                [is_bc],
                [benchmark_name],
                [worker_number],
                [benchmark_scaling_argument],
                [scaled_down],
                [server_name],
                [database_name],
                [warmup_timespan_minutes],
                [run_timespan_minutes],
                [custom_master_tsql_query],
                [required_processor_count],
                [environment]
        ) VALUES
        (
                [source].[processor_count],
                [source].[parallel_exec_cnt],
                [source].[hardware_generation],
                [source].[is_bc],
                [source].[benchmark_name],
                [source].[worker_number],
                [source].[benchmark_scaling_argument],
                [source].[scaled_down],
                [source].[server_name],
                [source].[database_name],
                [source].[warmup_timespan_minutes],
                [source].[run_timespan_minutes],
                [source].[custom_master_tsql_query],
                [source].[required_processor_count],
                [source].[environment]
        );
COMMIT TRANSACTION INIT_SLO_BENCH
