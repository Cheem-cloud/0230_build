import SwiftUI
@preconcurrency import FirebaseStorage

// Extension for Firebase Storage functions
extension Storage {
    
    // New utility function to handle image uploads in a more reliable way
    static func uploadImage(uiImage: UIImage, path: String) async throws -> URL {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imageRef = storageRef.child(path)
        
        print("DEBUG: Preparing to upload image to path: \(path)")
        
        // Compress the image to reasonable size
        let maxSize: CGFloat = 800
        let scaleFactor = min(maxSize/uiImage.size.width, maxSize/uiImage.size.height, 1.0)
        let scaledSize = CGSize(width: uiImage.size.width * scaleFactor, height: uiImage.size.height * scaleFactor)
        
        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        let scaledImageData = renderer.jpegData(withCompressionQuality: 0.7) { context in
            uiImage.draw(in: CGRect(origin: .zero, size: scaledSize))
        }
        
        print("DEBUG: Image scaled from \(uiImage.size) to \(scaledSize), data size: \(scaledImageData.count) bytes")
        
        // Create metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Use a local copy for capture in the continuation
        let imageRefCopy = imageRef
        
        // Upload with progress monitoring
        print("DEBUG: Starting upload...")
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            let uploadTask = imageRefCopy.putData(scaledImageData, metadata: metadata)
            
            // Monitor upload progress
            uploadTask.observe(.progress) { snapshot in
                if let progress = snapshot.progress {
                    let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount) * 100
                    print("DEBUG: Upload progress: \(Int(percentComplete))%")
                }
            }
            
            // Handle success
            uploadTask.observe(.success) { snapshot in
                print("DEBUG: Upload succeeded!")
                
                // Delay slightly to ensure metadata is available
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    imageRefCopy.downloadURL { url, error in
                        if let error = error {
                            print("DEBUG: Error getting download URL: \(error.localizedDescription)")
                            continuation.resume(throwing: error)
                            return
                        }
                        
                        if let downloadURL = url {
                            print("DEBUG: Got download URL: \(downloadURL.absoluteString)")
                            continuation.resume(returning: downloadURL)
                        } else {
                            print("DEBUG: Download URL was nil")
                            continuation.resume(throwing: NSError(domain: "com.cheemhang.storage", 
                                                                 code: 1, 
                                                                 userInfo: [NSLocalizedDescriptionKey: "Download URL was nil"]))
                        }
                    }
                }
            }
            
            // Handle failures
            uploadTask.observe(.failure) { snapshot in
                if let error = snapshot.error {
                    print("DEBUG: Upload failed: \(error.localizedDescription)")
                    print("DEBUG: Full error: \(error)")
                    
                    // Get more detailed information about the error
                    if let storageError = error as? StorageError {
                        print("DEBUG: Storage error: \(storageError)")
                        
                        // Access error code properly, or use different approach for error type
                        if let nsError = error as NSError? {
                            print("DEBUG: Error domain: \(nsError.domain), code: \(nsError.code)")
                            
                            // Handle different error codes
                            switch nsError.code {
                            case 404:
                                print("DEBUG: The path doesn't exist or you don't have permission")
                            case 403:
                                print("DEBUG: User is not authorized to perform the operation")
                            case -999:
                                print("DEBUG: User canceled the operation")
                            case 413:
                                print("DEBUG: Quota exceeded")
                            case 401:
                                print("DEBUG: User is not authenticated")
                            default:
                                print("DEBUG: Other storage error: \(nsError.localizedDescription)")
                            }
                        }
                    }
                    
                    continuation.resume(throwing: error)
                } else {
                    print("DEBUG: Upload failed with unknown error")
                    continuation.resume(throwing: NSError(domain: "com.cheemhang.storage", 
                                                          code: 2, 
                                                          userInfo: [NSLocalizedDescriptionKey: "Unknown upload error"]))
                }
            }
        }
    }
} 