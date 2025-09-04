-- --------------------------
-- If dealing with very large datasets, consider table partitioning.
-- Assume the Booking table is large and query performance is slow.
-- Assuming bookings table is partitioned by start_date.
-- Query specific partition for better performance.
-- -------------------------
SELECT 
    b.booking_id,
    b.booking_date,
    b.check_in_date,
    b.check_out_date,
    b.total_amount,
    b.booking_status,
    u.user_id,
    u.username,
    u.email,
    p.property_id,
    p.property_name,
    p.city,
    p.country,
    json_build_object(
        'payments', (
            SELECT json_agg(
                json_build_object(
                    'method', payment_method,
                    'date', payment_date,
                    'amount', amount,
                    'status', transaction_status
                )
            )
            FROM payments 
            WHERE booking_id = b.booking_id
        )
    ) as payment_info
FROM bookings b
INNER JOIN users u ON b.user_id = u.user_id
INNER JOIN properties p ON b.property_id = p.property_id
WHERE b.check_in_date >= '2024-01-01'
  AND b.check_out_date < '2024-02-01' -- Query specific partition
ORDER BY b.booking_date DESC
LIMIT 100;
