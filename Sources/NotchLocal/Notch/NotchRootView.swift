import SwiftUI

struct NotchRootView: View {
    var viewModel: NotchViewModel
    var musicController: MusicController

    var body: some View {
        let expanded = viewModel.state == .expanded
        let size = expanded ? NotchGeometry.expandedSize : viewModel.geometry.notchSize
        let radius: CGFloat = expanded ? 24 : 10

        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                NotchShape(cornerRadius: radius)
                    .fill(.black)
                    .frame(width: size.width, height: size.height)

                if expanded {
                    MusicView(controller: musicController)
                        .padding(.top, viewModel.geometry.notchSize.height)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        .frame(width: size.width, height: size.height, alignment: .top)
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                }
            }
            Spacer(minLength: 0)
        }
        .frame(
            width: NotchGeometry.expandedSize.width,
            height: NotchGeometry.expandedSize.height
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.state)
    }
}
