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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
) ;

-- Convert it to HyperTable
SELECT create_hypertable('analytics.events', by_range('created_at'));



-- dummy data
-- insert into analytics.events (event_name, data) values('CUSTOMER_VIEW', '{"title": "My first day at work", "Feeling": "Mixed feeling"}');
-- insert into analytics.events (event_name, data) values('CUSTOMER_VIEW', '{"title": "My second day at work", "Feeling": "Mixed feeling"}');

-- -- Load test
Insert into analytics.events (event_name, event_type, title, data)
select 'CUSTOMER_VIEW'||id, 'CUSTOMER_VIEW', 'My first day at work', '{"title":"My first day "}'
from generate_series(1,10000) as t(id);

SELECT CLOCK_TIMESTAMP();

