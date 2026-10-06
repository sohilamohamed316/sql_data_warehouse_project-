/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to
    populate the 'silver' schema tables from the 'bronze' schema.
Actions Performed:
    - Truncates Silver tables.
    - Inserts transformed and cleansed data from Bronze into Silver tables.

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC silver.load_silver;
===============================================================================
*/
CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN

DECLARE @start_time DATETIME,
        @end_time DATETIME,
        @start_total DATETIME,
        @end_total DATETIME;

SET @start_total = GETDATE();

--1
PRINT '>>> TRUNCATING silver.erp_px_cat_g1v2';

SET @start_time = GETDATE();

TRUNCATE TABLE silver.erp_px_cat_g1v2;

INSERT INTO silver.erp_px_cat_g1v2
(id,
 cat,
 subcat,
 maintenance)
SELECT 
id,
cat,
subcat,
maintenance 
FROM bronze.erp_px_cat_g1v2;

SET @end_time = GETDATE();

PRINT '>> loading time '
    + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
    + ' seconds';


--2
PRINT '>>> TRUNCATING silver.erp_LOC_A101';

SET @start_time = GETDATE();

TRUNCATE TABLE silver.erp_LOC_A101;

INSERT INTO silver.erp_LOC_A101
(cid, cntry)
SELECT 
REPLACE(cid,'-','_') cid,
CASE 
    WHEN TRIM(cntry) = 'DE' THEN 'germany'
    WHEN TRIM(cntry) IN ('usa','us') THEN 'united states'
    WHEN TRIM(cntry) = ' ' OR cntry IS NULL THEN 'n/a'
    ELSE TRIM(cntry)
END AS cntry
FROM bronze.erp_LOC_A101;

SET @end_time = GETDATE();

PRINT '>> loading time '
    + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
    + ' seconds';


--3
PRINT '>>> TRUNCATING silver.erp_cust_az12';

SET @start_time = GETDATE();

TRUNCATE TABLE silver.erp_cust_az12;

INSERT INTO silver.erp_cust_az12
(CID, BDATE, GEN)
SELECT
CASE 
    WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID,4,LEN(CID))
    ELSE CID
END AS CID,

CASE 
    WHEN BDATE > GETDATE() THEN NULL
    ELSE BDATE
END AS BDATE,

CASE 
    WHEN UPPER(TRIM(GEN)) IN ('f','FEMALE') THEN 'female'
    WHEN UPPER(TRIM(GEN)) IN ('m','MALE') THEN 'male'
    ELSE 'n/a'
END AS GEN

FROM bronze.erp_cust_az12;

SET @end_time = GETDATE();

PRINT '>> loading time '
    + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
    + ' seconds';


--4
PRINT '>>> TRUNCATING silver.crm_cus_info';

SET @start_time = GETDATE();

TRUNCATE TABLE silver.crm_cus_info;

INSERT INTO silver.crm_cus_info (
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_material_status,
    cst_gndr,
    cst_create_date
)
SELECT 
cst_id,
cst_key,
TRIM(cst_firstname) AS cst_firstname,
TRIM(cst_lastname) AS cst_lastname,

CASE 
    WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
    WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
    ELSE 'n/a'
END AS cst_material_status,

CASE 
    WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
    WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
    ELSE 'n/a'
END AS cst_gndr,

cst_create_date

FROM (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY cst_id 
            ORDER BY cst_create_date DESC
        ) AS flag_last
    FROM bronze.crm_cus_info
) t

WHERE flag_last = 1;

SET @end_time = GETDATE();

PRINT '>> loading time '
    + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
    + ' seconds';


--5
PRINT '>>> TRUNCATING silver.crm_prd_info';

SET @start_time = GETDATE();

TRUNCATE TABLE silver.crm_prd_info;

INSERT INTO silver.crm_prd_info (
    prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
)
SELECT 
prd_id,
REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,
prd_nm,
ISNULL(prd_cost,0) AS prd_cost,

CASE 
    WHEN UPPER(TRIM(prd_line)) = 'm' THEN 'montain'
    WHEN UPPER(TRIM(prd_line)) = 'r' THEN 'road'
    WHEN UPPER(TRIM(prd_line)) = 's' THEN 'other sales'
    WHEN UPPER(TRIM(prd_line)) = 't' THEN 'touring'
    ELSE 'n/a'
END AS prd_line,

CAST(prd_start_dt AS DATE) AS prd_start_dt,

CAST(
    DATEADD(
        DAY,
        -1,
        LEAD(prd_start_dt) OVER (
            PARTITION BY prd_key 
            ORDER BY prd_start_dt
        )
    ) AS DATE
) AS prd_end_dt

FROM bronze.crm_prd_info;

SET @end_time = GETDATE();

PRINT '>> loading time '
    + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
    + ' seconds';


--6
PRINT '>>> TRUNCATING silver.crm_sales_details';

SET @start_time = GETDATE();

TRUNCATE TABLE silver.crm_sales_details;

INSERT INTO silver.crm_sales_details (
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
)
SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,

CASE 
    WHEN sls_order_dt = 0 
         OR LEN(CAST(sls_order_dt AS VARCHAR)) != 8 
    THEN NULL
    ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
END AS sls_order_dt,

CASE 
    WHEN sls_ship_dt = 0 
         OR LEN(CAST(sls_ship_dt AS VARCHAR)) != 8 
    THEN NULL
    ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
END AS sls_ship_dt,

CASE 
    WHEN sls_due_dt = 0 
         OR LEN(CAST(sls_due_dt AS VARCHAR)) != 8 
    THEN NULL
    ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
END AS sls_due_dt,

CASE 
    WHEN sls_sales IS NULL 
         OR sls_sales <= 0 
         OR sls_sales != sls_quantity * ABS(sls_price)
    THEN sls_quantity * ABS(sls_price)
    ELSE sls_sales
END AS sls_sales,

sls_quantity,

CASE 
    WHEN sls_price IS NULL 
         OR sls_price <= 0 
    THEN sls_sales / NULLIF(sls_quantity, 0)
    ELSE sls_price
END AS sls_price

FROM bronze.crm_sales_details;

SET @end_time = GETDATE();

PRINT '>> loading time '
    + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
    + ' seconds';


-- Total Silver Loading Time
SET @end_total = GETDATE();

PRINT '========================================';
PRINT '>> Total loading time '
    + CAST(DATEDIFF(SECOND, @start_total, @end_total) AS NVARCHAR)
    + ' seconds';
PRINT '========================================';

END
