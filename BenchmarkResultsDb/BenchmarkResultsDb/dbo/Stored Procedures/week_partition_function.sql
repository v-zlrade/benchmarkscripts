CREATE PARTITION FUNCTION [week_partition_function]
	(
	int
	)
	AS RANGE LEFT
	FOR VALUES (1, 2, 3, 4, 5, 6, 7, 8)