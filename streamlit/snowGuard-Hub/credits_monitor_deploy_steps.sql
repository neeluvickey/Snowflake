-- ============================================================
-- CREDITS MONITOR — DEPLOY STEPS
-- ============================================================
-- App:     STREAMLIT_APPS.CREDITS_MONITOR.CREDITS_MONITOR_APP
-- Schema:  STREAMLIT_APPS.CREDITS_MONITOR
-- Stage:   STREAMLIT_APPS.CREDITS_MONITOR.APP_STAGE
-- Source:  /streamlit_apps/credits_monitor_app.sql
-- ============================================================


-- ============================================================
-- STEP 1: CREATE DATABASE, SCHEMA & STAGE
-- ============================================================
-- Each Streamlit app gets its own dedicated schema and stage
-- within the STREAMLIT_APPS database.

CREATE DATABASE IF NOT EXISTS STREAMLIT_APPS;
CREATE SCHEMA IF NOT EXISTS STREAMLIT_APPS.CREDITS_MONITOR;
CREATE OR REPLACE STAGE STREAMLIT_APPS.CREDITS_MONITOR.APP_STAGE;


-- ============================================================
-- STEP 2: UPLOAD APP SOURCE TO STAGE
-- ============================================================

COPY FILES INTO @STREAMLIT_APPS.CREDITS_MONITOR.APP_STAGE
    FROM 'snow://workspace/USER$.PUBLIC.DEFAULT$/versions/live/streamlit_apps'
    FILES=('credits_monitor_app.sql');


-- ============================================================
-- STEP 3: VERIFY FILE ON STAGE
-- ============================================================

LIST @STREAMLIT_APPS.CREDITS_MONITOR.APP_STAGE;


-- ============================================================
-- STEP 4: CREATE THE STREAMLIT APP
-- ============================================================

CREATE OR REPLACE STREAMLIT STREAMLIT_APPS.CREDITS_MONITOR.CREDITS_MONITOR_APP
    FROM '@STREAMLIT_APPS.CREDITS_MONITOR.APP_STAGE'
    MAIN_FILE = 'credits_monitor_app.sql'
    QUERY_WAREHOUSE = COMPUTE_WH
    TITLE = 'Credits Monitor';


-- ============================================================
-- STEP 5: SET LIVE VERSION
-- ============================================================

ALTER STREAMLIT STREAMLIT_APPS.CREDITS_MONITOR.CREDITS_MONITOR_APP
    ADD LIVE VERSION FROM LAST;


-- ============================================================
-- STEP 6: VERIFY
-- ============================================================

DESCRIBE STREAMLIT STREAMLIT_APPS.CREDITS_MONITOR.CREDITS_MONITOR_APP;

SHOW STREAMLITS IN SCHEMA STREAMLIT_APPS.CREDITS_MONITOR;


-- ============================================================
-- STEP 7: ACCESS THE APP
-- ============================================================
-- In Snowsight: Projects > Streamlit > CREDITS_MONITOR_APP


-- ============================================================
-- HOW TO UPDATE (after code changes)
-- ============================================================

-- CREATE OR REPLACE STAGE STREAMLIT_APPS.CREDITS_MONITOR.APP_STAGE;
--
-- COPY FILES INTO @STREAMLIT_APPS.CREDITS_MONITOR.APP_STAGE
--     FROM 'snow://workspace/USER$.PUBLIC.DEFAULT$/versions/live/streamlit_apps'
--     FILES=('credits_monitor_app.sql');
--
-- CREATE OR REPLACE STREAMLIT STREAMLIT_APPS.CREDITS_MONITOR.CREDITS_MONITOR_APP
--     FROM '@STREAMLIT_APPS.CREDITS_MONITOR.APP_STAGE'
--     MAIN_FILE = 'credits_monitor_app.sql'
--     QUERY_WAREHOUSE = COMPUTE_WH
--     TITLE = 'Credits Monitor';
--
-- ALTER STREAMLIT STREAMLIT_APPS.CREDITS_MONITOR.CREDITS_MONITOR_APP
--     ADD LIVE VERSION FROM LAST;


-- ============================================================
-- HOW TO DROP (cleanup)
-- ============================================================

-- DROP STREAMLIT IF EXISTS STREAMLIT_APPS.CREDITS_MONITOR.CREDITS_MONITOR_APP;
-- DROP STAGE IF EXISTS STREAMLIT_APPS.CREDITS_MONITOR.APP_STAGE;
-- DROP SCHEMA IF EXISTS STREAMLIT_APPS.CREDITS_MONITOR;
