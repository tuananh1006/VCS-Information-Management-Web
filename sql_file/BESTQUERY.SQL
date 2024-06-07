CREATE DATABASE DO_AN_QLTT;
GO
USE DO_AN_QLTT;

-- Creating Tables
CREATE TABLE PLAYER (
    playerID INT PRIMARY KEY,
    playerName NVARCHAR(100),
    playerBirthDate DATETIME,
    playerHomeTown NVARCHAR(100),
	playerImage NVARCHAR(255),
    playerStatus BIT,
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
	playerRole NVARCHAR(50),
    DateStart DATETIME,
    DateEnd DATETIME,
    FOREIGN KEY (playerID) REFERENCES PLAYER(playerID),
    FOREIGN KEY (teamID) REFERENCES TEAM_ESPORT(teamID),
    PRIMARY KEY (playerID, teamID,DateStart)
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
               PT.playerRole AS 'ĐƯỜNG THI ĐẤU',
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


CREATE VIEW PLAYERINFO
AS
	SELECT TEAMNAME, NICKNAME, PLAYERNAME, playerRole, DATESTART, DATEEND
	FROM TEAM_ESPORT TE, PLAYER_TEAM_ESPORT PTE, PLAYER P
	WHERE TE.TEAMID = PTE.TEAMID AND PTE.PLAYERID = P.PLAYERID
GO

CREATE VIEW RankingsBySeason AS
WITH TMP1 AS
(
    SELECT 
        teamID,
        seasonID,
        SUM(CASE WHEN result = 'win' THEN 1 ELSE 0 END) AS wins,
        SUM(CASE WHEN result = 'lose' THEN 1 ELSE 0 END) AS losses,
		SUM(CASE WHEN result = 'win' THEN 1 ELSE 0 END) + SUM(CASE WHEN result = 'lose' THEN -1 ELSE 0 END) AS NUMBER
    FROM (
        SELECT
            teamoneID AS teamID,
            seasonID,
            CASE 
                WHEN teamoneScore > teamtwoScore THEN 'win'
                ELSE 'lose'
            END AS result
        FROM MATCH
        UNION ALL
        SELECT
            teamtwoID AS teamID,
            seasonID,
            CASE 
                WHEN teamtwoScore > teamoneScore THEN 'win'
                ELSE 'lose'
            END AS result
        FROM MATCH
    ) AS results
    GROUP BY teamID, seasonID
)
SELECT 
    ROW_NUMBER() OVER (PARTITION BY S.seasonName ORDER BY TMP1.NUMBER DESC) AS RANKING,
    T.teamLogo,
    T.TEAMNAME,
    CONCAT(TMP1.wins, '-', TMP1.losses) AS [T/B],
    TES.TEAMTOTALSCORE,
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
    S.seasonName;

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


