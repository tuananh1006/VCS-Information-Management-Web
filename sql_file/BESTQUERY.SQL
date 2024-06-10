CREATE DATABASE DO_AN_QLTT15;
GO
USE DO_AN_QLTT15;

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
    teamName NVARCHAR(100) NOT NULL,
    teamYearEstablished INT,
    teamLogo NVARCHAR(255)
);
GO

CREATE TABLE TEAM_ESPORT_SPONSOR(
	teamID INT,
	teamSponsor NVARCHAR(255),
	PRIMARY KEY (teamID,teamSponsor),
	FOREIGN KEY (teamID) REFERENCES TEAM_ESPORT(teamID),
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
    seasonName NVARCHAR(100) NOT NULL,
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
	playerRole NVARCHAR(50) NOT NULL,
    DateStart DATETIME,
    DateEnd DATETIME,
    FOREIGN KEY (playerID) REFERENCES PLAYER(playerID),
    FOREIGN KEY (teamID) REFERENCES TEAM_ESPORT(teamID),
    PRIMARY KEY (playerID, teamID,DateStart)
);
GO

CREATE TABLE CHAMPION (
    championID INT PRIMARY KEY,
    championName NVARCHAR(100) NOT NULL,
	ChampionImage NVARCHAR(255),
);
GO

CREATE TABLE CHITIETTRANDAU (
    playerID INT,
    matchID INT,
    numberOfMatch INT,
    championID INT,
    playerKill INT,
    playerDie INT,
    playerSupport INT,
    PRIMARY KEY (playerID, matchID, numberOfMatch),
    FOREIGN KEY (playerID) REFERENCES PLAYER(playerID),
    FOREIGN KEY (matchID) REFERENCES MATCH(matchID),
    FOREIGN KEY (championID) REFERENCES CHAMPION(championID)  -- Assuming there is a CHAMPION table
);

GO

CREATE TABLE TEAM_ESPORT_SEASON (
    teamID INT,
    seasonID INT,
    teamTotalScore INT,
	teamShortName varchar(40) NOT NULL,
    FOREIGN KEY (teamID) REFERENCES TEAM_ESPORT(teamID),
    FOREIGN KEY (seasonID) REFERENCES SEASON(seasonID),
    PRIMARY KEY (teamID, seasonID)
);
GO

CREATE TABLE CUSTOMER (
    ID_CUSTOMER INT PRIMARY KEY,
    NAME_CUSTOMER NVARCHAR(50) NOT NULL,
    date_of_birth SMALLDATETIME NOT NULL,
    EMAIL NVARCHAR NOT NULL,
    SEX CHAR(4) NOT NULL,
    NICKNAME NVARCHAR NOT NULL,
    PASSWORD NVARCHAR NOT NULL,
    USERNAME_LOGIN VARCHAR(30) NOT NULL,
    COIN INT
);
GO

CREATE TABLE BET (
    ID_CUSTOMER INT,
    matchID INT,
    T1Score_predict INT not null,
    T2Score_predict INT not null,
    COIN_BET INT,
    DAY_BET SMALLDATETIME,
	PRIMARY KEY(ID_CUSTOMER,matchID),
    FOREIGN KEY (ID_CUSTOMER) REFERENCES CUSTOMER(ID_CUSTOMER),
    FOREIGN KEY (matchID) REFERENCES MATCH(matchID)
);
GO

alter table PLAYER add CONSTRAINT CHK_Age CHECK (DATEDIFF(YEAR, playerBirthDate, GETDATE()) >= 18)
alter table PLAYER add CONSTRAINT CHK_Status CHECK (playerStatus in(0,1))
alter table TEAM_ESPORT add constraint CHK_year CHECK (teamYearEstablished<=YEAR(GETDATE()))
alter table PLAYER_TEAM_ESPORT add constraint CHK_START CHECK(DateStart<=DateEnd)
alter table stadium add constraint CHK_CAP CHECK (stadiumCapacity>0)
alter table MATCHTYPE add constraint CHK_name CHECK(matchtypeName in ('BO3','BO5'))
alter table matchtype add constraint CHK_quantity check(matchtypeQuantity>0)
alter table CHITIETTRANDAU add constraint CHK_KDA CHECK(playerKill>=0 AND playerDie>=0 AND playerSupport>=0)
GO

-- Creating Triggers

CREATE TRIGGER trgCheckBetScores
ON BET
FOR INSERT, UPDATE
AS
BEGIN
    -- Kiểm tra nếu điểm dự đoán của đội 1 hoặc đội 2 không thỏa mãn điều kiện
    IF EXISTS (
        SELECT 1
        FROM INSERTED i
        JOIN MATCH m ON i.matchID = m.matchID
        JOIN MATCHTYPE mt ON m.matchtypeID = mt.matchtypeID
        WHERE i.T1Score_predict > (mt.matchtypeQuantity / 2) + 1
           OR i.T2Score_predict > (mt.matchtypeQuantity / 2) + 1 OR  (i.T1Score_predict+i.T2Score_predict)>mt.matchtypeQuantity
    )
    BEGIN
        RAISERROR ('T1Score_predict and T2Score_predict must be less equal than (matchtypeQuantity / 2) + 1.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

CREATE TRIGGER trgCheckAndDeductCoin
ON BET
FOR INSERT, UPDATE
AS
BEGIN
    -- Kiểm tra nếu COIN_BET lớn hơn COIN của user
    IF EXISTS (
        SELECT 1
        FROM INSERTED i
        JOIN CUSTOMER c ON i.ID_CUSTOMER = c.ID_CUSTOMER
        WHERE i.COIN_BET > c.COIN
    )
    BEGIN
        RAISERROR ('COIN_BET must be less than or equal to COIN of the user.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Trừ số COIN_BET từ COIN của user
    UPDATE c
    SET c.COIN = c.COIN - i.COIN_BET
    FROM CUSTOMER c
    JOIN INSERTED i ON c.ID_CUSTOMER = i.ID_CUSTOMER;
END;
GO

CREATE TRIGGER trgUpdateMatchScore
ON MATCH
FOR UPDATE
AS
BEGIN
    -- Kiểm tra nếu tỉ số teamoneScore và teamtwoScore trùng khớp với dự đoán của người dùng
    IF EXISTS (
        SELECT 1
        FROM INSERTED i
        JOIN BET b ON i.matchID = b.matchID
        WHERE i.teamoneScore = b.T1Score_predict AND i.teamtwoScore = b.T2Score_predict
    )
    BEGIN
        -- Cộng số COIN_BET * 2 vào COIN của người dùng
        UPDATE c
        SET c.COIN = c.COIN + (2 * b.COIN_BET)
        FROM CUSTOMER c
        JOIN BET b ON c.ID_CUSTOMER = b.ID_CUSTOMER
        JOIN INSERTED i ON b.matchID = i.matchID
        WHERE i.teamoneScore = b.T1Score_predict AND i.teamtwoScore = b.T2Score_predict;
    END
END;
GO

CREATE TRIGGER trgCheckAndSetCoin
ON CUSTOMER
FOR INSERT, UPDATE
AS
BEGIN
    -- Kiểm tra nếu có bản ghi có COIN nhỏ hơn 0
    IF EXISTS (
        SELECT 1
        FROM INSERTED
        WHERE COIN < 0
    )
    BEGIN
        RAISERROR ('COIN must be greater than or equal to 0.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
    
    -- Cập nhật COIN thành 0 nếu COIN là NULL
    UPDATE CUSTOMER
    SET COIN = 50
    FROM CUSTOMER c
    JOIN INSERTED i ON c.ID_CUSTOMER = i.ID_CUSTOMER
    WHERE i.COIN IS NULL;
END;
GO

CREATE TRIGGER CheckNumberOfMatch
ON CHITIETTRANDAU
FOR INSERT, UPDATE
AS
BEGIN
    -- Kiểm tra nếu numberOfMatch lớn hơn tổng teamoneScore và teamtwoScore
    IF EXISTS (
        SELECT 1
        FROM INSERTED i
        JOIN MATCH m ON i.matchID = m.matchID
        WHERE i.numberOfMatch > (m.teamoneScore + m.teamtwoScore)
    )
    BEGIN
        RAISERROR ('numberOfMatch must be less equal than the total of teamoneScore and teamtwoScore in the MATCH table.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

CREATE TRIGGER CheckMatchScore 
ON MATCH
AFTER INSERT, UPDATE
AS
BEGIN
    -- Kiểm tra ràng buộc cho mỗi hàng được chèn hoặc cập nhật trong bảng MATCH
    IF EXISTS (
        SELECT 1
        FROM INSERTED i
        JOIN MATCH m ON i.matchID = m.matchID
        JOIN MATCHTYPE mt ON m.matchtypeID = mt.matchtypeID
        WHERE (i.teamoneScore + i.teamtwoScore) > mt.matchtypeQuantity
    )
    BEGIN
        RAISERROR ('Tổng điểm đội 1 và điểm đội 2 phải bé hơn hoặc bằng matchtypeQuantity.', 16, 1)
        ROLLBACK TRANSACTION
    END
END;

go

CREATE TRIGGER CheckTeamIDs
ON MATCH
FOR INSERT, UPDATE
AS
BEGIN
    -- Kiểm tra nếu teamoneID không xuất hiện trong bảng TEAM_ESPORT_SEASON
    IF EXISTS (
        SELECT 1
        FROM INSERTED i
        LEFT JOIN TEAM_ESPORT_SEASON t1 ON i.teamoneID = t1.teamID
        WHERE t1.teamID IS NULL
    )
    BEGIN
        RAISERROR ('TeamoneID must exist in TEAM_ESPORT_SEASON.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Kiểm tra nếu teamtwoID không xuất hiện trong bảng TEAM_ESPORT_SEASON
    IF EXISTS (
        SELECT 1
        FROM INSERTED i
        LEFT JOIN TEAM_ESPORT_SEASON t2 ON i.teamtwoID = t2.teamID
        WHERE t2.teamID IS NULL
    )
    BEGIN
        RAISERROR ('TeamtwoID must exist in TEAM_ESPORT_SEASON.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO



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
CREATE PROCEDURE PRINT_TT_PLAYER (@playerID INT)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM PLAYER WHERE playerID = @playerID)
    BEGIN
        SELECT P.playerName AS 'TÊN TUYỂN THỦ',
               P.playerBirthDate AS 'NGÀY SINH',
               P.playerHomeTown AS 'QUÊ QUÁN',
               T.teamName AS 'TÊN TEAM',
               PT.playerRole AS 'VỊ TRÍ THAM GIA',
               PT.DateStart AS 'NGÀY BẮT ĐẦU THI ĐẤU',
               PT.DateEnd AS 'NGÀY KẾT THÚC THI ĐẤU'
        FROM PLAYER P
        JOIN PLAYER_TEAM_ESPORT PT ON P.playerID = PT.playerID
        JOIN TEAM_ESPORT T ON PT.teamID = T.teamID
        WHERE P.playerID=@playerID;
    END
    ELSE
    BEGIN
        PRINT N'KHÔNG TÌM THẤY TUYỂN THỦ';
    END
END;
GO

CREATE PROCEDURE PRINT_TT_PLAYER_THIDAU (@playerID INT)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM PLAYER WHERE playerID = @playerID)
    BEGIN
        SELECT P.playerName AS 'TÊN TUYỂN THỦ',
               PT.NickName AS 'Nickname',
               M.matchDate AS 'NGÀY THI ĐẤU',
			   T.teamName AS 'Tên đội 1',
			   T2.teamName as 'Tên đội 2',
               C.championName AS 'VỊ TƯỚNG SỬ DỤNG',
               PM.playerKill AS 'SỐ LẦN HẠ GỤC ĐỐI PHƯƠNG',
               PM.playerDie AS 'SỐ LẦN BỊ HẠ GỤC',
               PM.playerSupport AS 'SỐ LẦN HỖ TRỢ ĐỒNG ĐỘI'
        FROM PLAYER P
        JOIN CHITIETTRANDAU PM ON P.playerID = PM.playerID
        JOIN MATCH M ON PM.matchID = M.matchID
		JOIN Champion C ON PM.championID=C.championID 
		JOIN PLAYER_TEAM_ESPORT PT ON P.playerID=PT.playerID
		JOIN TEAM_ESPORT T ON M.teamoneID=T.teamID
		JOIN TEAM_ESPORT T2 ON M.teamtwoID=T2.teamID
        WHERE P.playerID = @playerID;
    END
    ELSE
    BEGIN
        PRINT N'KHÔNG TÌM THẤY TUYỂN THỦ';
    END
END;
GO
/*In ra thứ hạng của đội có số điểm nằm trong top 10(BXH) TRONG CAC MUA GIAI */
go
CREATE PROC BXH_SEASON @season_name NVARCHAR(100)
AS
BEGIN
-- Kiểm tra xem tên mùa giải (@season_name) có tồn tại trong bảng SEASON hay không
	IF EXISTS (SELECT * FROM SEASON WHERE seasonName = @season_name)
	BEGIN
	 -- Nếu tồn tại, lấy thông tin xếp hạng của các đội trong mùa giải đó
		SELECT ROW_NUMBER() OVER (ORDER BY TES.TEAMTOTALSCORE DESC) AS 'RANKING',
			   T.TEAMNAME ,
			   TES.TEAMTOTALSCORE 
		FROM TEAM_ESPORT_SEASON tes, TEAM_ESPORT t, SEASON S
		WHERE tes.teamID = t.teamID AND TES.SEASONID = S.SEASONID AND S.seasonName = @season_name
		GROUP BY T.TEAMNAME ,TES.TEAMTOTALSCORE,S.SEASONNAME
		ORDER BY TES.TEAMTOTALSCORE DESC
	END

END

go
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

CREATE PROCEDURE SP_LICH_THI_DAU (@seasonName NVARCHAR(100))
AS
BEGIN
    -- Kiểm tra xem mùa giải có tồn tại hay không
    IF EXISTS (SELECT * FROM SEASON WHERE seasonName = @seasonName)
    BEGIN
        -- Xuất ra lịch thi đấu
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

--Phan Quyen--
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


--employee role
GRANT SELECT, INSERT, UPDATE(playerName,playerBirthDate,playerHomeTown,playerStatus),DELETE ON PLAYER TO employee_role
GRANT SELECT, INSERT, UPDATE,DELETE ON PLAYER_TEAM_ESPORT TO employee_role
GRANT SELECT, INSERT, UPDATE(teamName,teamYearEstablished,teamLogo),DELETE ON TEAM_ESPORT TO employee_role
GRANT SELECT, INSERT, UPDATE,DELETE ON  MATCH  TO employee_role
GRANT SELECT, INSERT, UPDATE,DELETE ON STADIUM TO employee_role
GRANT SELECT, INSERT, UPDATE,DELETE ON SEASON TO employee_role
GRANT SELECT, INSERT, UPDATE,DELETE ON MATCHTYPE TO employee_role
GRANT SELECT, INSERT, UPDATE,DELETE ON CHITIETTRANDAU TO employee_role
GRANT SELECT, INSERT, UPDATE,DELETE ON TEAM_ESPORT_SEASON TO employee_role
--Store procedures
GRANT EXECUTE ON PRINT_TT_PLAYER TO employee_role
GRANT EXECUTE ON BXH_SEASON TO employee_role
GRANT EXECUTE ON SP_LICH_THI_DAU TO employee_role
--Function
GRANT SELECT ON FC_IN_THONG_TIN_DOI TO employee_role
GRANT SELECT ON FC_SL_TUONG TO employee_role

--user role
GRANT SELECT ON PLAYER to user_role
GRANT SELECT ON PLAYER_TEAM_ESPORT to user_role
GRANT SELECT ON TEAM_ESPORT to user_role
GRANT SELECT ON MATCH to user_role
GRANT SELECT ON STADIUM to user_role
GRANT SELECT ON SEASON to user_role
GRANT SELECT ON MATCHTYPE to user_role
GRANT SELECT ON CHITIETTRANDAU to user_role
GRANT SELECT ON TEAM_ESPORT_SEASON to user_role
--Store procedures
GRANT EXECUTE ON PRINT_TT_PLAYER TO user_role
GRANT EXECUTE ON BXH_SEASON TO user_role
GRANT EXECUTE ON SP_LICH_THI_DAU TO user_role
--Function
GRANT SELECT ON FC_IN_THONG_TIN_DOI TO user_role
GRANT SELECT ON FC_SL_TUONG TO user_role

--view


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
	SELECT TEAMNAME, NICKNAME, PLAYERNAME, playerRole, DATESTART, DATEEND
	FROM TEAM_ESPORT TE, PLAYER_TEAM_ESPORT PTE, PLAYER P
	WHERE TE.TEAMID = PTE.TEAMID AND PTE.PLAYERID = P.PLAYERID
GO

drop view RankingsBySeason
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

CREATE OR REPLACE VIEW THONGTINTEAMSPORT
AS
	SELECT TEAM_ESPORT.teamID, teamName, teamYearEstablished,TEAM_ESPORT_SPONSOR.teamSponsor, teamLogo
    FROM TEAM_ESPORT,TEAM_ESPORT_SPONSOR
	WHERE TEAM_ESPORT.teamID=TEAM_ESPORT_SPONSOR.teamID
go
SELECT * FROM THONGTINTEAMSPORT

go

CREATE OR REPLACE VIEW USERS 
AS
	SELECT  FAVOR, USERBIRTH, EMAIL, USERNAME, COIN
	FROM USERS
GO

--LICH SU CA CUOC

CREATE OR REPLACE VIEW BET88
AS
	SELECT ID_BET, ID_CUS, ID_MATCH, T1_PREDICT, T2_PREDICT, COIN_NUM, DAY_BET 
	FROM BET, CUSTOMER
	WHERE BET.ID_CUS = CUSTOMER.ID_CUS
GO


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

GO

CREATE PROCEDURE CalculateWinRateRecentMatches
    @TeamID INT
AS
BEGIN
    -- Declare variables
    DECLARE @TotalMatches INT;
    DECLARE @TotalWins INT;
    DECLARE @WinRate DECIMAL(10, 4);

    -- Calculate the total number of matches and wins for the team
    SELECT 
        @TotalMatches = COUNT(*),
        @TotalWins = SUM(CASE WHEN (teamoneID = @TeamID AND teamoneScore > teamtwoScore) OR (teamtwoID = @TeamID AND teamtwoScore > teamoneScore) THEN 1 ELSE 0 END)
    FROM (
        SELECT TOP 5 * 
        FROM match 
        WHERE teamoneID = @TeamID OR teamtwoID = @TeamID
        ORDER BY matchDate DESC
    ) AS RecentMatches;

    -- Calculate the win rate
    IF @TotalMatches > 0
    BEGIN
        SET @WinRate = CAST(@TotalWins AS DECIMAL(10, 4)) / @TotalMatches;
    END
    ELSE
    BEGIN
        SET @WinRate = 0; -- Set win rate to 0 if there are no matches
    END;

    -- Return the win rate
    SELECT @WinRate AS WinRate;
END;

EXEC CalculateWinRateRecentMatches @TeamID = 21; -- Thay đổi ID của đội cần tính tỉ lệ thắng

CREATE PROCEDURE GetTop5MatchResults
    @TeamOneID INT,
    @TeamTwoID INT
AS
BEGIN
    -- Truy vấn để lấy top 5 kết quả trận đấu
    SELECT TOP 5 
        T1.teamName AS TeamOneName,
        T2.teamName AS TeamTwoName,
        M.matchDate,
        CONCAT(M.teamoneScore, '-', M.teamtwoScore) AS Score
    FROM 
        [match] M
    INNER JOIN 
        TEAM_ESPORT T1 ON M.teamoneID = T1.teamID
    INNER JOIN 
        TEAM_ESPORT T2 ON M.teamtwoID = T2.teamID
    WHERE 
        (M.teamoneID = @TeamOneID AND M.teamtwoID = @TeamTwoID)
        OR
        (M.teamoneID = @TeamTwoID AND M.teamtwoID = @TeamOneID)
    ORDER BY 
        M.matchDate DESC;
END;

EXEC GetTop5MatchResults @TeamOneID = 22, @TeamTwoID = 21;

select * from TEAM_ESPORT;
