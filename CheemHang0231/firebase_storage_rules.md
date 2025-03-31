# Firebase Storage Rules Update

Your image uploads are failing because of Firebase Storage rules restrictions. Here's how to update them:

1. Go to your Firebase Console: https://console.firebase.google.com/
2. Select your project (CheemCore)
3. Go to Storage in the left navigation menu
4. Click on the "Rules" tab
5. Replace your current rules with the following:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow read/write access to all users under any path
    match /{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // More specific rules for personas images
    match /personas/{imageId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // User-specific images
    match /users/{userId}/{allImages=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Images folder
    match /images/{allImages=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

6. Click "Publish" to apply the rules

These rules allow any authenticated user to read/write images, which is appropriate for your app's current needs. Once your app grows, you might want to implement more restrictive rules.

The most common issue with Firebase Storage is having overly restrictive rules that prevent uploading or retrieving download URLs. 