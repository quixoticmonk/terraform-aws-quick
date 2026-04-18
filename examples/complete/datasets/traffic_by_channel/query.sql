SELECT
    channel,
    device_type,
    COUNT(*)                AS sessions,
    SUM(page_views)         AS page_views,
    SUM(converted_order_id IS NOT NULL) AS conversions
FROM storefront.web_sessions
WHERE session_start >= CURRENT_DATE - INTERVAL '7' DAY
GROUP BY channel, device_type
