DROP PROCEDURE IF EXISTS pivot_table;
DELIMITER //

CREATE PROCEDURE pivot_table(
	IN tableName VARCHAR(255),
	IN pivotColumns VARCHAR(255),
	IN pivotRows VARCHAR(255),
	IN pivotValues  VARCHAR(255),
	IN groupFunction VARCHAR(20)
)
BEGIN

	-- Usage example:
	-- call pivot_table('data_table', 'columns_field', 'rows_field', 'values_field', 'SUM');

	IF groupFunction IS NULL THEN 
		SET groupFunction = "SUM";
	END IF;

	SET SESSION group_concat_max_len = 1000000;
	-- Prepare the columns
	
	SET @sql = CONCAT("
	SELECT
	GROUP_CONCAT(DISTINCT CONCAT(
	  '",groupFunction,"(
	  CASE WHEN ", pivotColumns, " = \"', ", pivotColumns, ", '\" THEN ", pivotValues, " ELSE 0 END) 
	  AS \"', ",pivotColumns, ", '\"')
	)
	INTO @sql
	FROM (select distinct ", pivotColumns, " from ", tableName, ") as a;
	");

	PREPARE stmt FROM @sql;
	EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
	
	-- Create pivot table
	SET @sql = CONCAT('SELECT COALESCE(', pivotRows, ', "Total") as ', pivotRows, ', ', @sql, ', ', groupFunction, '(', pivotValues, ') AS "Total" FROM ', tableName,' GROUP BY ', pivotRows, ' WITH ROLLUP');

	PREPARE stmt FROM @sql;
	EXECUTE stmt;
	DEALLOCATE PREPARE stmt;
END //

DELIMITER ;
