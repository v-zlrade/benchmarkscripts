/*
Post-Deployment Script Template
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.
 Use SQLCMD syntax to include a file in the post-deployment script.
 Example:      :r .\myfile.sql
 Use SQLCMD syntax to reference a variable in the post-deployment script.
 Example:      :setvar TableName MyTable
               SELECT * FROM [$(TableName)]
--------------------------------------------------------------------------------------
*/


-- We can only set one file to be post deploy script
-- so we call other scripts here
--

-- Insert data to slo benchmark config
:r .\Script.slo_benchmark_configs.sql

-- Insert data for scheduled benchmarks
:r .\Script.scheduled_benchmarks.sql
