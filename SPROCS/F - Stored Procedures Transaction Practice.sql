--  Stored Procedures (Sprocs)
-- Practice using Transactions in a Stored Procedure

USE [A01-School]
GO

/*
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = N'PROCEDURE' AND ROUTINE_NAME = 'SprocName')
    DROP PROCEDURE SprocName
GO
CREATE PROCEDURE SprocName
    -- Parameters here
AS
    -- Body of procedure here
RETURN
GO
*/

-- 1. Create a stored procedure called DissolveClub that will accept a club id as its parameter. Ensure that the club exists before attempting to dissolve the club. You are to dissolve the club by first removing all the members of the club and then removing the club itself.
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = N'PROCEDURE' AND ROUTINE_NAME = 'DissolveClub')
    DROP PROCEDURE DissolveClub
GO
CREATE PROCEDURE DissolveClub
    -- Parameters here
    @ClubId varchar(10)

AS
    -- Body of procedure here

    IF @ClubId IS NULL
    BEGIN
        RAISERROR('ClubId is required', 16, 1)
    END
    ELSE
    BEGIN
        IF NOT EXISTS(SELECT ClubId FROM Club WHERE ClubId = @ClubId)
        BEGIN
            RAISERROR('That club does not exist', 16, 1)
        END
        ELSE
        BEGIN
            BEGIN TRANSACTION
            DELETE FROM Activity WHERE ClubId = @ClubId
            IF @@ERROR <> 0
            BEGIN
                ROLLBACK TRANSACTION
                RAISERROR('Unable to remove members from club', 16, 1)
            END
            ELSE
            BEGIN
                DELETE FROM Club WHERE ClubId = @ClubId
                IF @@ERROR <> 0 OR @@ROWCOUNT = 0
                BEGIN
                    ROLLBACK TRANSACTION
                    RAISERROR('Unable to delete club', 16, 1)
                END
                ELSE
                BEGIN
                    COMMIT TRANSACTION
                END
            END
        END
    END
RETURN
GO
SELECT * FROM Club C LEFT OUTER JOIN Activity A ON C.ClubId = A.ClubId

EXEC DissolveClub 'ACM'

GO
-- 2. Create a stored procedure called ArchivePayments. This stored procedure must transfer all payment records to the StudentPaymentArchive table. After archiving, delete the payment records.
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'StudentPaymentArchive')
    DROP TABLE StudentPaymentArchive

CREATE TABLE StudentPaymentArchive
(
    ArchiveId       int
        CONSTRAINT PK_StudentPaymentArchive
        PRIMARY KEY
        IDENTITY(1,1)
                                NOT NULL,
    StudentID       int         NOT NULL,
    FirstName       varchar(25) NOT NULL,
    LastName        varchar(35) NOT NULL,
    PaymentMethod   varchar(40) NOT NULL,
    Amount          money       NOT NULL,
    PaymentDate     datetime    NOT NULL
)
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ArchivePayments')
    DROP TABLE ArchivePayments

AS
    BEGIN TRANSACTION
    INSERT INTO StudentPaymentArchive(StudentID, FirstName, LastName, PaymentDate,PaymentMethod, Amount)
    SELECT  S.StudentID, FirstName, LastName, PaymentDate, PaymentTypeDescription, Amount
    FROM    Student S
        INNER JOIN Payment P ON S.StudentID = P.StudentID
        INNER JOIN PaymentType PT ON P.PaymentTypeID = PT.PaymentTypeID
    IF @@ERROR > 0
    BEGIN
        ROLLBACK TRANSACTION
        RAISERROR('Unable to archive payments', 16, 1)
    END
    ELSE
    BEGIN
    --Delete from Payment
        DELETE FROM Payment
        IF @@ERROR > 0
        BEGIN
            ROLLBACK TRANSACTION
            RAISERROR('Unable to delete payments after archiving', 16, 1)
        END
        ELSE
        BEGIN
            COMMIT TRANSACTION
        END
    END
RETURN
GO