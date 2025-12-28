# Database Performance Recommendations for Ride Maintenance

## Required Database Indexes

To ensure optimal performance of the auto-cancellation and no-show processing features, add these indexes:

### 1. Rides Table Indexes

```sql
-- Index for finding expired rides
CREATE NONCLUSTERED INDEX IX_Rides_Status_TravelDate 
ON Rides(Status, TravelDate) 
INCLUDE (Id, RideNumber, DriverId, UpdatedAt)
WHERE Status IN ('scheduled', 'upcoming');

-- Additional index for ride lookups
CREATE NONCLUSTERED INDEX IX_Rides_TravelDate_Status 
ON Rides(TravelDate, Status) 
INCLUDE (Id, RideNumber);
```

### 2. Bookings Table Indexes

```sql
-- Index for finding bookings by ride with status
CREATE NONCLUSTERED INDEX IX_Bookings_RideId_Status 
ON Bookings(RideId, Status) 
INCLUDE (Id, BookingNumber, PassengerId, PaymentStatus, IsVerified);

-- Index for no-show detection
CREATE NONCLUSTERED INDEX IX_Bookings_Status_IsVerified 
ON Bookings(Status, IsVerified) 
INCLUDE (Id, RideId, PassengerId, BookingNumber, PaymentStatus)
WHERE Status IN ('confirmed', 'active') AND IsVerified = 0;

-- Index for payment status lookups
CREATE NONCLUSTERED INDEX IX_Bookings_PaymentStatus 
ON Bookings(PaymentStatus) 
INCLUDE (Id, Status);
```

### 3. Users Table Index

```sql
-- Index for user existence validation
CREATE NONCLUSTERED INDEX IX_Users_Id 
ON Users(Id);
-- Note: This may already exist as primary key
```

### 4. Notifications Table Index

```sql
-- Index for notification queries
CREATE NONCLUSTERED INDEX IX_Notifications_UserId_CreatedAt 
ON Notifications(UserId, CreatedAt DESC) 
INCLUDE (Id, Type, IsRead);
```

## Query Performance Tips

### 1. Monitor Query Execution Plans
```sql
-- Enable execution plan analysis
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

-- Test your maintenance queries
SELECT * FROM Rides 
WHERE Status IN ('scheduled', 'upcoming') 
AND TravelDate <= GETDATE();
```

### 2. Check Index Fragmentation
```sql
-- Check index fragmentation monthly
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent,
    ips.page_count
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 10
AND ips.page_count > 1000
ORDER BY ips.avg_fragmentation_in_percent DESC;

-- Rebuild fragmented indexes
ALTER INDEX IX_Rides_Status_TravelDate ON Rides REBUILD;
```

### 3. Update Statistics Regularly
```sql
-- Update statistics for better query optimization
UPDATE STATISTICS Rides WITH FULLSCAN;
UPDATE STATISTICS Bookings WITH FULLSCAN;
UPDATE STATISTICS Users WITH FULLSCAN;
UPDATE STATISTICS Notifications WITH FULLSCAN;
```

## Configuration Tuning

### 1. Batch Size Configuration
- **Default**: 100 records per batch
- **Small dataset (<10K rides)**: 100-200
- **Medium dataset (10K-100K rides)**: 50-100
- **Large dataset (>100K rides)**: 25-50

Adjust in `appsettings.json`:
```json
"RideAutoCancellation": {
  "BatchSize": 100
},
"BookingNoShow": {
  "BatchSize": 50
}
```

### 2. Query Timeout
- **Default**: 300 seconds (5 minutes)
- Increase if dealing with very large datasets

```json
"RideAutoCancellation": {
  "QueryTimeout": 600
}
```

### 3. Connection Pool Settings
Update connection string:
```json
"ConnectionStrings": {
  "DefaultConnection": "Server=...;Min Pool Size=5;Max Pool Size=100;Connection Timeout=30;"
}
```

## Monitoring Recommendations

### 1. Track Slow Queries
```sql
-- Find slow queries
SELECT 
    qs.execution_count,
    qs.total_worker_time / qs.execution_count AS avg_cpu_time_ms,
    qs.total_elapsed_time / qs.execution_count AS avg_elapsed_time_ms,
    SUBSTRING(qt.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2) + 1) AS statement_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
WHERE qt.text LIKE '%Rides%' OR qt.text LIKE '%Bookings%'
ORDER BY avg_elapsed_time_ms DESC;
```

### 2. Monitor Lock Contention
```sql
-- Check for blocking
SELECT 
    blocking_session_id,
    session_id,
    wait_type,
    wait_time,
    wait_resource
FROM sys.dm_exec_requests
WHERE blocking_session_id <> 0;
```

### 3. Application-Level Monitoring
Add to your logging:
- Batch processing time
- Number of records processed
- Memory usage
- Database connection count

Example log output:
```
[INFO] Batch 1: Processed 100 rides in 2.5s
[INFO] Memory usage: 45MB
[INFO] Active DB connections: 3
```

## Performance Benchmarks

### Expected Performance (with indexes)
- **Small dataset (100 rides)**: < 1 second
- **Medium dataset (1,000 rides)**: 2-5 seconds  
- **Large dataset (10,000 rides)**: 30-60 seconds
- **Very large dataset (100,000 rides)**: 5-10 minutes

### Warning Signs
❌ Query timeout errors  
❌ High CPU usage (>80%) for extended periods  
❌ Memory pressure warnings  
❌ Database connection pool exhaustion  
❌ Deadlocks or blocking chains  

## Scaling Recommendations

### For Growing Datasets (>100K rides):
1. **Partition tables** by TravelDate
2. **Archive old data** (older than 1 year)
3. **Implement read replicas** for reporting
4. **Consider message queue** for notifications (RabbitMQ/Azure Service Bus)
5. **Move to distributed processing** (Azure Functions/AWS Lambda)

### Database Partitioning Example
```sql
-- Create partition function
CREATE PARTITION FUNCTION pfRidesByMonth (DATE)
AS RANGE RIGHT FOR VALUES 
('2024-01-01', '2024-02-01', '2024-03-01', ...);

-- Create partition scheme
CREATE PARTITION SCHEME psRidesByMonth
AS PARTITION pfRidesByMonth
ALL TO ([PRIMARY]);

-- Recreate table with partitioning
CREATE TABLE Rides_New (
    Id uniqueidentifier NOT NULL,
    TravelDate date NOT NULL,
    ...
) ON psRidesByMonth(TravelDate);
```

## Testing Load

### Load Testing Script
```bash
# Test with varying data volumes
dotnet run --project LoadTest -- \
  --endpoint "http://localhost:5000/api/RideMaintenance/cancel-expired-rides" \
  --rides 1000 \
  --concurrent-requests 5 \
  --duration 60s
```

### SQL Load Generation
```sql
-- Create test data for performance testing
INSERT INTO Rides (Id, Status, TravelDate, ...)
SELECT 
    NEWID(),
    'scheduled',
    DATEADD(DAY, -ABS(CHECKSUM(NEWID()) % 365), GETDATE()),
    ...
FROM sys.all_columns c1, sys.all_columns c2
WHERE c1.column_id <= 100; -- Adjust count as needed
```

## Maintenance Schedule

| Task | Frequency | Command |
|------|-----------|---------|
| Update statistics | Weekly | `UPDATE STATISTICS` |
| Rebuild indexes | Monthly | `ALTER INDEX ... REBUILD` |
| Check fragmentation | Monthly | Query index_physical_stats |
| Archive old data | Quarterly | Custom archive script |
| Performance review | Quarterly | Review slow query log |

## Emergency Response

If performance degrades:

1. **Check current locks**: `sp_who2 'active'`
2. **Kill long-running queries**: `KILL <session_id>`
3. **Disable background service temporarily**: Set `Enabled: false` in appsettings.json
4. **Reduce batch size**: Lower BatchSize to 10-25
5. **Schedule during off-peak**: Change DailyRunTime to 3:00 AM
6. **Review indexes**: Ensure all recommended indexes exist

## Contact & Support

For performance issues:
1. Check application logs: `/logs/RideSharing.API.log`
2. Check SQL Server error log
3. Enable verbose logging: Set `Logging:LogLevel:Default` to `Debug`
4. Contact DBA team with query execution plans
