# Phase 3 Implementation Plan: Database Implementation & Advanced SQL
## Topic 05: Healthcare Clinic & Telemedicine Portal | PTIT
**Course:** INT1313 - Database Systems | **Team:** G5 - Pingo  
**Team Leader:** Ho Thi Truc Linh (@linh-h-annanie)

---

## 1. Mục tiêu Phase 3 (Theo chuẩn mục 4 Template đề tài)

Hiện thực hóa toàn bộ thiết kế ở Phase 1 và Phase 2 lên hệ quản trị cơ sở dữ liệu quan hệ (khuyến nghị **PostgreSQL** để hỗ trợ tối đa UUID, GIST exclusion constraints, Window functions):

## 2. Danh mục 3 file bàn giao chuẩn theo Guide của thầy

Dự án gói gọn trong đúng 3 file SQL:

1. **`01_schema.sql`**: Toàn bộ DDL (11 Tables, Constraints, Indexes, Views, 3 Triggers).
2. **`02_mock_data.sql`**: Kịch bản INSERT toàn bộ dữ liệu mẫu ($\ge 10,000$ bản ghi).
3. **`03_advanced_queries.sql`**: 10 truy vấn thống kê báo cáo nghiệp vụ và kiểm tra thời gian chạy.

## 3. Phân công nhiệm vụ chi tiết (Team G5)

Mỗi thành viên phụ trách độc lập 1 file cốt lõi (Tỷ lệ đóng góp: 33.3% - 33.3% - 33.4%):

| Thành viên | Vai trò kỹ thuật | Trách nhiệm chính | Sản phẩm bàn giao | Tỷ trọng |
| :--- | :--- | :--- | :--- | :---: |
| **Hồ Thị Trúc Linh** (Leader) | **Team Leader & Data Reporting** | - Quản lý tiến độ chung của nhóm và điều phối bàn giao Phase 3.<br>- Viết 10 câu truy vấn thống kê nghiệp vụ (kết nối bảng `JOIN`, gom nhóm `GROUP BY`, tính tổng doanh thu, đếm lượt khám).<br>- Chạy thử kiểm tra thời gian trả kết quả và tổng hợp vào báo cáo Word. | `03_advanced_queries.sql`<br>+ Hoàn thiện Báo cáo Word | **33.4%** |
| **Nguyễn Đăng Tuấn Minh** | **Database Architect** | - Hiện thực hóa DDL 11 bảng, hệ thống ràng buộc toàn vẹn (PK, FK, CHECK, DEFAULT).<br>- Thiết lập hệ thống chỉ mục B-Tree Indexes và các Views xem dữ liệu.<br>- Kiểm chuẩn cấu trúc schema tuân thủ quy chuẩn SQL. | `01_schema.sql`<br>(Core DDL, Constraints, Indexes & Views) | **33.3%** |
| **Huỳnh Mai Trí Lộc** | **Data Engineer & Procedural Logic** | - Lập trình hệ thống 3 Triggers tự động (Chặn trùng lịch BR-01, Trừ tồn kho BR-09, Khóa đơn thuốc BR-10).<br>- Xây dựng kịch bản nạp dữ liệu mẫu lớn $\ge 10,000$ bản ghi (`02_mock_data.sql`).<br>- Đảm bảo toàn vẹn dữ liệu đa quan hệ. | `02_mock_data.sql`<br>+ Module Procedural Triggers | **33.3%** |

---

## 4. Lộ trình thực hiện (Timeline)

- **Tuần 1 (Day 1 - Day 4):**
  - Tuấn Minh triển khai Core DDL 11 bảng, Indexes và Views trong `01_schema.sql`.
  - Trí Lộc viết 3 Triggers tự động (tích hợp vào `01_schema.sql`) và chuẩn bị dữ liệu mẫu.
- **Tuần 1 (Day 5 - Day 7):**
  - Trí Lộc nạp toàn bộ file `02_mock_data.sql` ($\ge 10k$ dòng) vào database, kích hoạt kiểm thử Trigger.
- **Tuần 2 (Day 8 - Day 11):**
  - Trúc Linh chạy thử 10 câu truy vấn trên tập dữ liệu đã nạp và chụp lại thời gian thực thi.
- **Tuần 2 (Day 12 - Day 14):**
  - Trúc Linh tổng hợp hoàn tất báo cáo Word, cả nhóm nghiệm thu chốt mã nguồn và commit lên GitHub.



