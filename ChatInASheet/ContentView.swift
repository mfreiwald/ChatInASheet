//
//  ContentView.swift
//  ChatInASheet
//
//  Created by Michael on 22.09.23.
//

import SwiftUI
import StreamChatSwiftUI
import StreamChat
import SwiftUIKit

let apiKeyString = ""
let channelIdString = ""

class ChatManager: ObservableObject {

    let chatClient: ChatClient = ChatClient(
        config: ChatClientConfig(apiKeyString: apiKeyString)
    )

    init() {}

    func configChat() {
        _ = StreamChat(chatClient: chatClient)

        chatClient.connectAnonymousUser { error in
            if let error {
                print(error)
            }
        }
    }
}

struct ContentView: View {
    enum Chat: Identifiable, CaseIterable {
        case custom
        case getStream

        var id: Self { self }
    }
    @State private var showChat: Chat?

    @StateObject private var chatManager: ChatManager = .init()

    var body: some View {
        VStack(spacing: 0) {
            PlayerView()

            BrandsView() { brand in
                if brand.id == "customChat" {
                    showChat = .custom
                } else if brand.id == "getstream" {
                    showChat = .getStream
                } else {
                    showChat = Chat.allCases.randomElement()!
                }
            }

            Spacer()
        }
        .onAppear {
            chatManager.configChat()
        }
        .sheet(item: $showChat, content: { chat in
            Group {
                switch chat {
                case .custom:
                    CustomChat()
                case .getStream:
                    if apiKeyString.isEmpty || channelIdString.isEmpty {
                        Text("Please add APIKey and ChannelId to the project!")
                            .font(.title)
                    } else {
                        StreamChatView()
                    }
                }
            }
            .presentationDetents([.fraction(0.72), .large])
            .presentationBackgroundInteraction(.enabled)
        })
    }
}

struct Message: Identifiable {
    var id: String
    var user: String
    var content: String

    static let users = [
        "John Smith",
        "Alice Johnson",
        "Michael Brown",
        "Emily Davis",
        "William Wilson",
        "Olivia Lee",
        "James Jones",
        "Sophia Martinez",
        "Benjamin Harris",
        "Emma Clark"
    ]

    static func generateDummyMessages() -> [Message] {
        var messages = [Message]()

        for i in 1...50 {
            let randomUserIndex = Int(arc4random_uniform(UInt32(users.count)))
            let randomUser = users[randomUserIndex]
            let randomMessageID = UUID().uuidString
            let randomMessageContent = "This is message \(i) from \(randomUser)."

            let message = Message(id: randomMessageID, user: randomUser, content: randomMessageContent)
            messages.append(message)
        }

        return messages
    }
}

struct CustomChat: View {
    let messages: [Message] = Message.generateDummyMessages()

    @State private var newMessage: String = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                ScrollViewReader { proxy in
                    LazyVStack {
                        titleBar
                            .hidden()

                        ForEach(messages) { message in
                            VStack(alignment: .leading) {
                                Text(message.user)
                                    .font(.caption.bold())

                                Text(message.content)
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                        }
                    }
                    .onAppear {
                        if let lastMessageId = messages.last?.id {
                            Task {
                                try? await Task.sleep(for: .milliseconds(150))
                                print("ScrollTo \(lastMessageId)")
                                proxy.scrollTo(lastMessageId)
                            }
                        }
                    }
                }
            }

            HStack {
                TextField("New message", text: $newMessage)
                    .textFieldStyle(.roundedBorder)

                Button {
                    
                } label: {
                    Image(systemName: "paperplane.fill")
                }
            }
            .padding(16)
        }
        .overlay(alignment: .top) {
            titleBar
        }
    }

    @ViewBuilder
    private var titleBar: some View {
        Text("Chat")
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
    }
}

struct StreamChatView: View {
    let channelId: ChannelId = .init(type: .livestream, id: channelIdString)
    var viewFactory: some ViewFactory = CustomViewFactory.shared
    @Injected(\.chatClient) private var chatClient

    private var channelController: ChatChannelController {
        chatClient.channelController(for: channelId)
    }

    var body: some View {
        ChatChannelView(viewFactory: viewFactory, channelController: channelController)
            .overlay(alignment: .top) {
                Text("Chat")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
            }
    }
}

/// Default class conforming to `ViewFactory`, used throughout the SDK.
public class CustomViewFactory: ViewFactory {
    @Injected(\.chatClient) public var chatClient

    private init() {
        // Private init.
    }

    public static let shared = CustomViewFactory()

    public func makeMessageAvatarView(for userDisplayInfo: UserDisplayInfo) -> some View {
        EmptyView()
    }
}

struct PlayerView: View {
    @State var color: Color = .random
    @State var showPlayerUI = true

    var body: some View {
        Rectangle()
            .fill(color.gradient)
            .frame(maxWidth: .infinity)
            .aspectRatio(16/9, contentMode: .fit)
            .overlay {
                if showPlayerUI {
                    Image(systemName: "play.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30)
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 5).repeatForever(autoreverses: true)) {
                    color = .random
                }
            }
            .onTapGesture {
                withAnimation {
                    showPlayerUI.toggle()
                }
            }
            .task(id: showPlayerUI) {
                if showPlayerUI {
                    try? await Task.sleep(for: .seconds(2))
                    withAnimation {
                        showPlayerUI = false
                    }
                }
            }
    }
}

struct Brand: Identifiable {
    var id: String { brandId }
    var brandId: String
    var title: String
    var color: Color
}

struct BrandsView: View {
    let brands = [
        Brand(brandId: "customChat", title: "Custom Chat", color: .gray),
        Brand(brandId: "getstream", title: "GetStream Chat", color: .blue),
    ] + (0...30).map { Brand(brandId: "id\($0)", title: "Title \($0)", color: .random)}

    var open: (Brand) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                Rectangle().frame(height: 50).hidden()

                ForEach(brands) { brand in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(brand.color)
                        .frame(height: 60)
                    .overlay(alignment: .leading) {
                        Text(brand.title)
                            .padding(.leading, 80)
                    }
                    .onTapGesture {
                        open(brand)
                    }
                }
            }
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.gray.gradient)
                .frame(height: 50)
                .overlay {
                    Text("Select your favorite one")
                        .font(.headline)
                }
        }
    }
}

extension Color {
    static var random: Color {
        Color(hue: .random(in: 0..<1), saturation: 0.8, brightness: 0.8)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
