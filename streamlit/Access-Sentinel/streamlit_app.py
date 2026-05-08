import streamlit as st
from snowflake.snowpark.context import get_active_session
import pandas as pd

st.set_page_config(page_title="Access Sentinel", layout="wide")

session = get_active_session()

CRITICAL_PRIVILEGES = [
    'ACCOUNTADMIN', 'SECURITYADMIN', 'SYSADMIN',
    'MANAGE GRANTS', 'CREATE USER', 'CREATE ROLE',
    'CREATE DATABASE', 'CREATE WAREHOUSE', 'CREATE INTEGRATION',
    'MANAGE WAREHOUSES', 'MONITOR USAGE', 'OVERRIDE SHARE RESTRICTIONS',
    'EXECUTE TASK', 'EXECUTE MANAGED TASK', 'IMPORT SHARE',
    'CREATE SHARE', 'CREATE ACCOUNT', 'ATTACH POLICY',
    'APPLY MASKING POLICY', 'APPLY ROW ACCESS POLICY', 'APPLY TAG'
]

SYSTEM_ROLES = ['ACCOUNTADMIN', 'SECURITYADMIN', 'SYSADMIN', 'USERADMIN', 'PUBLIC', 'ORGADMIN']


def load_css():
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
        @keyframes gradientShift {
            0% { background-position: 0% 50%; }
            50% { background-position: 100% 50%; }
            100% { background-position: 0% 50%; }
        }
        @keyframes pulse {
            0%, 100% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.5); }
            50% { box-shadow: 0 0 15px 5px rgba(239, 68, 68, 0); }
        }
        @keyframes float {
            0%, 100% { transform: translateY(0px); }
            50% { transform: translateY(-6px); }
        }
        @keyframes shimmer {
            0% { background-position: -200% 0; }
            100% { background-position: 200% 0; }
        }
        @keyframes countUp {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
        }
        @keyframes borderGlow {
            0%, 100% { border-color: rgba(16, 185, 129, 0.3); }
            50% { border-color: rgba(16, 185, 129, 0.8); }
        }

        .hero-banner {
            background: linear-gradient(270deg, #0f766e, #115e59, #134e4a, #0f766e);
            background-size: 600% 600%;
            animation: gradientShift 8s ease infinite, fadeInScale 0.8s ease-out;
            border-radius: 18px;
            padding: 40px 32px;
            text-align: center;
            margin-bottom: 24px;
            box-shadow: 0 10px 30px rgba(15, 118, 110, 0.3);
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
            background: radial-gradient(circle, rgba(255,255,255,0.05) 0%, transparent 60%);
            animation: float 6s ease-in-out infinite;
        }
        .hero-banner h1 {
            color: white !important;
            -webkit-text-fill-color: white !important;
            font-size: 2.5em;
            margin: 8px 0;
            animation: fadeInUp 0.8s ease-out 0.3s both;
            text-shadow: 0 2px 15px rgba(0,0,0,0.2);
        }
        .hero-banner .hero-subtitle {
            color: rgba(255,255,255,0.85);
            font-size: 1.05em;
            animation: fadeInUp 0.8s ease-out 0.6s both;
            letter-spacing: 1.5px;
            text-transform: uppercase;
            font-weight: 300;
        }
        .hero-banner .hero-divider {
            width: 50px;
            height: 3px;
            background: rgba(255,255,255,0.4);
            margin: 14px auto;
            border-radius: 2px;
            animation: fadeInUp 0.8s ease-out 0.5s both;
        }

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
            top: 0; left: -100%; width: 100%; height: 100%;
            background: linear-gradient(90deg, transparent, rgba(255,255,255,0.15), transparent);
            transition: left 0.5s ease;
        }
        .kpi-card:hover::before { left: 100%; }
        .kpi-card .kpi-icon { font-size: 1.6em; margin-bottom: 6px; display: block; }
        .kpi-card .kpi-value {
            font-size: 1.6em; font-weight: 700; color: white; display: block;
            animation: countUp 0.8s ease-out both;
            text-shadow: 0 1px 8px rgba(0,0,0,0.15);
        }
        .kpi-card .kpi-label {
            font-size: 0.72em; color: rgba(255,255,255,0.85); text-transform: uppercase;
            letter-spacing: 1.2px; margin-top: 4px; display: block; font-weight: 500;
        }

        .kpi-teal { background: linear-gradient(135deg, #0f766e, #14b8a6); box-shadow: 0 4px 15px rgba(15,118,110,0.3); }
        .kpi-blue { background: linear-gradient(135deg, #1d4ed8, #3b82f6); box-shadow: 0 4px 15px rgba(29,78,216,0.3); }
        .kpi-purple { background: linear-gradient(135deg, #7c3aed, #a78bfa); box-shadow: 0 4px 15px rgba(124,58,237,0.3); }
        .kpi-red { background: linear-gradient(135deg, #dc2626, #f87171); box-shadow: 0 4px 15px rgba(220,38,38,0.3); }

        .alert-critical {
            background: linear-gradient(135deg, #fef2f2 0%, #fee2e2 100%);
            border-left: 4px solid #ef4444;
            border-radius: 10px;
            padding: 16px 20px;
            margin: 10px 0;
            animation: fadeInUp 0.4s ease-out both;
            color: #7f1d1d;
            transition: all 0.3s ease;
        }
        .alert-critical:hover {
            transform: translateX(4px);
            box-shadow: 0 4px 12px rgba(239, 68, 68, 0.15);
        }
        .alert-warning {
            background: linear-gradient(135deg, #fffbeb 0%, #fef3c7 100%);
            border-left: 4px solid #f59e0b;
            border-radius: 10px;
            padding: 16px 20px;
            margin: 10px 0;
            color: #78350f;
        }
        .alert-safe {
            background: linear-gradient(135deg, #ecfdf5 0%, #d1fae5 100%);
            border-left: 4px solid #10b981;
            border-radius: 10px;
            padding: 16px 20px;
            margin: 10px 0;
            color: #064e3b;
            animation: borderGlow 3s ease-in-out infinite;
        }

        .badge-critical {
            background: linear-gradient(135deg, #dc2626, #b91c1c);
            color: white;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.75rem;
            font-weight: 600;
            animation: pulse 2s infinite;
            display: inline-block;
            margin: 2px;
        }
        .badge-warning {
            background: linear-gradient(135deg, #d97706, #b45309);
            color: white;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.75rem;
            font-weight: 600;
            display: inline-block;
            margin: 2px;
        }
        .badge-safe {
            background: linear-gradient(135deg, #059669, #047857);
            color: white;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.75rem;
            font-weight: 600;
            display: inline-block;
            margin: 2px;
        }

        .role-card {
            background: white;
            border: 1px solid #e5e7eb;
            border-radius: 12px;
            padding: 18px 20px;
            margin: 10px 0;
            transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
            color: #1f2937;
            position: relative;
            overflow: hidden;
        }
        .role-card::before {
            content: '';
            position: absolute;
            top: 0; left: -100%; width: 100%; height: 100%;
            background: linear-gradient(90deg, transparent, rgba(15,118,110,0.04), transparent);
            transition: left 0.6s ease;
        }
        .role-card:hover::before { left: 100%; }
        .role-card:hover {
            transform: translateY(-4px);
            border-color: #0f766e;
            box-shadow: 0 8px 25px rgba(15, 118, 110, 0.12);
        }

        .section-title {
            animation: slideInLeft 0.6s ease-out;
            font-size: 1.3em;
            margin: 10px 0 16px 0;
            background: linear-gradient(135deg, #0f766e 0%, #14b8a6 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            font-weight: 700;
        }

        .divider {
            height: 2px;
            background: linear-gradient(90deg, transparent, #d1d5db, transparent);
            margin: 24px 0;
            border-radius: 1px;
        }

        .footer-text {
            text-align: center;
            color: #6b7280;
            font-size: 0.8rem;
            padding: 16px 0;
        }
    </style>
    """, unsafe_allow_html=True)


@st.cache_data(ttl=300)
def get_all_roles():
    return session.sql("SHOW ROLES").collect()


@st.cache_data(ttl=300)
def get_grants_to_role(role_name):
    try:
        return session.sql(f"SHOW GRANTS TO ROLE \"{role_name}\"").collect()
    except:
        return []


@st.cache_data(ttl=300)
def get_grants_of_role(role_name):
    try:
        return session.sql(f"SHOW GRANTS OF ROLE \"{role_name}\"").collect()
    except:
        return []


@st.cache_data(ttl=300)
def get_users():
    return session.sql("SHOW USERS").collect()


@st.cache_data(ttl=300)
def get_roles_granted_to_user(user_name):
    try:
        return session.sql(f"SHOW GRANTS TO USER \"{user_name}\"").collect()
    except:
        return []


def classify_privilege(privilege, granted_on, role_name):
    if privilege == 'OWNERSHIP' and granted_on == 'ACCOUNT':
        return 'critical'
    if privilege in CRITICAL_PRIVILEGES:
        return 'critical'
    if privilege in ['OWNERSHIP', 'ALL PRIVILEGES', 'ALL']:
        return 'warning'
    if privilege in ['OPERATE', 'MODIFY', 'DELETE', 'INSERT', 'UPDATE', 'TRUNCATE', 'CREATE TABLE', 'CREATE VIEW']:
        return 'warning'
    return 'safe'


def render_badge(level, text):
    return f'<span class="badge-{level}">{text}</span>'


def main():
    load_css()

    st.markdown("""
    <div class="hero-banner">
        <h1>🛡️ Access Sentinel</h1>
        <div class="hero-divider"></div>
        <div class="hero-subtitle">RBAC Inspector • Privilege Auditor • Security Monitor</div>
    </div>
    """, unsafe_allow_html=True)

    roles_data = get_all_roles()
    users_data = get_users()

    roles_df = pd.DataFrame(roles_data)
    users_df = pd.DataFrame(users_data)

    all_role_names = roles_df['name'].tolist() if 'name' in roles_df.columns else []
    custom_roles = [r for r in all_role_names if r not in SYSTEM_ROLES]

    critical_findings = []
    for role in custom_roles:
        grants = get_grants_to_role(role)
        for g in grants:
            row = g.as_dict() if hasattr(g, 'as_dict') else g
            priv = row.get('privilege', '')
            if priv in CRITICAL_PRIVILEGES or priv == 'OWNERSHIP':
                critical_findings.append({
                    'role': role,
                    'privilege': priv,
                    'granted_on': row.get('granted_on', ''),
                    'name': row.get('name', '')
                })

    st.markdown(f"""
    <div class="kpi-grid">
        <div class="kpi-card kpi-teal">
            <span class="kpi-icon">👤</span>
            <span class="kpi-value">{len(users_df)}</span>
            <span class="kpi-label">Total Users</span>
        </div>
        <div class="kpi-card kpi-blue">
            <span class="kpi-icon">🎭</span>
            <span class="kpi-value">{len(all_role_names)}</span>
            <span class="kpi-label">Total Roles</span>
        </div>
        <div class="kpi-card kpi-purple">
            <span class="kpi-icon">⚙️</span>
            <span class="kpi-value">{len(custom_roles)}</span>
            <span class="kpi-label">Custom Roles</span>
        </div>
        <div class="kpi-card kpi-red">
            <span class="kpi-icon">🚨</span>
            <span class="kpi-value">{len(critical_findings)}</span>
            <span class="kpi-label">Critical Grants</span>
        </div>
    </div>
    """, unsafe_allow_html=True)

    tab1, tab2, tab3, tab4 = st.tabs([
        "🚨 Must Check (Critical Audit)",
        "👤 Users & Roles",
        "🎭 Role Privileges",
        "🔍 Deep Inspector"
    ])

    with tab1:
        st.markdown('<p class="section-title">🚨 Critical Privilege Audit</p>', unsafe_allow_html=True)
        st.markdown("*Admin-level privileges granted to custom roles — review immediately*")

        if critical_findings:
            filter_priv = st.multiselect(
                "Filter by privilege type:",
                options=list(set(f['privilege'] for f in critical_findings)),
                default=list(set(f['privilege'] for f in critical_findings)),
                key="critical_filter"
            )

            filtered = [f for f in critical_findings if f['privilege'] in filter_priv]

            for finding in filtered:
                level = 'critical'
                icon = "🔴"
                st.markdown(f"""
                <div class="alert-critical">
                    <div class="user-row">
                        {icon} <strong>{finding['role']}</strong> has
                        {render_badge(level, finding['privilege'])}
                        on <code>{finding['granted_on']}: {finding['name']}</code>
                    </div>
                </div>
                """, unsafe_allow_html=True)

            st.markdown("---")
            st.markdown(f"**Total critical findings: {len(filtered)}**")
        else:
            st.markdown("""
            <div class="alert-safe">
                ✅ <strong>All clear!</strong> No admin-level privileges found on custom roles.
            </div>
            """, unsafe_allow_html=True)

    with tab2:
        st.markdown('<p class="section-title">👤 User → Role Mapping</p>', unsafe_allow_html=True)

        search_user = st.text_input("🔎 Search user:", "", key="user_search")

        user_list = users_df['name'].tolist() if 'name' in users_df.columns else []
        if search_user:
            user_list = [u for u in user_list if search_user.upper() in u.upper()]

        for user in user_list:
            user_roles = get_roles_granted_to_user(user)
            role_names = []
            for r in user_roles:
                row = r.as_dict() if hasattr(r, 'as_dict') else r
                if row.get('granted_on', '') == 'ROLE' and row.get('role', ''):
                    role_names.append(row.get('role'))

            has_admin = any(r in ['ACCOUNTADMIN', 'SECURITYADMIN'] for r in role_names)
            border_color = "#ef4444" if has_admin else "#e5e7eb"

            badges_html = ""
            for rn in role_names:
                if rn in ['ACCOUNTADMIN', 'SECURITYADMIN']:
                    badges_html += render_badge('critical', rn) + " "
                elif rn in ['SYSADMIN', 'USERADMIN']:
                    badges_html += render_badge('warning', rn) + " "
                else:
                    badges_html += render_badge('safe', rn) + " "

            st.markdown(f"""
            <div class="role-card" style="border-color: {border_color};">
                <div class="user-row">
                    <strong>{'🔴' if has_admin else '👤'} {user}</strong><br/>
                    <small style="color: #a0a0b0;">Roles:</small> {badges_html}
                </div>
            </div>
            """, unsafe_allow_html=True)

    with tab3:
        st.markdown('<p class="section-title">🎭 Role → Privileges Breakdown</p>', unsafe_allow_html=True)

        col_a, col_b = st.columns([1, 2])
        with col_a:
            role_filter_type = st.radio(
                "Show roles:",
                ["All", "Custom Only", "System Only"],
                key="role_type_filter"
            )
            if role_filter_type == "Custom Only":
                display_roles = custom_roles
            elif role_filter_type == "System Only":
                display_roles = [r for r in all_role_names if r in SYSTEM_ROLES]
            else:
                display_roles = all_role_names

            severity_filter = st.multiselect(
                "Filter by severity:",
                ["🔴 Critical", "🟡 Warning", "🟢 Safe"],
                default=["🔴 Critical", "🟡 Warning", "🟢 Safe"],
                key="sev_filter"
            )

        with col_b:
            selected_role = st.selectbox("Select a role to inspect:", display_roles, key="role_select")

            if selected_role:
                grants = get_grants_to_role(selected_role)
                if grants:
                    rows = []
                    for g in grants:
                        row = g.as_dict() if hasattr(g, 'as_dict') else g
                        priv = row.get('privilege', '')
                        granted_on = row.get('granted_on', '')
                        level = classify_privilege(priv, granted_on, selected_role)

                        level_map = {'critical': '🔴 Critical', 'warning': '🟡 Warning', 'safe': '🟢 Safe'}
                        if level_map[level] in severity_filter:
                            rows.append({
                                'Severity': level_map[level],
                                'Privilege': priv,
                                'Granted On': granted_on,
                                'Object': row.get('name', ''),
                                'Granted By': row.get('granted_by', '')
                            })

                    if rows:
                        priv_df = pd.DataFrame(rows)
                        priv_df = priv_df.sort_values('Severity')
                        st.dataframe(priv_df, use_container_width=True, hide_index=True)
                    else:
                        st.info("No privileges match the selected severity filter.")
                else:
                    st.info("No grants found for this role.")

    with tab4:
        st.markdown('<p class="section-title">🔍 Deep Privilege Inspector</p>', unsafe_allow_html=True)
        st.markdown("*Search for specific privileges across all roles*")

        search_priv = st.text_input(
            "🔎 Search privilege (e.g., MANAGE GRANTS, CREATE USER, OWNERSHIP):",
            "",
            key="priv_search"
        )

        if search_priv:
            with st.spinner("Scanning all roles..."):
                findings = []
                for role in all_role_names:
                    grants = get_grants_to_role(role)
                    for g in grants:
                        row = g.as_dict() if hasattr(g, 'as_dict') else g
                        priv = row.get('privilege', '')
                        if search_priv.upper() in priv.upper():
                            findings.append({
                                'Role': role,
                                'Privilege': priv,
                                'Granted On': row.get('granted_on', ''),
                                'Object': row.get('name', ''),
                                'Is Custom Role': '⚠️ Yes' if role not in SYSTEM_ROLES else 'No'
                            })

                if findings:
                    findings_df = pd.DataFrame(findings)
                    st.dataframe(findings_df, use_container_width=True, hide_index=True)
                    st.markdown(f"**Found {len(findings)} matching grants across {len(set(f['Role'] for f in findings))} roles**")
                else:
                    st.info(f"No grants matching '{search_priv}' found.")

    st.markdown('<div class="divider"></div>', unsafe_allow_html=True)
    st.markdown(
        '<p class="footer-text">'
        '🛡️ Access Sentinel v2.0 • RBAC Governance Dashboard'
        '</p>',
        unsafe_allow_html=True
    )


if __name__ == "__main__":
    main()
