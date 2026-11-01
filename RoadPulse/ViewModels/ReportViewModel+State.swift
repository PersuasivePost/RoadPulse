import Foundation

// MARK: - Report flow states

extension ReportViewModel {
    enum Analysis: Equatable {
        case idle, analyzing
        case finished(ClassificationResult)
        case failed(String)
    }

    enum SaveState: Equatable {
        case idle, saving
        case saved(UUID)
        case failed(String)
    }
}
