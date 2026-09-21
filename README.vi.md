<p align="right">
  <strong>🌐 Language / Ngôn ngữ:</strong>
  <a href="README.md"><b>🇬🇧 English</b></a> |
  <a href="README.vi.md"><b>🇻🇳 Tiếng Việt</b></a>
</p>

# Phòng khám Y tế & Cổng thông tin Khám bệnh từ xa
*(Healthcare Clinic & Telemedicine Portal)*

Đồ án môn học **INT1313 - Hệ cơ sở dữ liệu**, Học kỳ 1, Năm học 2026–2027.  
Học viện Công nghệ Bưu chính Viễn thông (PTIT).

---

## Thông tin đề tài

- **Chủ đề:** #05 — Phòng khám Y tế & Cổng thông tin Khám bệnh từ xa (Healthcare Clinic & Telemedicine Portal)
- **Nhóm:** G5 — Pingo

### Danh sách thành viên

| Mã sinh viên | Họ và tên | GitHub | Email |
| :--- | :--- | :--- | :--- |
| **N25DCAT086** | Hồ Thị Trúc Linh | [@linh-h-annanie](https://github.com/linh-h-annanie) | `n25dcat086@student.ptithcm.edu.vn` |
| **N25DCAT087** | Huỳnh Mai Trí Lộc | [@halo16-04](https://github.com/halo16-04) | `n25dcat087@student.ptithcm.edu.vn` |
| **N25DCAT089** | Nguyễn Đăng Tuấn Minh | [@ndtuanminh-o](https://github.com/ndtuanminh-o) | `n25dcat089@student.ptithcm.edu.vn` |

---

## Tổng quan dự án

Dự án thiết kế hệ thống quản lý cơ sở dữ liệu quan hệ cho cơ sở y tế tích hợp giữa **khám trực tiếp tại phòng khám (In-Person)** và **khám bệnh từ xa qua video (Telemedicine)**.

### Các phân hệ nghiệp vụ chính
- **Bệnh nhân & Hồ sơ bệnh án:** Quản lý tập trung nhân khẩu học, chẩn đoán y khoa và lịch sử khám bệnh với cơ chế soft-delete lưu vết kiểm toán.
- **Phân cấp Bác sĩ:** Lớp cha `DOCTOR` chuyên biệt hóa thành `GENERAL_PRACTITIONER` (Bác sĩ đa khoa - phòng khám trực tiếp) và `SPECIALIST` (Bác sĩ chuyên khoa - tư vấn khám từ xa).
- **Lịch hẹn & Ca trực:** Quản lý ca làm việc (`DOCTOR_SCHEDULE`) và định tuyến lịch hẹn theo 2 chế độ (`In-Person` vs `Telemedicine`).
- **Nhà thuốc số & Kho dược:** Đơn thuốc điện tử, liều lượng chi tiết và quản lý tồn kho thời gian thực với ngưỡng cảnh báo đặt hàng.
- **Hóa đơn & Thanh toán:** Hóa đơn tổng hợp duy nhất cho mỗi cuộc hẹn (kết hợp phí khám bệnh và tiền thuốc), thanh toán đa kênh.

---

## Các sản phẩm bàn giao (Project Deliverables)

### Phase 1: Thiết kế quan niệm (Conceptual Design - EER)
- [Phạm vi dự án](phase%201/project_scope.md): Ranh giới hệ thống và đặc tả yêu cầu chức năng (ISO/IEC/IEEE 29148).
- [Quy tắc nghiệp vụ](phase%201/business_rules.md): 12 quy tắc nghiệp vụ toàn vẹn dữ liệu (BR-01 đến BR-12).
- [Tài liệu thiết kế EER (English)](phase%201/eer/EER_Diagram_EN.md): Đặc tả thực thể, mối kết hợp và sơ đồ Mermaid EER chuẩn hóa.
- [Tài liệu thiết kế EER (Tiếng Việt)](phase%201/eer/EER_Diagram_VI.md): Bản tiếng Việt hoàn chỉnh cho mô hình EER.

### Phase 2: Thiết kế logic & vật lý (Logical & Physical Design)
- [Lược đồ quan hệ vật lý](phase%202/relational_schema_mapping/physical_schema_diagram.md): Đặc tả cấu trúc bảng quan hệ vật lý và sơ đồ Mermaid IE Crow's Foot.
- [Từ điển dữ liệu](phase%202/data_dictionary.md): Danh mục siêu dữ liệu chuẩn hóa quốc tế ISO/IEC 11179.
- [Chứng minh chuẩn hóa](phase%202/normalization_verification.md): Phân tích phụ thuộc hàm và chứng minh toán học đạt 1NF → 2NF → 3NF → BCNF.

---

## Cấu trúc thư mục (Repository Structure)

```text
.
├── docs/
│   └── project-identity.md
├── phase 1/
│   ├── eer/
│   │   ├── EER_Diagram_EN.md
│   │   └── EER_Diagram_VI.md
│   ├── business_rules.md
│   └── project_scope.md
├── phase 2/
│   ├── relational_schema_mapping/
│   │   └── physical_schema_diagram.md
│   ├── data_dictionary.md
│   └── normalization_verification.md
├── .gitignore
├── README.md
└── README.vi.md
```
