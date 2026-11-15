import SwiftUI

struct NotchRootView: View {
    var viewModel: NotchViewModel
    var musicController: MusicController
    var calendarController: CalendarController
    var trayController: FileTrayController

    @Namespace private var glassNamespace

    var body: some View {
        let size = shapeSize
        let radius: CGFloat = viewModel.state == .expanded ? 24 : 10

        VStack(spacing: 0) {
            panel(size: size, radius: radius)
            Spacer(minLength: 0)
        }
        .frame(
            width: NotchGeometry.expandedSize.width,
            height: NotchGeometry.expandedSize.height
        )
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.state)
    }

    private var shapeSize: CGSize {
        switch viewModel.state {
        case .collapsed:
            viewModel.geometry.notchSize
        case .peek:
            viewModel.geometry.peekSize
        case .expanded:
            NotchGeometry.expandedSize
        }
    }

    @ViewBuilder
    private func panel(size: CGSize, radius: CGFloat) -> some View {
        if #available(macOS 26.0, *) {
            glassPanel(size: size, radius: radius)
        } else {
            classicPanel(size: size, radius: radius)
        }
    }

    @available(macOS 26.0, *)
    private func glassPanel(size: CGSize, radius: CGFloat) -> some View {
        let shape = NotchShape(cornerRadius: radius)

        return GlassEffectContainer(spacing: 20) {
            ZStack(alignment: .top) {
                switch viewModel.state {
                case .expanded:
                    expandedContent
                        .padding(.top, viewModel.geometry.contentTopInset)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)
                        .frame(width: size.width, height: size.height, alignment: .top)
                        .glassEffect(.regular.interactive(), in: shape)
                        .glassEffectID("notch", in: glassNamespace)
                        .glassEffectTransition(.matchedGeometry)
                case .peek:
                    if let peek = viewModel.currentPeek {
                        PeekView(peek: peek, artwork: musicController.artwork)
                            .frame(width: size.width, height: size.height)
                            .glassEffect(.regular, in: shape)
                            .glassEffectID("notch", in: glassNamespace)
                    }
                case .collapsed:
                    shape
                        .fill(.black)
                        .frame(width: size.width, height: size.height)
                        .glassEffectID("notch", in: glassNamespace)
                }
            }
        }
    }

    private func classicPanel(size: CGSize, radius: CGFloat) -> some View {
        ZStack(alignment: .top) {
            NotchShape(cornerRadius: radius)
                .fill(.black)
                .frame(width: size.width, height: size.height)

            switch viewModel.state {
            case .expanded:
                expandedContent
                    .padding(.top, viewModel.geometry.contentTopInset)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                    .frame(width: size.width, height: size.height, alignment: .top)
            case .peek:
                if let peek = viewModel.currentPeek {
                    PeekView(peek: peek, artwork: musicController.artwork)
                        .frame(width: size.width, height: size.height)
                }
            case .collapsed:
                EmptyView()
            }
        }
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                MusicView(controller: musicController)
                    .frame(width: 268, alignment: .leading)
                Rectangle()
                    .fill(.white.opacity(0.22))
                    .frame(width: 1)
                CalendarPeekView(controller: calendarController)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            FileTrayView(controller: trayController)
                .frame(height: 44)
        }
    }
}
