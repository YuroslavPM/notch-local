import SwiftUI

struct NotchRootView: View {
    let geometry: NotchGeometry

    var body: some View {
        VStack(spacing: 0) {
            NotchShape(cornerRadius: 10)
                .fill(.black)
                .frame(width: geometry.notchSize.width, height: geometry.notchSize.height)
            Spacer(minLength: 0)
        }
        .frame(
            width: NotchGeometry.expandedSize.width,
            height: NotchGeometry.expandedSize.height
        )
    }
}
