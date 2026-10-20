async function loadTelemedicineReport() {
    const response = await fetch("/api/dashboard/telemedicine");
    const data = await response.json();

    const table = document.getElementById("telemedicine-table");

    table.innerHTML = data.map(row => `
        <tr>
            <td>${row.doctor_name}</td>
            <td>${row.total_appointments}</td>
            <td>${row.telemedicine_appointments}</td>
            <td>${row.telemedicine_percentage ?? 0}%</td>
        </tr>
    `).join("");

    document.getElementById("telemedicine-summary").textContent =
        `${data.length} doctors`;
}

loadTelemedicineReport();
