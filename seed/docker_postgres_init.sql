CREATE SCHEMA IF NOT EXISTS analytics;
-- TIP : Passwords would be encrypted and stored in key management services like AWS KMS and not in code base
CREATE USER event_ingestion WITH encrypted password 'password';

GRANT ALL PRIVILEGES ON schema analytics TO event_ingestion;

CREATE EXTENSION IF NOT EXISTS timescaledb;


CREATE TABLE IF NOT EXISTS analytics.events
(
    id uuid DEFAULT gen_random_uuid(),
    event_name varchar(512),
    event_type varchar(512),
    title varchar(512),
    data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
) ;

-- Convert it to HyperTable
SELECT create_hypertable('analytics.events', by_range('created_at'));

-- Lets create continuous materialized views
-- https://www.timescale.com/learn/real-time-analytics-in-postgres
CREATE MATERIALIZED VIEW public.live_dashboard
WITH (timescaledb.continuous, timescaledb.materialized_only=false) AS
SELECT
    title,
    time_bucket(INTERVAL '5 seconds', created_at) as seconds,
    COUNT(title) as number_of_events
FROM analytics.events
GROUP BY title, seconds;

-- Set up a refresh policy
SELECT add_continuous_aggregate_policy('live_dashboard',
    start_offset => INTERVAL '1 month',
    end_offset => INTERVAL '10 minutes',
    schedule_interval => INTERVAL '15 minute');

-- dummy data
-- insert into analytics.events (event_name, data) values('CUSTOMER_VIEW', '{"title": "My first day at work", "Feeling": "Mixed feeling"}');
-- insert into analytics.events (event_name, data) values('CUSTOMER_VIEW', '{"title": "My second day at work", "Feeling": "Mixed feeling"}');

-- -- Load test
Insert into analytics.events (event_name, event_type, title, data)
select 'CUSTOMER_VIEW'||id, 'CUSTOMER_VIEW', 'My first day at work', '{"title":"My first day "}'
from generate_series(1,100000) as t(id);

Insert into analytics.events (event_name, event_type, title, data)
select 'CUSTOMER_VIEW'||id, 'CUSTOMER_VIEW', 'My second day at work', '{"title":"My second day "}'
from generate_series(1,1000) as t(id);

SELECT CLOCK_TIMESTAMP();

