# Firebase Firestore Rules Update

You need to update your Firestore security rules. Currently, your app is unable to read/write to the Firestore database because of permission restrictions.

1. Go to your Firebase Console: https://console.firebase.google.com/
2. Select your project (CheemCore) 
3. Go to Firestore Database in the left navigation menu
4. Click on the "Rules" tab
5. Replace your current rules with the following:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read and write their own user data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Allow users to read and write their own personas
      match /personas/{personaId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // For development only - you'll want to tighten this later
    // match /{document=**} {
    //   allow read, write: if request.auth != null;
    // }
  }
}
```

6. Click "Publish" to apply the rules

These rules allow authenticated users to:
- Read/write their own user document
- Read/write their own persona documents

After updating these rules, you should be able to create and manage personas in your app. 