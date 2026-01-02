-- Fix Users Email unique constraint to allow multiple NULL values
-- The current UK_Users_Email constraint doesn't allow multiple NULLs
-- We'll drop it and create a filtered unique index that ignores NULLs

USE RideSharingDb;
GO

-- Drop the existing unique constraint
ALTER TABLE Users DROP CONSTRAINT UK_Users_Email;
GO

-- Set required options for filtered index
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- Create a filtered unique index that allows multiple NULLs
-- This index only enforces uniqueness for non-NULL email values
CREATE UNIQUE NONCLUSTERED INDEX UX_Users_Email 
ON Users(Email) 
WHERE Email IS NOT NULL;
GO

-- Verify the change
SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique AS IsUnique,
    i.filter_definition AS FilterDefinition
FROM sys.indexes i
INNER JOIN sys.objects o ON i.object_id = o.object_id
WHERE o.name = 'Users' AND i.name LIKE '%Email%';
GO

PRINT 'Email constraint fixed - now allows multiple NULL values';
GO
