import streamlit as st
import os
import pandas as pd
import altair as alt
from datetime import datetime, timedelta

# ─── Page Config ───
st.set_page_config(page_title="Warehouse Efficiency Analyzer", page_icon="❄️", layout="wide")

# ─── Snowflake Connection ───
conn = st.connection("snowflake", ttl=os.getenv("SNOWFLAKE_CONNECTION_TTL"))

# ─── Gradient Palettes (Credit Monitor style) ───
GRADIENT_WARM = ["#667eea", "#764ba2", "#e040fb", "#f5576c", "#ff6f00"]
GRADIENT_COOL = ["#4facfe", "#00f2fe", "#43e97b", "#38f9d7", "#667eea"]
GRADIENT_ALL = ["#667eea", "#764ba2", "#f093fb", "#f5576c", "#4facfe", "#00f2fe", "#43e97b", "#38f9d7"]

# ─── Custom CSS ───
st.markdown("""
<style>
@keyframes fadeInUp {
    from { opacity: 0; transform: translateY(30px); }
    to { opacity: 1; transform: translateY(0); }
}
@keyframes gradientShift {
    0% { background-position: 0% 50%; }
    50% { background-position: 100% 50%; }
    100% { background-position: 0% 50%; }
}
@keyframes float {
    0%, 100% { transform: translateY(0px); }
    50% { transform: translateY(-8px); }
}
@keyframes countUp {
    from { opacity: 0; transform: translateY(10px); }
    to { opacity: 1; transform: translateY(0); }
}
@keyframes alertPulse {
    0%, 100% { box-shadow: 0 4px 15px rgba(102,126,234,0.3); }
    50% { box-shadow: 0 4px 25px rgba(245,87,108,0.5); }
}
@keyframes borderGlow {
    0%, 100% { border-color: #667eea40; box-shadow: 0 0 5px #667eea20; }
    50% { border-color: #764ba280; box-shadow: 0 0 20px #764ba240; }
}
@keyframes slideInLeft {
    from { opacity: 0; transform: translateX(-40px); }
    to { opacity: 1; transform: translateX(0); }
}

/* Hero Banner */
.hero-banner {
    background: linear-gradient(270deg, #667eea, #764ba2, #f093fb, #667eea);
    background-size: 600% 600%;
    animation: gradientShift 8s ease infinite;
    border-radius: 20px;
    padding: 50px 40px;
    text-align: center;
    margin-bottom: 30px;
    box-shadow: 0 12px 40px rgba(102,126,234,0.4);
    position: relative;
    overflow: hidden;
}
.hero-banner::before {
    content: '';
    position: absolute;
    top: -50%; left: -50%;
    width: 200%; height: 200%;
    background: radial-gradient(circle, rgba(255,255,255,0.1) 0%, transparent 60%);
    animation: float 6s ease-in-out infinite;
}
.hero-banner h1 {
    color: white !important;
    font-size: 2.6em;
    margin: 8px 0 16px 0;
    animation: fadeInUp 0.8s ease-out 0.5s both;
    text-shadow: 0 2px 20px rgba(0,0,0,0.2);
    position: relative;
}
.hero-banner .hero-subtitle {
    color: rgba(255,255,255,0.9);
    font-size: 1.1em;
    animation: fadeInUp 0.8s ease-out 0.8s both;
    max-width: 700px;
    margin: 0 auto;
    line-height: 1.6;
    position: relative;
}
.hero-banner .hero-divider {
    width: 60px; height: 3px;
    background: rgba(255,255,255,0.5);
    margin: 16px auto;
    border-radius: 2px;
    animation: fadeInUp 0.8s ease-out 0.6s both;
}

/* Section Titles */
.section-title {
    animation: slideInLeft 0.6s ease-out;
    font-size: 1.4em;
    margin: 10px 0 16px 0;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    font-weight: 700;
}

/* KPI Cards */
.kpi-grid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 14px;
    margin-bottom: 24px;
}
.kpi-card {
    border-radius: 14px;
    padding: 20px 16px;
    text-align: center;
    position: relative;
    overflow: hidden;
    transition: all 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);
    animation: fadeInUp 0.5s ease-out both;
}
.kpi-card:nth-child(1) { animation-delay: 0.1s; }
.kpi-card:nth-child(2) { animation-delay: 0.2s; }
.kpi-card:nth-child(3) { animation-delay: 0.3s; }
.kpi-card:nth-child(4) { animation-delay: 0.4s; }
.kpi-card:hover { transform: translateY(-4px) scale(1.02); }
.kpi-card::before {
    content: '';
    position: absolute;
    top: 0; left: -100%;
    width: 100%; height: 100%;
    background: linear-gradient(90deg, transparent, rgba(255,255,255,0.15), transparent);
    transition: left 0.5s ease;
}
.kpi-card:hover::before { left: 100%; }
.kpi-card .kpi-icon { font-size: 1.6em; margin-bottom: 6px; display: block; }
.kpi-card .kpi-value {
    font-size: 1.5em; font-weight: 700; color: white; display: block;
    animation: countUp 0.8s ease-out both;
    text-shadow: 0 1px 8px rgba(0,0,0,0.15);
}
.kpi-card .kpi-label {
    font-size: 0.72em; color: rgba(255,255,255,0.85);
    text-transform: uppercase; letter-spacing: 1.2px;
    margin-top: 4px; display: block;
}
.kpi-g1 { background: linear-gradient(135deg, #667eea, #764ba2); box-shadow: 0 4px 15px rgba(102,126,234,0.3); }
.kpi-g2 { background: linear-gradient(135deg, #764ba2, #9b59b6); box-shadow: 0 4px 15px rgba(118,75,162,0.3); }
.kpi-g3 { background: linear-gradient(135deg, #f093fb, #f5576c); box-shadow: 0 4px 15px rgba(240,147,251,0.3); }
.kpi-g4 { background: linear-gradient(135deg, #4facfe, #00f2fe); box-shadow: 0 4px 15px rgba(79,172,254,0.3); }
.kpi-alert { animation: alertPulse 2s ease-in-out infinite; }

/* Recommendation Cards */
.rec-card {
    background: linear-gradient(135deg, rgba(102,126,234,0.05) 0%, rgba(118,75,162,0.05) 100%);
    border: 1px solid #667eea30;
    border-radius: 12px;
    padding: 16px 20px;
    margin: 10px 0;
    transition: all 0.3s ease;
    animation: borderGlow 3s ease-in-out infinite;
}
.rec-card:hover {
    transform: translateY(-3px);
    box-shadow: 0 8px 20px rgba(102,126,234,0.15);
}
.rec-severity {
    display: inline-block;
    padding: 2px 10px;
    border-radius: 20px;
    font-size: 0.75em;
    font-weight: 600;
    margin-right: 8px;
}
.severity-high { background: rgba(245,87,108,0.2); color: #f5576c; }
.severity-medium { background: rgba(255,165,0,0.2); color: #ff9800; }
.severity-low { background: rgba(79,172,254,0.2); color: #4facfe; }
.rec-card h4 { margin: 8px 0 4px 0; color: #667eea; font-size: 1em; }
.rec-card p { margin: 0; color: #555; font-size: 0.9em; line-height: 1.5; }
</style>
""", unsafe_allow_html=True)


# ─── Data Loaders ───

@st.cache_data(ttl=600, show_spinner=False)
def get_warehouse_names():
    """Fetch distinct warehouse names from the last 90 days."""
    return conn.query("""
        SELECT DISTINCT WAREHOUSE_NAME
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE WAREHOUSE_NAME IS NOT NULL
          AND START_TIME >= DATEADD('day', -90, CURRENT_TIMESTAMP())
        ORDER BY WAREHOUSE_NAME
    """)["WAREHOUSE_NAME"].tolist()


@st.cache_data(ttl=600, show_spinner=False)
def get_query_metrics(start_date: str, end_date: str):
    """Load daily query metrics between the selected dates."""
    return conn.query(f"""
        SELECT
            DATE_TRUNC('day', START_TIME)::DATE AS QUERY_DATE,
            WAREHOUSE_NAME,
            COUNT(*) AS TOTAL_QUERIES,
            SUM(CASE WHEN EXECUTION_STATUS = 'SUCCESS' THEN 1 ELSE 0 END) AS SUCCESSFUL_QUERIES,
            AVG(QUEUED_OVERLOAD_TIME / 1000) AS AVG_QUEUE_TIME_SEC,
            AVG(TOTAL_ELAPSED_TIME / 1000) AS AVG_EXECUTION_TIME_SEC,
            COUNT(CASE WHEN QUEUED_OVERLOAD_TIME > 0 THEN 1 END) AS QUEUED_QUERY_COUNT,
            COUNT(CASE WHEN EXECUTION_STATUS = 'SUCCESS' AND QUEUED_OVERLOAD_TIME = 0 THEN 1 END) AS RUNNING_QUERY_COUNT
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE START_TIME >= '{start_date}'
          AND START_TIME < '{end_date}'
          AND WAREHOUSE_NAME IS NOT NULL
          AND QUERY_TYPE IN ('SELECT','INSERT','UPDATE','DELETE','MERGE','CREATE_TABLE_AS_SELECT')
        GROUP BY QUERY_DATE, WAREHOUSE_NAME
        ORDER BY QUERY_DATE
    """)


@st.cache_data(ttl=600, show_spinner=False)
def get_concurrency_data(start_date: str, end_date: str):
    """Load daily concurrency stats."""
    return conn.query(f"""
        SELECT
            DATE_TRUNC('day', START_TIME)::DATE AS QUERY_DATE,
            WAREHOUSE_NAME,
            MAX(CLUSTER_NUMBER) AS PEAK_CLUSTERS,
            ROUND(COUNT(*)::FLOAT / NULLIF(COUNT(DISTINCT DATE_TRUNC('hour', START_TIME)), 0), 2) AS AVG_QUERIES_PER_HOUR
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE START_TIME >= '{start_date}'
          AND START_TIME < '{end_date}'
          AND WAREHOUSE_NAME IS NOT NULL
        GROUP BY QUERY_DATE, WAREHOUSE_NAME
        ORDER BY QUERY_DATE
    """)


@st.cache_data(ttl=600, show_spinner=False)
def get_credit_usage(start_date: str, end_date: str):
    """Load warehouse credit consumption."""
    return conn.query(f"""
        SELECT
            DATE_TRUNC('day', START_TIME)::DATE AS USAGE_DATE,
            WAREHOUSE_NAME,
            ROUND(SUM(CREDITS_USED), 2) AS CREDITS_USED
        FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
        WHERE START_TIME >= '{start_date}'
          AND START_TIME < '{end_date}'
        GROUP BY USAGE_DATE, WAREHOUSE_NAME
        ORDER BY USAGE_DATE
    """)


def clear_caches():
    """Clear all cached data."""
    get_warehouse_names.clear()
    get_query_metrics.clear()
    get_concurrency_data.clear()
    get_credit_usage.clear()


def build_recommendations(df: pd.DataFrame, warehouses: list) -> list:
    """Generate optimization recommendations based on warehouse metrics."""
    recs = []
    for wh in warehouses:
        wh_data = df[df["WAREHOUSE_NAME"] == wh]
        if wh_data.empty:
            continue
        total_q = wh_data["TOTAL_QUERIES"].sum()
        total_queued = wh_data["QUEUED_QUERY_COUNT"].sum()
        avg_qt = wh_data["AVG_QUEUE_TIME_SEC"].mean()
        avg_et = wh_data["AVG_EXECUTION_TIME_SEC"].mean()
        qr = (total_queued / total_q * 100) if total_q > 0 else 0

        if qr > 20:
            recs.append({"warehouse": wh, "severity": "HIGH",
                         "issue": f"High queue ratio ({qr:.1f}%)",
                         "suggestion": "Scale up warehouse size or enable multi-cluster scaling. Queries frequently wait for compute."})
        elif qr > 10:
            recs.append({"warehouse": wh, "severity": "MEDIUM",
                         "issue": f"Moderate queue ratio ({qr:.1f}%)",
                         "suggestion": "Consider auto-scaling with MIN/MAX clusters to handle peak demand."})
        if avg_qt > 10:
            recs.append({"warehouse": wh, "severity": "HIGH",
                         "issue": f"High avg queue time ({avg_qt:.1f}s)",
                         "suggestion": "Increase warehouse size. Long queue times indicate insufficient compute capacity."})
        if avg_et > 60 and qr < 5:
            recs.append({"warehouse": wh, "severity": "MEDIUM",
                         "issue": f"Long execution time ({avg_et:.1f}s) with low queuing",
                         "suggestion": "Queries are slow but don't queue. Consider upsizing or optimizing queries."})
        if total_q < 10 and avg_qt < 1:
            recs.append({"warehouse": wh, "severity": "LOW",
                         "issue": "Very low utilization",
                         "suggestion": "Warehouse is underutilized. Consider downsizing or consolidating workloads."})
        if len(wh_data) > 3:
            cv = (wh_data["TOTAL_QUERIES"].std() / wh_data["TOTAL_QUERIES"].mean()) if wh_data["TOTAL_QUERIES"].mean() > 0 else 0
            if cv > 1.5:
                recs.append({"warehouse": wh, "severity": "MEDIUM",
                             "issue": "Highly variable workload",
                             "suggestion": "Enable auto-suspend (1-2 min) and auto-scaling to match spiky demand."})
    return recs


# ═══════════════════════════════════════════════════════════
# ─── HERO BANNER ───
# ═══════════════════════════════════════════════════════════

st.markdown("""
<div class="hero-banner">
    <h1>❄️ Warehouse Efficiency Analyzer</h1>
    <div class="hero-divider"></div>
    <p class="hero-subtitle">
        Analyze virtual warehouse performance, detect queuing bottlenecks,
        and get actionable optimization recommendations.
    </p>
</div>
""", unsafe_allow_html=True)


# ═══════════════════════════════════════════════════════════
# ─── FILTERS ROW ───
# ═══════════════════════════════════════════════════════════

filter_cols = st.columns([2, 2, 2, 1])

with filter_cols[0]:
    start_date = st.date_input(
        "Start Date",
        value=datetime.now() - timedelta(days=30),
        max_value=datetime.now(),
    )

with filter_cols[1]:
    end_date = st.date_input(
        "End Date",
        value=datetime.now(),
        max_value=datetime.now(),
    )

# Load warehouse list
all_warehouses = get_warehouse_names()

with filter_cols[2]:
    selected_warehouses = st.multiselect(
        "Warehouses",
        options=all_warehouses,
        default=all_warehouses[:5] if len(all_warehouses) > 5 else all_warehouses,
        placeholder="Select warehouses...",
    )

with filter_cols[3]:
    st.markdown("<br>", unsafe_allow_html=True)
    st.button("🔄 Refresh", on_click=clear_caches, use_container_width=True)

# Format dates for SQL
start_str = start_date.strftime("%Y-%m-%d")
end_str = (end_date + timedelta(days=1)).strftime("%Y-%m-%d")

# ─── Load Data ───
with st.spinner("Loading warehouse metrics..."):
    metrics_df = get_query_metrics(start_str, end_str)
    concurrency_df = get_concurrency_data(start_str, end_str)
    credits_df = get_credit_usage(start_str, end_str)

# Filter by selected warehouses
if selected_warehouses:
    metrics_df = metrics_df[metrics_df["WAREHOUSE_NAME"].isin(selected_warehouses)]
    concurrency_df = concurrency_df[concurrency_df["WAREHOUSE_NAME"].isin(selected_warehouses)]
    credits_df = credits_df[credits_df["WAREHOUSE_NAME"].isin(selected_warehouses)]

if metrics_df.empty:
    st.warning("No query data found for the selected date range and warehouses.")
    st.stop()


# ═══════════════════════════════════════════════════════════
# ─── KPI CARDS ───
# ═══════════════════════════════════════════════════════════

total_queries = int(metrics_df["TOTAL_QUERIES"].sum())
avg_queue_time = metrics_df["AVG_QUEUE_TIME_SEC"].mean()
total_queued = int(metrics_df["QUEUED_QUERY_COUNT"].sum())
queue_ratio = (total_queued / total_queries * 100) if total_queries > 0 else 0
avg_exec_time = metrics_df["AVG_EXECUTION_TIME_SEC"].mean()

alert_class = " kpi-alert" if queue_ratio > 15 else ""

st.markdown(f"""
<div class="kpi-grid">
    <div class="kpi-card kpi-g1">
        <span class="kpi-icon">📊</span>
        <span class="kpi-value">{total_queries:,}</span>
        <span class="kpi-label">Total Queries</span>
    </div>
    <div class="kpi-card kpi-g2">
        <span class="kpi-icon">⏱️</span>
        <span class="kpi-value">{avg_queue_time:.2f}s</span>
        <span class="kpi-label">Avg Queue Time</span>
    </div>
    <div class="kpi-card kpi-g3{alert_class}">
        <span class="kpi-icon">🚦</span>
        <span class="kpi-value">{queue_ratio:.1f}%</span>
        <span class="kpi-label">Queue Ratio</span>
    </div>
    <div class="kpi-card kpi-g4">
        <span class="kpi-icon">⚡</span>
        <span class="kpi-value">{avg_exec_time:.1f}s</span>
        <span class="kpi-label">Avg Execution Time</span>
    </div>
</div>
""", unsafe_allow_html=True)


# ═══════════════════════════════════════════════════════════
# ─── TABS ───
# ═══════════════════════════════════════════════════════════

tab_home, tab1, tab2, tab3, tab4 = st.tabs([
    "🏠 Home",
    "📈 Running vs Queued",
    "🏢 Per-Warehouse",
    "🔀 Concurrency",
    "💡 Recommendations",
])


# ─── TAB: Home ───
with tab_home:
    st.markdown('<div class="section-title">About This App</div>', unsafe_allow_html=True)

    st.markdown("""
    <div style="background: linear-gradient(135deg, rgba(102,126,234,0.05), rgba(118,75,162,0.08));
                border: 1px solid #667eea30; border-radius: 14px; padding: 28px 32px; margin-bottom: 24px;">
        <p style="font-size: 1.05em; line-height: 1.7; color: #444; margin: 0;">
            <strong>Warehouse Efficiency Analyzer</strong> helps Snowflake administrators and data engineers
            understand how well their virtual warehouses are performing. It connects directly to
            <code>SNOWFLAKE.ACCOUNT_USAGE</code> views to pull real query execution data, detect bottlenecks,
            and deliver clear optimization recommendations — all in one place.
        </p>
    </div>
    """, unsafe_allow_html=True)

    st.markdown('<div class="section-title">Key Features</div>', unsafe_allow_html=True)

    feat_cols = st.columns(2)
    with feat_cols[0]:
        st.markdown("""
        <div class="rec-card" style="border-left: 4px solid #667eea;">
            <h4 style="color: #667eea;">📊 Queue vs Running Analysis</h4>
            <p>Visualize the daily ratio of running queries to queued queries. Instantly spot when warehouses are overloaded and queries start waiting.</p>
        </div>
        <div class="rec-card" style="border-left: 4px solid #764ba2;">
            <h4 style="color: #764ba2;">🔀 Concurrency Tracking</h4>
            <p>Monitor average queries per hour and peak cluster usage over time to understand workload patterns and concurrency pressure.</p>
        </div>
        <div class="rec-card" style="border-left: 4px solid #43e97b;">
            <h4 style="color: #43e97b;">📅 Flexible Date Range</h4>
            <p>Select custom start and end dates to analyze any period. Compare week-over-week or month-over-month trends easily.</p>
        </div>
        """, unsafe_allow_html=True)

    with feat_cols[1]:
        st.markdown("""
        <div class="rec-card" style="border-left: 4px solid #f5576c;">
            <h4 style="color: #f5576c;">💡 Smart Recommendations</h4>
            <p>Get actionable, severity-rated suggestions: scale up, enable auto-scaling, downsize underutilized warehouses, or optimize queries.</p>
        </div>
        <div class="rec-card" style="border-left: 4px solid #4facfe;">
            <h4 style="color: #4facfe;">🏢 Per-Warehouse Breakdown</h4>
            <p>Compare all your warehouses side-by-side on queue time, execution time, query volume, and efficiency ratio.</p>
        </div>
        <div class="rec-card" style="border-left: 4px solid #ff9800;">
            <h4 style="color: #ff9800;">💰 Credit Usage Visibility</h4>
            <p>Track daily credit consumption per warehouse alongside performance metrics to correlate cost with efficiency.</p>
        </div>
        """, unsafe_allow_html=True)

    st.markdown('<div class="section-title">How to Use</div>', unsafe_allow_html=True)

    st.markdown("""
    <div style="background: linear-gradient(135deg, rgba(79,172,254,0.05), rgba(0,242,254,0.05));
                border: 1px solid #4facfe30; border-radius: 14px; padding: 24px 28px;">
        <ol style="font-size: 0.95em; line-height: 2; color: #444; margin: 0; padding-left: 20px;">
            <li><strong>Select dates</strong> — Use the Start Date and End Date pickers above to define your analysis window.</li>
            <li><strong>Choose warehouses</strong> — Pick one or more warehouses from the multi-select to focus your analysis.</li>
            <li><strong>Explore tabs</strong> — Navigate between Running vs Queued, Per-Warehouse, Concurrency, and Recommendations.</li>
            <li><strong>Act on insights</strong> — Review recommendations and apply suggested changes to your warehouse configuration.</li>
            <li><strong>Refresh</strong> — Click the 🔄 Refresh button to pull the latest data from Account Usage views.</li>
        </ol>
    </div>
    """, unsafe_allow_html=True)

    st.markdown("")
    st.markdown('<div class="section-title">Data Sources</div>', unsafe_allow_html=True)
    st.markdown("""
    | View | What It Provides |
    |------|-----------------|
    | `SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY` | Query execution times, queue times, status, warehouse assignment |
    | `SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY` | Daily credit consumption per warehouse |
    """)


# ─── TAB 1: Running vs Queued ───
with tab1:
    st.markdown('<div class="section-title">Daily Running vs Queued Queries</div>', unsafe_allow_html=True)

    daily_totals = metrics_df.groupby("QUERY_DATE").agg(
        Running=("RUNNING_QUERY_COUNT", "sum"),
        Queued=("QUEUED_QUERY_COUNT", "sum"),
    ).reset_index()

    melted = daily_totals.melt(
        id_vars="QUERY_DATE", value_vars=["Running", "Queued"],
        var_name="Type", value_name="Count"
    )

    area_chart = alt.Chart(melted).mark_area(
        opacity=0.7, interpolate="monotone"
    ).encode(
        x=alt.X("QUERY_DATE:T", title="Date"),
        y=alt.Y("Count:Q", stack=True, title="Query Count"),
        color=alt.Color("Type:N",
                        scale=alt.Scale(domain=["Running", "Queued"], range=["#667eea", "#f5576c"]),
                        legend=alt.Legend(title="Type")),
        tooltip=["QUERY_DATE:T", "Type:N", "Count:Q"]
    ).properties(height=380)

    st.altair_chart(area_chart, use_container_width=True)

    # Queue Ratio Trend
    st.markdown('<div class="section-title">Queue Ratio Trend (%)</div>', unsafe_allow_html=True)

    ratio_data = daily_totals.copy()
    ratio_data["Queue_Ratio"] = ratio_data.apply(
        lambda r: (r["Queued"] / (r["Queued"] + r["Running"]) * 100)
        if (r["Queued"] + r["Running"]) > 0 else 0, axis=1
    )

    line_chart = alt.Chart(ratio_data).mark_line(
        strokeWidth=3, interpolate="monotone", color="#f5576c"
    ).encode(
        x=alt.X("QUERY_DATE:T", title="Date"),
        y=alt.Y("Queue_Ratio:Q", title="Queue Ratio (%)",
                 scale=alt.Scale(domain=[0, max(ratio_data["Queue_Ratio"].max() * 1.2, 5)])),
    ).properties(height=300)

    # Nearest-point selection for interactive tooltip
    nearest = alt.selection_point(nearest=True, on="pointerover",
                                  fields=["QUERY_DATE"], empty=False)

    # Invisible voronoi layer to capture hover anywhere
    selectors = alt.Chart(ratio_data).mark_point(opacity=0, size=100).encode(
        x="QUERY_DATE:T",
    ).add_params(nearest)

    # Visible circle on hover
    points = alt.Chart(ratio_data).mark_circle(size=80, color="#f5576c").encode(
        x="QUERY_DATE:T",
        y="Queue_Ratio:Q",
        opacity=alt.condition(nearest, alt.value(1), alt.value(0)),
        tooltip=["QUERY_DATE:T", alt.Tooltip("Queue_Ratio:Q", title="Queue Ratio %", format=".1f")]
    )

    # Vertical rule on hover
    rule = alt.Chart(ratio_data).mark_rule(color="#667eea", strokeWidth=1, strokeDash=[3, 3]).encode(
        x="QUERY_DATE:T",
        opacity=alt.condition(nearest, alt.value(0.6), alt.value(0)),
    )

    # 15% threshold line
    threshold = alt.Chart(pd.DataFrame({"y": [15]})).mark_rule(
        strokeDash=[4, 4], color="#ff9800", strokeWidth=2
    ).encode(y="y:Q")

    st.altair_chart(line_chart + selectors + points + rule + threshold, use_container_width=True)
    st.caption("⚠️ Orange dashed line = 15% threshold (consider scaling above this).")


# ─── TAB 2: Per-Warehouse ───
with tab2:
    st.markdown('<div class="section-title">Per-Warehouse Performance</div>', unsafe_allow_html=True)

    wh_summary = metrics_df.groupby("WAREHOUSE_NAME").agg(
        Total_Queries=("TOTAL_QUERIES", "sum"),
        Avg_Queue_Time_Sec=("AVG_QUEUE_TIME_SEC", "mean"),
        Avg_Execution_Time_Sec=("AVG_EXECUTION_TIME_SEC", "mean"),
        Queued_Queries=("QUEUED_QUERY_COUNT", "sum"),
    ).reset_index()
    wh_summary["Queue_Ratio"] = (
        wh_summary["Queued_Queries"] / wh_summary["Total_Queries"] * 100
    ).fillna(0).round(1)

    col1, col2 = st.columns(2)

    with col1:
        bar_queue = alt.Chart(wh_summary).mark_bar(
            cornerRadiusTopLeft=6, cornerRadiusTopRight=6
        ).encode(
            x=alt.X("WAREHOUSE_NAME:N", sort="-y", title="Warehouse"),
            y=alt.Y("Avg_Queue_Time_Sec:Q", title="Avg Queue Time (s)"),
            color=alt.Color("Avg_Queue_Time_Sec:Q",
                            scale=alt.Scale(range=GRADIENT_WARM), legend=None),
            tooltip=["WAREHOUSE_NAME", "Avg_Queue_Time_Sec", "Queue_Ratio"]
        ).properties(height=320, title="Avg Queue Time by Warehouse")
        st.altair_chart(bar_queue, use_container_width=True)

    with col2:
        bar_vol = alt.Chart(wh_summary).mark_bar(
            cornerRadiusTopLeft=6, cornerRadiusTopRight=6
        ).encode(
            x=alt.X("WAREHOUSE_NAME:N", sort="-y", title="Warehouse"),
            y=alt.Y("Total_Queries:Q", title="Total Queries"),
            color=alt.Color("Total_Queries:Q",
                            scale=alt.Scale(range=GRADIENT_COOL), legend=None),
            tooltip=["WAREHOUSE_NAME", "Total_Queries", "Avg_Execution_Time_Sec"]
        ).properties(height=320, title="Query Volume by Warehouse")
        st.altair_chart(bar_vol, use_container_width=True)

    # Summary table
    st.markdown('<div class="section-title">Warehouse Summary Table</div>', unsafe_allow_html=True)
    display_df = wh_summary.rename(columns={
        "WAREHOUSE_NAME": "Warehouse",
        "Total_Queries": "Total Queries",
        "Avg_Queue_Time_Sec": "Avg Queue (s)",
        "Avg_Execution_Time_Sec": "Avg Exec (s)",
        "Queue_Ratio": "Queue Ratio (%)",
    })[["Warehouse", "Total Queries", "Avg Queue (s)", "Avg Exec (s)", "Queue Ratio (%)"]]
    st.dataframe(display_df, hide_index=True, use_container_width=True)


# ─── TAB 3: Concurrency ───
with tab3:
    st.markdown('<div class="section-title">Daily Query Concurrency (Avg Queries/Hour)</div>', unsafe_allow_html=True)

    if not concurrency_df.empty:
        conc_chart = alt.Chart(concurrency_df).mark_line(
            strokeWidth=2, interpolate="monotone"
        ).encode(
            x=alt.X("QUERY_DATE:T", title="Date"),
            y=alt.Y("AVG_QUERIES_PER_HOUR:Q", title="Avg Queries/Hour"),
            color=alt.Color("WAREHOUSE_NAME:N",
                            scale=alt.Scale(range=GRADIENT_ALL),
                            legend=alt.Legend(title="Warehouse")),
            tooltip=["QUERY_DATE:T", "WAREHOUSE_NAME:N", "AVG_QUERIES_PER_HOUR:Q"]
        ).properties(height=350)
        st.altair_chart(conc_chart, use_container_width=True)
    else:
        st.info("No concurrency data available for the selected filters.")

    # Credits usage
    st.markdown('<div class="section-title">Daily Credit Usage</div>', unsafe_allow_html=True)
    if not credits_df.empty:
        credit_chart = alt.Chart(credits_df).mark_bar(
            cornerRadiusTopLeft=4, cornerRadiusTopRight=4
        ).encode(
            x=alt.X("USAGE_DATE:T", title="Date"),
            y=alt.Y("CREDITS_USED:Q", title="Credits Used", stack=True),
            color=alt.Color("WAREHOUSE_NAME:N",
                            scale=alt.Scale(range=GRADIENT_ALL),
                            legend=alt.Legend(title="Warehouse")),
            tooltip=["USAGE_DATE:T", "WAREHOUSE_NAME:N", "CREDITS_USED:Q"]
        ).properties(height=300)
        st.altair_chart(credit_chart, use_container_width=True)
    else:
        st.info("No credit usage data available.")


# ─── TAB 4: Recommendations ───
with tab4:
    st.markdown('<div class="section-title">Optimization Recommendations</div>', unsafe_allow_html=True)

    recs = build_recommendations(metrics_df, selected_warehouses or all_warehouses)

    if not recs:
        st.markdown("""
        <div class="rec-card" style="border-left: 4px solid #43e97b; text-align: center;">
            <h4 style="color: #43e97b;">✅ All Clear</h4>
            <p>All warehouses are operating efficiently for the selected period.</p>
        </div>
        """, unsafe_allow_html=True)
    else:
        for rec in recs:
            sev_class = {"HIGH": "severity-high", "MEDIUM": "severity-medium", "LOW": "severity-low"}[rec["severity"]]
            border_clr = {"HIGH": "#f5576c", "MEDIUM": "#ff9800", "LOW": "#4facfe"}[rec["severity"]]
            st.markdown(f"""
            <div class="rec-card" style="border-left: 4px solid {border_clr};">
                <span class="rec-severity {sev_class}">{rec['severity']}</span>
                <h4>{rec['warehouse']} — {rec['issue']}</h4>
                <p>{rec['suggestion']}</p>
            </div>
            """, unsafe_allow_html=True)
