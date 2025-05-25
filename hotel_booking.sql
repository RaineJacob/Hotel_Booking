-- Load the dataset
SELECT * 
FROM hotel_bookings;


-- 1. Cancellation Rate by Hotel
SELECT 
    hotel,
    COUNT(*) AS total_bookings,
    SUM(CAST(is_canceled AS INT)) AS cancellations,
    ROUND(100.0 * SUM(CAST(is_canceled AS INT)) / COUNT(*), 2) AS cancellation_rate
FROM hotel_bookings
GROUP BY hotel
ORDER BY cancellation_rate DESC;


-- 2. Monthly Cancellation Trend
SELECT 
    arrival_date_month,
    COUNT(*) AS total_bookings,
    SUM(CAST(is_canceled AS INT)) AS cancellations,
    ROUND(100.0 * SUM(CAST(is_canceled AS INT)) / COUNT(*), 2) AS cancellation_rate
FROM hotel_bookings
GROUP BY arrival_date_month
ORDER BY cancellation_rate DESC;


-- 3. Cancellation Rate by Country (with threshold filter)
SELECT 
    country,
    COUNT(*) AS total_bookings,
    SUM(CAST(is_canceled AS INT)) AS cancellations,
    ROUND(100.0 * SUM(CAST(is_canceled AS INT)) / COUNT(*), 2) AS cancellation_rate
FROM hotel_bookings
GROUP BY country
HAVING COUNT(*) > 100
ORDER BY cancellation_rate DESC;


-- 4. Revenue Lost vs Revenue Kept Due to Cancellations
SELECT 
    hotel,
    SUM(CASE WHEN is_canceled = 1 THEN adr * (stays_in_week_nights + stays_in_weekend_nights) ELSE 0 END) AS revenue_lost,
    SUM(CASE WHEN is_canceled = 0 THEN adr * (stays_in_week_nights + stays_in_weekend_nights) ELSE 0 END) AS revenue_kept
FROM hotel_bookings
GROUP BY hotel;


-- 5. Cancellation Rate by Repeated Guest Status
SELECT 
    is_repeated_guest,
    COUNT(*) AS total_bookings,
    SUM(CAST(is_canceled AS INT)) AS cancellations,
    ROUND(100.0 * SUM(CAST(is_canceled AS INT)) / COUNT(*), 2) AS cancellation_rate
FROM hotel_bookings
GROUP BY is_repeated_guest;


-- 6. Cancellation Rate by Special Requests Count
SELECT 
    total_of_special_requests,
    COUNT(*) AS total_bookings,
    SUM(CAST(is_canceled AS INT)) AS cancellations,
    ROUND(100.0 * SUM(CAST(is_canceled AS INT)) / COUNT(*), 2) AS cancellation_rate
FROM hotel_bookings
GROUP BY total_of_special_requests
ORDER BY cancellation_rate DESC;


-- 7. Lead Time Bucket Cancellation Rate
WITH lead_time_buckets AS (
    SELECT 
        CASE 
            WHEN lead_time <= 7 THEN '0–7 days'
            WHEN lead_time BETWEEN 8 AND 30 THEN '8–30 days'
            WHEN lead_time BETWEEN 31 AND 90 THEN '31–90 days'
            ELSE '90+ days'
        END AS lead_time_range,
        CAST(is_canceled AS INT) AS canceled
    FROM hotel_bookings
)
SELECT 
    lead_time_range,
    COUNT(*) AS bookings,
    SUM(canceled) AS cancellations,
    ROUND(100.0 * SUM(canceled) / COUNT(*), 2) AS cancellation_rate
FROM lead_time_buckets
GROUP BY lead_time_range
ORDER BY cancellation_rate DESC;


-- 8. Average ADR by Hotel and Customer Type
SELECT 
    h1.hotel,
    h1.customer_type,
    ROUND(AVG(h1.adr), 2) AS avg_adr,
    h2.max_adr
FROM hotel_bookings h1
JOIN (
    SELECT customer_type, MAX(adr) AS max_adr
    FROM hotel_bookings
    GROUP BY customer_type
) h2 ON h1.customer_type = h2.customer_type
GROUP BY h1.hotel, h1.customer_type, h2.max_adr
ORDER BY avg_adr DESC;


-- 9. Cancellation Rate by Special Request Bucket
WITH special_requests AS (
    SELECT 
        total_of_special_requests,
        CAST(is_canceled AS INT) AS canceled
    FROM hotel_bookings
)
SELECT 
    total_of_special_requests,
    COUNT(*) AS guests,
    SUM(canceled) AS cancellations,
    ROUND(100.0 * SUM(canceled) / COUNT(*), 2) AS cancellation_rate
FROM special_requests
GROUP BY total_of_special_requests
ORDER BY cancellation_rate DESC;


-- 10. Monthly Booking Seasonality
WITH monthly_bookings AS (
    SELECT 
        arrival_date_month,
        COUNT(*) AS total_booking
    FROM hotel_bookings
    GROUP BY arrival_date_month
)
SELECT 
    arrival_date_month,
    total_booking
FROM monthly_bookings
ORDER BY 
    CASE arrival_date_month
        WHEN 'January' THEN 1
        WHEN 'February' THEN 2
        WHEN 'March' THEN 3
        WHEN 'April' THEN 4
        WHEN 'May' THEN 5
        WHEN 'June' THEN 6
        WHEN 'July' THEN 7
        WHEN 'August' THEN 8
        WHEN 'September' THEN 9
        WHEN 'October' THEN 10
        WHEN 'November' THEN 11
        WHEN 'December' THEN 12
    END;


-- 11. Stay Length Segmentation and Cancellation Rate
WITH stay_segments AS (
    SELECT 
        CASE 
            WHEN (stays_in_week_nights + stays_in_weekend_nights) <= 2 THEN 'Short Stay'
            WHEN (stays_in_week_nights + stays_in_weekend_nights) <= 5 THEN 'Mid Stay'
            ELSE 'Long Stay'
        END AS stay_length,
        CAST(is_canceled AS INT) AS canceled
    FROM hotel_bookings
)
SELECT 
    stay_length,
    COUNT(*) AS bookings,
    SUM(canceled) AS cancellations,
    ROUND(100.0 * SUM(canceled) / COUNT(*), 2) AS cancellation_rate
FROM stay_segments
GROUP BY stay_length;


-- 12. Top Revenue Generating Countries
SELECT 
    country,
    COUNT(*) AS total_bookings,
    SUM(adr * (stays_in_week_nights + stays_in_weekend_nights)) AS revenue_generated
FROM hotel_bookings
WHERE is_canceled = 0
GROUP BY country
HAVING COUNT(*) > 100
ORDER BY revenue_generated DESC;


-- 13. Customer Loyalty (Repeat Guest Rate)
SELECT 
    customer_type,
    COUNT(*) AS total_bookings,
    SUM(is_repeated_guest) AS repeat_guests,
    ROUND(100.0 * SUM(is_repeated_guest) / COUNT(*), 2) AS repeat_rate
FROM hotel_bookings
GROUP BY customer_type
ORDER BY repeat_rate DESC;


-- 14. Average Lead Time by Market Segment
SELECT 
    market_segment,
    AVG(lead_time) AS avg_lead_time,
    RANK() OVER (ORDER BY AVG(lead_time) DESC) AS lead_time_rank
FROM hotel_bookings
GROUP BY market_segment;


-- 15. Booking Cleanliness (Room Type Mismatch Rate)
SELECT 
    hotel,
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN reserved_room_type != assigned_room_type THEN 1 ELSE 0 END) AS mismatched_rooms,
    ROUND(100.0 * SUM(CASE WHEN reserved_room_type != assigned_room_type THEN 1 ELSE 0 END) / COUNT(*), 2) AS mismatch_rate
FROM hotel_bookings
GROUP BY hotel;


-- 16. Daily Revenue Trend with Rolling Average
WITH daily_revenue AS (
    SELECT 
        reservation_status_date AS date,
        SUM(adr * (stays_in_week_nights + stays_in_weekend_nights)) AS revenue
    FROM hotel_bookings
    WHERE is_canceled = 0
    GROUP BY reservation_status_date
)
SELECT 
    *,
    AVG(revenue) OVER (ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_avg_7_day
FROM daily_revenue
ORDER BY date;
