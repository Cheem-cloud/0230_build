# Firebase Cloud Functions for CheemHang

This directory contains the Firebase Cloud Functions necessary for CheemHang's push notification system.

## Functions Included

1. **ping** - A simple function to test connectivity
2. **sendPushNotification** - Manually sends push notifications (called from app)
3. **onNewHangout** - Automatically sends notifications when new hangouts are created
4. **onHangoutUpdate** - Automatically sends notifications when hangout status changes

## Deployment Instructions

### Prerequisites

1. Install Node.js (v14 or later recommended)
2. Install Firebase CLI:
   ```
   npm install -g firebase-tools
   ```

### Steps to Deploy

1. **Login to Firebase**
   ```
   firebase login
   ```

2. **Initialize Firebase (if you haven't connected to your project yet)**
   ```
   firebase use --add
   ```
   Then select your project.

3. **Install Dependencies**
   ```
   cd functions
   npm install
   ```

4. **Deploy the Functions**
   ```
   firebase deploy --only functions
   ```

## Testing

After deployment, you can test if the functions are working:

1. In the CheemHang app, press the "Test Notification" button to test connectivity with the `ping` function.
2. Create a new hangout to test the automatic notifications.

## Logs

To view the logs from your functions:
```
firebase functions:log
```

## Troubleshooting

If you encounter issues:

1. Ensure your Firebase project has the Blaze (pay-as-you-go) plan activated. Cloud Functions require a Blaze plan.
2. Check that your Firebase Admin SDK is properly configured.
3. Verify your APNs certificate is correctly set up in Firebase Console.
4. Check the logs for any errors using `firebase functions:log`. 