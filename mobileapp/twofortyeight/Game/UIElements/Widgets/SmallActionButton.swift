import SwiftUI

struct SmallActionButton: View {
    let title: String
    let action: () -> ()
    var enabled: Bool
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 21, weight: .black, design: .rounded))
//                .padding(.horizontal, 20)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
//                .background(enabled ? Color.orange : Color(UIColor.orange.withAlphaComponent(0.5)))
                .background(enabled ? Color(Color.customGolden) : Color(Color.customGolden.withAlphaComponent(0.5)))
                .foregroundColor(enabled ? Color.white : Color(UIColor.white.withAlphaComponent(0.5)))
                .cornerRadius(4)
            }.disabled(!enabled)
    }
}

struct SmallActionButton_Previews: PreviewProvider {
    static var previews: some View {
        SmallActionButton(title: "MENU", action: {}, enabled: false)
    }
}
