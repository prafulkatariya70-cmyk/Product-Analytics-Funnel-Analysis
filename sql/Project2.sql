create database project_two
use project_two

select count(*) from events
select count(*) from users

-- USERS AT EACH STAGE --

select event_type,
count(distinct user_id) as users
from events
group by event_type
order by users desc

-- CONVERSION RATE --

SELECT 
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) * 100.0 /
    COUNT(DISTINCT CASE WHEN event_type = 'signup' THEN user_id END)
    AS conversion_rate
FROM events;

-- DROP-OFF ANALYSIS --
select event_type,
count(distinct user_id) as users,
LAG(COUNT(DISTINCT user_id)) OVER (
        ORDER BY 
            CASE 
                WHEN event_type = 'signup' THEN 1
                WHEN event_type = 'login' THEN 2
                WHEN event_type = 'view_product' THEN 3
                WHEN event_type = 'add_to_cart' THEN 4
                WHEN event_type = 'purchase' THEN 5
            END
    ) AS previous_stage
FROM events
GROUP BY event_type;

-- FUNNEL % --

SELECT 
    event_type,
    COUNT(DISTINCT user_id) AS users,
    ROUND(
        COUNT(DISTINCT user_id) * 100.0 /
        (SELECT COUNT(DISTINCT user_id) 
         FROM events 
         WHERE event_type = 'signup'),
    2) AS percentage_of_signup
FROM events
GROUP BY event_type
order by users desc

-- STAGE-TO-STAGE CONVERSION --

WITH funnel AS (
    SELECT 
        event_type,
        COUNT(DISTINCT user_id) AS users
    FROM events
    GROUP BY event_type
)

SELECT 
    f1.event_type AS current_stage,
    f1.users AS current_users,
    f2.event_type AS next_stage,
    f2.users AS next_users,
    ROUND(f2.users * 100.0 / f1.users, 2) AS conversion_percentage
FROM funnel f1
JOIN funnel f2 
ON 
    CASE 
        WHEN f1.event_type = 'signup' AND f2.event_type = 'login' THEN 1
        WHEN f1.event_type = 'login' AND f2.event_type = 'view_product' THEN 1
        WHEN f1.event_type = 'view_product' AND f2.event_type = 'add_to_cart' THEN 1
        WHEN f1.event_type = 'add_to_cart' AND f2.event_type = 'purchase' THEN 1
        ELSE 0
    END = 1;