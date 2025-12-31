-- Fix email UNIQUE constraint to allow multiple NULL values
-- This allows users to register without email (NULL) but prevents duplicate non-NULL emails
USE RideSharingDb;
GO

SET QUOTED_IDENTIFIER ON;
GO

-- Drop the existing UNIQUE constraint that doesn't allow multiple NULLs
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'UK_Users_Email' AND type = 'UQ')
BEGIN
    ALTER TABLE [dbo].[Users] DROP CONSTRAINT [UK_Users_Email];
    PRINT 'Dropped UK_Users_Email constraint';
END
ELSE
    PRINT 'UK_Users_Email constraint does not exist';
GO

-- Create a filtered unique index that only applies to non-NULL emails
-- This allows multiple NULL emails but prevents duplicate non-NULL emails
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'UX_Users_Email_NotNull' AND object_id = OBJECT_ID('Users'))
BEGIN
    CREATE UNIQUE INDEX [UX_Users_Email_NotNull] 
    ON [dbo].[Users]([Email]) 
    WHERE [Email] IS NOT NULL;
    PRINT 'Created filtered unique index UX_Users_Email_NotNull';
END
ELSE
    PRINT 'Filtered unique index UX_Users_Email_NotNull already exists';
GO

PRINT 'Email constraint fix completed! Multiple users can now have NULL emails.';
GO
