import SwiftUI

struct HangoutsView: View {
    @StateObject private var viewModel = HangoutsViewModel()
    @State private var showCreationSheet = false
    @State private var showDetails = false
    @State private var selectedHangout: Hangout?

    var body: some View {
        VStack {
            if viewModel.hangouts.isEmpty {
                Text("No hangouts available")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.hangouts) { hangout in
                            HangoutCard(hangout: hangout, onTap: {
                                selectedHangout = hangout
                                showDetails = true
                            })
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .refreshable {
                    await viewModel.fetchHangouts()
                }
            }
        }
        .navigationTitle("Hangouts")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showCreationSheet = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.mutedGold)
                }
            }
        }
        .sheet(isPresented: $showCreationSheet) {
            HangoutFormView(isPresented: $showCreationSheet)
        }
        .sheet(isPresented: $showDetails, onDismiss: {
            selectedHangout = nil
        }) {
            if let hangout = selectedHangout {
                HangoutDetailView(hangout: hangout)
            }
        }
    }
}

struct HangoutsView_Previews: PreviewProvider {
    static var previews: some View {
        HangoutsView()
    }
} 