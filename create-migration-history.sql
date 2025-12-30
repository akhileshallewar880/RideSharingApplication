-- Create __EFMigrationsHistory table
-- This table tells Entity Framework Core which migrations have been applied
-- CRITICAL: Without this table, EF Core will try to recreate all tables on every restart

CREATE TABLE [__EFMigrationsHistory] (
    [MigrationId] NVARCHAR(150) NOT NULL,
    [ProductVersion] NVARCHAR(32) NOT NULL,
    CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
);

-- Insert all 11 existing migrations to mark them as applied
INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion]) VALUES
('20251113164941_InitialCreate', '9.0.8'),
('20251205073002_AddDocumentsAndSeatManagement', '9.0.8'),
('20251205093313_AddBannerAndNotificationModels', '9.0.8'),
('20251205173722_AddNameFieldsToUser', '9.0.8'),
('20251206075842_AddFullNameComputed', '9.0.8'),
('20251209141658_FixUserDocuments', '9.0.8'),
('20251221174000_AddOTPToBookings', '9.0.8'),
('20251223135832_AddDeletedAtFields', '9.0.8'),
('20251224183140_AddSeatingArrangementFields', '9.0.8'),
('20251226112846_AddDriverVehicleModelAndCityRelations', '9.0.8'),
('20251228174040_AddRouteSegmentsTable', '9.0.8');

-- Verify the migrations were inserted
SELECT COUNT(*) AS TotalMigrations FROM [__EFMigrationsHistory];
SELECT MigrationId, ProductVersion FROM [__EFMigrationsHistory] ORDER BY MigrationId;

PRINT 'Migration history table created successfully with 11 migrations!';
