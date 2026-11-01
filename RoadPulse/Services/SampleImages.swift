import UIKit

// MARK: - Bundled sample photos

/// Held-out road photos shipped in the app (never used for training). They let the report flow
/// be tried in the simulator, which has no camera and an empty photo library, and they are the
/// fixtures for `ClassifierServiceTests`.
enum SampleImages {
    struct Sample: Identifiable {
        let resource: String
        let title: String
        let isPothole: Bool
        var id: String { resource }
    }

    static let all: [Sample] = [
        Sample(resource: "pothole_sample_1", title: "Pothole: rubble", isPothole: true),
        Sample(resource: "pothole_sample_2", title: "Pothole: cracked road", isPothole: true),
        Sample(resource: "pothole_sample_3", title: "Pothole: water-filled", isPothole: true),
        Sample(resource: "normal_sample_1", title: "Normal: clean tarmac", isPothole: false),
        Sample(resource: "normal_sample_2", title: "Normal: street", isPothole: false),
    ]

    static let signboardResource = "signboard_sample"

    static func image(resource: String, bundle: Bundle = Bundle(for: ClassifierService.self)) -> UIImage? {
        bundle.path(forResource: resource, ofType: "jpg").flatMap { UIImage(contentsOfFile: $0) }
    }

    static func image(for sample: Sample) -> UIImage? {
        image(resource: sample.resource)
    }

    static var signboard: UIImage? {
        image(resource: signboardResource)
    }
}
