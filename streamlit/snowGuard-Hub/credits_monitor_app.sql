import streamlit as st
import pandas as pd
import altair as alt
from snowflake.snowpark.context import get_active_session

session = get_active_session()

@st.cache_data(ttl=600, show_spinner=False)
def run_query(query):
    return session.sql(query).to_pandas()

GRADIENT = ["#667eea", "#764ba2", "#f093fb", "#f5576c", "#4facfe", "#00f2fe", "#43e97b", "#38f9d7"]
GRADIENT_WARM = ["#667eea", "#764ba2", "#e040fb", "#f5576c", "#ff6f00"]
GRADIENT_COOL = ["#4facfe", "#00f2fe", "#43e97b", "#38f9d7", "#667eea"]

st.set_page_config(page_title="Credit Monitor App", page_icon="❄️", layout="wide")

st.markdown("""
<style>
    @keyframes fadeInUp {
        from { opacity: 0; transform: translateY(30px); }
        to { opacity: 1; transform: translateY(0); }
    }
    @keyframes fadeInScale {
        from { opacity: 0; transform: scale(0.9); }
        to { opacity: 1; transform: scale(1); }
    }
    @keyframes slideInLeft {
        from { opacity: 0; transform: translateX(-40px); }
        to { opacity: 1; transform: translateX(0); }
    }
    @keyframes typewriter {
        from { width: 0; }
        to { width: 100%; }
    }
    @keyframes blink {
        50% { border-color: transparent; }
    }
    @keyframes gradientShift {
        0% { background-position: 0% 50%; }
        50% { background-position: 100% 50%; }
        100% { background-position: 0% 50%; }
    }
    @keyframes pulse {
        0%, 100% { box-shadow: 0 0 0 0 rgba(102, 126, 234, 0.6); }
        50% { box-shadow: 0 0 20px 10px rgba(102, 126, 234, 0); }
    }
    @keyframes float {
        0%, 100% { transform: translateY(0px); }
        50% { transform: translateY(-8px); }
    }
    @keyframes shimmer {
        0% { background-position: -200% 0; }
        100% { background-position: 200% 0; }
    }
    @keyframes borderGlow {
        0%, 100% { border-color: #667eea40; box-shadow: 0 0 5px #667eea20; }
        50% { border-color: #764ba280; box-shadow: 0 0 20px #764ba240; }
    }
    @keyframes iconBounce {
        0%, 100% { transform: scale(1); }
        50% { transform: scale(1.3); }
    }

    .stMetric {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        padding: 15px;
        border-radius: 12px;
        color: white;
        box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
    }
    .stMetric label, .stMetric [data-testid="stMetricValue"], .stMetric [data-testid="stMetricDelta"] {
        color: white !important;
    }

    /* ── KPI Cards ── */
    @keyframes countUp { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
    @keyframes alertPulse {
        0%, 100% { box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3); }
        50% { box-shadow: 0 4px 25px rgba(245, 87, 108, 0.5); }
    }
    .kpi-grid { display: grid; grid-template-columns: repeat(6, 1fr); gap: 14px; margin-bottom: 20px; }
    .kpi-card {
        border-radius: 14px; padding: 18px 16px; text-align: center;
        position: relative; overflow: hidden;
        transition: all 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);
        animation: fadeInUp 0.5s ease-out both;
    }
    .kpi-card:nth-child(1) { animation-delay: 0.1s; }
    .kpi-card:nth-child(2) { animation-delay: 0.2s; }
    .kpi-card:nth-child(3) { animation-delay: 0.3s; }
    .kpi-card:nth-child(4) { animation-delay: 0.4s; }
    .kpi-card:nth-child(5) { animation-delay: 0.5s; }
    .kpi-card:nth-child(6) { animation-delay: 0.6s; }
    .kpi-card:hover { transform: translateY(-4px) scale(1.02); }
    .kpi-card::before {
        content: ''; position: absolute; top: 0; left: -100%; width: 100%; height: 100%;
        background: linear-gradient(90deg, transparent, rgba(255,255,255,0.15), transparent);
        transition: left 0.5s ease;
    }
    .kpi-card:hover::before { left: 100%; }
    .kpi-card .kpi-icon { font-size: 1.6em; margin-bottom: 6px; display: block; }
    .kpi-card .kpi-value {
        font-size: 1.5em; font-weight: 700; color: white; display: block;
        animation: countUp 0.8s ease-out both; text-shadow: 0 1px 8px rgba(0,0,0,0.15);
    }
    .kpi-card .kpi-label {
        font-size: 0.72em; color: rgba(255,255,255,0.85); text-transform: uppercase;
        letter-spacing: 1.2px; margin-top: 4px; display: block;
    }
    .kpi-card .kpi-delta {
        font-size: 0.75em; margin-top: 4px; display: inline-block;
        padding: 2px 8px; border-radius: 20px; font-weight: 600;
    }
    .kpi-delta.up { background: rgba(245,87,108,0.3); color: #ffd6dd; }
    .kpi-delta.down { background: rgba(67,233,123,0.3); color: #d6ffe2; }
    .kpi-alert { animation: alertPulse 2s ease-in-out infinite; }
    .kpi-g1 { background: linear-gradient(135deg, #667eea, #764ba2); box-shadow: 0 4px 15px rgba(102,126,234,0.3); }
    .kpi-g2 { background: linear-gradient(135deg, #764ba2, #9b59b6); box-shadow: 0 4px 15px rgba(118,75,162,0.3); }
    .kpi-g3 { background: linear-gradient(135deg, #f093fb, #f5576c); box-shadow: 0 4px 15px rgba(240,147,251,0.3); }
    .kpi-g4 { background: linear-gradient(135deg, #4facfe, #00f2fe); box-shadow: 0 4px 15px rgba(79,172,254,0.3); }
    .kpi-g5 { background: linear-gradient(135deg, #43e97b, #38f9d7); box-shadow: 0 4px 15px rgba(67,233,123,0.3); }
    .kpi-g6 { background: linear-gradient(135deg, #fa709a, #fee140); box-shadow: 0 4px 15px rgba(250,112,154,0.3); }

    .hero-banner {
        background: linear-gradient(270deg, #667eea, #764ba2, #f093fb, #667eea);
        background-size: 600% 600%;
        animation: gradientShift 8s ease infinite, fadeInScale 0.8s ease-out;
        border-radius: 20px;
        padding: 50px 40px;
        text-align: center;
        margin-bottom: 30px;
        box-shadow: 0 12px 40px rgba(102, 126, 234, 0.4);
        position: relative;
        overflow: hidden;
    }
    .hero-banner::before {
        content: '';
        position: absolute;
        top: -50%;
        left: -50%;
        width: 200%;
        height: 200%;
        background: radial-gradient(circle, rgba(255,255,255,0.1) 0%, transparent 60%);
        animation: float 6s ease-in-out infinite;
    }
    .hero-banner .welcome-text {
        color: rgba(255,255,255,0.8);
        font-size: 1.3em;
        margin-bottom: 4px;
        animation: fadeInUp 0.8s ease-out 0.2s both;
        letter-spacing: 2px;
        text-transform: uppercase;
        font-weight: 300;
    }
    .hero-banner h1 {
        color: white !important;
        -webkit-text-fill-color: white !important;
        font-size: 3em;
        margin: 8px 0 16px 0;
        animation: fadeInUp 0.8s ease-out 0.5s both;
        text-shadow: 0 2px 20px rgba(0,0,0,0.2);
    }
    .hero-banner .hero-subtitle {
        color: rgba(255,255,255,0.9);
        font-size: 1.15em;
        margin: 0;
        animation: fadeInUp 0.8s ease-out 0.8s both;
        max-width: 600px;
        margin: 0 auto;
        line-height: 1.6;
    }
    .hero-banner .hero-divider {
        width: 60px;
        height: 3px;
        background: rgba(255,255,255,0.5);
        margin: 16px auto;
        border-radius: 2px;
        animation: fadeInUp 0.8s ease-out 0.6s both;
    }

    .section-title {
        animation: slideInLeft 0.6s ease-out;
        font-size: 1.5em;
        margin: 10px 0 20px 0;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        font-weight: 700;
    }

    .home-card {
        background: linear-gradient(135deg, rgba(102,126,234,0.05) 0%, rgba(118,75,162,0.05) 100%);
        border: 1px solid #667eea30;
        border-radius: 16px;
        padding: 24px;
        margin: 8px 0;
        transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
        cursor: default;
        position: relative;
        overflow: hidden;
    }
    .home-card::before {
        content: '';
        position: absolute;
        top: 0;
        left: -100%;
        width: 100%;
        height: 100%;
        background: linear-gradient(90deg, transparent, rgba(102,126,234,0.08), transparent);
        transition: left 0.6s ease;
    }
    .home-card:hover::before {
        left: 100%;
    }
    .home-card:hover {
        transform: translateY(-8px);
        border-color: #667eea80;
        box-shadow: 0 12px 30px rgba(102,126,234,0.2), 0 0 15px rgba(118,75,162,0.1);
        background: linear-gradient(135deg, rgba(102,126,234,0.1) 0%, rgba(118,75,162,0.1) 100%);
    }
    .home-card .card-icon {
        font-size: 2.2em;
        margin-bottom: 12px;
        display: inline-block;
        transition: transform 0.3s ease;
    }
    .home-card:hover .card-icon {
        animation: iconBounce 0.6s ease;
    }
    .home-card h4 {
        margin: 0 0 10px 0;
        color: #667eea;
        font-size: 1.1em;
        font-weight: 600;
    }
    .home-card p {
        margin: 0;
        color: #666;
        font-size: 0.9em;
        line-height: 1.5;
    }
    .card-row-1 .home-card:nth-child(1) { animation: fadeInUp 0.6s ease-out 0.3s both; }
    .card-row-1 .home-card:nth-child(2) { animation: fadeInUp 0.6s ease-out 0.5s both; }
    .card-row-1 .home-card:nth-child(3) { animation: fadeInUp 0.6s ease-out 0.7s both; }

    .feature-card {
        background: linear-gradient(135deg, rgba(102,126,234,0.04) 0%, rgba(118,75,162,0.04) 100%);
        border: 1px solid #667eea20;
        border-radius: 12px;
        padding: 20px;
        text-align: center;
        transition: all 0.3s ease;
        animation: borderGlow 3s ease-in-out infinite;
    }
    .feature-card:hover {
        transform: translateY(-4px);
        box-shadow: 0 8px 20px rgba(102,126,234,0.15);
    }
    .feature-card .feat-icon {
        font-size: 2em;
        margin-bottom: 8px;
        display: block;
        animation: float 3s ease-in-out infinite;
    }
    .feature-card h5 {
        margin: 0 0 8px 0;
        color: #667eea;
        font-size: 1em;
    }
    .feature-card p {
        margin: 0;
        color: #777;
        font-size: 0.85em;
        line-height: 1.4;
    }
    .feat-delay-1 .feat-icon { animation-delay: 0s; }
    .feat-delay-2 .feat-icon { animation-delay: 0.5s; }
    .feat-delay-3 .feat-icon { animation-delay: 1.0s; }
    .feat-delay-4 .feat-icon { animation-delay: 1.5s; }

    .stats-ribbon {
        background: linear-gradient(90deg, #667eea, #764ba2, #f093fb, #764ba2, #667eea);
        background-size: 200% 100%;
        animation: shimmer 3s linear infinite;
        border-radius: 12px;
        padding: 16px 24px;
        display: flex;
        justify-content: space-around;
        margin: 20px 0;
    }
    .stats-ribbon .stat-item {
        text-align: center;
        color: white;
    }
    .stats-ribbon .stat-num {
        font-size: 1.8em;
        font-weight: 700;
        display: block;
    }
    .stats-ribbon .stat-label {
        font-size: 0.8em;
        opacity: 0.85;
        text-transform: uppercase;
        letter-spacing: 1px;
    }
</style>
""", unsafe_allow_html=True)

current_user = run_query("SELECT CURRENT_USER() AS u").iloc[0]["U"]

if "page" not in st.session_state:
    st.session_state["page"] = "home"

date_filter_start = "DATEADD(DAY, -7, CURRENT_DATE())"
date_filter_end = "CURRENT_DATE()"
selected_warehouse = "All"
selected_user = "All"
selected_service = "All"

with st.sidebar:
    st.markdown("### ❄️ SnowGuard FinOps Hub")
    st.markdown("---")
    if st.button("🏠 Home", use_container_width=True):
        st.session_state["page"] = "home"
    if st.button("💎 Credits Monitor", use_container_width=True):
        st.session_state["page"] = "dashboard"
    if st.button("🗄️ Storage Analysis", use_container_width=True):
        st.session_state["page"] = "storage"
    if st.button("🧹 Unused Objects", use_container_width=True):
        st.session_state["page"] = "unused"
    st.markdown("---")

    if st.session_state["page"] == "dashboard":
        st.markdown("### 🎛️ Filters")
        wh_list_df = run_query("SELECT DISTINCT warehouse_name FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY WHERE start_time >= DATEADD(DAY, -90, CURRENT_DATE()) ORDER BY 1")
        wh_options = ["All"] + wh_list_df["WAREHOUSE_NAME"].tolist()
        user_list_df = run_query("SELECT DISTINCT user_name FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY WHERE start_time >= DATEADD(DAY, -90, CURRENT_DATE()) AND user_name IS NOT NULL ORDER BY 1")
        user_options = ["All"] + user_list_df["USER_NAME"].tolist()
        service_list_df = run_query("SELECT DISTINCT service_type FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_DAILY_HISTORY WHERE usage_date >= DATEADD(DAY, -90, CURRENT_DATE()) ORDER BY 1")
        svc_options = ["All"] + service_list_df["SERVICE_TYPE"].tolist()

        with st.form("sidebar_filters"):
            date_range = st.selectbox("Date Range", ["Last 7 Days", "Last 14 Days", "Last 30 Days", "Last 90 Days", "Custom"])
            if date_range == "Custom":
                col_d1, col_d2 = st.columns(2)
                with col_d1:
                    start_date = st.date_input("Start Date")
                with col_d2:
                    end_date = st.date_input("End Date")
            selected_warehouse = st.selectbox("Warehouse", wh_options)
            selected_user = st.selectbox("User", user_options)
            selected_service = st.selectbox("Service Type", svc_options)
            st.form_submit_button("🚀 Apply Filters", use_container_width=True)

        if date_range == "Custom":
            date_filter_start = f"'{start_date}'"
            date_filter_end = f"'{end_date}'"
        else:
            days_map = {"Last 7 Days": 7, "Last 14 Days": 14, "Last 30 Days": 30, "Last 90 Days": 90}
            days = days_map[date_range]
            date_filter_start = f"DATEADD(DAY, -{days}, CURRENT_DATE())"
            date_filter_end = "CURRENT_DATE()"

if st.session_state["page"] == "home":
    st.markdown(f"""
    <div class="hero-banner">
        <p class="welcome-text">Welcome back,</p>
        <h1>{current_user}</h1>
        <div class="hero-divider"></div>
        <p class="hero-subtitle">Your intelligent command center for Snowflake FinOps — credit monitoring, storage optimization, and governance analytics.</p>
    </div>
    """, unsafe_allow_html=True)

    st.markdown("""
    <div class="stats-ribbon">
        <div class="stat-item"><span class="stat-num">3</span><span class="stat-label">Modules</span></div>
        <div class="stat-item"><span class="stat-num">30+</span><span class="stat-label">Metrics Tracked</span></div>
        <div class="stat-item"><span class="stat-num">15+</span><span class="stat-label">Chart Types</span></div>
        <div class="stat-item"><span class="stat-num">7</span><span class="stat-label">AI Services</span></div>
        <div class="stat-item"><span class="stat-num">7</span><span class="stat-label">Object Types</span></div>
    </div>
    """, unsafe_allow_html=True)

    st.markdown('<div class="section-title">What can this app do?</div>', unsafe_allow_html=True)

    r0c1, r0c2, r0c3 = st.columns(3)
    with r0c1:
        st.markdown("""
        <div class="home-card" style="animation: fadeInUp 0.6s ease-out 0.2s both; border-left: 4px solid #667eea;">
            <span class="card-icon">💎</span>
            <h4>Credits Monitor</h4>
            <p>Complete credit tracking across warehouses, users, queries, AI/ML services, Snowpark containers, and Cortex Code — with anomaly detection and object-level attribution.</p>
        </div>
        """, unsafe_allow_html=True)
    with r0c2:
        st.markdown("""
        <div class="home-card" style="animation: fadeInUp 0.6s ease-out 0.5s both; border-left: 4px solid #4facfe;">
            <span class="card-icon">🗄️</span>
            <h4>Storage Analysis</h4>
            <p>Database, schema, and table-level storage breakdown with actual vs compressed size, compression ratios, failsafe bytes, growth trends, and clustering costs.</p>
        </div>
        """, unsafe_allow_html=True)
    with r0c3:
        st.markdown("""
        <div class="home-card" style="animation: fadeInUp 0.6s ease-out 0.8s both; border-left: 4px solid #43e97b;">
            <span class="card-icon">🧹</span>
            <h4>Unused Objects</h4>
            <p>Find tables, views, functions, stored procedures, warehouses, users, and compute pools that haven't been accessed — with configurable inactivity thresholds.</p>
        </div>
        """, unsafe_allow_html=True)

    st.markdown("")

    st.markdown('<div class="section-title" style="animation-delay: 0.8s;">Credits Monitor — Deep Dive</div>', unsafe_allow_html=True)
    r1c1, r1c2, r1c3 = st.columns(3)
    with r1c1:
        st.markdown("""
        <div class="home-card" style="animation: fadeInUp 0.6s ease-out 1.0s both;">
            <span class="card-icon">🏭</span>
            <h4>Warehouse & User Analytics</h4>
            <p>Per-warehouse credits, daily trends, anomaly detection, user breakdown, and month-over-month cost changes.</p>
        </div>
        """, unsafe_allow_html=True)
    with r1c2:
        st.markdown("""
        <div class="home-card" style="animation: fadeInUp 0.6s ease-out 1.2s both;">
            <span class="card-icon">📦</span>
            <h4>Object-Level Tracking</h4>
            <p>Every table, view, stage, and procedure — who accessed it, how often, and how many credits it consumed.</p>
        </div>
        """, unsafe_allow_html=True)
    with r1c3:
        st.markdown("""
        <div class="home-card" style="animation: fadeInUp 0.6s ease-out 1.4s both;">
            <span class="card-icon">🤖</span>
            <h4>AI, SPCS & Cortex Code</h4>
            <p>Cortex AI Functions, Agents, Search, SPCS compute pools, Notebooks, and Cortex Code credits — by user, model, and service.</p>
        </div>
        """, unsafe_allow_html=True)

    st.markdown("")
    st.markdown('<div class="section-title" style="animation-delay: 1.2s;">Key Features</div>', unsafe_allow_html=True)
    f1, f2, f3, f4 = st.columns(4)
    with f1:
        st.markdown("""
        <div class="feature-card feat-delay-1" style="animation: fadeInUp 0.6s ease-out 1.6s both;">
            <span class="feat-icon">🔍</span>
            <h5>Smart Filters</h5>
            <p>Date range, warehouse, user, service type, database, schema, object type.</p>
        </div>
        """, unsafe_allow_html=True)
    with f2:
        st.markdown("""
        <div class="feature-card feat-delay-2" style="animation: fadeInUp 0.6s ease-out 1.8s both;">
            <span class="feat-icon">🚨</span>
            <h5>Anomaly Detection</h5>
            <p>2-sigma statistical flags + Snowflake's built-in anomaly forecasting.</p>
        </div>
        """, unsafe_allow_html=True)
    with f3:
        st.markdown("""
        <div class="feature-card feat-delay-3" style="animation: fadeInUp 0.6s ease-out 2.0s both;">
            <span class="feat-icon">📐</span>
            <h5>Compression Ratios</h5>
            <p>See actual vs compressed sizes at table level — find inefficient storage.</p>
        </div>
        """, unsafe_allow_html=True)
    with f4:
        st.markdown("""
        <div class="feature-card feat-delay-4" style="animation: fadeInUp 0.6s ease-out 2.2s both;">
            <span class="feat-icon">🧹</span>
            <h5>Cleanup Insights</h5>
            <p>Identify unused tables, stale views, idle warehouses, and inactive users.</p>
        </div>
        """, unsafe_allow_html=True)

    st.markdown("---")
    st.markdown("")
    b1, b2, b3 = st.columns(3)
    with b1:
        if st.button("💎 Launch Credits Monitor", use_container_width=True, type="primary"):
            st.session_state["page"] = "dashboard"
    with b2:
        if st.button("🗄️ Launch Storage Analysis", use_container_width=True, type="primary"):
            st.session_state["page"] = "storage"
    with b3:
        if st.button("🧹 Launch Unused Objects", use_container_width=True, type="primary"):
            st.session_state["page"] = "unused"
    st.stop()

if st.session_state["page"] == "storage":
    st.title("🗄️ Storage Analysis")
    st.caption("Database, schema, and table-level storage breakdown — actual vs compressed, failsafe, growth trends, and clustering costs.")

    stor_tabs = st.tabs(["Database Level", "Table Level", "Growth Trend", "Clustering Costs"])

    with stor_tabs[0]:
        st.subheader("Storage by Database")
        try:
            db_storage = run_query("""
                SELECT database_name,
                       ROUND(AVG(average_database_bytes) / (1024*1024*1024), 4) AS avg_storage_gb,
                       ROUND(AVG(average_failsafe_bytes) / (1024*1024*1024), 4) AS avg_failsafe_gb,
                       ROUND(AVG(COALESCE(average_hybrid_table_storage_bytes, 0)) / (1024*1024*1024), 4) AS avg_hybrid_gb,
                       ROUND(AVG(average_database_bytes + average_failsafe_bytes + COALESCE(average_hybrid_table_storage_bytes, 0)) / (1024*1024*1024), 4) AS total_gb
                FROM SNOWFLAKE.ACCOUNT_USAGE.DATABASE_STORAGE_USAGE_HISTORY
                WHERE usage_date >= DATEADD(DAY, -7, CURRENT_DATE()) AND usage_date < CURRENT_DATE()
                  AND deleted IS NULL
                GROUP BY database_name ORDER BY total_gb DESC LIMIT 50
            """)
            if not db_storage.empty:
                total_storage = db_storage["TOTAL_GB"].sum()
                total_fs = db_storage["AVG_FAILSAFE_GB"].sum()
                st.markdown(f"""
                <div class="kpi-grid" style="grid-template-columns: repeat(3, 1fr);">
                    <div class="kpi-card kpi-g1"><span class="kpi-icon">🗄️</span><span class="kpi-value">{total_storage:,.2f} GB</span><span class="kpi-label">Total Storage</span></div>
                    <div class="kpi-card kpi-g3"><span class="kpi-icon">🛡️</span><span class="kpi-value">{total_fs:,.2f} GB</span><span class="kpi-label">Failsafe Storage</span></div>
                    <div class="kpi-card kpi-g4"><span class="kpi-icon">📁</span><span class="kpi-value">{len(db_storage)}</span><span class="kpi-label">Databases</span></div>
                </div>
                """, unsafe_allow_html=True)
                bar_db = alt.Chart(db_storage).mark_bar(cornerRadiusTopLeft=6, cornerRadiusTopRight=6).encode(
                    x=alt.X("DATABASE_NAME:N", sort="-y", title="Database"),
                    y=alt.Y("TOTAL_GB:Q", title="Storage (GB)", axis=alt.Axis(tickMinStep=1)),
                    color=alt.Color("TOTAL_GB:Q", scale=alt.Scale(range=GRADIENT_WARM), legend=None),
                    tooltip=["DATABASE_NAME", "AVG_STORAGE_GB", "AVG_FAILSAFE_GB", "TOTAL_GB"]
                ).properties(height=350)
                st.altair_chart(bar_db, use_container_width=True)
                st.dataframe(db_storage, use_container_width=True)
            else:
                st.info("No database storage data found.")
        except Exception as e:
            st.warning(f"Unable to retrieve database storage: {e}")

    with stor_tabs[1]:
        st.subheader("Storage by Table")
        st.caption("Active bytes, time travel, failsafe — with compression insights.")
        try:
            tbl_storage = run_query("""
                SELECT t.table_catalog AS database_name, t.table_schema, t.table_name, t.table_type,
                       t.row_count,
                       ROUND(t.bytes / (1024*1024), 2) AS compressed_mb,
                       ROUND(sm.active_bytes / (1024*1024), 2) AS active_mb,
                       ROUND(sm.time_travel_bytes / (1024*1024), 2) AS time_travel_mb,
                       ROUND(sm.failsafe_bytes / (1024*1024), 2) AS failsafe_mb,
                       ROUND((sm.active_bytes + sm.time_travel_bytes + sm.failsafe_bytes) / (1024*1024), 2) AS total_storage_mb,
                       t.created, t.last_altered
                FROM SNOWFLAKE.ACCOUNT_USAGE.TABLES t
                LEFT JOIN SNOWFLAKE.ACCOUNT_USAGE.TABLE_STORAGE_METRICS sm
                    ON t.table_catalog = sm.table_catalog
                   AND t.table_schema = sm.table_schema
                   AND t.table_name = sm.table_name
                WHERE t.deleted IS NULL AND t.bytes > 0
                  AND sm.table_dropped IS NULL
                ORDER BY t.bytes DESC LIMIT 100
            """)
            if not tbl_storage.empty:
                total_compressed = tbl_storage["COMPRESSED_MB"].sum()
                total_active = tbl_storage["ACTIVE_MB"].sum()
                total_all = tbl_storage["TOTAL_STORAGE_MB"].sum()
                st.markdown(f"""
                <div class="kpi-grid" style="grid-template-columns: repeat(4, 1fr);">
                    <div class="kpi-card kpi-g1"><span class="kpi-icon">📊</span><span class="kpi-value">{total_compressed:,.2f} MB</span><span class="kpi-label">Compressed (Active)</span></div>
                    <div class="kpi-card kpi-g2"><span class="kpi-icon">🗄️</span><span class="kpi-value">{total_all:,.2f} MB</span><span class="kpi-label">Total (incl. TT & FS)</span></div>
                    <div class="kpi-card kpi-g4"><span class="kpi-icon">📋</span><span class="kpi-value">{len(tbl_storage)}</span><span class="kpi-label">Tables with Data</span></div>
                    <div class="kpi-card kpi-g5"><span class="kpi-icon">📝</span><span class="kpi-value">{tbl_storage['ROW_COUNT'].sum():,.0f}</span><span class="kpi-label">Total Rows</span></div>
                </div>
                """, unsafe_allow_html=True)
                bar_tbl = alt.Chart(tbl_storage.head(20)).mark_bar(cornerRadiusTopLeft=6, cornerRadiusTopRight=6).encode(
                    x=alt.X("TABLE_NAME:N", sort="-y", title="Table"),
                    y=alt.Y("TOTAL_STORAGE_MB:Q", title="Total Storage (MB)", axis=alt.Axis(tickMinStep=1)),
                    color=alt.Color("TOTAL_STORAGE_MB:Q", scale=alt.Scale(range=GRADIENT_COOL), legend=None),
                    tooltip=["DATABASE_NAME", "TABLE_SCHEMA", "TABLE_NAME", "ROW_COUNT", "COMPRESSED_MB", "ACTIVE_MB", "TIME_TRAVEL_MB", "FAILSAFE_MB", "TOTAL_STORAGE_MB"]
                ).properties(height=350)
                st.altair_chart(bar_tbl, use_container_width=True)
                st.dataframe(tbl_storage, use_container_width=True, height=400)
            else:
                st.info("No table storage data found.")
        except Exception as e:
            st.warning(f"Unable to retrieve table storage: {e}")

    with stor_tabs[2]:
        st.subheader("Storage Growth Trend (Top 10 DBs, Last 30 Days)")
        try:
            growth_df = run_query("""
                SELECT usage_date, database_name,
                       ROUND((average_database_bytes + average_failsafe_bytes + COALESCE(average_hybrid_table_storage_bytes, 0)) / (1024*1024*1024), 4) AS total_gb
                FROM SNOWFLAKE.ACCOUNT_USAGE.DATABASE_STORAGE_USAGE_HISTORY
                WHERE usage_date >= DATEADD(DAY, -30, CURRENT_DATE())
                  AND deleted IS NULL
                  AND database_name IN (
                      SELECT database_name FROM SNOWFLAKE.ACCOUNT_USAGE.DATABASE_STORAGE_USAGE_HISTORY
                      WHERE usage_date = DATEADD(DAY, -1, CURRENT_DATE()) AND deleted IS NULL
                      ORDER BY (average_database_bytes + average_failsafe_bytes) DESC LIMIT 10
                  )
                ORDER BY database_name, usage_date
            """)
            if not growth_df.empty:
                area_growth = alt.Chart(growth_df).mark_area(opacity=0.6, interpolate="monotone").encode(
                    x=alt.X("USAGE_DATE:T", title="Date"),
                    y=alt.Y("TOTAL_GB:Q", stack=True, title="Storage (GB)", axis=alt.Axis(tickMinStep=1)),
                    color=alt.Color("DATABASE_NAME:N", scale=alt.Scale(range=GRADIENT)),
                    tooltip=["USAGE_DATE:T", "DATABASE_NAME", "TOTAL_GB"]
                ).properties(height=400)
                st.altair_chart(area_growth, use_container_width=True)
            else:
                st.info("No growth trend data available.")
        except Exception as e:
            st.warning(f"Unable to retrieve growth trends: {e}")

    with stor_tabs[3]:
        st.subheader("Auto-Clustering Costs (Last 30 Days)")
        try:
            cluster_df = run_query("""
                SELECT database_name, schema_name, table_name,
                       ROUND(SUM(credits_used), 4) AS total_credits,
                       COUNT(*) AS clustering_events,
                       ROUND(AVG(credits_used), 6) AS avg_credits_per_event
                FROM SNOWFLAKE.ACCOUNT_USAGE.AUTOMATIC_CLUSTERING_HISTORY
                WHERE start_time >= DATEADD(DAY, -30, CURRENT_DATE())
                GROUP BY database_name, schema_name, table_name
                ORDER BY total_credits DESC LIMIT 20
            """)
            if not cluster_df.empty:
                bar_cl = alt.Chart(cluster_df).mark_bar(cornerRadiusTopLeft=6, cornerRadiusTopRight=6).encode(
                    x=alt.X("TABLE_NAME:N", sort="-y", title="Table"),
                    y=alt.Y("TOTAL_CREDITS:Q", title="Clustering Credits", axis=alt.Axis(tickMinStep=1)),
                    color=alt.Color("TOTAL_CREDITS:Q", scale=alt.Scale(range=GRADIENT_WARM), legend=None),
                    tooltip=["DATABASE_NAME", "SCHEMA_NAME", "TABLE_NAME", "TOTAL_CREDITS", "CLUSTERING_EVENTS"]
                ).properties(height=350)
                st.altair_chart(bar_cl, use_container_width=True)
                st.dataframe(cluster_df, use_container_width=True)
            else:
                st.info("No auto-clustering activity found in the last 30 days.")
        except Exception as e:
            st.warning(f"Unable to retrieve clustering data: {e}")
    st.stop()

if st.session_state["page"] == "unused":
    st.title("🧹 Unused Objects")
    st.caption("Find objects that haven't been accessed within a configurable time period.")

    unused_days = st.selectbox("Inactivity Threshold", [30, 60, 90, 180, 365], index=1, format_func=lambda d: f"Not accessed in {d} days")

    unused_tabs = st.tabs(["Tables", "Views", "Functions", "Stored Procs", "Warehouses", "Users", "Compute Pools"])

    with unused_tabs[0]:
        st.subheader("Unused Tables")
        try:
            unused_tables = run_query(f"""
                WITH accessed AS (
                    SELECT DISTINCT obj.value:"objectName"::STRING AS object_name
                    FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY ah,
                         LATERAL FLATTEN(input => ah.direct_objects_accessed) obj
                    WHERE ah.query_start_time >= DATEADD(DAY, -{unused_days}, CURRENT_TIMESTAMP())
                      AND obj.value:"objectDomain"::STRING = 'Table'
                )
                SELECT t.table_catalog AS database_name, t.table_schema, t.table_name,
                       t.row_count, ROUND(t.bytes / (1024*1024), 2) AS size_mb,
                       t.created, t.last_altered
                FROM SNOWFLAKE.ACCOUNT_USAGE.TABLES t
                LEFT JOIN accessed a ON a.object_name = t.table_catalog || '.' || t.table_schema || '.' || t.table_name
                WHERE t.deleted IS NULL AND t.table_type = 'BASE TABLE'
                  AND t.table_catalog != 'SNOWFLAKE'
                  AND a.object_name IS NULL
                  AND t.created < DATEADD(DAY, -{unused_days}, CURRENT_TIMESTAMP())
                ORDER BY t.bytes DESC NULLS LAST LIMIT 100
            """)
            if not unused_tables.empty:
                total_wasted = unused_tables["SIZE_MB"].sum()
                st.markdown(f"""
                <div class="kpi-grid" style="grid-template-columns: repeat(2, 1fr);">
                    <div class="kpi-card kpi-g3"><span class="kpi-icon">🗑️</span><span class="kpi-value">{len(unused_tables)}</span><span class="kpi-label">Unused Tables</span></div>
                    <div class="kpi-card kpi-g6"><span class="kpi-icon">💾</span><span class="kpi-value">{total_wasted:,.2f} MB</span><span class="kpi-label">Reclaimable Storage</span></div>
                </div>
                """, unsafe_allow_html=True)
                st.dataframe(unused_tables, use_container_width=True, height=400)
            else:
                st.success(f"All tables have been accessed in the last {unused_days} days!")
        except Exception as e:
            st.warning(f"Unable to check unused tables: {e}")

    with unused_tabs[1]:
        st.subheader("Unused Views")
        try:
            unused_views = run_query(f"""
                WITH accessed AS (
                    SELECT DISTINCT REGEXP_REPLACE(obj.value:"objectName"::STRING, '\\$V[0-9]+$', '') AS object_name
                    FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY ah,
                         LATERAL FLATTEN(input => ah.direct_objects_accessed) obj
                    WHERE ah.query_start_time >= DATEADD(DAY, -{unused_days}, CURRENT_TIMESTAMP())
                      AND obj.value:"objectDomain"::STRING = 'View'
                )
                SELECT v.table_catalog AS database_name, v.table_schema, v.table_name AS view_name,
                       v.created, v.last_altered
                FROM SNOWFLAKE.ACCOUNT_USAGE.VIEWS v
                LEFT JOIN accessed a ON a.object_name = v.table_catalog || '.' || v.table_schema || '.' || v.table_name
                WHERE v.deleted IS NULL AND v.table_catalog != 'SNOWFLAKE'
                  AND a.object_name IS NULL
                  AND v.created < DATEADD(DAY, -{unused_days}, CURRENT_TIMESTAMP())
                ORDER BY v.created LIMIT 100
            """)
            if not unused_views.empty:
                st.metric("Unused Views", len(unused_views))
                st.dataframe(unused_views, use_container_width=True, height=400)
            else:
                st.success(f"All views have been accessed in the last {unused_days} days!")
        except Exception as e:
            st.warning(f"Unable to check unused views: {e}")

    with unused_tabs[2]:
        st.subheader("Unused Functions")
        try:
            unused_funcs = run_query(f"""
                WITH accessed AS (
                    SELECT DISTINCT obj.value:"objectName"::STRING AS object_name
                    FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY ah,
                         LATERAL FLATTEN(input => ah.direct_objects_accessed) obj
                    WHERE ah.query_start_time >= DATEADD(DAY, -{unused_days}, CURRENT_TIMESTAMP())
                      AND obj.value:"objectDomain"::STRING = 'Function'
                )
                SELECT f.function_catalog AS database_name, f.function_schema, f.function_name,
                       f.argument_signature, f.function_language, f.created, f.last_altered
                FROM SNOWFLAKE.ACCOUNT_USAGE.FUNCTIONS f
                LEFT JOIN accessed a ON a.object_name = f.function_catalog || '.' || f.function_schema || '.' || f.function_name
                WHERE f.deleted IS NULL AND f.function_catalog != 'SNOWFLAKE'
                  AND a.object_name IS NULL
                  AND f.created < DATEADD(DAY, -{unused_days}, CURRENT_TIMESTAMP())
                ORDER BY f.created LIMIT 100
            """)
            if not unused_funcs.empty:
                st.metric("Unused Functions", len(unused_funcs))
                st.dataframe(unused_funcs, use_container_width=True, height=400)
            else:
                st.success(f"All functions have been accessed in the last {unused_days} days!")
        except Exception as e:
            st.warning(f"Unable to check unused functions: {e}")

    with unused_tabs[3]:
        st.subheader("Unused Stored Procedures")
        try:
            unused_sps = run_query(f"""
                WITH accessed AS (
                    SELECT DISTINCT obj.value:"objectName"::STRING AS object_name
                    FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY ah,
                         LATERAL FLATTEN(input => ah.direct_objects_accessed) obj
                    WHERE ah.query_start_time >= DATEADD(DAY, -{unused_days}, CURRENT_TIMESTAMP())
                      AND obj.value:"objectDomain"::STRING = 'Procedure'
                )
                SELECT p.procedure_catalog AS database_name, p.procedure_schema, p.procedure_name,
                       p.argument_signature, p.procedure_language, p.created, p.last_altered
                FROM SNOWFLAKE.ACCOUNT_USAGE.PROCEDURES p
                LEFT JOIN accessed a ON a.object_name = p.procedure_catalog || '.' || p.procedure_schema || '.' || p.procedure_name
                WHERE p.deleted IS NULL AND p.procedure_catalog != 'SNOWFLAKE'
                  AND a.object_name IS NULL
                  AND p.created < DATEADD(DAY, -{unused_days}, CURRENT_TIMESTAMP())
                ORDER BY p.created LIMIT 100
            """)
            if not unused_sps.empty:
                st.metric("Unused Stored Procedures", len(unused_sps))
                st.dataframe(unused_sps, use_container_width=True, height=400)
            else:
                st.success(f"All stored procedures have been accessed in the last {unused_days} days!")
        except Exception as e:
            st.warning(f"Unable to check unused procedures: {e}")

    with unused_tabs[4]:
        st.subheader("Idle Warehouses")
        try:
            idle_wh = run_query(f"""
                WITH all_wh AS (
                    SELECT DISTINCT warehouse_name
                    FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
                    WHERE start_time >= DATEADD(DAY, -365, CURRENT_TIMESTAMP())
                ),
                active AS (
                    SELECT DISTINCT warehouse_name
                    FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
                    WHERE start_time >= DATEADD(DAY, -{unused_days}, CURRENT_TIMESTAMP())
                )
                SELECT aw.warehouse_name,
                       MAX(wm.start_time) AS last_active
                FROM all_wh aw
                LEFT JOIN active a ON aw.warehouse_name = a.warehouse_name
                LEFT JOIN SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY wm ON aw.warehouse_name = wm.warehouse_name
                WHERE a.warehouse_name IS NULL
                GROUP BY aw.warehouse_name
                ORDER BY last_active NULLS FIRST LIMIT 50
            """)
            if not idle_wh.empty:
                st.metric("Idle Warehouses", len(idle_wh))
                st.dataframe(idle_wh, use_container_width=True)
            else:
                st.success(f"All warehouses have been used in the last {unused_days} days!")
        except Exception as e:
            st.warning(f"Unable to check idle warehouses: {e}")

    with unused_tabs[5]:
        st.subheader("Inactive Users")
        try:
            inactive_users = run_query(f"""
                WITH active AS (
                    SELECT DISTINCT user_name
                    FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
                    WHERE start_time >= DATEADD(DAY, -{unused_days}, CURRENT_TIMESTAMP())
                )
                SELECT u.name AS user_name, u.login_name, u.default_role,
                       u.default_warehouse, u.created_on, u.last_success_login,
                       u.disabled, u.has_password
                FROM SNOWFLAKE.ACCOUNT_USAGE.USERS u
                LEFT JOIN active a ON u.name = a.user_name
                WHERE u.deleted_on IS NULL AND a.user_name IS NULL
                  AND u.name NOT IN ('SNOWFLAKE')
                ORDER BY u.created_on LIMIT 100
            """)
            if not inactive_users.empty:
                st.metric("Inactive Users", len(inactive_users))
                st.dataframe(inactive_users, use_container_width=True, height=400)
            else:
                st.success(f"All users have been active in the last {unused_days} days!")
        except Exception as e:
            st.warning(f"Unable to check inactive users: {e}")

    with unused_tabs[6]:
        st.subheader("Idle Compute Pools")
        try:
            idle_pools = run_query(f"""
                WITH active AS (
                    SELECT DISTINCT compute_pool_name
                    FROM SNOWFLAKE.ACCOUNT_USAGE.SNOWPARK_CONTAINER_SERVICES_HISTORY
                    WHERE start_time >= DATEADD(DAY, -{unused_days}, CURRENT_TIMESTAMP())
                )
                SELECT cp.name AS compute_pool_name, cp.instance_family, cp.min_nodes, cp.max_nodes,
                       cp.auto_suspend_secs, cp.created
                FROM SNOWFLAKE.ACCOUNT_USAGE.COMPUTE_POOLS cp
                LEFT JOIN active a ON cp.name = a.compute_pool_name
                WHERE cp.deleted IS NULL AND a.compute_pool_name IS NULL
                ORDER BY cp.created LIMIT 50
            """)
            if not idle_pools.empty:
                st.metric("Idle Compute Pools", len(idle_pools))
                st.dataframe(idle_pools, use_container_width=True)
            else:
                st.success(f"All compute pools have been active in the last {unused_days} days!")
        except Exception as e:
            st.warning(f"Unable to check compute pools: {e}")
    st.stop()

if st.session_state["page"] == "dashboard":
    st.title("💎 Credits Monitor")

# ── KPIs ──
kpi_df = run_query(f"""
    SELECT
        ROUND(SUM(credits_used), 2) AS total_credits,
        ROUND(SUM(credits_used_compute), 2) AS compute_credits,
        ROUND(SUM(credits_used_cloud_services), 2) AS cloud_credits,
        COUNT(DISTINCT usage_date) AS active_days,
        ROUND(AVG(credits_used), 4) AS avg_daily_credits
    FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_DAILY_HISTORY
    WHERE usage_date >= {date_filter_start} AND usage_date < {date_filter_end}
""")

prev_kpi_df = run_query(f"""
    SELECT ROUND(SUM(credits_used), 2) AS prev_total
    FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_DAILY_HISTORY
    WHERE usage_date >= DATEADD(DAY, -DATEDIFF(DAY, {date_filter_start}, {date_filter_end}), {date_filter_start})
      AND usage_date < {date_filter_start}
""")

wh_count_df = run_query(f"""
    SELECT COUNT(DISTINCT warehouse_name) AS wh_count
    FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
    WHERE start_time >= {date_filter_start} AND start_time < {date_filter_end}
""")

dollar_df = run_query(f"""
    SELECT ROUND(SUM(m.credits_billed * r.effective_rate), 2) AS total_dollars
    FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_DAILY_HISTORY m
    JOIN SNOWFLAKE.ORGANIZATION_USAGE.RATE_SHEET_DAILY r
      ON m.service_type = r.service_type AND m.usage_date = r.date
      AND r.account_locator = CURRENT_ACCOUNT()
    WHERE m.usage_date >= {date_filter_start} AND m.usage_date < {date_filter_end}
""")

total_cr = kpi_df["TOTAL_CREDITS"].iloc[0] if not kpi_df.empty else 0
prev_cr = prev_kpi_df["PREV_TOTAL"].iloc[0] if not prev_kpi_df.empty and prev_kpi_df["PREV_TOTAL"].iloc[0] else 0
delta_cr = round(total_cr - prev_cr, 2) if prev_cr else None
compute_cr = kpi_df['COMPUTE_CREDITS'].iloc[0] if not kpi_df.empty else 0
cloud_cr = kpi_df['CLOUD_CREDITS'].iloc[0] if not kpi_df.empty else 0
wh_count = wh_count_df['WH_COUNT'].iloc[0] if not wh_count_df.empty else 0
total_dollars = dollar_df['TOTAL_DOLLARS'].iloc[0] if not dollar_df.empty and dollar_df['TOTAL_DOLLARS'].iloc[0] else 0
avg_daily = kpi_df['AVG_DAILY_CREDITS'].iloc[0] if not kpi_df.empty else 0

delta_html = ""
if delta_cr is not None:
    delta_class = "up" if delta_cr > 0 else "down"
    delta_symbol = "▲" if delta_cr > 0 else "▼"
    delta_html = f'<span class="kpi-delta {delta_class}">{delta_symbol} {abs(delta_cr):,.2f}</span>'

alert_class = " kpi-alert" if delta_cr and delta_cr > 0 and abs(delta_cr) > total_cr * 0.2 else ""

st.markdown(f"""
<div class="kpi-grid">
    <div class="kpi-card kpi-g1{alert_class}">
        <span class="kpi-icon">💎</span>
        <span class="kpi-value">{total_cr:,.2f}</span>
        <span class="kpi-label">Total Credits</span>
        {delta_html}
    </div>
    <div class="kpi-card kpi-g2">
        <span class="kpi-icon">💰</span>
        <span class="kpi-value">${total_dollars:,.2f}</span>
        <span class="kpi-label">Total Spend (USD)</span>
    </div>
    <div class="kpi-card kpi-g3">
        <span class="kpi-icon">⚡</span>
        <span class="kpi-value">{compute_cr:,.2f}</span>
        <span class="kpi-label">Compute Credits</span>
    </div>
    <div class="kpi-card kpi-g4">
        <span class="kpi-icon">☁️</span>
        <span class="kpi-value">{cloud_cr:,.2f}</span>
        <span class="kpi-label">Cloud Services</span>
    </div>
    <div class="kpi-card kpi-g5">
        <span class="kpi-icon">🏭</span>
        <span class="kpi-value">{wh_count}</span>
        <span class="kpi-label">Active Warehouses</span>
    </div>
    <div class="kpi-card kpi-g6">
        <span class="kpi-icon">📊</span>
        <span class="kpi-value">{avg_daily:,.4f}</span>
        <span class="kpi-label">Avg Daily Credits</span>
    </div>
</div>
""", unsafe_allow_html=True)

# ── Tabs ──
tab1, tab2, tab3, tab4, tab5, tab6 = st.tabs(["Warehouse", "Users", "Queries", "Objects", "AI & SPCS", "Overview"])

# ────────────────── TAB 1: WAREHOUSE ──────────────────
with tab1:
    wh_filter = f"AND warehouse_name = '{selected_warehouse}'" if selected_warehouse != "All" else ""

    wh_credits_df = run_query(f"""
        SELECT warehouse_name, ROUND(SUM(credits_used), 2) AS total_credits,
               COUNT(DISTINCT DATE(start_time)) AS active_days
        FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
        WHERE start_time >= {date_filter_start} AND start_time < {date_filter_end} {wh_filter}
        GROUP BY warehouse_name ORDER BY total_credits DESC LIMIT 20
    """)

    st.subheader("Warehouse Credits Usage")
    if not wh_credits_df.empty:
        bar = alt.Chart(wh_credits_df).mark_bar(
            cornerRadiusTopLeft=6, cornerRadiusTopRight=6
        ).encode(
            x=alt.X("WAREHOUSE_NAME:N", sort="-y", title="Warehouse"),
            y=alt.Y("TOTAL_CREDITS:Q", title="Credits", axis=alt.Axis(tickMinStep=1)),
            color=alt.Color("TOTAL_CREDITS:Q", scale=alt.Scale(range=GRADIENT_WARM), legend=None),
            tooltip=["WAREHOUSE_NAME", "TOTAL_CREDITS", "ACTIVE_DAYS"]
        ).properties(height=350)
        st.altair_chart(bar, use_container_width=True)

    wh_daily_df = run_query(f"""
        SELECT DATE(start_time) AS usage_date, warehouse_name,
               ROUND(SUM(credits_used), 2) AS daily_credits
        FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
        WHERE start_time >= {date_filter_start} AND start_time < {date_filter_end} {wh_filter}
        GROUP BY usage_date, warehouse_name ORDER BY usage_date
    """)

    st.subheader("Daily Credit Trend by Warehouse")
    if not wh_daily_df.empty:
        line = alt.Chart(wh_daily_df).mark_area(opacity=0.6, interpolate="monotone").encode(
            x=alt.X("USAGE_DATE:T", title="Date"),
            y=alt.Y("DAILY_CREDITS:Q", stack=True, title="Credits", axis=alt.Axis(tickMinStep=1)),
            color=alt.Color("WAREHOUSE_NAME:N", scale=alt.Scale(range=GRADIENT), legend=alt.Legend(title="Warehouse")),
            tooltip=["USAGE_DATE:T", "WAREHOUSE_NAME", "DAILY_CREDITS"]
        ).properties(height=350)
        st.altair_chart(line, use_container_width=True)

    st.subheader("Warehouse Anomaly Detection")
    wh_anomaly_df = run_query(f"""
        WITH daily AS (
            SELECT DATE(start_time) AS dt, ROUND(SUM(credits_used), 2) AS credits
            FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
            WHERE start_time >= {date_filter_start} AND start_time < {date_filter_end} {wh_filter}
            GROUP BY dt
        ),
        stats AS (
            SELECT AVG(credits) AS avg_cr, STDDEV(credits) AS std_cr FROM daily
        )
        SELECT d.dt AS USAGE_DATE, d.credits AS DAILY_CREDITS,
               ROUND(s.avg_cr, 2) AS AVG_CREDITS,
               ROUND(s.avg_cr + 2 * s.std_cr, 2) AS UPPER_BOUND,
               ROUND(GREATEST(s.avg_cr - 2 * s.std_cr, 0), 2) AS LOWER_BOUND,
               CASE WHEN d.credits > s.avg_cr + 2 * s.std_cr THEN 'Anomaly' ELSE 'Normal' END AS STATUS
        FROM daily d, stats s ORDER BY d.dt
    """)

    if not wh_anomaly_df.empty:
        base = alt.Chart(wh_anomaly_df).encode(x=alt.X("USAGE_DATE:T", title="Date"))
        band = base.mark_area(opacity=0.15, color="#764ba2").encode(
            y="LOWER_BOUND:Q", y2="UPPER_BOUND:Q"
        )
        avg_line = base.mark_line(strokeDash=[5, 5], color="#667eea").encode(y="AVG_CREDITS:Q")
        points = base.mark_circle(size=80).encode(
            y=alt.Y("DAILY_CREDITS:Q", title="Credits"),
            color=alt.Color("STATUS:N", scale=alt.Scale(domain=["Normal", "Anomaly"], range=["#43e97b", "#f5576c"])),
            tooltip=["USAGE_DATE:T", "DAILY_CREDITS", "AVG_CREDITS", "UPPER_BOUND", "STATUS"]
        )
        st.altair_chart(band + avg_line + points, use_container_width=True)

    st.subheader("Warehouse Users")
    wh_users_df = run_query(f"""
        SELECT qh.warehouse_name, qh.user_name, COUNT(*) AS query_count,
               ROUND(SUM(qa.credits_attributed_compute), 2) AS total_credits
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY qh
        JOIN SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY qa ON qh.query_id = qa.query_id
        WHERE qh.start_time >= {date_filter_start} AND qh.start_time < {date_filter_end}
          {wh_filter.replace('warehouse_name', 'qh.warehouse_name') if wh_filter else ''}
        GROUP BY qh.warehouse_name, qh.user_name ORDER BY total_credits DESC LIMIT 50
    """)
    if not wh_users_df.empty:
        st.dataframe(wh_users_df, use_container_width=True)

# ────────────────── TAB 2: USERS ──────────────────
with tab2:
    user_filter = f"AND user_name = '{selected_user}'" if selected_user != "All" else ""

    st.subheader("Top Users by Credits")
    user_credits_df = run_query(f"""
        SELECT user_name, COUNT(DISTINCT query_id) AS query_count,
               ROUND(SUM(credits_attributed_compute + COALESCE(credits_used_query_acceleration, 0)), 2) AS total_credits
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY
        WHERE start_time >= {date_filter_start} AND start_time < {date_filter_end} {user_filter}
        GROUP BY user_name ORDER BY total_credits DESC LIMIT 20
    """)

    if not user_credits_df.empty:
        bar_u = alt.Chart(user_credits_df).mark_bar(
            cornerRadiusTopLeft=6, cornerRadiusTopRight=6
        ).encode(
            x=alt.X("USER_NAME:N", sort="-y", title="User"),
            y=alt.Y("TOTAL_CREDITS:Q", title="Credits", axis=alt.Axis(tickMinStep=1)),
            color=alt.Color("TOTAL_CREDITS:Q", scale=alt.Scale(range=GRADIENT_COOL), legend=None),
            tooltip=["USER_NAME", "TOTAL_CREDITS", "QUERY_COUNT"]
        ).properties(height=350)
        st.altair_chart(bar_u, use_container_width=True)

    st.subheader("User Daily Trend")
    user_daily_df = run_query(f"""
        SELECT DATE(start_time) AS usage_date, user_name,
               ROUND(SUM(credits_attributed_compute), 2) AS daily_credits
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY
        WHERE start_time >= {date_filter_start} AND start_time < {date_filter_end} {user_filter}
        GROUP BY usage_date, user_name ORDER BY usage_date
    """)

    if not user_daily_df.empty:
        top_users = user_daily_df.groupby("USER_NAME")["DAILY_CREDITS"].sum().nlargest(10).index.tolist()
        user_daily_top = user_daily_df[user_daily_df["USER_NAME"].isin(top_users)]
        area_u = alt.Chart(user_daily_top).mark_area(opacity=0.6, interpolate="monotone").encode(
            x=alt.X("USAGE_DATE:T", title="Date"),
            y=alt.Y("DAILY_CREDITS:Q", stack=True, title="Credits", axis=alt.Axis(tickMinStep=1)),
            color=alt.Color("USER_NAME:N", scale=alt.Scale(range=GRADIENT)),
            tooltip=["USAGE_DATE:T", "USER_NAME", "DAILY_CREDITS"]
        ).properties(height=350)
        st.altair_chart(area_u, use_container_width=True)

    st.subheader("User Anomaly Detection")
    user_anom_df = run_query(f"""
        WITH daily AS (
            SELECT DATE(start_time) AS dt, user_name, ROUND(SUM(credits_attributed_compute), 2) AS credits
            FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY
            WHERE start_time >= {date_filter_start} AND start_time < {date_filter_end} {user_filter}
            GROUP BY dt, user_name
        ),
        agg AS (
            SELECT dt, SUM(credits) AS credits FROM daily GROUP BY dt
        ),
        stats AS (
            SELECT AVG(credits) AS avg_cr, STDDEV(credits) AS std_cr FROM agg
        )
        SELECT a.dt AS USAGE_DATE, a.credits AS DAILY_CREDITS,
               ROUND(s.avg_cr, 2) AS AVG_CREDITS,
               ROUND(s.avg_cr + 2 * s.std_cr, 2) AS UPPER_BOUND,
               CASE WHEN a.credits > s.avg_cr + 2 * s.std_cr THEN 'Anomaly' ELSE 'Normal' END AS STATUS
        FROM agg a, stats s ORDER BY a.dt
    """)

    if not user_anom_df.empty:
        base_u = alt.Chart(user_anom_df).encode(x=alt.X("USAGE_DATE:T", title="Date"))
        band_u = base_u.mark_area(opacity=0.12, color="#764ba2").encode(y="AVG_CREDITS:Q", y2="UPPER_BOUND:Q")
        pts_u = base_u.mark_circle(size=80).encode(
            y=alt.Y("DAILY_CREDITS:Q", title="Credits"),
            color=alt.Color("STATUS:N", scale=alt.Scale(domain=["Normal", "Anomaly"], range=["#4facfe", "#f5576c"])),
            tooltip=["USAGE_DATE:T", "DAILY_CREDITS", "AVG_CREDITS", "UPPER_BOUND", "STATUS"]
        )
        st.altair_chart(band_u + pts_u, use_container_width=True)

    st.subheader("User MoM Change")
    user_mom_df = run_query(f"""
        WITH monthly AS (
            SELECT user_name, DATE_TRUNC('month', start_time) AS mth,
                   SUM(credits_attributed_compute) AS credits
            FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY
            WHERE start_time >= DATE_TRUNC('month', DATEADD('month', -1, CURRENT_DATE()))
              AND start_time < DATE_TRUNC('month', DATEADD('month', 1, CURRENT_DATE()))
            GROUP BY user_name, mth
        ),
        comp AS (
            SELECT user_name,
                SUM(CASE WHEN mth = DATE_TRUNC('month', CURRENT_DATE()) THEN credits ELSE 0 END) AS curr,
                SUM(CASE WHEN mth = DATE_TRUNC('month', DATEADD('month', -1, CURRENT_DATE())) THEN credits ELSE 0 END) AS prev
            FROM monthly GROUP BY user_name
        )
        SELECT user_name, ROUND(curr, 2) AS current_month, ROUND(prev, 2) AS previous_month,
               ROUND(curr - prev, 2) AS change,
               CASE WHEN prev > 0 THEN ROUND(((curr - prev)/prev)*100, 1) ELSE NULL END AS pct_change
        FROM comp WHERE curr > 0 OR prev > 0 ORDER BY ABS(curr - prev) DESC LIMIT 15
    """)
    if not user_mom_df.empty:
        st.dataframe(user_mom_df, use_container_width=True)

# ────────────────── TAB 3: EXPENSIVE QUERIES ──────────────────
with tab3:
    st.subheader("Most Expensive Queries")
    eq_wh_filter = f"AND qa.warehouse_name = '{selected_warehouse}'" if selected_warehouse != "All" else ""
    eq_user_filter = f"AND qa.user_name = '{selected_user}'" if selected_user != "All" else ""

    expensive_df = run_query(f"""
        SELECT qa.query_id,
               qh.query_text,
               qa.user_name,
               DATE(qa.start_time) AS run_date,
               qa.warehouse_name,
               ROUND(DATEDIFF('second', qh.start_time, qh.end_time)/60.0, 2) AS duration_min,
               ROUND(qa.credits_attributed_compute, 4) AS credits_compute,
               ROUND(COALESCE(qa.credits_used_query_acceleration, 0), 4) AS credits_qas,
               ROUND(qa.credits_attributed_compute + COALESCE(qa.credits_used_query_acceleration, 0), 4) AS total_credits
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY qa
        JOIN SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY qh ON qa.query_id = qh.query_id
        WHERE qa.start_time >= {date_filter_start} AND qa.start_time < {date_filter_end}
          AND qa.credits_attributed_compute > 0
          {eq_wh_filter} {eq_user_filter}
        ORDER BY total_credits DESC LIMIT 50
    """)

    if not expensive_df.empty:
        st.markdown(f"""
        <div class="kpi-grid" style="grid-template-columns: repeat(3, 1fr);">
            <div class="kpi-card kpi-g1"><span class="kpi-icon">🏆</span><span class="kpi-value">{expensive_df['TOTAL_CREDITS'].iloc[0]:,.4f}</span><span class="kpi-label">Top Query Credits</span></div>
            <div class="kpi-card kpi-g2"><span class="kpi-icon">📊</span><span class="kpi-value">{expensive_df['TOTAL_CREDITS'].mean():,.4f}</span><span class="kpi-label">Avg Credits (Top 50)</span></div>
            <div class="kpi-card kpi-g4"><span class="kpi-icon">⏱️</span><span class="kpi-value">{expensive_df['DURATION_MIN'].max():,.1f}</span><span class="kpi-label">Max Duration (min)</span></div>
        </div>
        """, unsafe_allow_html=True)

        scatter = alt.Chart(expensive_df).mark_circle(opacity=0.7).encode(
            x=alt.X("DURATION_MIN:Q", title="Duration (minutes)"),
            y=alt.Y("TOTAL_CREDITS:Q", title="Credits", axis=alt.Axis(tickMinStep=1)),
            size=alt.Size("TOTAL_CREDITS:Q", legend=None),
            color=alt.Color("TOTAL_CREDITS:Q", scale=alt.Scale(range=GRADIENT_WARM), legend=None),
            tooltip=["QUERY_ID", "USER_NAME", "WAREHOUSE_NAME", "DURATION_MIN", "TOTAL_CREDITS", "RUN_DATE:T"]
        ).properties(height=350)
        st.altair_chart(scatter, use_container_width=True)

        st.dataframe(expensive_df, use_container_width=True, height=400)
    else:
        st.info("No expensive queries found for the selected filters.")

# ────────────────── TAB 4: OBJECTS ──────────────────
with tab4:
    st.subheader("Object-Level Access & Credits")
    st.caption("Every object (table, view, stage, etc.) accessed by queries — with per-object access count, users, and credits consumed.")

    obj_f1, obj_f2, obj_f3 = st.columns(3)
    with obj_f1:
        try:
            db_list_df = run_query("SELECT DISTINCT database_name FROM SNOWFLAKE.ACCOUNT_USAGE.DATABASES WHERE deleted IS NULL ORDER BY 1")
            obj_db_options = ["All"] + db_list_df["DATABASE_NAME"].tolist()
        except Exception:
            obj_db_options = ["All"]
        obj_selected_db = st.selectbox("Database", obj_db_options, key="obj_db")
    with obj_f2:
        if obj_selected_db != "All":
            try:
                schema_list_df = run_query(f"SELECT DISTINCT schema_name FROM SNOWFLAKE.ACCOUNT_USAGE.SCHEMATA WHERE deleted IS NULL AND catalog_name = '{obj_selected_db}' ORDER BY 1")
                obj_schema_options = ["All"] + schema_list_df["SCHEMA_NAME"].tolist()
            except Exception:
                obj_schema_options = ["All"]
        else:
            obj_schema_options = ["All"]
        obj_selected_schema = st.selectbox("Schema", obj_schema_options, key="obj_schema")
    with obj_f3:
        obj_domain_filter = st.selectbox("Object Type", ["All", "Table", "View", "Stream", "Stage", "Function", "Procedure", "External table", "Materialized view"], key="obj_domain")

    obj_db_clause = f"AND obj_db = '{obj_selected_db}'" if obj_selected_db != "All" else ""
    obj_schema_clause = f"AND obj_schema = '{obj_selected_schema}'" if obj_selected_schema != "All" and obj_selected_db != "All" else ""
    obj_domain_clause = f"AND object_type ILIKE '{obj_domain_filter}'" if obj_domain_filter != "All" else ""

    try:
        obj_credits_df = run_query(f"""
            WITH object_access_raw AS (
                SELECT
                    ah.query_id,
                    ah.user_name,
                    ah.query_start_time,
                    obj.value:"objectDomain"::STRING AS object_type,
                    REGEXP_REPLACE(obj.value:"objectName"::STRING, '\\$V[0-9]+$', '') AS object_name_clean,
                    ARRAY_SIZE(SPLIT(REGEXP_REPLACE(obj.value:"objectName"::STRING, '\\$V[0-9]+$', ''), '.')) AS dot_parts
                FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY ah,
                     LATERAL FLATTEN(input => ah.direct_objects_accessed) obj
                WHERE ah.query_start_time >= {date_filter_start}
                  AND ah.query_start_time < CURRENT_TIMESTAMP()
                  AND obj.value:"objectDomain"::STRING IS NOT NULL
                  AND obj.value:"objectName"::STRING IS NOT NULL
            ),
            object_access AS (
                SELECT
                    query_id, user_name, query_start_time, object_type, object_name_clean,
                    CASE
                        WHEN dot_parts >= 3 THEN SPLIT_PART(object_name_clean, '.', 1)
                        WHEN object_type = 'Stage' THEN 'User Stage'
                        ELSE 'N/A'
                    END AS obj_db,
                    CASE
                        WHEN dot_parts >= 3 THEN SPLIT_PART(object_name_clean, '.', 2)
                        ELSE 'N/A'
                    END AS obj_schema,
                    CASE
                        WHEN dot_parts >= 3 THEN SPLIT_PART(object_name_clean, '.', 3)
                        WHEN object_type = 'Stage' AND dot_parts < 3 THEN '@~/' || object_name_clean
                        ELSE object_name_clean
                    END AS obj_name
                FROM object_access_raw
            )
            SELECT
                oa.object_type,
                oa.obj_db AS database_name,
                oa.obj_schema AS schema_name,
                oa.obj_name AS object_name,
                oa.object_name_clean AS full_object_name,
                COUNT(DISTINCT oa.query_id) AS access_count,
                COUNT(DISTINCT oa.user_name) AS unique_users,
                ROUND(SUM(COALESCE(qa.credits_attributed_compute, 0)), 4) AS total_credits,
                ROUND(AVG(COALESCE(qa.credits_attributed_compute, 0)), 6) AS avg_credits_per_query,
                MIN(oa.query_start_time) AS first_accessed,
                MAX(oa.query_start_time) AS last_accessed,
                ARRAY_AGG(DISTINCT oa.user_name) WITHIN GROUP (ORDER BY oa.user_name) AS users_list
            FROM object_access oa
            LEFT JOIN SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY qa
                ON oa.query_id = qa.query_id
            WHERE 1=1
                {obj_db_clause}
                {obj_schema_clause}
                {obj_domain_clause}
            GROUP BY oa.object_type, oa.obj_db, oa.obj_schema, oa.obj_name, oa.object_name_clean
            ORDER BY access_count DESC
            LIMIT 100
        """)

        if not obj_credits_df.empty:
            st.markdown(f"""
            <div class="kpi-grid" style="grid-template-columns: repeat(4, 1fr);">
                <div class="kpi-card kpi-g1"><span class="kpi-icon">📦</span><span class="kpi-value">{len(obj_credits_df)}</span><span class="kpi-label">Objects Tracked</span></div>
                <div class="kpi-card kpi-g2"><span class="kpi-icon">🔄</span><span class="kpi-value">{obj_credits_df['ACCESS_COUNT'].sum():,}</span><span class="kpi-label">Total Access Count</span></div>
                <div class="kpi-card kpi-g4"><span class="kpi-icon">💎</span><span class="kpi-value">{obj_credits_df['TOTAL_CREDITS'].sum():,.4f}</span><span class="kpi-label">Total Credits</span></div>
                <div class="kpi-card kpi-g5"><span class="kpi-icon">👥</span><span class="kpi-value">{obj_credits_df['UNIQUE_USERS'].max()}</span><span class="kpi-label">Unique Users</span></div>
            </div>
            """, unsafe_allow_html=True)

            st.markdown("---")

            bar_obj = alt.Chart(obj_credits_df.head(20)).mark_bar(
                cornerRadiusTopLeft=6, cornerRadiusTopRight=6
            ).encode(
                x=alt.X("OBJECT_NAME:N", sort="-y", title="Object"),
                y=alt.Y("ACCESS_COUNT:Q", title="Access Count", axis=alt.Axis(tickMinStep=1)),
                color=alt.Color("OBJECT_TYPE:N", scale=alt.Scale(range=GRADIENT), legend=alt.Legend(title="Type")),
                tooltip=["OBJECT_TYPE", "DATABASE_NAME", "SCHEMA_NAME", "OBJECT_NAME", "ACCESS_COUNT", "UNIQUE_USERS", "TOTAL_CREDITS"]
            ).properties(height=400, title="Top Objects by Access Count")
            st.altair_chart(bar_obj, use_container_width=True)

            type_agg = obj_credits_df.groupby("OBJECT_TYPE").agg({"ACCESS_COUNT": "sum", "TOTAL_CREDITS": "sum"}).reset_index()
            donut_obj = alt.Chart(type_agg).mark_arc(innerRadius=50, outerRadius=110).encode(
                theta=alt.Theta("ACCESS_COUNT:Q"),
                color=alt.Color("OBJECT_TYPE:N", scale=alt.Scale(range=GRADIENT_WARM), legend=alt.Legend(title="Type")),
                tooltip=["OBJECT_TYPE", "ACCESS_COUNT", "TOTAL_CREDITS"]
            ).properties(height=300, title="Access Count by Object Type")
            st.altair_chart(donut_obj, use_container_width=True)

            db_agg = obj_credits_df.groupby("DATABASE_NAME").agg({"ACCESS_COUNT": "sum", "TOTAL_CREDITS": "sum"}).reset_index()
            db_agg = db_agg[db_agg["DATABASE_NAME"] != ""]
            if not db_agg.empty:
                donut_db = alt.Chart(db_agg).mark_arc(innerRadius=50, outerRadius=110).encode(
                    theta=alt.Theta("ACCESS_COUNT:Q"),
                    color=alt.Color("DATABASE_NAME:N", scale=alt.Scale(range=GRADIENT_COOL), legend=alt.Legend(title="Database")),
                    tooltip=["DATABASE_NAME", "ACCESS_COUNT", "TOTAL_CREDITS"]
                ).properties(height=300, title="Access Count by Database")
                st.altair_chart(donut_db, use_container_width=True)

            display_df = obj_credits_df.drop(columns=["USERS_LIST", "FULL_OBJECT_NAME"], errors="ignore")
            st.dataframe(display_df, use_container_width=True, height=400)

            st.session_state["obj_credits_cache"] = obj_credits_df

            st.markdown("---")
            st.subheader("Object Deep Dive")

            cached_df = st.session_state.get("obj_credits_cache", obj_credits_df)
            obj_display_names = cached_df.apply(lambda r: f"{r['FULL_OBJECT_NAME']}  ({r['OBJECT_TYPE']}, {r['ACCESS_COUNT']} accesses)", axis=1).tolist()
            obj_full_names = cached_df["FULL_OBJECT_NAME"].tolist()

            with st.form("obj_drill_form"):
                selected_obj_idx = st.selectbox("Select an object to drill down", range(len(obj_display_names)), format_func=lambda i: obj_display_names[i], key="obj_drill")
                drill_submitted = st.form_submit_button("🔍 Analyze Object", use_container_width=True)

            if drill_submitted or st.session_state.get("last_drilled_obj"):
                if drill_submitted:
                    selected_obj = obj_full_names[selected_obj_idx]
                    st.session_state["last_drilled_obj"] = selected_obj
                else:
                    selected_obj = st.session_state["last_drilled_obj"]

                drill_users_df = run_query(f"""
                    WITH object_queries AS (
                        SELECT ah.query_id, ah.user_name, ah.query_start_time
                        FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY ah,
                             LATERAL FLATTEN(input => ah.direct_objects_accessed) obj
                        WHERE ah.query_start_time >= {date_filter_start}
                          AND ah.query_start_time < CURRENT_TIMESTAMP()
                          AND REGEXP_REPLACE(obj.value:"objectName"::STRING, '\\$V[0-9]+$', '') = '{selected_obj}'
                    )
                    SELECT
                        oq.user_name,
                        COUNT(DISTINCT oq.query_id) AS query_count,
                        ROUND(SUM(COALESCE(qa.credits_attributed_compute, 0)), 4) AS total_credits,
                        MIN(oq.query_start_time) AS first_access,
                        MAX(oq.query_start_time) AS last_access
                    FROM object_queries oq
                    LEFT JOIN SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY qa
                        ON oq.query_id = qa.query_id
                    GROUP BY oq.user_name
                    ORDER BY query_count DESC
                """)

                drill_daily_df = run_query(f"""
                    WITH object_queries AS (
                        SELECT ah.query_id, DATE(ah.query_start_time) AS access_date, ah.user_name
                        FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY ah,
                             LATERAL FLATTEN(input => ah.direct_objects_accessed) obj
                        WHERE ah.query_start_time >= {date_filter_start}
                          AND ah.query_start_time < CURRENT_TIMESTAMP()
                          AND REGEXP_REPLACE(obj.value:"objectName"::STRING, '\\$V[0-9]+$', '') = '{selected_obj}'
                    )
                    SELECT
                        oq.access_date,
                        COUNT(DISTINCT oq.query_id) AS daily_access_count,
                        COUNT(DISTINCT oq.user_name) AS daily_unique_users,
                        ROUND(SUM(COALESCE(qa.credits_attributed_compute, 0)), 4) AS daily_credits
                    FROM object_queries oq
                    LEFT JOIN SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY qa
                        ON oq.query_id = qa.query_id
                    GROUP BY oq.access_date
                    ORDER BY oq.access_date
                """)

                drill_queries_df = run_query(f"""
                    WITH object_queries AS (
                        SELECT ah.query_id, ah.user_name
                        FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY ah,
                             LATERAL FLATTEN(input => ah.direct_objects_accessed) obj
                        WHERE ah.query_start_time >= {date_filter_start}
                          AND ah.query_start_time < CURRENT_TIMESTAMP()
                          AND REGEXP_REPLACE(obj.value:"objectName"::STRING, '\\$V[0-9]+$', '') = '{selected_obj}'
                    )
                    SELECT
                        oq.query_id,
                        oq.user_name,
                        qh.query_text,
                        qh.warehouse_name,
                        qh.start_time,
                        ROUND(DATEDIFF('second', qh.start_time, qh.end_time)/60.0, 2) AS duration_min,
                        ROUND(COALESCE(qa.credits_attributed_compute, 0), 6) AS credits
                    FROM object_queries oq
                    LEFT JOIN SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY qh ON oq.query_id = qh.query_id
                    LEFT JOIN SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY qa ON oq.query_id = qa.query_id
                    ORDER BY qh.start_time DESC
                    LIMIT 50
                """)

                st.markdown(f"#### Drilling into: `{selected_obj}`")

                if not drill_users_df.empty:
                    st.markdown(f"**Users accessing this object**")
                    user_bar = alt.Chart(drill_users_df).mark_bar(
                        cornerRadiusTopLeft=6, cornerRadiusTopRight=6
                    ).encode(
                        y=alt.Y("USER_NAME:N", sort="-x", title="User"),
                        x=alt.X("QUERY_COUNT:Q", title="Query Count", axis=alt.Axis(tickMinStep=1)),
                        color=alt.Color("QUERY_COUNT:Q", scale=alt.Scale(range=GRADIENT_WARM), legend=None),
                        tooltip=["USER_NAME", "QUERY_COUNT", "TOTAL_CREDITS", "FIRST_ACCESS:T", "LAST_ACCESS:T"]
                    ).properties(height=300)
                    st.altair_chart(user_bar, use_container_width=True)
                    st.dataframe(drill_users_df, use_container_width=True)

                if not drill_daily_df.empty:
                    st.markdown(f"**Daily access trend**")
                    daily_line = alt.Chart(drill_daily_df).mark_area(
                        opacity=0.6, interpolate="monotone",
                        line={"color": "#667eea"}, color=alt.Gradient(
                            gradient="linear", stops=[
                                alt.GradientStop(color="#667eea", offset=0),
                                alt.GradientStop(color="#764ba2", offset=1)
                            ], x1=1, x2=1, y1=1, y2=0
                        )
                    ).encode(
                        x=alt.X("ACCESS_DATE:T", title="Date"),
                        y=alt.Y("DAILY_ACCESS_COUNT:Q", title="Access Count", axis=alt.Axis(tickMinStep=1)),
                        tooltip=["ACCESS_DATE:T", "DAILY_ACCESS_COUNT", "DAILY_UNIQUE_USERS", "DAILY_CREDITS"]
                    ).properties(height=300)
                    st.altair_chart(daily_line, use_container_width=True)

                st.markdown(f"**Queries that accessed this object**")
                if not drill_queries_df.empty:
                    st.dataframe(drill_queries_df, use_container_width=True, height=350)
        else:
            st.info("No object access data found for the selected filters. Ensure ACCESS_HISTORY (Enterprise Edition) is available.")
    except Exception as e:
        st.warning(f"Unable to retrieve object access data: {e}")
        st.caption("This feature requires Enterprise Edition for ACCESS_HISTORY view access.")

# ────────────────── TAB 5: AI & CONTAINERS ──────────────────
with tab5:
    st.subheader("AI, Snowpark & Container Credits")
    st.caption("Cortex AI Functions, Cortex Agents, Cortex Search, Snowpark Container Services (SPCS), and Notebook Container Runtime credits.")

    ai_tabs = st.tabs(["🧠 Cortex AI Functions", "🤖 Cortex Agents", "🔍 Cortex Search", "📦 SPCS / Compute Pools", "📓 Notebooks (Container)", "💻 Cortex Code"])

    with ai_tabs[0]:
        st.subheader("Cortex AI Functions (COMPLETE, TRANSLATE, etc.)")
        try:
            ai_func_summary = run_query(f"""
                SELECT
                    ROUND(SUM(TOKEN_CREDITS), 4) AS total_credits,
                    SUM(TOKENS) AS total_tokens,
                    COUNT(DISTINCT QUERY_ID) AS total_queries,
                    COUNT(DISTINCT FUNCTION_NAME) AS unique_functions,
                    COUNT(DISTINCT MODEL_NAME) AS unique_models
                FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_AISQL_USAGE_HISTORY
                WHERE USAGE_TIME >= {date_filter_start} AND USAGE_TIME < CURRENT_TIMESTAMP()
            """)
            if not ai_func_summary.empty and ai_func_summary["TOTAL_CREDITS"].iloc[0]:
                st.markdown(f"""
                <div class="kpi-grid" style="grid-template-columns: repeat(4, 1fr);">
                    <div class="kpi-card kpi-g1"><span class="kpi-icon">💎</span><span class="kpi-value">{ai_func_summary['TOTAL_CREDITS'].iloc[0]:,.4f}</span><span class="kpi-label">Total Credits</span></div>
                    <div class="kpi-card kpi-g2"><span class="kpi-icon">🔤</span><span class="kpi-value">{ai_func_summary['TOTAL_TOKENS'].iloc[0]:,}</span><span class="kpi-label">Total Tokens</span></div>
                    <div class="kpi-card kpi-g4"><span class="kpi-icon">🔍</span><span class="kpi-value">{ai_func_summary['TOTAL_QUERIES'].iloc[0]:,}</span><span class="kpi-label">Queries</span></div>
                    <div class="kpi-card kpi-g5"><span class="kpi-icon">🤖</span><span class="kpi-value">{ai_func_summary['UNIQUE_MODELS'].iloc[0]}</span><span class="kpi-label">Models Used</span></div>
                </div>
                """, unsafe_allow_html=True)

                ai_by_func = run_query(f"""
                    SELECT FUNCTION_NAME,
                           ROUND(SUM(TOKEN_CREDITS), 4) AS total_credits,
                           SUM(TOKENS) AS total_tokens,
                           COUNT(DISTINCT QUERY_ID) AS total_queries
                    FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_AISQL_USAGE_HISTORY
                    WHERE USAGE_TIME >= {date_filter_start} AND USAGE_TIME < CURRENT_TIMESTAMP()
                    GROUP BY FUNCTION_NAME ORDER BY total_credits DESC
                """)
                if not ai_by_func.empty:
                    bar_af = alt.Chart(ai_by_func).mark_bar(cornerRadiusTopLeft=6, cornerRadiusTopRight=6).encode(
                        x=alt.X("FUNCTION_NAME:N", sort="-y", title="Function"),
                        y=alt.Y("TOTAL_CREDITS:Q", title="Credits"),
                        color=alt.Color("TOTAL_CREDITS:Q", scale=alt.Scale(range=GRADIENT_WARM), legend=None),
                        tooltip=["FUNCTION_NAME", "TOTAL_CREDITS", "TOTAL_TOKENS", "TOTAL_QUERIES"]
                    ).properties(height=300, title="Credits by Function")
                    st.altair_chart(bar_af, use_container_width=True)

                ai_by_model = run_query(f"""
                    SELECT MODEL_NAME,
                           ROUND(SUM(TOKEN_CREDITS), 4) AS total_credits,
                           SUM(TOKENS) AS total_tokens
                    FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_AISQL_USAGE_HISTORY
                    WHERE USAGE_TIME >= {date_filter_start} AND USAGE_TIME < CURRENT_TIMESTAMP()
                    GROUP BY MODEL_NAME ORDER BY total_credits DESC
                """)
                if not ai_by_model.empty:
                    donut_model = alt.Chart(ai_by_model).mark_arc(innerRadius=50, outerRadius=110).encode(
                        theta=alt.Theta("TOTAL_CREDITS:Q"),
                        color=alt.Color("MODEL_NAME:N", scale=alt.Scale(range=GRADIENT), legend=alt.Legend(title="Model")),
                        tooltip=["MODEL_NAME", "TOTAL_CREDITS", "TOTAL_TOKENS"]
                    ).properties(height=300, title="Credits by Model")
                    st.altair_chart(donut_model, use_container_width=True)

                ai_by_user = run_query(f"""
                    SELECT u.NAME AS user_name,
                           ROUND(SUM(h.TOKEN_CREDITS), 4) AS total_credits,
                           SUM(h.TOKENS) AS total_tokens,
                           COUNT(DISTINCT h.QUERY_ID) AS total_queries
                    FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_AISQL_USAGE_HISTORY h
                    LEFT JOIN SNOWFLAKE.ACCOUNT_USAGE.USERS u ON TRY_CAST(h.USER_ID AS NUMBER) = u.USER_ID
                    WHERE h.USAGE_TIME >= {date_filter_start} AND h.USAGE_TIME < CURRENT_TIMESTAMP()
                    GROUP BY user_name ORDER BY total_credits DESC LIMIT 20
                """)
                if not ai_by_user.empty:
                    st.markdown("**Credits by User**")
                    bar_afu = alt.Chart(ai_by_user).mark_bar(cornerRadiusTopLeft=6, cornerRadiusTopRight=6).encode(
                        y=alt.Y("USER_NAME:N", sort="-x", title="User"),
                        x=alt.X("TOTAL_CREDITS:Q", title="Credits"),
                        color=alt.Color("TOTAL_CREDITS:Q", scale=alt.Scale(range=GRADIENT_COOL), legend=None),
                        tooltip=["USER_NAME", "TOTAL_CREDITS", "TOTAL_TOKENS", "TOTAL_QUERIES"]
                    ).properties(height=300)
                    st.altair_chart(bar_afu, use_container_width=True)

                ai_daily = run_query(f"""
                    SELECT DATE(USAGE_TIME) AS usage_date,
                           ROUND(SUM(TOKEN_CREDITS), 4) AS daily_credits,
                           SUM(TOKENS) AS daily_tokens
                    FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_AISQL_USAGE_HISTORY
                    WHERE USAGE_TIME >= {date_filter_start} AND USAGE_TIME < CURRENT_TIMESTAMP()
                    GROUP BY usage_date ORDER BY usage_date
                """)
                if not ai_daily.empty:
                    st.markdown("**Daily Trend**")
                    line_ai = alt.Chart(ai_daily).mark_area(
                        opacity=0.6, interpolate="monotone",
                        line={"color": "#667eea"}, color=alt.Gradient(
                            gradient="linear", stops=[alt.GradientStop(color="#667eea", offset=0), alt.GradientStop(color="#764ba2", offset=1)],
                            x1=1, x2=1, y1=1, y2=0)
                    ).encode(
                        x=alt.X("USAGE_DATE:T", title="Date"),
                        y=alt.Y("DAILY_CREDITS:Q", title="Credits"),
                        tooltip=["USAGE_DATE:T", "DAILY_CREDITS", "DAILY_TOKENS"]
                    ).properties(height=250)
                    st.altair_chart(line_ai, use_container_width=True)
            else:
                st.info("No Cortex AI Function usage found for the selected period.")
        except Exception as e:
            st.warning(f"Unable to retrieve Cortex AI Function data: {e}")

    with ai_tabs[1]:
        st.subheader("Cortex Agents")
        try:
            agent_summary = run_query(f"""
                SELECT ROUND(SUM(TOKEN_CREDITS), 4) AS total_credits,
                       SUM(TOKENS) AS total_tokens,
                       COUNT(DISTINCT REQUEST_ID) AS total_requests,
                       COUNT(DISTINCT USER_NAME) AS unique_users
                FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_AGENT_USAGE_HISTORY
                WHERE START_TIME >= {date_filter_start} AND START_TIME < CURRENT_TIMESTAMP()
            """)
            if not agent_summary.empty and agent_summary["TOTAL_CREDITS"].iloc[0]:
                st.markdown(f"""
                <div class="kpi-grid" style="grid-template-columns: repeat(4, 1fr);">
                    <div class="kpi-card kpi-g1"><span class="kpi-icon">💎</span><span class="kpi-value">{agent_summary['TOTAL_CREDITS'].iloc[0]:,.4f}</span><span class="kpi-label">Total Credits</span></div>
                    <div class="kpi-card kpi-g2"><span class="kpi-icon">🔤</span><span class="kpi-value">{agent_summary['TOTAL_TOKENS'].iloc[0]:,}</span><span class="kpi-label">Total Tokens</span></div>
                    <div class="kpi-card kpi-g4"><span class="kpi-icon">📨</span><span class="kpi-value">{agent_summary['TOTAL_REQUESTS'].iloc[0]:,}</span><span class="kpi-label">Requests</span></div>
                    <div class="kpi-card kpi-g5"><span class="kpi-icon">👥</span><span class="kpi-value">{agent_summary['UNIQUE_USERS'].iloc[0]}</span><span class="kpi-label">Unique Users</span></div>
                </div>
                """, unsafe_allow_html=True)

                agent_by_agent = run_query(f"""
                    SELECT COALESCE(AGENT_NAME, 'Unknown') AS agent_name,
                           AGENT_DATABASE_NAME, AGENT_SCHEMA_NAME,
                           ROUND(SUM(TOKEN_CREDITS), 4) AS total_credits,
                           SUM(TOKENS) AS total_tokens,
                           COUNT(DISTINCT REQUEST_ID) AS request_count,
                           COUNT(DISTINCT USER_NAME) AS unique_users
                    FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_AGENT_USAGE_HISTORY
                    WHERE START_TIME >= {date_filter_start} AND START_TIME < CURRENT_TIMESTAMP()
                    GROUP BY AGENT_DATABASE_NAME, AGENT_SCHEMA_NAME, AGENT_NAME
                    ORDER BY total_credits DESC
                """)
                if not agent_by_agent.empty:
                    bar_ag = alt.Chart(agent_by_agent).mark_bar(cornerRadiusTopLeft=6, cornerRadiusTopRight=6).encode(
                        x=alt.X("AGENT_NAME:N", sort="-y", title="Agent"),
                        y=alt.Y("TOTAL_CREDITS:Q", title="Credits", axis=alt.Axis(tickMinStep=1)),
                        color=alt.Color("TOTAL_CREDITS:Q", scale=alt.Scale(range=GRADIENT_WARM), legend=None),
                        tooltip=["AGENT_NAME", "AGENT_DATABASE_NAME", "AGENT_SCHEMA_NAME", "TOTAL_CREDITS", "REQUEST_COUNT", "UNIQUE_USERS"]
                    ).properties(height=300, title="Credits by Agent")
                    st.altair_chart(bar_ag, use_container_width=True)
                    st.dataframe(agent_by_agent, use_container_width=True)

                agent_by_user = run_query(f"""
                    SELECT USER_NAME,
                           ROUND(SUM(TOKEN_CREDITS), 4) AS total_credits,
                           COUNT(DISTINCT REQUEST_ID) AS request_count
                    FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_AGENT_USAGE_HISTORY
                    WHERE START_TIME >= {date_filter_start} AND START_TIME < CURRENT_TIMESTAMP()
                    GROUP BY USER_NAME ORDER BY total_credits DESC LIMIT 20
                """)
                if not agent_by_user.empty:
                    st.markdown("**Credits by User**")
                    st.dataframe(agent_by_user, use_container_width=True)
            else:
                st.info("No Cortex Agent usage found for the selected period.")
        except Exception as e:
            st.warning(f"Unable to retrieve Cortex Agent data: {e}")

    with ai_tabs[2]:
        st.subheader("Cortex Search")
        try:
            search_summary = run_query(f"""
                SELECT ROUND(SUM(CREDITS), 4) AS total_credits,
                       SUM(TOKENS) AS total_tokens,
                       COUNT(DISTINCT SERVICE_NAME) AS unique_services
                FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_SEARCH_DAILY_USAGE_HISTORY
                WHERE USAGE_DATE >= DATE({date_filter_start}) AND USAGE_DATE < CURRENT_DATE()
            """)
            if not search_summary.empty and search_summary["TOTAL_CREDITS"].iloc[0]:
                st.markdown(f"""
                <div class="kpi-grid" style="grid-template-columns: repeat(3, 1fr);">
                    <div class="kpi-card kpi-g1"><span class="kpi-icon">💎</span><span class="kpi-value">{search_summary['TOTAL_CREDITS'].iloc[0]:,.4f}</span><span class="kpi-label">Total Credits</span></div>
                    <div class="kpi-card kpi-g2"><span class="kpi-icon">🔤</span><span class="kpi-value">{search_summary['TOTAL_TOKENS'].iloc[0]:,}</span><span class="kpi-label">Total Tokens</span></div>
                    <div class="kpi-card kpi-g4"><span class="kpi-icon">🔍</span><span class="kpi-value">{search_summary['UNIQUE_SERVICES'].iloc[0]}</span><span class="kpi-label">Services</span></div>
                </div>
                """, unsafe_allow_html=True)

                search_by_svc = run_query(f"""
                    SELECT SERVICE_NAME, DATABASE_NAME, SCHEMA_NAME,
                           ROUND(SUM(CREDITS), 4) AS total_credits,
                           SUM(TOKENS) AS total_tokens
                    FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_SEARCH_DAILY_USAGE_HISTORY
                    WHERE USAGE_DATE >= DATE({date_filter_start}) AND USAGE_DATE < CURRENT_DATE()
                    GROUP BY SERVICE_NAME, DATABASE_NAME, SCHEMA_NAME ORDER BY total_credits DESC
                """)
                if not search_by_svc.empty:
                    bar_cs = alt.Chart(search_by_svc).mark_bar(cornerRadiusTopLeft=6, cornerRadiusTopRight=6).encode(
                        x=alt.X("SERVICE_NAME:N", sort="-y", title="Service"),
                        y=alt.Y("TOTAL_CREDITS:Q", title="Credits", axis=alt.Axis(tickMinStep=1)),
                        color=alt.Color("TOTAL_CREDITS:Q", scale=alt.Scale(range=GRADIENT_COOL), legend=None),
                        tooltip=["SERVICE_NAME", "DATABASE_NAME", "SCHEMA_NAME", "TOTAL_CREDITS", "TOTAL_TOKENS"]
                    ).properties(height=300, title="Credits by Search Service")
                    st.altair_chart(bar_cs, use_container_width=True)

                search_by_type = run_query(f"""
                    SELECT CONSUMPTION_TYPE,
                           ROUND(SUM(CREDITS), 4) AS total_credits,
                           SUM(TOKENS) AS total_tokens
                    FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_SEARCH_DAILY_USAGE_HISTORY
                    WHERE USAGE_DATE >= DATE({date_filter_start}) AND USAGE_DATE < CURRENT_DATE()
                    GROUP BY CONSUMPTION_TYPE ORDER BY total_credits DESC
                """)
                if not search_by_type.empty:
                    donut_ct = alt.Chart(search_by_type).mark_arc(innerRadius=50, outerRadius=110).encode(
                        theta=alt.Theta("TOTAL_CREDITS:Q"),
                        color=alt.Color("CONSUMPTION_TYPE:N", scale=alt.Scale(range=GRADIENT_WARM)),
                        tooltip=["CONSUMPTION_TYPE", "TOTAL_CREDITS", "TOTAL_TOKENS"]
                    ).properties(height=250, title="Serving vs Embedding")
                    st.altair_chart(donut_ct, use_container_width=True)

                search_daily = run_query(f"""
                    SELECT USAGE_DATE, ROUND(SUM(CREDITS), 4) AS daily_credits
                    FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_SEARCH_DAILY_USAGE_HISTORY
                    WHERE USAGE_DATE >= DATE({date_filter_start}) AND USAGE_DATE < CURRENT_DATE()
                    GROUP BY USAGE_DATE ORDER BY USAGE_DATE
                """)
                if not search_daily.empty:
                    st.markdown("**Daily Trend**")
                    line_cs = alt.Chart(search_daily).mark_area(
                        opacity=0.6, interpolate="monotone",
                        line={"color": "#4facfe"}, color=alt.Gradient(
                            gradient="linear", stops=[alt.GradientStop(color="#4facfe", offset=0), alt.GradientStop(color="#00f2fe", offset=1)],
                            x1=1, x2=1, y1=1, y2=0)
                    ).encode(
                        x=alt.X("USAGE_DATE:T", title="Date"), y=alt.Y("DAILY_CREDITS:Q", title="Credits"),
                        tooltip=["USAGE_DATE:T", "DAILY_CREDITS"]
                    ).properties(height=250)
                    st.altair_chart(line_cs, use_container_width=True)
            else:
                st.info("No Cortex Search usage found for the selected period.")
        except Exception as e:
            st.warning(f"Unable to retrieve Cortex Search data: {e}")

    with ai_tabs[3]:
        st.subheader("Snowpark Container Services (SPCS)")
        try:
            spcs_summary = run_query(f"""
                SELECT ROUND(SUM(credits_used), 2) AS total_credits,
                       COUNT(DISTINCT compute_pool_name) AS unique_pools,
                       COUNT(DISTINCT application_name) AS unique_apps
                FROM SNOWFLAKE.ACCOUNT_USAGE.SNOWPARK_CONTAINER_SERVICES_HISTORY
                WHERE start_time >= {date_filter_start} AND start_time < CURRENT_TIMESTAMP()
            """)
            if not spcs_summary.empty and spcs_summary["TOTAL_CREDITS"].iloc[0]:
                st.markdown(f"""
                <div class="kpi-grid" style="grid-template-columns: repeat(3, 1fr);">
                    <div class="kpi-card kpi-g1"><span class="kpi-icon">💎</span><span class="kpi-value">{spcs_summary['TOTAL_CREDITS'].iloc[0]:,.2f}</span><span class="kpi-label">Total SPCS Credits</span></div>
                    <div class="kpi-card kpi-g4"><span class="kpi-icon">🖥️</span><span class="kpi-value">{spcs_summary['UNIQUE_POOLS'].iloc[0]}</span><span class="kpi-label">Compute Pools</span></div>
                    <div class="kpi-card kpi-g5"><span class="kpi-icon">📦</span><span class="kpi-value">{spcs_summary['UNIQUE_APPS'].iloc[0]}</span><span class="kpi-label">Applications</span></div>
                </div>
                """, unsafe_allow_html=True)

                spcs_by_pool = run_query(f"""
                    SELECT compute_pool_name,
                           ROUND(SUM(credits_used), 2) AS total_credits,
                           COUNT(*) AS usage_hours,
                           ROUND(AVG(credits_used), 4) AS avg_per_hour,
                           MAX(application_name) AS application
                    FROM SNOWFLAKE.ACCOUNT_USAGE.SNOWPARK_CONTAINER_SERVICES_HISTORY
                    WHERE start_time >= {date_filter_start} AND start_time < CURRENT_TIMESTAMP()
                    GROUP BY compute_pool_name ORDER BY total_credits DESC LIMIT 20
                """)
                if not spcs_by_pool.empty:
                    bar_sp = alt.Chart(spcs_by_pool).mark_bar(cornerRadiusTopLeft=6, cornerRadiusTopRight=6).encode(
                        x=alt.X("COMPUTE_POOL_NAME:N", sort="-y", title="Compute Pool"),
                        y=alt.Y("TOTAL_CREDITS:Q", title="Credits", axis=alt.Axis(tickMinStep=1)),
                        color=alt.Color("TOTAL_CREDITS:Q", scale=alt.Scale(range=GRADIENT_WARM), legend=None),
                        tooltip=["COMPUTE_POOL_NAME", "TOTAL_CREDITS", "USAGE_HOURS", "AVG_PER_HOUR", "APPLICATION"]
                    ).properties(height=300, title="Credits by Compute Pool")
                    st.altair_chart(bar_sp, use_container_width=True)
                    st.dataframe(spcs_by_pool, use_container_width=True)

                spcs_daily = run_query(f"""
                    SELECT DATE(start_time) AS usage_date, compute_pool_name,
                           ROUND(SUM(credits_used), 2) AS daily_credits
                    FROM SNOWFLAKE.ACCOUNT_USAGE.SNOWPARK_CONTAINER_SERVICES_HISTORY
                    WHERE start_time >= {date_filter_start} AND start_time < CURRENT_TIMESTAMP()
                    GROUP BY usage_date, compute_pool_name ORDER BY usage_date
                """)
                if not spcs_daily.empty:
                    st.markdown("**Daily Trend by Compute Pool**")
                    area_sp = alt.Chart(spcs_daily).mark_area(opacity=0.6, interpolate="monotone").encode(
                        x=alt.X("USAGE_DATE:T", title="Date"),
                        y=alt.Y("DAILY_CREDITS:Q", stack=True, title="Credits"),
                        color=alt.Color("COMPUTE_POOL_NAME:N", scale=alt.Scale(range=GRADIENT)),
                        tooltip=["USAGE_DATE:T", "COMPUTE_POOL_NAME", "DAILY_CREDITS"]
                    ).properties(height=300)
                    st.altair_chart(area_sp, use_container_width=True)

                spcs_by_app = run_query(f"""
                    SELECT COALESCE(application_name, 'Direct Usage') AS application_name,
                           ROUND(SUM(credits_used), 2) AS total_credits
                    FROM SNOWFLAKE.ACCOUNT_USAGE.SNOWPARK_CONTAINER_SERVICES_HISTORY
                    WHERE start_time >= {date_filter_start} AND start_time < CURRENT_TIMESTAMP()
                    GROUP BY application_name ORDER BY total_credits DESC
                """)
                if not spcs_by_app.empty:
                    st.markdown("**Credits by Application**")
                    donut_app = alt.Chart(spcs_by_app).mark_arc(innerRadius=50, outerRadius=110).encode(
                        theta=alt.Theta("TOTAL_CREDITS:Q"),
                        color=alt.Color("APPLICATION_NAME:N", scale=alt.Scale(range=GRADIENT_COOL)),
                        tooltip=["APPLICATION_NAME", "TOTAL_CREDITS"]
                    ).properties(height=250)
                    st.altair_chart(donut_app, use_container_width=True)
            else:
                st.info("No Snowpark Container Services usage found for the selected period.")
        except Exception as e:
            st.warning(f"Unable to retrieve SPCS data: {e}")

    with ai_tabs[4]:
        st.subheader("Notebooks (Container Runtime)")
        try:
            nb_summary = run_query(f"""
                SELECT ROUND(SUM(CREDITS), 4) AS total_credits,
                       COUNT(DISTINCT NOTEBOOK_NAME) AS unique_notebooks,
                       COUNT(DISTINCT USER_NAME) AS unique_users,
                       ROUND(SUM(NOTEBOOK_EXECUTION_TIME_SECS)/3600.0, 2) AS total_hours
                FROM SNOWFLAKE.ACCOUNT_USAGE.NOTEBOOKS_CONTAINER_RUNTIME_HISTORY
                WHERE START_TIME >= {date_filter_start} AND START_TIME < CURRENT_TIMESTAMP()
            """)
            if not nb_summary.empty and nb_summary["TOTAL_CREDITS"].iloc[0]:
                st.markdown(f"""
                <div class="kpi-grid" style="grid-template-columns: repeat(4, 1fr);">
                    <div class="kpi-card kpi-g1"><span class="kpi-icon">💎</span><span class="kpi-value">{nb_summary['TOTAL_CREDITS'].iloc[0]:,.4f}</span><span class="kpi-label">Total Credits</span></div>
                    <div class="kpi-card kpi-g2"><span class="kpi-icon">📓</span><span class="kpi-value">{nb_summary['UNIQUE_NOTEBOOKS'].iloc[0]}</span><span class="kpi-label">Notebooks</span></div>
                    <div class="kpi-card kpi-g4"><span class="kpi-icon">👥</span><span class="kpi-value">{nb_summary['UNIQUE_USERS'].iloc[0]}</span><span class="kpi-label">Users</span></div>
                    <div class="kpi-card kpi-g5"><span class="kpi-icon">⏱️</span><span class="kpi-value">{nb_summary['TOTAL_HOURS'].iloc[0]:,.2f}</span><span class="kpi-label">Runtime (hrs)</span></div>
                </div>
                """, unsafe_allow_html=True)

                nb_by_notebook = run_query(f"""
                    SELECT NOTEBOOK_NAME, USER_NAME, COMPUTE_POOL_NAME,
                           ROUND(SUM(CREDITS), 4) AS total_credits,
                           ROUND(SUM(NOTEBOOK_EXECUTION_TIME_SECS)/60.0, 2) AS runtime_min
                    FROM SNOWFLAKE.ACCOUNT_USAGE.NOTEBOOKS_CONTAINER_RUNTIME_HISTORY
                    WHERE START_TIME >= {date_filter_start} AND START_TIME < CURRENT_TIMESTAMP()
                    GROUP BY NOTEBOOK_NAME, USER_NAME, COMPUTE_POOL_NAME
                    ORDER BY total_credits DESC LIMIT 20
                """)
                if not nb_by_notebook.empty:
                    bar_nb = alt.Chart(nb_by_notebook).mark_bar(cornerRadiusTopLeft=6, cornerRadiusTopRight=6).encode(
                        x=alt.X("NOTEBOOK_NAME:N", sort="-y", title="Notebook"),
                        y=alt.Y("TOTAL_CREDITS:Q", title="Credits", axis=alt.Axis(tickMinStep=1)),
                        color=alt.Color("USER_NAME:N", scale=alt.Scale(range=GRADIENT), legend=alt.Legend(title="User")),
                        tooltip=["NOTEBOOK_NAME", "USER_NAME", "COMPUTE_POOL_NAME", "TOTAL_CREDITS", "RUNTIME_MIN"]
                    ).properties(height=300, title="Credits by Notebook")
                    st.altair_chart(bar_nb, use_container_width=True)
                    st.dataframe(nb_by_notebook, use_container_width=True)
            else:
                st.info("No Notebook container runtime usage found for the selected period.")
        except Exception as e:
            st.warning(f"Unable to retrieve Notebook container data: {e}")

    with ai_tabs[5]:
        st.subheader("Cortex Code (Snowsight)")
        try:
            coc_summary = run_query(f"""
                SELECT ROUND(SUM(TOKEN_CREDITS), 4) AS total_credits,
                       SUM(TOKENS) AS total_tokens,
                       COUNT(DISTINCT REQUEST_ID) AS total_requests,
                       COUNT(DISTINCT USER_ID) AS unique_users
                FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_CODE_SNOWSIGHT_USAGE_HISTORY
                WHERE USAGE_TIME >= {date_filter_start} AND USAGE_TIME < CURRENT_TIMESTAMP()
            """)
            if not coc_summary.empty and coc_summary["TOTAL_CREDITS"].iloc[0]:
                st.markdown(f"""
                <div class="kpi-grid" style="grid-template-columns: repeat(4, 1fr);">
                    <div class="kpi-card kpi-g1"><span class="kpi-icon">💎</span><span class="kpi-value">{coc_summary['TOTAL_CREDITS'].iloc[0]:,.4f}</span><span class="kpi-label">Total Credits</span></div>
                    <div class="kpi-card kpi-g2"><span class="kpi-icon">🔤</span><span class="kpi-value">{coc_summary['TOTAL_TOKENS'].iloc[0]:,}</span><span class="kpi-label">Total Tokens</span></div>
                    <div class="kpi-card kpi-g4"><span class="kpi-icon">📨</span><span class="kpi-value">{coc_summary['TOTAL_REQUESTS'].iloc[0]:,}</span><span class="kpi-label">Requests</span></div>
                    <div class="kpi-card kpi-g5"><span class="kpi-icon">👥</span><span class="kpi-value">{coc_summary['UNIQUE_USERS'].iloc[0]}</span><span class="kpi-label">Unique Users</span></div>
                </div>
                """, unsafe_allow_html=True)

                coc_by_user = run_query(f"""
                    SELECT u.NAME AS user_name,
                           ROUND(SUM(h.TOKEN_CREDITS), 4) AS total_credits,
                           SUM(h.TOKENS) AS total_tokens,
                           COUNT(DISTINCT h.REQUEST_ID) AS request_count
                    FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_CODE_SNOWSIGHT_USAGE_HISTORY h
                    LEFT JOIN SNOWFLAKE.ACCOUNT_USAGE.USERS u ON h.USER_ID = u.USER_ID
                    WHERE h.USAGE_TIME >= {date_filter_start} AND h.USAGE_TIME < CURRENT_TIMESTAMP()
                    GROUP BY user_name ORDER BY total_credits DESC LIMIT 20
                """)
                if not coc_by_user.empty:
                    st.subheader("Credits by User")
                    bar_coc = alt.Chart(coc_by_user).mark_bar(cornerRadiusTopLeft=6, cornerRadiusTopRight=6).encode(
                        y=alt.Y("USER_NAME:N", sort="-x", title="User"),
                        x=alt.X("TOTAL_CREDITS:Q", title="Credits", axis=alt.Axis(tickMinStep=1)),
                        color=alt.Color("TOTAL_CREDITS:Q", scale=alt.Scale(range=GRADIENT_WARM), legend=None),
                        tooltip=["USER_NAME", "TOTAL_CREDITS", "TOTAL_TOKENS", "REQUEST_COUNT"]
                    ).properties(height=300)
                    st.altair_chart(bar_coc, use_container_width=True)
                    st.dataframe(coc_by_user, use_container_width=True)

                coc_by_model = run_query(f"""
                    SELECT f.key AS model_name,
                           ROUND(SUM(COALESCE(f.value:input::FLOAT, 0) + COALESCE(f.value:output::FLOAT, 0) + COALESCE(f.value:cache_read_input::FLOAT, 0) + COALESCE(f.value:cache_write_input::FLOAT, 0)), 4) AS total_credits
                    FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_CODE_SNOWSIGHT_USAGE_HISTORY h,
                         LATERAL FLATTEN(input => h.CREDITS_GRANULAR) f
                    WHERE h.USAGE_TIME >= {date_filter_start} AND h.USAGE_TIME < CURRENT_TIMESTAMP()
                    GROUP BY f.key ORDER BY total_credits DESC
                """)
                if not coc_by_model.empty:
                    st.subheader("Credits by Model")
                    donut_coc = alt.Chart(coc_by_model).mark_arc(innerRadius=50, outerRadius=110).encode(
                        theta=alt.Theta("TOTAL_CREDITS:Q"),
                        color=alt.Color("MODEL_NAME:N", scale=alt.Scale(range=GRADIENT), legend=alt.Legend(title="Model")),
                        tooltip=["MODEL_NAME", "TOTAL_CREDITS"]
                    ).properties(height=300)
                    st.altair_chart(donut_coc, use_container_width=True)

                coc_daily = run_query(f"""
                    SELECT DATE(USAGE_TIME) AS usage_date,
                           ROUND(SUM(TOKEN_CREDITS), 4) AS daily_credits,
                           SUM(TOKENS) AS daily_tokens,
                           COUNT(DISTINCT REQUEST_ID) AS daily_requests
                    FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_CODE_SNOWSIGHT_USAGE_HISTORY
                    WHERE USAGE_TIME >= {date_filter_start} AND USAGE_TIME < CURRENT_TIMESTAMP()
                    GROUP BY usage_date ORDER BY usage_date
                """)
                if not coc_daily.empty:
                    st.subheader("Daily Trend")
                    line_coc = alt.Chart(coc_daily).mark_area(
                        opacity=0.6, interpolate="monotone",
                        line={"color": "#667eea"}, color=alt.Gradient(
                            gradient="linear", stops=[alt.GradientStop(color="#667eea", offset=0), alt.GradientStop(color="#764ba2", offset=1)],
                            x1=1, x2=1, y1=1, y2=0)
                    ).encode(
                        x=alt.X("USAGE_DATE:T", title="Date"),
                        y=alt.Y("DAILY_CREDITS:Q", title="Credits", axis=alt.Axis(tickMinStep=1)),
                        tooltip=["USAGE_DATE:T", "DAILY_CREDITS", "DAILY_TOKENS", "DAILY_REQUESTS"]
                    ).properties(height=250)
                    st.altair_chart(line_coc, use_container_width=True)
            else:
                st.info("No Cortex Code usage found for the selected period.")
        except Exception as e:
            st.warning(f"Unable to retrieve Cortex Code data: {e}")

# ────────────────── TAB 6: OVERVIEW ──────────────────
with tab6:
    st.subheader("Credits by Service Type")
    svc_filter = f"AND service_type = '{selected_service}'" if selected_service != "All" else ""
    svc_df = run_query(f"""
        SELECT service_type, ROUND(SUM(credits_billed), 2) AS total_credits,
               ROUND(SUM(credits_billed) / SUM(SUM(credits_billed)) OVER () * 100, 1) AS pct
        FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_DAILY_HISTORY
        WHERE usage_date >= {date_filter_start} AND usage_date < {date_filter_end} {svc_filter}
        GROUP BY service_type ORDER BY total_credits DESC
    """)

    if not svc_df.empty:
        donut = alt.Chart(svc_df).mark_arc(innerRadius=60, outerRadius=120).encode(
            theta=alt.Theta("TOTAL_CREDITS:Q"),
            color=alt.Color("SERVICE_TYPE:N", scale=alt.Scale(range=GRADIENT), legend=alt.Legend(title="Service")),
            tooltip=["SERVICE_TYPE", "TOTAL_CREDITS", "PCT"]
        ).properties(height=350, title="Credit Distribution")
        st.altair_chart(donut, use_container_width=True)
        st.dataframe(svc_df, use_container_width=True)

    st.subheader("Daily Credit Trend (All Services)")
    daily_all_df = run_query(f"""
        SELECT usage_date, service_type,
               ROUND(SUM(credits_billed), 2) AS daily_credits
        FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_DAILY_HISTORY
        WHERE usage_date >= {date_filter_start} AND usage_date < {date_filter_end} {svc_filter}
        GROUP BY usage_date, service_type ORDER BY usage_date
    """)

    if not daily_all_df.empty:
        stacked = alt.Chart(daily_all_df).mark_bar(cornerRadiusTopLeft=4, cornerRadiusTopRight=4).encode(
            x=alt.X("USAGE_DATE:T", title="Date"),
            y=alt.Y("DAILY_CREDITS:Q", stack=True, title="Credits", axis=alt.Axis(tickMinStep=1)),
            color=alt.Color("SERVICE_TYPE:N", scale=alt.Scale(range=GRADIENT), legend=alt.Legend(title="Service")),
            tooltip=["USAGE_DATE:T", "SERVICE_TYPE", "DAILY_CREDITS"]
        ).properties(height=350)
        st.altair_chart(stacked, use_container_width=True)

    st.subheader("Account-Level Anomalies")
    anomaly_df = run_query("""
        SELECT date AS USAGE_DATE,
               ROUND(actual_value, 2) AS ACTUAL_CREDITS,
               ROUND(forecasted_value, 2) AS FORECAST,
               ROUND(upper_bound, 2) AS UPPER_BOUND,
               ROUND(lower_bound, 2) AS LOWER_BOUND,
               is_anomaly AS IS_ANOMALY
        FROM SNOWFLAKE.ACCOUNT_USAGE.ANOMALIES_DAILY
        WHERE date >= DATEADD('day', -90, CURRENT_DATE())
        ORDER BY date
    """)

    if not anomaly_df.empty:
        base_a = alt.Chart(anomaly_df).encode(x=alt.X("USAGE_DATE:T", title="Date"))
        band_a = base_a.mark_area(opacity=0.12, color="#764ba2").encode(y="LOWER_BOUND:Q", y2="UPPER_BOUND:Q")
        fc_line = base_a.mark_line(strokeDash=[5, 5], color="#667eea").encode(y="FORECAST:Q")
        pts_a = base_a.mark_circle(size=60).encode(
            y=alt.Y("ACTUAL_CREDITS:Q", title="Credits"),
            color=alt.condition(alt.datum.IS_ANOMALY == True, alt.value("#f5576c"), alt.value("#43e97b")),
            tooltip=["USAGE_DATE:T", "ACTUAL_CREDITS", "FORECAST", "UPPER_BOUND", "IS_ANOMALY"]
        )
        st.altair_chart(band_a + fc_line + pts_a, use_container_width=True)
    else:
        st.info("No anomaly data available. Ensure ANOMALIES_DAILY view is accessible.")