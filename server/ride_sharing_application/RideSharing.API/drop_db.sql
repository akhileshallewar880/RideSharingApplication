-- Set database to single user mode to disconnect all users
ALTER DATABASE RideSharingDb SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

-- Drop the database
DROP DATABASE RideSharingDb;
GO
