import SwiftUI

struct ContentView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let conversionVC = ConversionViewController()
        let navController = UINavigationController(rootViewController: conversionVC)
        navController.navigationBar.prefersLargeTitles = true
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
