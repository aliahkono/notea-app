import SwiftUI

struct CustomBackButton: View {
    @Environment(\.dismiss) private var dismiss
    var label: String?
    var body: some View {
        Button(action: { dismiss() }) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.body)
                if let label = label {
                    Text(label)
                        .font(.body)
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.black)
        }
    }
}

struct CustomBackButton_Previews: PreviewProvider {
    static var previews: some View {
        CustomBackButton(label: "Back")
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
