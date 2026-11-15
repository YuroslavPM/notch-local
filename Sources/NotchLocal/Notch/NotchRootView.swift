import SwiftUI

struct NotchRootView: View {
    var viewModel: NotchViewModel
    var musicController: MusicController
    var calendarController: CalendarController
    var trayController: FileTrayController
    var clipboardController: ClipboardController
    var batteryMonitor: BatteryMonitor
    var focusMonitor: FocusMonitor
    var settings: SettingsStore

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
        VStack(alignment: .leading, spacing: 8) {
            if settings.showStatus {
                StatusBarView(battery: batteryMonitor, focus: focusMonitor)
            }
            if settings.showMusic || settings.showCalendar {
                HStack(alignment: .top, spacing: 12) {
                    if settings.showMusic {
                        MusicView(controller: musicController)
                            .frame(width: settings.showCalendar ? 268 : nil, alignment: .leading)
                    }
                    if settings.showMusic, settings.showCalendar {
                        Rectangle()
                            .fill(.white.opacity(0.22))
                            .frame(width: 1)
                    }
                    if settings.showCalendar {
                        CalendarPeekView(controller: calendarController)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            } else {
                Spacer(minLength: 0)
            }
            if settings.showTray {
                FileTrayView(controller: trayController)
            }
            if settings.showClipboard {
                ClipboardView(controller: clipboardController)
                    .frame(height: 44)
            }
        }
    }
}
