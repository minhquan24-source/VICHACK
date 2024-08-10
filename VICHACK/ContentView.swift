import SwiftUI

@main
struct VICHACKApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// Custom struct to store spending data with date
struct Spending: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
}

struct ContentView: View {
    @State private var userResponse: String = ""
    @State private var navigateToLast7DaysView = false
    @State private var selectedDate = Date()  // State for DatePicker
    @State private var spendings = [Spending]() // Store spendings with date

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {  // VStack to stack elements vertically
                    // Calendar (DatePicker) at the top
                    DatePicker(
                        "Select a date",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(GraphicalDatePickerStyle()) // Graphical style for calendar look
                    .frame(maxWidth: .infinity) // Expand to fit screen width
                    .padding()

                    // Other content below the DatePicker
                    VStack {
                        Text("How much money did you spend today?")
                            .font(.title)
                            .padding()

                        TextField("Enter your answer here", text: $userResponse)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                            .onChange(of: userResponse) { newValue in
                                // Filter out any unwanted characters manually
                                let filtered = newValue.filter { "0123456789.".contains($0) }
                                if filtered != userResponse {
                                    userResponse = filtered
                                }
                            }

                        Button(action: {
                            if let amount = Double(userResponse) {
                                // Add spending to the list with the selected date
                                spendings.append(Spending(date: selectedDate, amount: amount))
                                // Trigger the navigation
                                navigateToLast7DaysView = true
                                submitAnswer(answer: userResponse)
                            }
                        }) {
                            Text("Submit")
                                .font(.headline)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .navigationDestination(isPresented: $navigateToLast7DaysView) {
                            Last7DaysView(spendings: filterLast7DaysSpendings())
                        }
                    }
                    .padding()
                }
                .padding()
            }
        }
    }

    // Function to filter spendings for the last 7 days
    func filterLast7DaysSpendings() -> [Spending] {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

        return spendings.filter { spending in
            spending.date >= sevenDaysAgo
        }
    }
}

func submitAnswer(answer: String) {
    guard let url = URL(string: "https://yourserver.com/api/submit") else { return }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = ["answer": answer]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error: \(error.localizedDescription)")
            return
        }

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            print("Success: Answer submitted!")
        } else {
            print("Failed: Unable to submit answer.")
        }
    }.resume()
}

struct Last7DaysView: View {
    var spendings: [Spending] // Received spendings data

    var body: some View {
        VStack {
            Text("Your Spendings Over the Last 7 Days")
                .font(.title)
                .padding()

            List(spendings) { spending in
                Text("Spent: $\(spending.amount, specifier: "%.2f") on \(formattedDate(spending.date))")
            }
            .padding()
        }
        .navigationTitle("Last 7 Days Spendings")
    }

    // Function to format the date
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

