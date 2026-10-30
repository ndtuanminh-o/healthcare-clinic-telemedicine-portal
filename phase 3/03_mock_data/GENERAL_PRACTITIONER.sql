USE healthcare_clinic_v2;
SET FOREIGN_KEY_CHECKS = 0;
SET @DISABLE_TRIGGERS = 1;
START TRANSACTION;

INSERT INTO GENERAL_PRACTITIONER (doctor_id, clinic_room_no, consultation_fee) VALUES
('d66e268f-2d4e-4d62-bfa8-f3b5ade5e217', 'Phòng 101', 150000.0),
('e9213441-64e2-4841-8f72-5063b139f820', 'Phòng 102', 150000.0),
('e7bd180e-e2bc-4b56-93b3-dabb53c43e6d', 'Phòng 103', 150000.0),
('ae088f35-da8c-44e2-ac1c-3fef03b7c116', 'Phòng 104', 150000.0),
('e57a915e-3cb9-4c54-aba2-2d106f5ab925', 'Phòng 105', 150000.0),
('052b5ded-ae1b-4772-adc7-4425eddb5aca', 'Phòng 106', 150000.0),
('6e3cc600-b05b-4923-86bd-9fe5b560a8bc', 'Phòng 107', 150000.0),
('5d3f92d2-4239-4339-b308-6e3e66d4139d', 'Phòng 108', 150000.0),
('90b55713-655c-4cce-b6b8-38b09db2551b', 'Phòng 109', 150000.0),
('bdcbbc2c-9130-48d7-84d7-4df696f467cf', 'Phòng 110', 150000.0),
('955e4490-c896-4064-ad86-3e1c2ed342ce', 'Phòng 111', 150000.0),
('3de9f16d-7e72-4e1b-8423-cb9e184f7886', 'Phòng 112', 150000.0),
('5d7a19cc-5882-4722-9759-fbbb2dc22ee3', 'Phòng 113', 150000.0),
('4a985519-d1fd-410e-9a2b-2220763cc21f', 'Phòng 114', 150000.0),
('69b6b657-8cba-4844-a468-073fb93ac715', 'Phòng 115', 150000.0),
('2ae582eb-5a7d-4dbc-8867-929ca7c33a43', 'Phòng 116', 150000.0),
('8ba4fc7b-b212-44ed-9003-d3534270174d', 'Phòng 117', 150000.0),
('357ec898-1c7b-4f7f-9563-a94f82d473b6', 'Phòng 118', 150000.0),
('78f03e2c-f724-4a59-a1de-7c1e656c8f88', 'Phòng 119', 150000.0),
('c354f522-59a1-4470-98b6-ccad0d0b665e', 'Phòng 120', 150000.0),
('a918473a-3465-454c-9261-04d3896a3c2f', 'Phòng 121', 150000.0),
('4cfa4da7-260b-4648-a322-134c26eb38a5', 'Phòng 122', 150000.0),
('a6ac9ce2-0e09-43f0-9f7a-2bdf71ef2255', 'Phòng 123', 150000.0),
('c6bd2f64-7482-47c6-849e-f27a8bc68c92', 'Phòng 124', 150000.0),
('03a70151-82ee-464a-aec5-443c2f20f85c', 'Phòng 125', 150000.0),
('7966a131-d585-4831-bf08-846a72c72111', 'Phòng 126', 150000.0),
('6ed208d6-919c-4cfb-baf8-cfa90734e02f', 'Phòng 127', 150000.0),
('e9c8cb7e-50a7-44ed-b7ff-c34086cd85e1', 'Phòng 128', 150000.0),
('614dae53-b39f-4c15-ad4a-9c9896d361b6', 'Phòng 129', 150000.0),
('be63e235-45b0-4384-8441-ec71d00b8235', 'Phòng 130', 150000.0);

COMMIT;
SET @DISABLE_TRIGGERS = 0;
SET FOREIGN_KEY_CHECKS = 1;
