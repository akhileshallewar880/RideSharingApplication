#!/bin/bash

echo "🔍 Admin Login Diagnostic Tool"
echo "================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "📋 Checking admin user in database..."
echo ""

# Create temporary SQL file
cat > /tmp/check_admin_detailed.sql << 'EOF'
-- Check admin user details
SELECT 
    'User Exists' as CheckType,
    CASE WHEN COUNT(*) > 0 THEN 'PASS ✅' ELSE 'FAIL ❌' END as Status
FROM Users 
WHERE Email = 'admin@vanyatra.com'

UNION ALL

SELECT 
    'UserType is admin' as CheckType,
    CASE WHEN COUNT(*) > 0 THEN 'PASS ✅' ELSE 'FAIL ❌' END as Status
FROM Users 
WHERE Email = 'admin@vanyatra.com' AND UserType = 'admin'

UNION ALL

SELECT 
    'Is Active' as CheckType,
    CASE WHEN COUNT(*) > 0 THEN 'PASS ✅' ELSE 'FAIL ❌' END as Status
FROM Users 
WHERE Email = 'admin@vanyatra.com' AND IsActive = 1

UNION ALL

SELECT 
    'Not Blocked' as CheckType,
    CASE WHEN COUNT(*) > 0 THEN 'PASS ✅' ELSE 'FAIL ❌' END as Status
FROM Users 
WHERE Email = 'admin@vanyatra.com' AND IsBlocked = 0

UNION ALL

SELECT 
    'Has Password Hash' as CheckType,
    CASE WHEN COUNT(*) > 0 THEN 'PASS ✅' ELSE 'FAIL ❌' END as Status
FROM Users 
WHERE Email = 'admin@vanyatra.com' AND PasswordHash IS NOT NULL;

-- Show user details
SELECT 
    '================================' as Separator;

SELECT 
    'ADMIN USER DETAILS' as Info;

SELECT 
    Id,
    Email,
    PhoneNumber,
    UserType,
    IsActive,
    IsBlocked,
    IsPhoneVerified,
    IsEmailVerified,
    LEFT(PasswordHash, 30) as PasswordHashPreview,
    CreatedAt
FROM Users 
WHERE Email = 'admin@vanyatra.com';
EOF

echo "SQL diagnostic file created"
echo ""
echo "To run the diagnostic, execute:"
echo ""
echo -e "${YELLOW}sqlcmd -S YOUR_SERVER.database.windows.net -d RideSharingDb -U YOUR_USER -P YOUR_PASSWORD -i /tmp/check_admin_detailed.sql${NC}"
echo ""
echo "Or use Azure Data Studio to run: /tmp/check_admin_detailed.sql"
echo ""
echo "================================"
echo ""
echo "📝 Test admin login via API:"
echo ""
echo -e "${GREEN}curl -X POST http://YOUR_SERVER:5056/api/v1/admin/auth/login \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"email\":\"admin@vanyatra.com\",\"password\":\"Admin@123\"}'${NC}"
echo ""
echo "================================"
echo ""
echo "❌ If admin login still fails, run:"
echo -e "${YELLOW}sqlcmd -S YOUR_SERVER -d RideSharingDb -U YOUR_USER -P YOUR_PASSWORD -i fix-admin-login.sql${NC}"
echo ""
