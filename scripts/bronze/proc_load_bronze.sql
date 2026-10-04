/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None. 
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
declare @start_time datetime, @end_time datetime,@first_time datetime,@last_time datetime
  
 BEGIN TRY
  PRINT'============================';
   PRINT'LOADING BRONZE LAYER';
   PRINT'============================';
   PRINT'-----------------';
   PRINT'CRM LOADING';
   PRINT'-----------------';
   set @first_time= GETDATE();
--1
set @start_time= getdate();
TRUNCATE TABLE bronze.crm_cus_info;
BULK INSERT bronze.crm_cus_info
FROM  'C:\Users\nv\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
WITH (
FIRSTROW = 2,
FIELDTERMINATOR =',',
TABLOCK
)
set @end_time= getdate();
  print'>>loading time'+ cast(datediff(second,@start_time,@end_time)as nvarchar) + 'seconds';


--2
set @start_time= getdate();
TRUNCATE TABLE bronze.crm_prd_info;
BULK INSERT bronze.crm_prd_info
FROM  'C:\Users\nv\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
WITH (
FIRSTROW = 2,
FIELDTERMINATOR =',',
TABLOCK
)
set @end_time= getdate();
  print'>>loading time'+ cast(datediff(second,@start_time,@end_time)as nvarchar) + 'seconds';


--3
set @start_time= getdate();
TRUNCATE TABLE bronze.crm_sales_details;
BULK INSERT bronze.crm_sales_details
FROM  'C:\Users\nv\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
WITH (
FIRSTROW = 2,
FIELDTERMINATOR =',',
TABLOCK
)
set @end_time= getdate();
  print'>>loading time'+ cast(datediff(second,@start_time,@end_time)as nvarchar) + 'seconds';


PRINT'---------------';
PRINT'ERP LOADING';
PRINT'---------------';

--4
set @start_time= getdate();
TRUNCATE TABLE bronze.erp_cust_az12;

BULK INSERT bronze.erp_cust_az12
FROM  'C:\Users\nv\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
WITH (
FIRSTROW = 2,
FIELDTERMINATOR =',',
TABLOCK
)
set @end_time= getdate();
  print'>>loading time'+ cast(datediff(second,@start_time,@end_time)as nvarchar )+ 'seconds';

--5
set @start_time= getdate();
TRUNCATE TABLE bronze.erp_LOC_A101;

BULK INSERT bronze.erp_LOC_A101
FROM  'C:\Users\nv\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
WITH (
FIRSTROW = 2,
FIELDTERMINATOR =',',
TABLOCK
)
set @end_time= getdate();
  print'>>loading time'+ cast(datediff(second,@start_time,@end_time)as nvarchar) + 'seconds';

--6
set @start_time= getdate();
BULK INSERT bronze.erp_px_cat_g1v2
FROM  'C:\Users\nv\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
WITH (
FIRSTROW = 2,
FIELDTERMINATOR =',',
TABLOCK
)
set @end_time= getdate();
   print'>>loading time'+ cast(datediff(second,@start_time,@end_time)as nvarchar )+ 'seconds';
 
 set @last_time =GETDATE();
   print '>>>>> all time for bronze layer' + cast(datediff(second,@first_time,@last_time)as nvarchar )+'seconds';
 END TRY
 BEGIN CATCH
   PRINT'============================';
   print'erorr ocurred during loading bronze layer';
   PRINT'============================';

  END CATCH
end








