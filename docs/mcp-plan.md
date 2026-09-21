# Model Context Protocol (MCP) Integration Plan
## Database Systems (INT1313) - Healthcare Clinic & Telemedicine Portal
**Project:** Clinic Management & Telemedicine Portal | **Team:** G5 (Pingo)  
**Author:** Nguyen Dang Tuan Minh (@ndtuanminh-o)  

---

## 1. Executive Summary & Objective

The Model Context Protocol (MCP) enables the AI coding assistant to communicate directly with local relational database management systems (RDBMS), the GitHub remote repository, and structured multi-step reasoning engines.

Integrating MCP provides immediate advantages for upcoming milestones:
- **Phase 3 (Weeks 9-10, 30% Weight):** Direct database execution of SQL DDL scripts, real-time trigger verification (`BR-09`, `BR-10`), automated mock data insertion (DML), and performance benchmarking (`EXPLAIN ANALYZE`) for 10+ complex queries.
- **Phase 4 (Weeks 11-12, 30% Weight):** Automated backend integration (Python/Flask or Node.js) and individual defense preparation.

---

## 2. Recommended MCP Servers

### 2.1. RDBMS Database Server (Primary for Phase 3)
Allows the AI assistant to inspect database schema catalogs, execute queries, and validate constraints in real time.

- **Option A: PostgreSQL MCP (`@modelcontextprotocol/server-postgres`)**
  - Best suited for the current schema utilizing UUID primary keys, exclusion constraints (`EXCLUDE USING gist`), and timestamp functions.
  - Connection string format: `postgresql://username:password@localhost:5432/clinic_db`
- **Option B: MySQL MCP (`@modelcontextprotocol/server-mysql`)**
  - Suitable if utilizing MySQL Workbench as required by university lab environments.
  - Connection string format: `mysql://root:password@localhost:3306/clinic_db`
- **Option C: SQLite MCP (`@modelcontextprotocol/server-sqlite`)**
  - Zero-configuration embedded database. Ideal for prototyping and running Phase 4 Python Flask demos locally.

### 2.2. GitHub MCP (`@modelcontextprotocol/server-github`)
- Directly automates repository actions using the project's Personal Access Token.
- Manages Pull Requests, reviews diffs between team members (Linh, Loc, Minh), and tracks milestone issues without manual CLI commands.

### 2.3. Sequential Thinking MCP (`@modelcontextprotocol/server-sequential-thinking`)
- Enhances multi-step logical chain-of-thought analysis.
- Specifically beneficial for:
  - Formulating complex relational algebra and SQL queries with nested subqueries, common table expressions (CTEs), and window functions.
  - Simulating live examination defense questions (Individual SQL Defense, 15% of total grade).

---

## 3. Configuration Template (`mcp_config.json`)

To activate these servers, insert the following configuration into:
`C:\Users\Admin\.gemini\config\mcp_config.json`

```json
{
  "mcpServers": {
    "postgres-clinic": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-postgres",
        "postgresql://postgres:postgres@localhost:5432/clinic_db"
      ]
    },
    "github-portal": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-github"
      ],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "<YOUR_GITHUB_PERSONAL_ACCESS_TOKEN>"
      }
    },
    "sequential-thinking": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-sequential-thinking"
      ]
    }
  }
}
```

---

## 4. Milestone Rollout Schedule

| Phase | Target Timeline | MCP Tools Utilized | Objectives Achieved |
| :---: | :--- | :--- | :--- |
| **Phase 3** | Weeks 9-10 | `postgres-clinic` (or `mysql`), `sequential-thinking` | Execute DDL, verify constraints and triggers, seed mock data, execute 10+ analytical queries. |
| **Phase 4** | Weeks 11-12 | `github-portal`, `sqlite` (embedded demo) | Connect backend application, generate final technical report, prepare defense question flashcards. |
