<<<<<<< Updated upstream
﻿CREATE DATABASE DO_AN_QLTT;
USE DO_AN_QLTT;
=======
﻿CREATE DATABASE QUANLI_VCS;
GO
USE QUANLI_VCS;
>>>>>>> Stashed changes

-- Creating Tables
CREATE TABLE PLAYER (
    playerID INT PRIMARY KEY,
    playerName NVARCHAR(100),
    playerBirthDate DATETIME,
    playerHomeTown NVARCHAR(100),
    playStatus INT
);
GO

CREATE TABLE TEAM_ESPORT (
    teamID INT PRIMARY KEY,
    teamName NVARCHAR(100),
    teamYearEstablished INT,
    teamOwner NVARCHAR(100),
    teamLogo NVARCHAR(255)
);
GO

CREATE TABLE STADIUM (
    stadiumID INT PRIMARY KEY,
    stadiumName NVARCHAR(100),
    stadiumAddress NVARCHAR(255),
    stadiumCapacity INT
);
GO

CREATE TABLE SEASON (
    seasonID INT PRIMARY KEY,
    seasonName NVARCHAR(100),
    seasonSponsor NVARCHAR(100),
    seasonDateStart DATETIME
);
GO

CREATE TABLE MATCHTYPE (
    matchtypeID INT PRIMARY KEY,
    matchtypeName NVARCHAR(100),
    matchtypeQuantity INT
);
GO

CREATE TABLE MATCH (
    matchID INT PRIMARY KEY,
    teamoneID INT,
    teamtwoID INT,
    teamoneScore INT,
    teamtwoScore INT,
    matchDate DATETIME,
    stadiumID INT,
    seasonID INT,
    matchtypeID INT,
    FOREIGN KEY (teamoneID) REFERENCES TEAM_ESPORT(teamID),
    FOREIGN KEY (teamtwoID) REFERENCES TEAM_ESPORT(teamID),
    FOREIGN KEY (stadiumID) REFERENCES STADIUM(stadiumID),
    FOREIGN KEY (seasonID) REFERENCES SEASON(seasonID),
    FOREIGN KEY (matchtypeID) REFERENCES MATCHTYPE(matchtypeID)
);
GO

CREATE TABLE PLAYER_TEAM_ESPORT (
    playerID INT,
    teamID INT,
    NickName NVARCHAR(100),
    Lane NVARCHAR(50),
    DateStart DATETIME,
    DateEnd DATETIME,
    FOREIGN KEY (playerID) REFERENCES PLAYER(playerID),
    FOREIGN KEY (teamID) REFERENCES TEAM_ESPORT(teamID),
    PRIMARY KEY (playerID, teamID)
);
GO

CREATE TABLE COACH (
    coachID INT PRIMARY KEY,
    coachName NVARCHAR(100),
    coachBirthDate DATETIME,
    coachHomeTown NVARCHAR(100)
);
GO

CREATE TABLE COACH_TEAM_ESPORT (
    coachID INT,
    teamID INT,
    NickName NVARCHAR(100),
    DateStart DATETIME,
    DateEnd DATETIME,
    FOREIGN KEY (coachID) REFERENCES COACH(coachID),
    FOREIGN KEY (teamID) REFERENCES TEAM_ESPORT(teamID),
    PRIMARY KEY (coachID, teamID)
);
GO

CREATE TABLE PLAYER_MATCH (
    playerID INT,
    matchID INT,
    Champion NVARCHAR(100),
    NUMKill INT,
    Die INT,
    Support INT,
    FOREIGN KEY (playerID) REFERENCES PLAYER(playerID),
    FOREIGN KEY (matchID) REFERENCES MATCH(matchID),
    PRIMARY KEY (playerID, matchID)
);
GO

CREATE TABLE TEAM_ESPORT_SEASON (
    teamID INT,
    seasonID INT,
<<<<<<< Updated upstream
    teamTotalScore INT,
=======
    teamTotalScore INT default 0,
	teamShortName varchar(40) NOT NULL,
>>>>>>> Stashed changes
    FOREIGN KEY (teamID) REFERENCES TEAM_ESPORT(teamID),
    FOREIGN KEY (seasonID) REFERENCES SEASON(seasonID),
    PRIMARY KEY (teamID, seasonID)
);
GO

CREATE TABLE CUSTOMER (
    ID_CUSTOMER INT PRIMARY KEY,
    NAME_CUSTOMER VARCHAR(50) NOT NULL,
    date_of_birth SMALLDATETIME,
    EMAIL NVARCHAR(255),
    SEX CHAR(10) NOT NULL,
    NICKNAME NVARCHAR(100),
    PASSWORD NVARCHAR(255),
    USERNAME_LOGIN VARCHAR(30),
    COIN INT
);
GO

CREATE TABLE BET (
    ID_BET INT PRIMARY KEY,
    ID_CUSTOMER INT,
    matchID INT,
    T1Score_predict INT,
    T2Score_predict INT,
    COIN_BET INT,
    DAY_BET SMALLDATETIME,
    FOREIGN KEY (ID_CUSTOMER) REFERENCES CUSTOMER(ID_CUSTOMER),
    FOREIGN KEY (matchID) REFERENCES MATCH(matchID)
);
GO

-- Creating Triggers
CREATE TRIGGER CHECK_START_SEASON ON SEASON
FOR INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM INSERTED I, MATCH M WHERE I.seasonDateStart > M.matchDate AND I.seasonID = M.seasonID)
    BEGIN
        PRINT N'NGÀY BẮT ĐẦU MÙA GIẢI PHẢI BÉ HƠN NGÀY THI ĐẤU';
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        PRINT N'NHẬP DỮ LIỆU THÀNH CÔNG';
    END
END;
GO

CREATE TRIGGER CHECK_START_MATCH ON MATCH
FOR INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM INSERTED I, SEASON S WHERE S.seasonDateStart > I.matchDate AND I.seasonID = S.seasonID)
    BEGIN
        PRINT N'NGÀY THI ĐẤU >= NGÀY BẮT ĐẦU MÙA GIẢI';
        ROLLBACK TRANSACTION;
    END
END;
GO

CREATE TRIGGER DELETE_TEAM ON TEAM_ESPORT 
INSTEAD OF DELETE
AS
BEGIN
    DECLARE @ID_TEAM INT;
    SELECT @ID_TEAM = TEAMID FROM DELETED;

    DELETE FROM PLAYER_TEAM_ESPORT WHERE TEAMID = @ID_TEAM;
    DELETE FROM COACH_TEAM_ESPORT WHERE TEAMID = @ID_TEAM;
    DELETE FROM TEAM_ESPORT_SEASON WHERE TEAMID = @ID_TEAM;
    DELETE FROM TEAM_ESPORT WHERE TEAMID = @ID_TEAM;
END;
GO

CREATE TRIGGER DELETE_PLAYER ON PLAYER
INSTEAD OF DELETE
AS
BEGIN
    DECLARE @DELETE_ID_PLAYER INT;
    SELECT @DELETE_ID_PLAYER = PLAYERID FROM DELETED;

    DELETE FROM PLAYER_TEAM_ESPORT WHERE PLAYERID = @DELETE_ID_PLAYER;
    DELETE FROM PLAYER_MATCH WHERE PLAYERID = @DELETE_ID_PLAYER;
    DELETE FROM PLAYER WHERE PLAYERID = @DELETE_ID_PLAYER;
END;
GO

CREATE TRIGGER DELETE_COACH ON COACH
INSTEAD OF DELETE
AS
BEGIN
    DECLARE @DELETE_ID_COACH INT;
    SELECT @DELETE_ID_COACH = COACHID FROM DELETED;

    DELETE FROM COACH_TEAM_ESPORT WHERE COACHID = @DELETE_ID_COACH;
    DELETE FROM COACH WHERE COACHID = @DELETE_ID_COACH;
END;
GO

--Update tong so diem cua mot doi tuyen trong mot giai dau
CREATE TRIGGER updateScore ON match
FOR INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE EXISTS (SELECT 1 FROM team_esport_season WHERE team_esport_season.seasonid = inserted.seasonid))
    BEGIN
        UPDATE team_esport_season
        SET teamtotalScore = teamtotalScore + i.teamonescore - i.teamtwoscore
        FROM inserted i
        WHERE team_esport_season.teamid = i.teamoneid
          AND team_esport_season.seasonid = i.seasonid;
          
        UPDATE team_esport_season
        SET teamtotalScore = teamtotalScore - i.teamonescore + i.teamtwoscore
        FROM inserted i
        WHERE team_esport_season.teamid = i.teamtwoid
          AND team_esport_season.seasonid = i.seasonid;
    END
END
GO

CREATE TRIGGER CHECK_NGTL ON TEAM_ESPORT
FOR INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM PLAYER_TEAM_ESPORT PTE, INSERTED I WHERE PTE.TEAMID = I.TEAMID AND PTE.DateStart < I.teamYearEstablished)
    BEGIN
        PRINT N'NGÀY THÀNH LẬP TEAM PHẢI NHỎ HƠN NGÀY TUYỂN THỦ GIA NHẬP TEAM NÀY';
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        PRINT N'THÊM THÀNH CÔNG';
    END
END;
GO

CREATE TRIGGER CHECK_hlv_NGTL ON TEAM_ESPORT
FOR INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM COACH_TEAM_ESPORT CTE, INSERTED I WHERE CTE.TEAMID = I.TEAMID AND CTE.DateStart < I.teamYearEstablished)
    BEGIN
        PRINT N'NGÀY THÀNH LẬP TEAM PHẢI NHỎ HƠN NGÀY HLV GIA NHẬP TEAM NÀY';
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        PRINT N'THÊM THÀNH CÔNG';
    END
END;
GO

CREATE TRIGGER CHECK_ID_MATCH ON BET
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM INSERTED I WHERE NOT EXISTS (SELECT 1 FROM MATCH M WHERE I.matchID = M.matchID))
    BEGIN
        PRINT N'ID_MATCH KHÔNG TỒN TẠI TRONG MATCH';
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        PRINT N'NHẬP DỮ LIỆU THÀNH CÔNG';
    END
END;
GO

CREATE TRIGGER CHECK_NGAY_BET ON BET
FOR INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM INSERTED I, MATCH M WHERE I.matchID = M.matchID AND I.DAY_BET > M.matchDate)
    BEGIN
        PRINT N'NGÀY BET PHẢI NHỎ HƠN NGÀY TRẬN ĐẤU DIỄN RA';
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        PRINT N'NHẬP DỮ LIỆU THÀNH CÔNG';
    END
END;
GO

-- Stored Procedures
CREATE PROCEDURE PRINT_TT_PLAYER (@nick_name NVARCHAR(100))
AS
BEGIN
    IF EXISTS (SELECT 1 FROM PLAYER_TEAM_ESPORT WHERE NickName = @nick_name)
    BEGIN
        SELECT P.playerName AS 'TÊN TUYỂN THỦ',
               P.playerBirthDate AS 'NGÀY SINH',
               P.playerHomeTown AS 'QUÊ QUÁN',
               T.teamName AS 'TÊN TEAM',
               PT.Lane AS 'ĐƯỜNG THI ĐẤU',
               PT.DateStart AS 'NGÀY BẮT ĐẦU THI ĐẤU',
               PT.DateEnd AS 'NGÀY KẾT THÚC THI ĐẤU'
        FROM PLAYER P
        JOIN PLAYER_TEAM_ESPORT PT ON P.playerID = PT.playerID
        JOIN TEAM_ESPORT T ON PT.teamID = T.teamID
        WHERE PT.NickName = @nick_name;
    END
    ELSE
    BEGIN
        PRINT N'KHÔNG TÌM THẤY TUYỂN THỦ';
    END
END;
GO

CREATE PROCEDURE PRINT_KT_PLAYER (@nick_name NVARCHAR(100))
AS
BEGIN
    IF EXISTS (SELECT 1 FROM PLAYER_TEAM_ESPORT WHERE NickName = @nick_name)
    BEGIN
        SELECT P.playerName AS 'TÊN TUYỂN THỦ',
               P.playerBirthDate AS 'NGÀY SINH',
               P.playerHomeTown AS 'QUÊ QUÁN',
               M.matchID AS 'ID TRẬN ĐẤU',
               M.matchDate AS 'NGÀY THI ĐẤU',
               PM.Champion AS 'VỊ TƯỚNG SỬ DỤNG',
               PM.NUMKill AS 'SỐ LẦN HẠ GỤC ĐỐI PHƯƠNG',
               PM.Die AS 'SỐ LẦN BỊ HẠ GỤC',
               PM.Support AS 'SỐ LẦN HỖ TRỢ ĐỒNG ĐỘI'
        FROM PLAYER P
        JOIN PLAYER_MATCH PM ON P.playerID = PM.playerID
        JOIN MATCH M ON PM.matchID = M.matchID
        JOIN PLAYER_TEAM_ESPORT PT ON P.playerID = PT.playerID
        WHERE PT.NickName = @nick_name;
    END
    ELSE
    BEGIN
        PRINT N'KHÔNG TÌM THẤY TUYỂN THỦ';
    END
END;
GO

CREATE PROCEDURE PRINT_MV_TEAM (@team_name NVARCHAR(100))
AS
BEGIN
    IF EXISTS (SELECT 1 FROM TEAM_ESPORT WHERE teamName = @team_name)
    BEGIN
        SELECT S.seasonName AS 'TÊN MÙA GIẢI',
               S.seasonDateStart AS 'NGÀY BẮT ĐẦU',
               TES.teamTotalScore AS 'TỔNG SỐ ĐIỂM'
        FROM TEAM_ESPORT_SEASON TES
        JOIN SEASON S ON TES.seasonID = S.seasonID
        JOIN TEAM_ESPORT T ON TES.teamID = T.teamID
        WHERE T.teamName = @team_name;
    END
    ELSE
    BEGIN
        PRINT N'KHÔNG TÌM THẤY TEAM';
    END
END;
GO

CREATE PROCEDURE PRINT_TT_HLV (@nick_name NVARCHAR(100))
AS
BEGIN
    IF EXISTS (SELECT 1 FROM COACH_TEAM_ESPORT WHERE NickName = @nick_name)
    BEGIN
        SELECT C.coachName AS 'TÊN HUẤN LUYỆN VIÊN',
               C.coachBirthDate AS 'NGÀY SINH',
               C.coachHomeTown AS 'QUÊ QUÁN',
               T.teamName AS 'TÊN TEAM',
               CTE.DateStart AS 'NGÀY BẮT ĐẦU HUẤN LUYỆN',
               CTE.DateEnd AS 'NGÀY KẾT THÚC HUẤN LUYỆN'
        FROM COACH C
        JOIN COACH_TEAM_ESPORT CTE ON C.coachID = CTE.coachID
        JOIN TEAM_ESPORT T ON CTE.teamID = T.teamID
        WHERE CTE.NickName = @nick_name;
    END
    ELSE
    BEGIN
        PRINT N'KHÔNG TÌM THẤY HUẤN LUYỆN VIÊN';
    END
END;
GO

--CREATE DATA FOR DATABASE--
USE DO_AN_QLTT;

-- Insert data into PLAYER table
INSERT INTO PLAYER (playerID, playerName, playerBirthDate, playerHomeTown, playStatus) VALUES
(1, N'Nguyen Van A', '1995-01-01', N'Hà Nội', 1),
(2, N'Tran Thi B', '1996-02-02', N'Hồ Chí Minh', 1),
(3, N'Le Van C', '1997-03-03', N'Đà Nẵng', 1),
(4, N'Pham Thi D', '1998-04-04', N'Hải Phòng', 1),
(5, N'Do Van E', '1999-05-05', N'Can Tho', 1);
SELECT * FROM PLAYER;
-- Insert data into TEAM_ESPORT table
INSERT INTO TEAM_ESPORT (teamID, teamName, teamYearEstablished, teamOwner, teamLogo) VALUES
(1, N'Team Alpha', 2015, N'Nguyen Van Owner1', 'logo1.png'),
(2, N'Team Beta', 2016, N'Tran Thi Owner2', 'logo2.png'),
(3, N'Team Gamma', 2017, N'Le Van Owner3', 'logo3.png'),
(4, N'Team Delta', 2018, N'Pham Thi Owner4', 'logo4.png'),
(5, N'Team Epsilon', 2019, N'Do Van Owner5', 'logo5.png');
SELECT * FROM TEAM_ESPORT;

-- Insert data into STADIUM table
INSERT INTO STADIUM (stadiumID, stadiumName, stadiumAddress, stadiumCapacity) VALUES
(1, N'Stadium A', N'Hà Nội', 10000),
(2, N'Stadium B', N'Hồ Chí Minh', 15000),
(3, N'Stadium C', N'Đà Nẵng', 20000),
(4, N'Stadium D', N'Hải Phòng', 25000),
(5, N'Stadium E', N'Can Tho', 30000);
SELECT * FROM STADIUM;
-- Insert data into SEASON table
INSERT INTO SEASON (seasonID, seasonName, seasonSponsor, seasonDateStart) VALUES
(1, N'Season 2020', N'Sponsor A', '2020-01-01'),
(2, N'Season 2021', N'Sponsor B', '2021-01-01'),
(3, N'Season 2022', N'Sponsor C', '2022-01-01'),
(4, N'Season 2023', N'Sponsor D', '2023-01-01'),
(5, N'Season 2024', N'Sponsor E', '2024-01-01');
SELECT * FROM SEASON;

-- Insert data into MATCHTYPE table
INSERT INTO MATCHTYPE (matchtypeID, matchtypeName, matchtypeQuantity) VALUES
(1, N'Type A', 3),
(2, N'Type B', 5),
(3, N'Type C', 7),
(4, N'Type D', 9),
(5, N'Type E', 11);
SELECT * FROM MATCHTYPE;

-- Insert data into MATCH table
INSERT INTO MATCH (matchID, teamoneID, teamtwoID, teamoneScore, teamtwoScore, matchDate, stadiumID, seasonID, matchtypeID) VALUES
(1, 1, 2, 2, 1, '2020-01-15', 1, 1, 1),
(2, 2, 3, 1, 2, '2021-01-15', 2, 2, 2),
(3, 3, 4, 2, 1, '2022-01-15', 3, 3, 3),
(4, 4, 5, 1, 2, '2023-01-15', 4, 4, 4),
(5, 5, 1, 2, 1, '2024-01-15', 5, 5, 5);
SELECT * FROM MATCH;

-- Insert data into PLAYER_TEAM_ESPORT table
INSERT INTO PLAYER_TEAM_ESPORT (playerID, teamID, NickName, Lane, DateStart, DateEnd) VALUES
(1, 1, N'Nick1', N'Top', '2021-01-01', '2023-01-01'),
(2, 2, N'Nick2', N'Jungle', '2021-02-01', '2023-02-01'),
(3, 3, N'Nick3', N'Mid', '2021-03-01', '2023-03-01'),
(4, 4, N'Nick4', N'ADC', '2021-04-01', '2023-04-01'),
(5, 5, N'Nick5', N'Support', '2021-05-01', '2023-05-01');
SELECT * FROM PLAYER_TEAM_ESPORT;


-- Insert data into COACH table
INSERT INTO COACH (coachID, coachName, coachBirthDate, coachHomeTown) VALUES
(1, N'Coach A', '1980-01-01', N'Hà Nội'),
(2, N'Coach B', '1981-02-02', N'Hồ Chí Minh'),
(3, N'Coach C', '1982-03-03', N'Đà Nẵng'),
(4, N'Coach D', '1983-04-04', N'Hải Phòng'),
(5, N'Coach E', '1984-05-05', N'Can Tho');
SELECT * FROM COACH;

-- Insert data into COACH_TEAM_ESPORT table
INSERT INTO COACH_TEAM_ESPORT (coachID, teamID, NickName, DateStart, DateEnd) VALUES
(1, 1, N'CoachNick1', '2020-01-01', '2022-01-01'),
(2, 2, N'CoachNick2', '2020-02-01', '2022-02-01'),
(3, 3, N'CoachNick3', '2020-03-01', '2022-03-01'),
(4, 4, N'CoachNick4', '2020-04-01', '2022-04-01'),
(5, 5, N'CoachNick5', '2020-05-01', '2022-05-01');
SELECT * FROM COACH_TEAM_ESPORT;

-- Insert data into PLAYER_MATCH table
INSERT INTO PLAYER_MATCH (playerID, matchID, Champion, NUMKill, Die, Support) VALUES
(1, 1, N'Champ1', 10, 2, 5),
(2, 2, N'Champ2', 8, 3, 7),
(3, 3, N'Champ3', 6, 4, 6),
(4, 4, N'Champ4', 5, 5, 5),
(5, 5, N'Champ5', 7, 2, 8);
SELECT * FROM PLAYER_MATCH;

-- Insert data into TEAM_ESPORT_SEASON table
INSERT INTO TEAM_ESPORT_SEASON (teamID, seasonID, teamTotalScore) VALUES
(1, 1, 20),
(2, 2, 25),
(3, 3, 30),
(4, 4, 35),
(5, 5, 40);
SELECT * FROM TEAM_ESPORT_SEASON;

-- Insert data into CUSTOMER table
INSERT INTO CUSTOMER (ID_CUSTOMER, NAME_CUSTOMER, date_of_birth, EMAIL, SEX, NICKNAME, PASSWORD, USERNAME_LOGIN, COIN) VALUES
(1, N'Customer A', '1990-01-01', N'customerA@example.com', N'Male', N'CustA', N'passwordA', N'usernameA', 1000),
(2, N'Customer B', '1991-02-02', N'customerB@example.com', N'Female', N'CustB', N'passwordB', N'usernameB', 1500),
(3, N'Customer C', '1992-03-03', N'customerC@example.com', N'Male', N'CustC', N'passwordC', N'usernameC', 2000),
(4, N'Customer D', '1993-04-04', N'customerD@example.com', N'Female', N'CustD', N'passwordD', N'usernameD', 2500),
(5, N'Customer E', '1994-05-05', N'customerE@example.com', N'Male', N'CustE', N'passwordE', N'usernameE', 3000);
SELECT * FROM CUSTOMER;

-- Insert data into BET table
INSERT INTO BET (ID_BET, ID_CUSTOMER, matchID, T1Score_predict, T2Score_predict, COIN_BET, DAY_BET) VALUES
(1, 1, 1, 2, 1, 100, '2020-01-10'),
(2, 2, 2, 1, 2, 200, '2021-01-10'),
(3, 3, 3, 2, 1, 300, '2022-01-10'),
(4, 4, 4, 1, 2, 400, '2023-01-10'),
(5, 5, 5, 2, 1, 500, '2024-01-10');

SELECT * FROM BET;
-- Kiểm tra dữ liệu trong bảng MATC



CREATE VIEW LICHTHIDAU
AS
	SELECT 
	M.matchDate AS 'NGÀY THI ĐẤU',
	T1.teamName AS 'ĐỘI 1',
	M.teamoneScore AS 'ĐIỂM ĐỘI 1',
	T2.teamName AS 'ĐỘI 2',
	M.teamtwoScore AS 'ĐIỂM ĐỘI 2',
	ST.stadiumName AS 'SÂN VẬN ĐỘNG'
	FROM 
            MATCH M
        INNER JOIN 
            TEAM_ESPORT T1 ON M.teamoneID = T1.teamID
        INNER JOIN 
            TEAM_ESPORT T2 ON M.teamtwoID = T2.teamID
        INNER JOIN 
            SEASON S ON M.seasonID = S.seasonID
        INNER JOIN 
            STADIUM ST ON M.stadiumID = ST.stadiumID
<<<<<<< Updated upstream
        ORDER BY M.matchDate;
=======
        WHERE 
            S.seasonName = @seasonName
        ORDER BY 
            M.matchDate;
    END
    ELSE
    BEGIN
        -- Nếu mùa giải không tồn tại, in ra thông báo lỗi
        PRINT N'Mùa giải không tồn tại.'
    END
END
/* FUNCTION */
CREATE FUNCTION FC_IN_THONG_TIN_DOI (@teamName NVARCHAR(100))
RETURNS TABLE
AS
RETURN (
    SELECT 
        P.PLAYERNAME, 
        T.TEAMNAME, 
        T.teamYearEstablished,
        T.teamLogo,
        STRING_AGG(TS.teamSponsor, ', ') AS sponsors -- Nối tất cả các tên nhà tài trợ thành một chuỗi
    FROM 
        PLAYER P
        INNER JOIN PLAYER_TEAM_ESPORT PTE ON P.PLAYERID = PTE.PLAYERID
        INNER JOIN TEAM_ESPORT T ON PTE.TEAMID = T.TEAMID
        INNER JOIN TEAM_ESPORT_SPONSOR TS ON T.TEAMID = TS.teamID
    WHERE 
        T.teamName = @teamName
    GROUP BY
        P.PLAYERNAME, 
        T.TEAMNAME, 
        T.teamYearEstablished,
        T.teamLogo
);


/* ĐƯA VÀO TÊN TUYỂN THỦ VÀ TÊN MÙA GIẢI IN RA SỐ LƯỢNG TƯỚNG MÀ NGƯỜI ĐÓ ĐÃ CHƠI */
go
CREATE FUNCTION FC_SL_TUONG (@NICK_NAME NVARCHAR(100), @seasonID INT)
RETURNS TABLE
AS
RETURN
(
    -- Kiểm tra và trả về số lượng tướng đã sử dụng bởi cầu thủ trong mùa giải đó
    SELECT C.championName AS 'TƯỚNG', COUNT(DISTINCT C.championName) AS 'SỐ LƯỢNG SỬ DỤNG'
    FROM CHITIETTRANDAU PM
    JOIN PLAYER_TEAM_ESPORT PTE ON PM.playerID = PTE.playerID
    JOIN TEAM_ESPORT_SEASON TES ON PTE.teamID = TES.teamID
    JOIN SEASON S ON TES.seasonID = S.seasonID
	JOIN CHAMPION C ON PM.championID=C.championID 
    WHERE PTE.NickName = @NICK_NAME AND S.seasonID = @seasonID
    GROUP BY C.championName
);
SELECT * FROM dbo.FC_SL_TUONG('Levi',1)
go
-- An toàn thông tin--
--Tạo role--
--Create a role for manager--
CREATE ROLE manager_role;
--Create a role for employee--
CREATE ROLE employee_role;
--Create a role for user--
CREATE ROLE user_role;

-- Create Manager user and assign Manager role
CREATE LOGIN manager_user WITH PASSWORD='manager'
CREATE USER manager_user FOR LOGIN manager_user;
ALTER ROLE manager_role ADD MEMBER manager_user;
-- Create Employee user and assign Employee role
CREATE LOGIN employee_user WITH PASSWORD='employee'
CREATE USER employee_user FOR LOGIN employee_user;
ALTER ROLE employee_role ADD MEMBER employee_user;
-- Create User and assign User role
CREATE LOGIN user_user WITH PASSWORD='user'
CREATE USER user_user FOR LOGIN user_user;
ALTER ROLE user_role ADD MEMBER user_user;


--Create  manager_user1 and assign Manager role
CREATE LOGIN manager_user1 WITH PASSWORD='manager'
CREATE USER manager_user1 FOR LOGIN manager_user1;
ALTER ROLE manager_role ADD MEMBER manager_user1
--Create  manager_user2 and assign Manager role
CREATE LOGIN manager_user2 WITH PASSWORD='manager'
CREATE USER manager_user2 FOR LOGIN manager_user2;
ALTER ROLE manager_role ADD MEMBER manager_user2;

-- Create Employee_user1 and assign Employee role
CREATE LOGIN employee_user1 WITH PASSWORD='employee'
CREATE USER employee_user1 FOR LOGIN employee_user1;
ALTER ROLE employee_role ADD MEMBER employee_user1;

-- Create Employee_user2 and assign Employee role
CREATE LOGIN employee_user2 WITH PASSWORD='employee'
CREATE USER employee_user2 FOR LOGIN employee_user2;
ALTER ROLE employee_role ADD MEMBER employee_user2;

-- Create User1 and assign User role
CREATE LOGIN user_user1 WITH PASSWORD='user'
CREATE USER user_user1 FOR LOGIN user_user1;
ALTER ROLE user_role ADD MEMBER user_user1;

-- Create User2 and assign User role
CREATE LOGIN user_user2 WITH PASSWORD='user'
CREATE USER user_user2 FOR LOGIN user_user2;
ALTER ROLE user_role ADD MEMBER user_user2;
SELECT * FROM master.sys.sql_logins;
--Grant--
--manager role--
GRANT SELECT, INSERT, UPDATE(playerName,playerBirthDate,playerHomeTown,playerStatus),DELETE ON PLAYER TO manager_role
GRANT SELECT, INSERT, UPDATE,DELETE ON PLAYER_TEAM_ESPORT TO manager_role
GRANT SELECT, INSERT, UPDATE(teamName,teamYearEstablished,teamLogo),DELETE ON TEAM_ESPORT TO manager_role
GRANT SELECT, INSERT, UPDATE,DELETE ON  MATCH  TO manager_role
GRANT SELECT, INSERT, UPDATE,DELETE ON STADIUM TO manager_role
GRANT SELECT, INSERT, UPDATE,DELETE ON SEASON TO manager_role
GRANT SELECT, INSERT, UPDATE,DELETE ON MATCHTYPE TO manager_role
GRANT SELECT, INSERT, UPDATE,DELETE ON CHITIETTRANDAU TO manager_role
GRANT SELECT, INSERT, UPDATE,DELETE ON TEAM_ESPORT_SEASON TO manager_role
GRANT SELECT, INSERT, UPDATE,DELETE ON CUSTOMER TO manager_role
GRANT SELECT, INSERT, UPDATE,DELETE ON BET TO manager_role


--Store procedures
GRANT EXECUTE ON PRINT_TT_PLAYER TO manager_role
GRANT EXECUTE ON BXH_SEASON TO manager_role
GRANT EXECUTE ON SP_LICH_THI_DAU TO manager_role
--Function
GRANT SELECT ON FC_IN_THONG_TIN_DOI TO manager_role
GRANT SELECT ON FC_SL_TUONG TO manager_role

--Deny--
DENY SELECT ON CUSTOMER TO manager_user
DENY SELECT ON BET TO manager_user
DENY SELECT ON CUSTOMER TO manager_user1
DENY SELECT ON BET TO manager_user2
--Revoke--
Revoke DELETE ON CUSTOMER TO manager_role
Revoke DELETE ON BET TO manager_role
Revoke UPDATE ON CUSTOMER TO manager_role
Revoke UPDATE ON BET TO manager_role

revoke DELETE ON CUSTOMER TO manager_user
revoke DELETE ON BET TO manager_user
revoke SELECT ON CUSTOMER TO manager_user1
revoke SELECT ON BET TO manager_user2

--employee role--
GRANT SELECT, INSERT, UPDATE(playerName,playerBirthDate,playerHomeTown,playerStatus),DELETE ON PLAYER TO employee_role
GRANT SELECT, INSERT, UPDATE,DELETE ON PLAYER_TEAM_ESPORT TO employee_role
GRANT SELECT, INSERT, UPDATE(teamName,teamYearEstablished,teamLogo),DELETE ON TEAM_ESPORT TO employee_role
GRANT SELECT, INSERT, UPDATE,DELETE ON  MATCH  TO employee_role
GRANT SELECT, INSERT, UPDATE,DELETE ON STADIUM TO employee_role
GRANT SELECT, INSERT, UPDATE,DELETE ON SEASON TO employee_role
GRANT SELECT, INSERT, UPDATE,DELETE ON MATCHTYPE TO employee_role
GRANT SELECT, INSERT, UPDATE,DELETE ON CHITIETTRANDAU TO employee_role
GRANT SELECT, INSERT, UPDATE,DELETE ON TEAM_ESPORT_SEASON TO employee_role
GRANT SELECT, INSERT, UPDATE,DELETE ON CUSTOMER TO employee_role
GRANT SELECT, INSERT, UPDATE,DELETE ON BET TO employee_role
--Store procedures
GRANT EXECUTE ON PRINT_TT_PLAYER TO employee_role
GRANT EXECUTE ON BXH_SEASON TO employee_role
GRANT EXECUTE ON SP_LICH_THI_DAU TO employee_role
--Function
GRANT SELECT ON FC_IN_THONG_TIN_DOI TO employee_role
GRANT SELECT ON FC_SL_TUONG TO employee_role

--Deny--
DENY SELECT ON CUSTOMER TO employee_role
DENY SELECT ON BET TO employee_role
DENY SELECT ON CUSTOMER TO employee_user
DENY SELECT ON BET TO employee_user
DENY SELECT ON CUSTOMER TO employee_user1
DENY SELECT ON BET TO employee_user2
--Revoke
REVOKE DELETE,UPDATE ON CUSTOMER TO employee_role
REVOKE DELETE,UPDATE ON BET TO employee_role

revoke DELETE,UPDATE ON CUSTOMER TO employee_user
revoke DELETE,UPDATE ON BET TO employee_user
revoke SELECT ON CUSTOMER TO employee_user1
revoke SELECT ON BET TO employee_user2

--user role--
GRANT SELECT ON PLAYER to user_role
GRANT SELECT ON PLAYER_TEAM_ESPORT to user_role
GRANT SELECT ON TEAM_ESPORT to user_role
GRANT SELECT ON MATCH to user_role
GRANT SELECT ON STADIUM to user_role
GRANT SELECT ON SEASON to user_role
GRANT SELECT ON MATCHTYPE to user_role
GRANT SELECT ON CHITIETTRANDAU to user_role
GRANT SELECT ON TEAM_ESPORT_SEASON to user_role
GRANT SELECT, INSERT, UPDATE,DELETE ON CUSTOMER TO user_role
GRANT SELECT, INSERT, UPDATE,DELETE ON BET TO user_role
--Store procedures
GRANT EXECUTE ON PRINT_TT_PLAYER TO user_role
GRANT EXECUTE ON BXH_SEASON TO user_role
GRANT EXECUTE ON SP_LICH_THI_DAU TO user_role
--Function
GRANT SELECT ON FC_IN_THONG_TIN_DOI TO user_role
GRANT SELECT ON FC_SL_TUONG TO user_role

--Deny--
DENY DELETE ON CUSTOMER TO user_role
DENY DELETE ON BET TO user_role

DENY SELECT ON CUSTOMER TO user_user
DENY SELECT ON BET TO user_user
DENY SELECT ON CUSTOMER TO user_user1
DENY SELECT ON BET TO user_user2

--REVOKE
REVOKE DELETE ON CUSTOMER TO user_role
REVOKE DELETE ON BET TO user_role

revoke DELETE,UPDATE ON CUSTOMER TO user_user
revoke DELETE,UPDATE ON BET TO user_user
revoke SELECT ON CUSTOMER TO user_user1
revoke SELECT ON BET TO user_user2

-- Bao mat password
ALTER TABLE CUSTOMER ADD Salt UNIQUEIDENTIFIER
GO
CREATE PROCEDURE customer_add(
    @ID_CUSTOMTER  INT ,
    @NAME_CUSTOMER VARCHAR(50) ,
    @date_of_birth smalldatetime,
    @EMAIL NVARCHAR,
    @SEX CHAR(4) ,
    @NICKNAME NVARCHAR,
    @PASSWORD NVARCHAR,
    @USERNAME_LOGIN VARCHAR(30),
    @COIN INT ,
	@reponseMessage NVARCHAR(250) OUTPUT)
AS	
 BEGIN
 SET NOCOUNT ON
 DECLARE @Salt UNIQUEIDENTIFIER =NEWID()
 BEGIN TRY

 INSERT INTO CUSTOMER(ID_CUSTOMER,NAME_CUSTOMER,date_of_birth,EMAIL,SEX,NICKNAME,PASSWORD,USERNAME_LOGIN,COIN,Salt)
  VALUES(@ID_CUSTOMTER,@NAME_CUSTOMER,@date_of_birth,@EMAIL,@SEX,@NICKNAME, HASHBYTES('SHA2_512', @PASSWORD+CAST(@Salt AS NVARCHAR(36))),@USERNAME_LOGIN,@COIN,@Salt)
  SET @reponseMessage='Nhap du lieu thanh cong'
  END TRY
   BEGIN CATCH 
   SET @reponseMessage=ERROR_MESSAGE()
   END CATCH
END

--
-- Thêm phần Procedure và View

--Tìm một trận đấu trong lịch thi đấu
--Đưa vào ngày thi đấu, xuất ra lịch thi đấu hôm nay Team1 (kq--kq) Team2
CREATE PROC matchFound 
    @date smalldatetime, 
    @teamone NVARCHAR(100) OUT, 
    @teamtwo NVARCHAR(100) OUT, 
    @res VARCHAR(7) OUT
AS
BEGIN
    -- Kiểm tra sự tồn tại của trận đấu vào ngày chỉ định
    IF EXISTS (SELECT * FROM match WHERE matchDate = @date)
    BEGIN
        -- Kiểm tra xem teamoneScore hoặc teamtwoScore có phải NULL hay không
        IF EXISTS (SELECT * FROM match WHERE matchDate = @date AND (teamoneScore IS NOT NULL OR teamtwoScore IS NOT NULL))
        BEGIN
            SELECT 
                @teamone = T1.teamName, 
                @teamtwo = T2.teamName, 
                @res = CONCAT(teamoneScore, ':', teamtwoScore)
            FROM 
                match M
                INNER JOIN TEAM_ESPORT T1 ON M.teamoneID = T1.teamID
                INNER JOIN TEAM_ESPORT T2 ON M.teamtwoID = T2.teamID
            WHERE 
                matchDate = @date;
        END
        ELSE
        BEGIN
            SELECT 
                @teamone = T1.teamName, 
                @teamtwo = T2.teamName, 
                @res = '-:-'
            FROM 
                match M
                INNER JOIN TEAM_ESPORT T1 ON M.teamoneID = T1.teamID
                INNER JOIN TEAM_ESPORT T2 ON M.teamtwoID = T2.teamID
            WHERE 
                matchDate = @date;
        END
    END
    ELSE
    BEGIN
        -- Trả về thông báo không tìm thấy lịch thi đấu
        PRINT 'Khong tim thay lich thi dau';
        RETURN 0;
    END
END;

--Tính KDA của tuyển thủ
CREATE PROC KDA 
    @idMatch INT, 
    @idPlayer INT, 
    @RES FLOAT OUT
AS
BEGIN
    -- Kiểm tra sự tồn tại của bản ghi trong bảng PLAYER_MATCH
    IF EXISTS (SELECT * FROM CHITIETTRANDAU WHERE PLAYERID = @idPlayer AND MATCHID = @idMatch)
    BEGIN
        -- Thực hiện phép tính KDA và gán giá trị cho biến @RES
        SELECT @RES = CAST((playerKill + playerSupport) AS FLOAT) / NULLIF(playerDie, 0)
        FROM CHITIETTRANDAU
        WHERE PLAYERID = @idPlayer AND MATCHID = @idMatch;
    END
    ELSE
    BEGIN
        -- Trả về thông báo khi không tìm thấy tuyển thủ
        PRINT 'KHONG TIM THAY TUYEN THU'
        RETURN 0;
    END
END;


DECLARE @RESULT FLOAT
EXEC KDA '1', '2', @RES = @RESULT OUT
PRINT @RESULT
--IN THONG TIN HIEUSO CUA CAC DOI TUYEN



CREATE VIEW PLAYERINFO
AS
	SELECT TEAMNAME, NICKNAME, PLAYERNAME, playerRole, format(DATESTART,'dd/mm/yyyy') as Contracts, format(DATEEND,'dd/mm/yyyy') as Ends
	FROM TEAM_ESPORT TE, PLAYER_TEAM_ESPORT PTE, PLAYER P
	WHERE TE.TEAMID = PTE.TEAMID AND PTE.PLAYERID = P.PLAYERID
GO
select * from playerinfo


CREATE VIEW RankingsBySeason AS
WITH TMP1 AS
(
    SELECT 
        teamID,
        seasonID,
        SUM(CASE WHEN result = 'win' THEN 1 ELSE 0 END) AS wins,
        SUM(CASE WHEN result = 'lose' THEN 1 ELSE 0 END) AS losses,
        SUM(CASE WHEN result = 'win' THEN 1 ELSE 0 END) - SUM(CASE WHEN result = 'lose' THEN 0 ELSE 1 END) AS NUMBER,
        SUM(teamoneScore) - SUM(teamtwoScore) AS goalDifference
    FROM (
        SELECT
            teamoneID AS teamID,
            seasonID,
            CASE 
                WHEN teamoneScore > teamtwoScore THEN 'win'
                ELSE 'lose'
            END AS result,
            teamoneScore,
            teamtwoScore
        FROM MATCH
        UNION ALL
        SELECT
            teamtwoID AS teamID,
            seasonID,
            CASE 
                WHEN teamtwoScore > teamoneScore THEN 'win'
                ELSE 'lose'
            END AS result,
            teamtwoScore,
            teamoneScore
        FROM MATCH
    ) AS results
    GROUP BY teamID, seasonID
)
SELECT 
    ROW_NUMBER() OVER (PARTITION BY S.seasonName ORDER BY TMP1.NUMBER DESC, goalDifference DESC) AS RANKING,
    T.teamLogo,
    T.TEAMNAME,
    CONCAT(TMP1.wins, '-', TMP1.losses) AS [T/B],
    goalDifference,
    S.seasonName
FROM
    TEAM_ESPORT_SEASON TES
    JOIN TEAM_ESPORT T ON TES.TEAMID = T.TEAMID
    JOIN SEASON S ON TES.SEASONID = S.SEASONID
    JOIN TMP1 ON TES.TEAMID = TMP1.teamID AND TES.SEASONID = TMP1.seasonID
GROUP BY 
    T.teamLogo,
    T.TEAMNAME,
    TMP1.NUMBER,
    TMP1.wins,
    TMP1.losses,
    TES.TEAMTOTALSCORE,
    S.seasonName,
    goalDifference;

go
select * from RankingsBySeason
>>>>>>> Stashed changes

CREATE VIEW LICHTHIDAU
AS
	SELECT TOP 100000 -- Replace with a large enough number
		format(M.matchDate,'dd/MM/yyyy') AS N'NGÀY THI ĐẤU',
		T1.teamName AS N'ĐỘI 1',
		concat(M.teamonescore,' - ', M.teamtwoscore) as N'TỈ SỐ',
		T2.teamName AS N'ĐỘI 2',
		ST.stadiumName AS N'SÂN VẬN ĐỘNG'
	FROM 
      MATCH M
    INNER JOIN 
      TEAM_ESPORT T1 ON M.teamoneID = T1.teamID
    INNER JOIN 
      TEAM_ESPORT T2 ON M.teamtwoID = T2.teamID
    INNER JOIN 
      SEASON S ON M.seasonID = S.seasonID
    INNER JOIN 
      STADIUM ST ON M.stadiumID = ST.stadiumID
	ORDER BY M.matchDate;
<<<<<<< Updated upstream

SELECT * FROM LICHTHIDAU;

CREATE VIEW PLAYERINFO
AS
	SELECT TEAMNAME, NICKNAME, PLAYERNAME, LANE, DATESTART, DATEEND
	FROM TEAM_ESPORT TE, PLAYER_TEAM_ESPORT PTE, PLAYER P
	WHERE TE.TEAMID = PTE.TEAMID AND PTE.PLAYERID = P.PLAYERID
=======
go
select * from lichthidau

create VIEW THONGTINTEAMSPORT
AS
	SELECT TEAM_ESPORT.teamID, teamName, teamYearEstablished,TEAM_ESPORT_SPONSOR.teamSponsor, teamLogo
    FROM TEAM_ESPORT,TEAM_ESPORT_SPONSOR
	WHERE TEAM_ESPORT.teamID=TEAM_ESPORT_SPONSOR.teamID
go
SELECT * FROM THONGTINTEAMSPORT

CREATE VIEW USERS 
AS
	SELECT  name_customer, date_of_birth, EMAIL, sex,  nickNAME, COIN
	FROM customer
GO
select * from users

--LICH SU CA CUOC
CREATE VIEW BET88
AS
	SELECT matchID, name_customer, T1score_PREDICT, T2score_PREDICT, COIN_bet, DAY_BET 
	FROM BET, CUSTOMER
	WHERE BET.ID_CUStomer = CUSTOMER.ID_CUStomer
GO
select * from bet88
go




CREATE PROCEDURE CalculateBayesProbability
    @TeamOneID INT,
    @TeamTwoID INT
AS
BEGIN
    -- Declare variables
    DECLARE @TotalMatches INT;
    DECLARE @TeamOneWins INT;
    DECLARE @TeamTwoWins INT;
    DECLARE @TotalRecentMatches INT;
    DECLARE @TeamOneRecentWins INT;
    DECLARE @TeamTwoRecentWins INT;
    DECLARE @P_A DECIMAL(10, 4);
    DECLARE @P_B DECIMAL(10, 4);
    DECLARE @P_B_given_A DECIMAL(10, 4);
    DECLARE @P_B_given_not_A DECIMAL(10, 4);
    DECLARE @P_A_given_B DECIMAL(10, 4);
    DECLARE @P_not_A_given_B DECIMAL(10, 4);

    -- Step 1: Calculate prior probabilities (P(A) and P(not A))
    SELECT 
        @TotalMatches = COUNT(*),
        @TeamOneWins = SUM(CASE WHEN (teamoneID = @TeamOneID AND teamoneScore > teamtwoScore) OR (teamtwoID = @TeamOneID AND teamtwoScore > teamoneScore) THEN 1 ELSE 0 END),
        @TeamTwoWins = SUM(CASE WHEN (teamoneID = @TeamTwoID AND teamoneScore > teamtwoScore) OR (teamtwoID = @TeamTwoID AND teamtwoScore > teamoneScore) THEN 1 ELSE 0 END)
    FROM match
    WHERE (teamoneID = @TeamOneID AND teamtwoID = @TeamTwoID) OR (teamoneID = @TeamTwoID AND teamtwoID = @TeamOneID);

    -- Check for zero denominator for P(A)
    IF @TotalMatches = 0
        SET @P_A = 0;
    ELSE
        SET @P_A = CAST(@TeamOneWins AS DECIMAL(10, 4)) / @TotalMatches;

    -- Check for zero denominator for P(not A)
    IF @TotalMatches = 0
        SET @P_B = 0;
    ELSE
        SET @P_B = CAST(@TeamTwoWins AS DECIMAL(10, 4)) / @TotalMatches;

    -- Step 2: Calculate likelihoods (P(B|A) and P(B|not A))
    SELECT 
        @TotalRecentMatches = COUNT(*),
        @TeamOneRecentWins = SUM(CASE WHEN (teamoneID = @TeamOneID AND teamoneScore > teamtwoScore) OR (teamtwoID = @TeamOneID AND teamtwoScore > teamoneScore) THEN 1 ELSE 0 END),
        @TeamTwoRecentWins = SUM(CASE WHEN (teamoneID = @TeamTwoID AND teamoneScore > teamtwoScore) OR (teamtwoID = @TeamTwoID AND teamtwoScore > teamoneScore) THEN 1 ELSE 0 END)
    FROM (
        SELECT TOP 5 * 
        FROM match 
        WHERE (teamoneID = @TeamOneID AND teamtwoID = @TeamTwoID) OR (teamoneID = @TeamTwoID AND teamtwoID = @TeamOneID)
        ORDER BY matchDate DESC
    ) AS RecentMatches;

    -- Check for zero denominator for P(B|A)
    IF @TotalRecentMatches = 0
        SET @P_B_given_A = 0;
    ELSE
        SET @P_B_given_A = CAST(@TeamTwoRecentWins AS DECIMAL(10, 4)) / @TotalRecentMatches;

    -- Check for zero denominator for P(B|not A)
    IF @TotalRecentMatches = 0
        SET @P_B_given_not_A = 0;
    ELSE
        SET @P_B_given_not_A = CAST(@TeamOneRecentWins AS DECIMAL(10, 4)) / @TotalRecentMatches;

    -- Step 3: Calculate the total probability P(B)
    SET @P_B = (@P_B_given_A * @P_A) + (@P_B_given_not_A * (1 - @P_A)); -- Using the complement of P(A)

    -- Check if total probability is zero (rare case)
    IF @P_B = 0
    BEGIN
        SET @P_A_given_B = 0;
        SET @P_not_A_given_B = 0;
    END
    ELSE
    BEGIN
        -- Step 4: Calculate posterior probabilities (P(A|B) and P(not A|B))
        SET @P_A_given_B = (@P_B_given_A * @P_A) / @P_B;
        SET @P_not_A_given_B = (@P_B_given_not_A * (1 - @P_A)) / @P_B; -- Using the complement of P(A)
    END

    -- Return the probabilities
    SELECT 
        @P_A_given_B AS P1,
        @P_not_A_given_B AS P2;
END;


EXEC CalculateBayesProbability 22, 18;

>>>>>>> Stashed changes
GO
DROP VIEW PLAYERINFO
SELECT * FROM PLAYERINFO