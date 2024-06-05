CREATE DATABASE DO_AN_QLTT;
USE DO_AN_QLTT;

-- Creating Tables
CREATE TABLE PLAYER (
    playerID INT PRIMARY KEY,
    playerName NVARCHAR(100),
    playerBirthDate DATETIME,
    playerHomeTown NVARCHAR(100),
    playStatus BIT,
);
GO

CREATE TABLE TEAM_ESPORT (
    teamID INT PRIMARY KEY,
    teamName NVARCHAR(100),
    teamYearEstablished INT,
    teamSponsor NVARCHAR(255),
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
    seasonDateStart DATETIME,
    seasonDateEnd DATETIME
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
    teamTotalScore INT,
	teamShortName varchar(40),
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

CREATE TRIGGER UPDATE_DIEM ON MATCH
FOR UPDATE, INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM INSERTED I, TEAM_ESPORT_SEASON T WHERE I.TEAMONESCORE = 2 AND I.teamoneID = T.TEAMID)
    BEGIN
        UPDATE TEAM_ESPORT_SEASON
        SET TEAMTOTALSCORE = TEAMTOTALSCORE + 1;
    END
END;
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

CREATE VIEW PLAYERINFO
AS
	SELECT TEAMNAME, NICKNAME, PLAYERNAME, LANE, DATESTART, DATEEND
	FROM TEAM_ESPORT TE, PLAYER_TEAM_ESPORT PTE, PLAYER P
	WHERE TE.TEAMID = PTE.TEAMID AND PTE.PLAYERID = P.PLAYERID
GO

CREATE VIEW TMP1 AS
(SELECT 
        teamID,
        SUM(CASE WHEN result = 'win' THEN 1 ELSE 0 END) AS wins,
        SUM(CASE WHEN result = 'lose' THEN 1 ELSE 0 END) AS losses
    FROM (
        SELECT
            teamoneID AS teamID,
            CASE 
                WHEN teamoneScore > teamtwoScore THEN 'win'
                ELSE 'lose'
            END AS result
        FROM MATCH
        UNION ALL
        SELECT
            teamtwoID AS teamID,
            CASE 
                WHEN teamtwoScore > teamoneScore THEN 'win'
                ELSE 'lose'
            END AS result
        FROM MATCH
    ) AS results
    GROUP BY teamID)

go

create view BXH1 AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY TES.TEAMTOTALSCORE DESC) AS RANKING,
    T.teamLogo,
    T.TEAMNAME,
    CONCAT(TMP1.wins, '-', TMP1.losses) AS [T/B],
    TES.TEAMTOTALSCORE,
	s.seasonName
FROM 
    TEAM_ESPORT_SEASON TES
    JOIN TEAM_ESPORT T ON TES.TEAMID = T.TEAMID
    JOIN SEASON S ON TES.SEASONID = S.SEASONID
    JOIN TMP1 ON TES.TEAMID = TMP1.teamID
GROUP BY 
    T.teamLogo,
    T.TEAMNAME,
    TMP1.wins,
    TMP1.losses,
    TES.TEAMTOTALSCORE,
	s.seasonName;

go

CREATE VIEW LICHTHIDAU
AS
	SELECT TOP 100000 -- Replace with a large enough number
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
	ORDER BY M.matchDate;
go

CREATE VIEW THONGTINTEAMSPORT
AS
	SELECT teamID, teamName, teamYearEstablished, teamSponsor, teamLogo
    FROM TEAM_ESPORT
go
SELECT * FROM THONGTINTEAMSPORT

go

--CREATE DATA FOR DATABASE--

-- Insert data into PLAYER table
INSERT INTO PLAYER (playerID, playerName, playerBirthDate, playerHomeTown, playStatus) VALUES
(1, N'Nguyen Van A', '1995-01-01', N'Hà Nội', 1),
(2, N'Tran Thi B', '1996-02-02', N'Hồ Chí Minh', 1),
(3, N'Le Van C', '1997-03-03', N'Đà Nẵng', 1),
(4, N'Pham Thi D', '1998-04-04', N'Hải Phòng', 1),
(5, N'Do Van E', '1999-05-05', N'Can Tho', 1);
SELECT * FROM PLAYER;
-- Insert data into TEAM_ESPORT table
INSERT INTO TEAM_ESPORT (teamID, teamName, teamYearEstablished, teamSponsor, teamLogo) VALUES
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
