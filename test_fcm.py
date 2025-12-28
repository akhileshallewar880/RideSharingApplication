#!/usr/bin/env python3
"""
Direct FCM API Test Script
Tests push notifications by calling Firebase Cloud Messaging API directly
"""

import json
import sys
import requests
import google.auth.transport.requests
from google.oauth2 import service_account

# Configuration
SERVICE_ACCOUNT_KEY_PATH = './server/ride_sharing_application/RideSharing.API/serviceAccountKey.json'
PROJECT_ID = 'vanyatra-69e38'

def get_access_token():
    """Generate OAuth 2.0 access token from service account key"""
    print('🔑 Loading service account key...')
    
    with open(SERVICE_ACCOUNT_KEY_PATH, 'r') as f:
        service_account_info = json.load(f)
    
    credentials = service_account.Credentials.from_service_account_info(
        service_account_info,
        scopes=['https://www.googleapis.com/auth/firebase.messaging']
    )
    
    print('🔄 Refreshing access token...')
    credentials.refresh(google.auth.transport.requests.Request())
    
    print('✅ Access token obtained')
    return credentials.token

def send_test_notification(fcm_token, access_token):
    """Send test notification via FCM API"""
    
    url = f'https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send'
    
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    payload = {
        "message": {
            "token": fcm_token,
            "notification": {
                "title": "🧪 Direct FCM Test",
                "body": "If you see this, FCM is working correctly!"
            },
            "data": {
                "type": "test",
                "source": "direct_api_call"
            },
            "android": {
                "priority": "high",
                "notification": {
                    "channel_id": "allapalli_ride_channel",
                    "sound": "default",
                    "default_sound": True,
                    "default_vibrate_timings": True,
                    "notification_priority": "PRIORITY_HIGH"
                }
            },
            "apns": {
                "payload": {
                    "aps": {
                        "alert": {
                            "title": "🧪 Direct FCM Test",
                            "body": "If you see this, FCM is working correctly!"
                        },
                        "sound": "default"
                    }
                }
            }
        }
    }
    
    print(f'📤 Sending notification to: {fcm_token[:30]}...')
    print(f'📍 Endpoint: {url}')
    
    response = requests.post(url, headers=headers, json=payload)
    
    print(f'\n📊 Response Status: {response.status_code}')
    
    if response.status_code == 200:
        print('✅ SUCCESS! Notification sent successfully!')
        print(f'📨 Message ID: {response.json().get("name", "N/A")}')
        return True
    else:
        print('❌ FAILED! Notification not sent')
        print(f'Error: {response.text}')
        return False

def main():
    print('=' * 60)
    print('🧪 FCM Direct API Test')
    print('=' * 60)
    print()
    
    if len(sys.argv) < 2:
        print('❌ Usage: python3 test_fcm.py <FCM_TOKEN>')
        print()
        print('Example:')
        print('  python3 test_fcm.py f_EVajcJT3qDwTv7M0eg...')
        print()
        print('💡 Tip: Get FCM token from backend logs when booking is created')
        print('   Look for: "📱 Sending booking confirmation to FCM token: ..."')
        sys.exit(1)
    
    fcm_token = sys.argv[1]
    
    try:
        # Get OAuth token
        access_token = get_access_token()
        
        print()
        print('-' * 60)
        print()
        
        # Send test notification
        success = send_test_notification(fcm_token, access_token)
        
        print()
        print('-' * 60)
        print()
        
        if success:
            print('🎉 Test completed successfully!')
            print('📱 Check your device for the notification')
            print()
            print('If you received the notification:')
            print('  ✅ FCM token is valid')
            print('  ✅ Firebase configuration is correct')
            print('  ✅ Backend is sending correctly')
            print('  ➡️  Issue is likely in the mobile app receiving/displaying')
            print()
            print('If you did NOT receive the notification:')
            print('  ❌ FCM token may be invalid or expired')
            print('  ❌ Device may have notifications disabled')
            print('  ❌ App may not be registered correctly with Firebase')
        else:
            print('⚠️  Test failed - check error message above')
            
    except FileNotFoundError:
        print(f'❌ Error: Service account key not found at: {SERVICE_ACCOUNT_KEY_PATH}')
        sys.exit(1)
    except Exception as e:
        print(f'❌ Error: {str(e)}')
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    main()
