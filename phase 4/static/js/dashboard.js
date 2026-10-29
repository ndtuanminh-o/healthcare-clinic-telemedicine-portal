const formatText = (value) => (value === null || value === undefined ? "" : String(value));
const formatInteger = (value) => String(Number(value ?? 0));
const formatMoney = (value) =>
    value === null || value === undefined ? "" : Number(value).toLocaleString("vi-VN");
const formatPercent = (value) => `${value ?? 0}%`;

const REPORTS = [
    {
        url: "/api/dashboard/telemedicine",
        tableId: "telemedicine-table",
        summaryId: "telemedicine-summary",
        summary: (count) => `${count} doctors`,
        columns: [
            ["doctor_name", formatText],
            ["total_appointments", formatInteger],
            ["telemedicine_appointments", formatInteger],
            ["telemedicine_percentage", formatPercent],
        ],
    },
    {
        url: "/api/dashboard/medicine-revenue",
        tableId: "medicine-table",
        summaryId: "medicine-summary",
        summary: (count) => `${count} medicines`,
        columns: [
            ["medicine_name", formatText],
            ["total_medicine_revenue", formatMoney],
            ["average_revenue_per_medicine", formatMoney],
        ],
    },
    {
        url: "/api/dashboard/telemedicine-revenue",
        tableId: "revenue-table",
        summaryId: "revenue-summary",
        summary: (count) => `${count} months`,
        columns: [
            ["revenue_year", formatText],
            ["revenue_month", formatText],
            ["total_monthly_revenue", formatMoney],
            ["telemedicine_revenue", formatMoney],
            ["telemedicine_revenue_percentage", formatPercent],
        ],
    },
    {
        url: "/api/dashboard/vip-patients",
        tableId: "vip-table",
        summaryId: "vip-summary",
        summary: (count) => `${count} patients`,
        columns: [
            ["patient_name", formatText],
            ["primary_treating_doctor", formatText],
            ["consultation_total", formatMoney],
            ["medicine_total", formatMoney],
            ["total_medical_spending", formatMoney],
            ["spending_percentile_rank", formatPercent],
        ],
    },
];

function showMessageRow(tbody, columnCount, message, cssClass) {
    tbody.replaceChildren();
    const tr = document.createElement("tr");
    const td = document.createElement("td");
    td.colSpan = columnCount;
    td.className = cssClass;
    td.textContent = message;
    tr.appendChild(td);
    tbody.appendChild(tr);
}

async function loadReport(report) {
    const tbody = document.getElementById(report.tableId);
    const summary = document.getElementById(report.summaryId);
    const columnCount = report.columns.length;

    try {
        const response = await fetch(report.url);
        const data = await response.json();
        if (!response.ok || !Array.isArray(data)) {
            throw new Error((data && data.error) || "Request failed");
        }

        summary.textContent = report.summary(data.length);
        if (data.length === 0) {
            showMessageRow(tbody, columnCount, "No data found", "empty-message");
            return;
        }

        const rows = data.map((row) => {
            const tr = document.createElement("tr");
            report.columns.forEach(([key, format]) => {
                const td = document.createElement("td");
                td.textContent = format(row[key]);
                tr.appendChild(td);
            });
            return tr;
        });
        tbody.replaceChildren(...rows);
    } catch (error) {
        console.error(error);
        summary.textContent = "-";
        showMessageRow(tbody, columnCount, "Could not load this report.", "error-message");
    }
}

REPORTS.forEach(loadReport);
