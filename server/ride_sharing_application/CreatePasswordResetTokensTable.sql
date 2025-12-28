-- Create PasswordResetTokens table for forgot password functionality
-- Run this script on your RideSharingDb database

USE RideSharingDb;
GO

-- Check if table exists, if not create it
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PasswordResetTokens]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[PasswordResetTokens] (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
        [UserId] UNIQUEIDENTIFIER NOT NULL,
        [Token] NVARCHAR(10) NOT NULL,
        [ExpiresAt] DATETIME2(7) NOT NULL,
        [IsUsed] BIT NOT NULL DEFAULT 0,
        [CreatedAt] DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
        [UsedAt] DATETIME2(7) NULL,
        CONSTRAINT [FK_PasswordResetTokens_Users_UserId] FOREIGN KEY ([UserId]) 
            REFERENCES [dbo].[Users] ([Id]) ON DELETE CASCADE
    );

    CREATE NONCLUSTERED INDEX [IX_PasswordResetTokens_UserId] ON [dbo].[PasswordResetTokens] ([UserId]);
    CREATE NONCLUSTERED INDEX [IX_PasswordResetTokens_Token] ON [dbo].[PasswordResetTokens] ([Token]);
    CREATE NONCLUSTERED INDEX [IX_PasswordResetTokens_ExpiresAt] ON [dbo].[PasswordResetTokens] ([ExpiresAt]);

    PRINT '✅ PasswordResetTokens table created successfully';
END
ELSE
BEGIN
    PRINT '⚠️  PasswordResetTokens table already exists';
END
GO

-- Verify table creation
SELECT 
    TABLE_NAME, 
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME = 'PasswordResetTokens';
GO
