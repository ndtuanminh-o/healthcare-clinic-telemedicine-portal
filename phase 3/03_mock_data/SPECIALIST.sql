START TRANSACTION;
SET FOREIGN_KEY_CHECKS = 0;

INSERT INTO SPECIALIST (doctor_id, specialty, consultation_fee, board_certified_year) VALUES
('533f9540-8d88-44de-bfba-fe2f88c70b12', 'Tim mạch', 300000.0, 2011),
('dfcb772e-24db-4043-b79d-6acdff709f1e', 'Nội tiết - Đái tháo đường', 400000.0, 2021),
('7b29a24c-289e-4024-a47e-96e10ac58e97', 'Tiêu hóa - Gan mật', 250000.0, 2012),
('6a69423c-4a76-41a3-a43b-12a8fa0c2876', 'Hô hấp - Phổi', 250000.0, 2015),
('918fb1e4-08b2-415b-9f9c-f8063967de9f', 'Thần kinh', 300000.0, 2020),
('6e368d04-f3a2-4786-8fef-f50286996045', 'Da liễu', 350000.0, 2018),
('e02cebcd-5b14-496e-a12c-3fcfefe6404b', 'Nhi khoa', 400000.0, 2006),
('ec95c791-7e6d-431a-8c49-8c8bbb854b03', 'Cơ Xương Khớp', 400000.0, 2022),
('1357ee02-64ce-413b-adcb-39b304fd39ce', 'Tai Mũi Họng', 250000.0, 2019),
('d498deb1-4e51-42a1-a665-536d16aac583', 'Mắt', 400000.0, 2018),
('a2ef2836-d5f7-48a9-a9e6-de8f5e4cc8df', 'Tim mạch', 400000.0, 2005),
('0d00988a-e8ab-4b43-92a5-bbb2cb0ece9a', 'Nội tiết - Đái tháo đường', 300000.0, 2009),
('f620e6ed-3b07-4909-98ee-0847eaf1f9ed', 'Tiêu hóa - Gan mật', 250000.0, 2006),
('86d94088-56b1-4497-9744-28efe54534a6', 'Hô hấp - Phổi', 300000.0, 2007),
('81130a19-747b-4b1a-9e24-b6266469ab0d', 'Thần kinh', 250000.0, 2012),
('0e5e6155-1cfb-48bf-b99d-daab23b7b5b4', 'Da liễu', 350000.0, 2015),
('52bb8d6d-8444-4669-883d-fc7901aaeb25', 'Nhi khoa', 350000.0, 2009),
('8fdee926-b1d3-424c-9343-2ca9131d4f99', 'Cơ Xương Khớp', 300000.0, 2007),
('a96bba46-05ad-4e78-8d7e-1ef7a8206e3e', 'Tai Mũi Họng', 300000.0, 2014),
('3f0f6ace-980f-4943-b241-f8643c51021c', 'Mắt', 350000.0, 2005),
('e8f06af9-a46a-4a93-95a1-66689650eb60', 'Tim mạch', 300000.0, 2022),
('a25886da-6dc5-4ea2-bc95-7b5623afdaab', 'Nội tiết - Đái tháo đường', 400000.0, 2021),
('3150e6f2-228a-438a-8d4e-29ed672a4251', 'Tiêu hóa - Gan mật', 250000.0, 2013),
('84ebed80-ebe3-4cd2-97c0-d13e7b09cd36', 'Hô hấp - Phổi', 400000.0, 2022),
('4e39e34b-96af-424e-8dc7-af9366bc5581', 'Thần kinh', 300000.0, 2016),
('37469802-8234-4073-b1dc-b705956e7fec', 'Da liễu', 300000.0, 2011),
('0f3e2708-8500-48ea-bc75-544127ac7f5a', 'Nhi khoa', 300000.0, 2012),
('6f9f8c47-4777-4461-9572-b1a89b4ee7e0', 'Cơ Xương Khớp', 400000.0, 2015),
('fd11c8af-b05f-47bf-b656-1361ecb9758c', 'Tai Mũi Họng', 400000.0, 2008),
('408223ea-9136-44c3-a8a1-e9db1e61b113', 'Mắt', 350000.0, 2016);

COMMIT;

SET FOREIGN_KEY_CHECKS = 1;
