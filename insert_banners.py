#!/usr/bin/env python3
import pyodbc
import uuid
from datetime import datetime, timedelta

# Connection string
conn_str = (
    'DRIVER={ODBC Driver 17 for SQL Server};'
    'SERVER=localhost,1433;'
    'DATABASE=RideSharingDb;'
    'UID=sa;'
    'PWD=Akhilesh@22;'
    'TrustServerCertificate=yes;'
)

try:
    # Connect to database
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    
    print("✅ Connected to database")
    
    # Banner 1
    cursor.execute("""
        INSERT INTO Banners 
        (Id, Title, Description, ImageUrl, ActionType, DisplayOrder, StartDate, EndDate, IsActive, TargetAudience, ImpressionCount, ClickCount, CreatedAt, UpdatedAt)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, 
    str(uuid.uuid4()),
    'Welcome to VanYatra! 🚐',
    'Book your comfortable ride today. Safe, reliable, and affordable transportation.',
    'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=800&q=80',
    'none',
    1,
    datetime.utcnow(),
    datetime.utcnow() + timedelta(days=365),
    True,
    'passenger',
    0,
    0,
    datetime.utcnow(),
    datetime.utcnow()
    )
    print("✅ Banner 1 created")
    
    # Banner 2
    cursor.execute("""
        INSERT INTO Banners 
        (Id, Title, Description, ImageUrl, ActionType, ActionText, DisplayOrder, StartDate, EndDate, IsActive, TargetAudience, ImpressionCount, ClickCount, CreatedAt, UpdatedAt)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """,
    str(uuid.uuid4()),
    'Special Offer! 🎉',
    'Get 20% off on your next 3 rides. Limited time offer for new passengers.',
    'https://images.unsplash.com/photo-1519003722824-194d4455a60c?w=800&q=80',
    'none',
    'Book Now',
    2,
    datetime.utcnow(),
    datetime.utcnow() + timedelta(days=90),
    True,
    'passenger',
    0,
    0,
    datetime.utcnow(),
    datetime.utcnow()
    )
    print("✅ Banner 2 created")
    
    conn.commit()
    
    # Verify
    cursor.execute("SELECT COUNT(*) FROM Banners WHERE IsActive = 1 AND TargetAudience IN ('passenger', 'all')")
    count = cursor.fetchone()[0]
    print(f"📊 Total active passenger banners: {count}")
    
    cursor.close()
    conn.close()
    
except Exception as e:
    print(f"❌ Error: {e}")
