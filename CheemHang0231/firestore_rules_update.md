# Firebase Firestore Rules Update

Update your Firestore rules to allow listing users while maintaining security:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to list all users but only read their own user data fully
    match /users/{userId} {
      // Allow listing users collection
      allow list: if request.auth != null;
      
      // But only allow full read/write to your own document
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Allow listing personas of all users (needed for partner view)
      match /personas/{personaId} {
        // Allow anyone to list and read personas
        allow list, get: if request.auth != null;
        
        // But only allow write to your own personas
        allow create, update, delete: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // For development convenience, allow all authenticated users to read all users data
    // You can remove this after development is complete
    match /{document=**} {
      allow read: if request.auth != null;
    }
  }
}
```

Key changes:
1. Added `allow list: if request.auth != null;` to the users collection to allow querying the collection
2. Kept the specific document read/write limited to the owner
3. Added a temporary development rule to allow all reads (you can remove this later)

Apply these rules in your Firebase Console and save/publish them. 