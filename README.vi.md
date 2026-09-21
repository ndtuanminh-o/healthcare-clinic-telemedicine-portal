<div align="center">

# Phòng khám Y tế & Cổng thông tin Khám bệnh từ xa
### Kỹ thuật Cơ sở Dữ liệu Quan hệ & Thiết kế Hệ thống

[![Môn học](https://img.shields.io/badge/Môn_học-INT1313%20Hệ%20Cơ%20Sở%20Dữ%20Liệu-0052CC?style=for-the-badge&logo=postgresql&logoColor=white)](https://ptithcm.edu.vn)
[![Học viện](https://img.shields.io/badge/Học_viện-PTIT%20HCM-DC2626?style=for-the-badge)](https://ptithcm.edu.vn)
[![Năm học](https://img.shields.io/badge/Năm_học-2026--2027-10B981?style=for-the-badge)]()
[![Tiến độ](https://img.shields.io/badge/Tiến_độ-Hoàn_thành_Phase_1_%26_2-8B5CF6?style=for-the-badge)]()

<br/>

**[ English ](README.md)** &nbsp;|&nbsp; **[ Tiếng Việt ](README.vi.md)**

<br/>

Hệ thống quản lý cơ sở dữ liệu quan hệ cho cơ sở y tế tích hợp giữa khám trực tiếp tại phòng khám và khám chữa bệnh từ xa qua video mã hóa.

</div>

---

## 1. Thông tin Đồ án

| Thông tin | Chi tiết đặc tả |
| :--- | :--- |
| **Môn học** | INT1313 - Hệ cơ sở dữ liệu (Học kỳ 1, Năm học 2026-2027) |
| **Đơn vị đào tạo** | Học viện Công nghệ Bưu chính Viễn thông (PTIT HCM) |
| **Mã đề tài** | Đề tài #05: Healthcare Clinic & Telemedicine Portal |
| **Tên nhóm** | G5 (Pingo) |

### Danh sách Thành viên

| Mã sinh viên | Họ và tên | Vai trò phụ trách | GitHub | Email liên hệ |
| :--- | :--- | :--- | :--- | :--- |
| **N25DCAT089** | Nguyễn Đăng Tuấn Minh | Trưởng nhóm EER & Mô hình hóa | [@ndtuanminh-o](https://github.com/ndtuanminh-o) | `nd.tuanminh.work@gmail.com` |
| **N25DCAT086** | Hồ Thị Trúc Linh | Phân tích Yêu cầu & Phạm vi | [@linh-h-annanie](https://github.com/linh-h-annanie) | `n25dcat086@student.ptithcm.edu.vn` |
| **N25DCAT087** | Huỳnh Mai Trí Lộc | Ánh xạ Lược đồ Quan hệ | [@halo16-04](https://github.com/halo16-04) | `n25dcat087@student.ptithcm.edu.vn` |

---

## 2. Các Sản phẩm Bàn giao & Lộ trình Dự án

| Giai đoạn | Trọng tâm & Phương pháp luận | Trạng thái | Sản phẩm bàn giao |
| :---: | :--- | :---: | :--- |
| **Phase 1** | **Thiết kế Quan niệm (EER)**<br/>Chuẩn SRS ISO/IEC/IEEE 29148 & Mô hình hóa EER Elmasri | **Hoàn thành** | • [Phạm vi Dự án](phase%201/project_scope.md)<br/>• [12 Quy tắc Nghiệp vụ (BR-01 đến BR-12)](phase%201/business_rules.md)<br/>• [Tài liệu Thiết kế EER (English)](phase%201/eer/EER_Diagram_EN.md)<br/>• [Tài liệu Thiết kế EER (Tiếng Việt)](phase%201/eer/EER_Diagram_VI.md) |
| **Phase 2** | **Thiết kế Logic & Vật lý**<br/>Từ điển Dữ liệu ISO/IEC 11179 & Sơ đồ IE Crow's Foot | **Hoàn thành** | • [Đặc tả Lược đồ Vật lý](phase%202/relational_schema_mapping/physical_schema_diagram.md)<br/>• [Từ điển Dữ liệu Siêu dữ liệu](phase%202/data_dictionary.md)<br/>• [Chứng minh Chuẩn hóa (1NF-BCNF)](phase%202/normalization_verification.md) |
| **Phase 3** | **Cài đặt Hệ thống & Kỹ thuật SQL** | **Chưa có kế hoạch (No plan yet)** | TBD |
| **Phase 4** | **Tích hợp & Bảo vệ Đồ án** | **Chưa có kế hoạch (No plan yet)** | TBD |

---

## 3. Cấu trúc Thư mục

```text
.
├── docs/
│   ├── project-identity.md
│   └── mcp-plan.md
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
