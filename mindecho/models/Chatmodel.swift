import SwiftUI
import Foundation

// MARK: - 治療模式
enum TherapyMode: String, CaseIterable, Codable {
    case chatMode = "chat"
    case cbtMode = "cbt"
    case mbtMode = "mbt"
    case mentalization = "mentalization"
    
    var displayName: String {
        switch self {
        case .chatMode: return "聊天模式"
        case .cbtMode: return "CBT模式"
        case .mbtMode: return "MBT模式"
        case .mentalization: return "心智化導向"
        }
    }
    
    var shortName: String {
        switch self {
        case .chatMode: return "聊天"
        case .cbtMode: return "CBT"
        case .mbtMode: return "MBT"
        case .mentalization: return "心智化"
        }
    }
    
    var description: String {
        switch self {
        case .chatMode: return "輕鬆自在的日常對話"
        case .cbtMode: return "認知行為療法，幫助您識別並改變負面思維模式"
        case .mbtMode: return "心智化療法，增強理解自己和他人想法與感受的能力"
        case .mentalization: return "心智化導向對話，提升理解情緒與意圖的能力"
        }
    }
    
    var color: Color {
        switch self {
        case .chatMode: return AppColors.chatModeColor
        case .cbtMode: return AppColors.cbtModeColor
        case .mbtMode: return AppColors.mbtModeColor
        case .mentalization: return AppColors.mbtModeColor
        }
    }
    
    var welcomeMessage: String {
        switch self {
        case .chatMode:
            return "您好！我是您的聊天夥伴 ☺️\n\n在這裡，我們可以輕鬆聊聊日常生活、心情感受，或任何您想分享的話題。我會用溫暖、自然的方式與您對話，就像和朋友聊天一樣。\n\n有什麼想聊的嗎？"
        case .cbtMode:
            return "您好！我是您的CBT治療助手 🧠\n\n認知行為療法(CBT)可以幫助您：\n• 識別負面的思維模式\n• 挑戰不合理的想法\n• 建立更積極健康的認知習慣\n\n您可以分享任何讓您困擾的想法或情緒，我們一起來分析和處理。"
        case .mbtMode:
            return "您好！我是您的MBT治療助手 🤝\n\n心智化療法(MBT)專注於：\n• 增強情感覺察能力\n• 改善人際關係理解\n• 提升心智化水平\n\n無論是人際困擾、情緒混亂，還是想更好地理解自己和他人，我都可以陪伴您一起探索。"
        case .mentalization:
            return "您好！這裡是心智化導向對話 💡\n\n我們會一起練習：\n• 辨識自己的情緒與想法\n• 站在他人角度理解意圖\n• 在衝突中維持清晰與彈性\n\n有任何情境想討論嗎？我們可以一起慢慢拆解。"
        }
    }
}

// MARK: - 聊天訊息
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let mode: TherapyMode
    
    init(id: UUID = UUID(), content: String, isFromUser: Bool, timestamp: Date = Date(), mode: TherapyMode) {
        self.id = id
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.mode = mode
    }
}

// MARK: - 聊天會話
struct ChatSession: Identifiable, Codable {
    let id: UUID
    var title: String
    var therapyMode: TherapyMode
    var lastMessage: String
    var lastUpdated: Date
    var tags: [String]
    var messageCount: Int
    
    init(id: UUID = UUID(), title: String, therapyMode: TherapyMode, lastMessage: String = "", lastUpdated: Date = Date(), tags: [String] = [], messageCount: Int = 0) {
        self.id = id
        self.title = title
        self.therapyMode = therapyMode
        self.lastMessage = lastMessage
        self.lastUpdated = lastUpdated
        self.tags = tags
        self.messageCount = messageCount
    }
}
