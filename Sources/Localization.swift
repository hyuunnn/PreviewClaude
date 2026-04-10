import Foundation

private let localBundle: Bundle = {
    let bundleName = "TranslateLLM_TranslateLLM"
    if let url = Bundle.main.resourceURL?.appendingPathComponent(bundleName + ".bundle"),
       let bundle = Bundle(url: url) {
        return bundle
    }
    return Bundle.module
}()

func L(_ key: String) -> String {
    NSLocalizedString(key, bundle: localBundle, comment: "")
}

func L(_ key: String, _ args: CVarArg...) -> String {
    String(format: NSLocalizedString(key, bundle: localBundle, comment: ""), arguments: args)
}
