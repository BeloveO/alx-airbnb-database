# High Usage Columns in the Database tables
Here are the high-usage columns to focus on, based on typical AirBnB-like queries (JOINs on user_id/property_id, filters by status/dates, ORDER BY on names/titles, WHERE on emails/dates):

## 1. Users table

- user_id (PK): used in JOINs to bookings; sometimes in ORDER BY.
- email: frequent WHERE lookups (login/uniqueness).
- last_name, first_name: used in ORDER BY; sometimes filtered (search).
- created_at: filtered or sorted by signup date.
- status/active: filtered to exclude suspended/inactive users.

### User Table High-Usage Columns

**Columns likely used in WHERE clauses:**
```sql
-- Authentication and lookups
WHERE email = 'user@example.com'
WHERE last_name = 'john_doe'
WHERE user_id = 123
WHERE status = 'active'

-- Date-based queries
WHERE created_at >= '2024-01-01'
WHERE last_login >= CURRENT_DATE - INTERVAL '30 days'
```

--- 
## 2. Bookings table

- booking_id (PK): primary key access and sorting in reports.
- user_id (FK): JOIN to users; frequent WHERE filter (user’s bookings).
- property_id (FK): JOIN to properties; frequent WHERE/GROUP BY (per-property stats).
- start_date, end_date: WHERE date-range searches and availability checks; ORDER BY.
- created_at: recent activity feeds, audits; ORDER BY.
- status: WHERE filters (confirmed/cancelled/completed).
- price_total or nightly_rate (if present): reporting/filtering.
- payment_status: WHERE filters (unpaid, partial, paid).

### Booking Table High-Usage Columns

**Columns likely used in WHERE/JOIN clauses:**
```sql
-- User and property relationships
WHERE user_id = 456
WHERE property_id = 789
WHERE status IN ('confirmed', 'completed')

-- Date range queries (very common!)
WHERE start_date BETWEEN '2024-01-01' AND '2024-01-31'
WHERE end_out_date >= CURRENT_DATE
WHERE booking_date >= CURRENT_DATE - INTERVAL '90 days'

-- Financial queries
WHERE price_total > 1000
WHERE payment_status = 'paid'
```

---
## 3. Properties table

- property_id (PK): JOIN to bookings and reviews; sometimes ORDER BY.
- title: used in ORDER BY/search results.
- host_id (FK to users): JOINs for host dashboards.
- city_id/location fields (city, state, country or geohash): frequent WHERE filters.
- price/nightly_rate: filtered/sorted in search.
- bedrooms/capacity/property_type: faceted filters.
- created_at: newest listings sort/filter.
- active/status: WHERE to hide inactive/unlisted.

### Property Table High-Usage Columns

**Columns likely used in WHERE clauses:**
```sql
-- Location-based queries
WHERE city = 'New York'
WHERE country = 'USA'
WHERE zip_code = '10001'

-- Filtering and search
WHERE property_type = 'apartment'
WHERE price_per_night BETWEEN 50 AND 200
WHERE bedrooms >= 2
WHERE rating >= 4.0
WHERE active = true

-- Host relationships
WHERE host_id = 123
```

---
## Indexing tips (to improve performance)

- Ensure all PKs and FKs are indexed:
  - bookings(user_id), bookings(property_id)
  - properties(host_id), properties(city_id)
  - users(email) UNIQUE
- Common composites:
  - bookings(property_id, start_date) for availability and per-property ranges.
  - bookings(user_id, start_date DESC) for user booking history.
  - bookings(property_id, created_at DESC) for recent bookings per property.
  - users(last_name, first_name) if you sort/filter by names often.
  - properties(city_id, price) for search filtering; properties(active, city_id) if you filter by active first.
- ORDER BY alone rarely benefits from an index unless paired with a selective WHERE or the index fully covers the query.
- Avoid over-indexing; monitor actual query plans and add indexes where they reduce cost.


## JOIN Operations Analysis

**Common JOIN patterns that need indexing:**
```sql
-- User-Booking joins
SELECT * FROM users u
JOIN bookings b ON u.user_id = b.user_id  -- Needs index on bookings.user_id

-- Property-Booking joins  
SELECT * FROM properties p
JOIN bookings b ON p.property_id = b.property_id  -- Needs index on bookings.property_id

-- User-Property joins (for hosts)
SELECT * FROM users u
JOIN properties p ON u.user_id = p.host_id  -- Needs index on properties.host_id
```

## Monitoring and Maintenance

**Check existing indexes:**
```sql
SELECT * FROM pg_indexes WHERE tablename = 'bookings';
```

**Monitor query performance:**
```sql
-- Enable query logging for slow queries
-- Analyze EXPLAIN plans for frequently run queries
```

**Consider partial indexes for better performance:**
```sql
-- Index only active bookings
CREATE INDEX idx_bookings_active ON bookings(booking_status) 
WHERE booking_status IN ('confirmed', 'pending');

-- Index only available properties  
CREATE INDEX idx_properties_available ON properties(is_available) 
WHERE is_available = true;
```

## Priority Order for Index Creation

1. **Primary keys** (should already be indexed)
2. **Foreign keys** (user_id, property_id in bookings table)
3. **Date columns** used in range queries (booking_date, check_in_date)
4. **Status columns** used in WHERE clauses
5. **Search columns** (email, city, property_type)
6. **Composite indexes** for common query patterns

Start with the most frequently queried columns and monitor performance before adding additional indexes, as each index adds overhead to write operations.



# Measure the Query Performance

## 1. First, Check Existing Indexes

```sql
-- Check current indexes on your tables
SELECT 
    tablename, 
    indexname, 
    indexdef 
FROM pg_indexes 
WHERE tablename IN ('users', 'bookings', 'properties')
ORDER BY tablename, indexname;
```

## 2. Create Test Queries for Performance Measurement

**Common performance-critical queries to test:**

```sql
-- Query 1: User bookings with date filter
EXPLAIN ANALYZE
SELECT u.username, b.booking_id, b.check_in_date, b.check_out_date
FROM users u
JOIN bookings b ON u.user_id = b.user_id
WHERE u.email = 'test@example.com'
AND b.booking_date >= '2024-01-01';

-- Query 2: Property bookings by date range
EXPLAIN ANALYZE
SELECT p.property_name, COUNT(b.booking_id) as booking_count
FROM properties p
JOIN bookings b ON p.property_id = b.property_id
WHERE p.city = 'New York'
AND b.check_in_date BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY p.property_name;

-- Query 3: Search available properties
EXPLAIN ANALYZE
SELECT property_name, price_per_night, bedrooms, rating
FROM properties
WHERE city = 'Los Angeles'
AND property_type = 'apartment'
AND bedrooms >= 2
AND price_per_night BETWEEN 100 AND 300
AND is_available = true
ORDER BY rating DESC;

-- Query 4: User booking history
EXPLAIN ANALYZE
SELECT b.booking_id, p.property_name, b.check_in_date, b.total_amount
FROM bookings b
JOIN properties p ON b.property_id = p.property_id
WHERE b.user_id = 123
AND b.booking_status = 'completed'
ORDER BY b.booking_date DESC
LIMIT 10;
```

## 3. Measure Performance BEFORE Indexing

Run each query with `EXPLAIN ANALYZE` and note these key metrics:

```sql
-- Example: Measure Query 1 before indexes
EXPLAIN ANALYZE
SELECT u.username, b.booking_id, b.check_in_date, b.check_out_date
FROM users u
JOIN bookings b ON u.user_id = b.user_id
WHERE u.email = 'test@example.com'
AND b.booking_date >= '2024-01-01';
```

**Key metrics to record:**
- Execution Time
- Planning Time
- Total Cost
- Seq Scans vs Index Scans
- Rows Removed by Filter

## 4. Create Recommended Indexes

```sql
-- User table indexes
CREATE UNIQUE INDEX IF NOT EXISTS ux_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

-- Booking table indexes  
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_booking_date ON bookings(booking_date);
CREATE INDEX IF NOT EXISTS idx_bookings_check_in ON bookings(check_in_date);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(booking_status);
CREATE INDEX IF NOT EXISTS idx_bookings_user_date ON bookings(user_id, booking_date);

-- Property table indexes
CREATE INDEX IF NOT EXISTS idx_properties_city ON properties(city);
CREATE INDEX IF NOT EXISTS idx_properties_property_type ON properties(property_type);
CREATE INDEX IF NOT EXISTS idx_properties_price ON properties(price_per_night);
CREATE INDEX IF NOT EXISTS idx_properties_bedrooms ON properties(bedrooms);
CREATE INDEX IF NOT EXISTS idx_properties_availability ON properties(is_available);
CREATE INDEX IF NOT EXISTS idx_properties_location_search ON properties(city, property_type, price_per_night);
```

## 5. Measure Performance AFTER Indexing

Run the same queries again with `EXPLAIN ANALYZE`:

```sql
-- Same Query 1 after indexes
EXPLAIN ANALYZE
SELECT u.username, b.booking_id, b.check_in_date, b.check_out_date
FROM users u
JOIN bookings b ON u.user_id = b.user_id
WHERE u.email = 'test@example.com'
AND b.booking_date >= '2024-01-01';
```

## 6. Performance Comparison Template

Create a table to track results:

```sql
CREATE TABLE performance_comparison (
    query_id SERIAL PRIMARY KEY,
    query_description TEXT,
    before_execution_time INTERVAL,
    after_execution_time INTERVAL,
    before_planning_time INTERVAL, 
    after_planning_time INTERVAL,
    before_total_cost FLOAT,
    after_total_cost FLOAT,
    performance_improvement FLOAT,
    notes TEXT
);
```

## 7. Automated Testing Script

```sql
-- Create a function to test multiple queries
CREATE OR REPLACE FUNCTION test_query_performance()
RETURNS TABLE (
    query_name TEXT,
    before_time INTERVAL,
    after_time INTERVAL,
    improvement_percent NUMERIC
) AS $$
DECLARE
    before_start TIMESTAMP;
    before_end TIMESTAMP;
    after_start TIMESTAMP;
    after_end TIMESTAMP;
    query_text TEXT;
BEGIN
    -- Test Query 1
    query_text := $$
        SELECT u.username, b.booking_id, b.check_in_date, b.check_out_date
        FROM users u
        JOIN bookings b ON u.user_id = b.user_id
        WHERE u.email = 'test@example.com'
        AND b.booking_date >= '2024-01-01'
    $$;
    
    before_start := clock_timestamp();
    EXECUTE 'EXPLAIN ANALYZE ' || query_text;
    before_end := clock_timestamp();
    
    -- (Would run after indexes in real scenario)
    after_start := clock_timestamp();
    EXECUTE 'EXPLAIN ANALYZE ' || query_text;
    after_end := clock_timestamp();
    
    query_name := 'User Bookings by Email';
    before_time := before_end - before_start;
    after_time := after_end - after_start;
    improvement_percent := (EXTRACT(EPOCH FROM before_time) - EXTRACT(EPOCH FROM after_time)) / EXTRACT(EPOCH FROM before_time) * 100;
    
    RETURN NEXT;
    
    -- Add more queries here...
END;
$$ LANGUAGE plpgsql;
```

## 8. Analyze Index Usage

After creating indexes, check if they're being used:

```sql
-- Check index usage statistics
SELECT 
    schemaname,
    relname,
    indexrelname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_all_indexes 
WHERE schemaname = 'public'
AND relname IN ('users', 'bookings', 'properties')
ORDER BY idx_scan DESC;
```

## 9. Sample Results Analysis

Here's what to look for in `EXPLAIN ANALYZE` output:

**Before indexes:**
- `Seq Scan` on large tables
- High `cost` values
- `Rows Removed by Filter: XXXXX` (indicates scanning many unnecessary rows)

**After indexes:**
- `Index Scan` or `Bitmap Index Scan`
- Lower `cost` values
- Faster execution time
- Better join performance with `Nested Loop` instead of `Hash Join`

## 10. Generate Performance Report

```sql
-- Compare specific metrics
SELECT 
    'Execution Time' as metric,
    (SELECT SUM(EXTRACT(EPOCH FROM before_execution_time)) FROM performance_comparison) as before_total,
    (SELECT SUM(EXTRACT(EPOCH FROM after_execution_time)) FROM performance_comparison) as after_total,
    ROUND((SELECT SUM(EXTRACT(EPOCH FROM before_execution_time)) - SUM(EXTRACT(EPOCH FROM after_execution_time)) 
           FROM performance_comparison) / SUM(EXTRACT(EPOCH FROM before_execution_time)) * 100, 2) as improvement_percent
FROM performance_comparison
GROUP BY metric;
```

## General measurement tips

- Run each query twice and compare the second run (to reduce cold-cache effects).
- Use the same session/settings for both runs.
- After creating indexes, refresh stats (PostgreSQL: ANALYZE; MySQL: ANALYZE TABLE).
- Compare changes in: plan shape (Seq Scan → Index Scan), rows examined, buffers/IO, and total execution time.
