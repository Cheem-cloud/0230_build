import SwiftUI
import Firebase
import FirebaseAuth
import GoogleSignIn

class GoogleCalendarViewModel: ObservableObject {
    @Published var isConnecting = false
    @Published var isCalendarConnected = false
    @Published var error: Error?
    
    private let calendarService = CalendarService.shared
    
    init() {
        Task {
            await checkCalendarConnection()
        }
    }
    
    @MainActor
    func checkCalendarConnection() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        self.isCalendarConnected = await calendarService.hasCalendarAccess(for: userId)
    }
    
    @MainActor
    func connectCalendar() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            error = NSError(domain: "com.cheemhang.calendar", code: 401, 
                    userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            return
        }
        
        isConnecting = true
        
        do {
            try await calendarService.authenticateAndSaveCalendarAccess(for: userId)
            await checkCalendarConnection() // Refresh connection status
            print("Successfully connected to Google Calendar")
        } catch {
            print("Error connecting to Google Calendar: \(error.localizedDescription)")
            self.error = error
        }
        
        isConnecting = false
    }
    
    @MainActor
    func disconnectCalendar() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isConnecting = true
        
        do {
            // Remove token from Firestore
            let db = Firestore.firestore()
            let docRef = db.collection("users").document(userId).collection("tokens").document("calendar")
            try await docRef.delete()
            
            // Sign out of Google (but maintain Firebase auth)
            GIDSignIn.sharedInstance.signOut()
            
            isCalendarConnected = false
            print("Successfully disconnected from Google Calendar")
        } catch {
            print("Error disconnecting from Google Calendar: \(error.localizedDescription)")
            self.error = error
        }
        
        isConnecting = false
    }
}

struct GoogleCalendarAuthView: View {
    @StateObject private var viewModel = GoogleCalendarViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "calendar")
                    .font(.system(size: 80))
                    .foregroundColor(.hunterGreen)
                    .padding(.bottom, 20)
                
                Text("Google Calendar Integration")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Connect your Google Calendar to easily check availability and schedule hangouts.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                if viewModel.isCalendarConnected {
                    // Calendar is connected
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Calendar Connected")
                            .font(.headline)
                        
                        Text("Your Google Calendar is connected. We'll use it to check your availability and schedule hangouts.")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button {
                            Task {
                                await viewModel.disconnectCalendar()
                            }
                        } label: {
                            Text("Disconnect Calendar")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                } else {
                    // Calendar is not connected
                    VStack(spacing: 16) {
                        Text("Your calendar is not connected")
                            .font(.headline)
                        
                        Text("Connect your calendar to automatically check availability when scheduling hangouts.")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button {
                            Task {
                                await viewModel.connectCalendar()
                            }
                        } label: {
                            HStack {
                                Text("Connect Google Calendar")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.hunterGreen)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                }
                
                Spacer()
                
                if viewModel.isConnecting {
                    ProgressView("Processing...")
                        .padding()
                }
            }
            .padding()
            .navigationTitle("Calendar Connection")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
        }
    }
}

#Preview {
    GoogleCalendarAuthView()
} 