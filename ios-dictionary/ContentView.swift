import SwiftUI
import Combine

struct ContentView: View {
    var body: some View {
        TabView {
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            
            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }
        }
        .font(.custom("Times New Roman", size: 18))
        .colorScheme(.dark)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct SearchView: View {
    @State private var searchText = ""
    @State private var definitions: [Definition] = []
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack {
                TextField("Enter word", text: $searchText)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Search") {
                    searchWord()
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                ForEach(definitions) { definition in
                    VStack {
                        HStack {
                            Text(definition.word)
                                .font(.custom("Times New Roman", size: 28))
                                .font(.bold(.system(size: 28))())
                                .font(.headline)
                        }
                        ForEach(definition.meanings) { meaning in
                            MeaningView(meaning: meaning)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    func searchWord() {
        guard !searchText.isEmpty else {
            errorMessage = "Please enter a word"
            return
        }
        
        let apiUrl = "https://api.dictionaryapi.dev/api/v2/entries/en/\(searchText)"
        
        guard let url = URL(string: apiUrl) else {
            errorMessage = "Invalid API URL"
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                self.errorMessage = "Error: \(error.localizedDescription)"
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                self.errorMessage = "Bad server response"
                return
            }
            
            guard let data = data else {
                self.errorMessage = "No data received"
                return
            }
            
            // Print raw JSON data
            if let jsonString = String(data: data, encoding: .utf8) {
                //print("Raw JSON data:", jsonString)
            }
            
            do {
                let definitions = try JSONDecoder().decode([Definition].self, from: data)
                DispatchQueue.main.async {
                    self.definitions = definitions
                    self.errorMessage = nil // Clear any previous error message
                }
            } catch {
                self.errorMessage = "Failed to decode data: \(error.localizedDescription)"
            }
        }
        
        task.resume()
    }
}

struct MeaningView: View {
    let meaning: Meaning
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(meaning.partOfSpeech)
                .font(.custom("Times New Roman", size: 18))
                .italic()
                .bold()
                .padding(.top, 6)
            
            ForEach(meaning.definitions.indices, id: \.self) { index in
                let count = index + 1
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(count). \(meaning.definitions[index].definition)")
                     
                    if let example = meaning.definitions[index].example {
                        Text("\"\(example)\"")
                    }
                    
                    if !meaning.synonyms.isEmpty {
                        HStack(spacing: 5) {
                            ForEach(meaning.synonyms.indices, id: \.self) { index in
                                let synonym = meaning.synonyms[index]
                                let isLastSynonym = index == meaning.synonyms.count - 1
                                let comma = isLastSynonym ? "" : ", "
                                Text("• \(synonym)\(comma)")
                                    .font(.custom("Times New Roman", size: 18))
                            }
                        }
                    }
                    
                    if !meaning.antonyms.isEmpty {
                        Text("Antonyms: \(meaning.antonyms.joined(separator: ", "))")
                    }
                }
                .padding(.bottom, 10)
            }
        }
    }
}

struct FavoritesView: View {
    var body: some View {
        Text("Favorites View")
    }
}

struct Definition: Codable, Identifiable {
    var id: UUID?
    var word: String
    let phonetics: [Phonetic]
    let meanings: [Meaning]
    let license: License
    let sourceUrls: [String]
}

struct Phonetic: Codable {
    let text: String
    let audio: String?
}

struct Meaning: Codable, Hashable, Identifiable {
    let id = UUID() // Add unique identifier
    let partOfSpeech: String
    let definitions: [DefinitionItem]
    let synonyms: [String]
    let antonyms: [String]
    
    // Conform to Hashable by providing an explicit hash value
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct DefinitionItem: Codable, Hashable {
    let definition: String
    let synonyms: [String]
    let antonyms: [String]
    let example: String? // Optional since not every definition may have an example
}


struct License: Codable {
    let name: String
    let url: URL
}
