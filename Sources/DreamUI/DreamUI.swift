import SwiftUI

protocol ToastViewControllerDelegate {
    func toastWillShow()
    func toastDidShow()
    func toastWillHide()
    func toastDidHide()
}

extension ToastViewControllerDelegate {
    func toastWillShow() { }
    func toastDidShow() { }
    func toastWillHide() { }
    func toastDidHide() { }
}

private let height: CGFloat = 50
private let width: CGFloat = 195
private let padding: CGFloat = 20
private let initialScale = CGAffineTransform(scaleX: 0.8, y: 0.8)

#if os(macOS)
private class ToastNSView: NSView {
    var stackView = NSStackView()
    var effectView = NSVisualEffectView()
    var imageView = NSImageView()
    var label = NSTextField()

    init() {
        super.init(frame: .zero)
        self.alphaValue = 0
        self.wantsLayer = true
        self.layer?.setAffineTransform(initialScale)

        self.effectView = NSVisualEffectView(frame: CGRect(origin: .zero, size: CGSize(width: width, height: height)))
        self.effectView.wantsLayer = true
        self.effectView.layer?.cornerCurve = .continuous
        self.effectView.layer?.cornerRadius = self.effectView.frame.size.height / 16
        self.effectView.layer?.masksToBounds = true
        self.effectView.material = .underWindowBackground

        self.stackView = NSStackView()
        self.stackView.orientation = .horizontal
        self.stackView.alignment = .width
        self.stackView.distribution = .fillProportionally
        self.stackView.spacing = 5
        self.stackView.edgeInsets = NSEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)

        self.imageView = NSImageView(frame: NSRect(origin: .zero, size: CGSize(width: 20, height: 20)))
        self.imageView.contentTintColor = .labelColor
        self.imageView.imageScaling = .scaleAxesIndependently
        self.stackView.addArrangedSubview(self.imageView)
        self.imageView.widthAnchor.constraint(equalToConstant: 20).isActive = true

        let labelWidth = width
        self.label = NSTextField()
        self.label.frame = CGRect(origin: .zero, size: CGSize(width: labelWidth, height: 40))
        self.label.textColor = .labelColor
        self.label.stringValue = ""
        self.label.font = .boldSystemFont(ofSize: 16)
        self.label.lineBreakMode = .byTruncatingTail
        self.label.maximumNumberOfLines = 2
        self.label.alignment = .center
        self.label.isEditable = false
        self.label.isBordered = false
        self.label.backgroundColor = .clear
        self.stackView.addArrangedSubview(self.label)

        self.addSubview(self.stackView)
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.stackView.heightAnchor.constraint(equalToConstant: height).isActive = true
        self.stackView.widthAnchor.constraint(equalToConstant: width).isActive = true
        self.stackView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true

        self.addSubview(self.effectView, positioned: .below, relativeTo: self.stackView)
        self.effectView.translatesAutoresizingMaskIntoConstraints = false
        self.effectView.heightAnchor.constraint(equalTo: self.stackView.heightAnchor).isActive = true
        self.effectView.widthAnchor.constraint(equalTo: self.stackView.widthAnchor).isActive = true
        self.effectView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("\(#function) has not been implemented") }
}

class ToastViewController: NSViewController {
    var label: String
    var image: NSImage?

    var delegate: ToastViewControllerDelegate?

    private var isPresented = false
    private var containerView = ToastNSView()

    init(
        label: String,
        image: NSImage?
    ) {
        self.label = label
        self.image = image

        super.init(nibName: nil, bundle: nil)

        self.containerView.frame = CGRect(x: 0, y: 0, width: height, height: height)
        self.containerView.label.stringValue = self.label
        self.containerView.imageView.image = self.image
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("\(#function) has not been implemented") }

    func showToast() {
        guard !isPresented else { return }
        let rootView = self.rootView()
        if self.containerView.superview == nil {
            rootView.addSubview(self.containerView)
        }
        layoutView(relativeTo: rootView)
        self.delegate?.toastWillShow()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.8
            context.allowsImplicitAnimation = true
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.containerView.alphaValue = 1
            self.containerView.layer?.setAffineTransform(CGAffineTransform(scaleX: 1, y: 1))
        } completionHandler: {
            self.isPresented = true
            self.delegate?.toastDidShow()
        }
    }

    func hideToast(_ animated: Bool = true) {
        guard isPresented else { return }
        delegate?.toastWillHide()
        if animated {
            NSAnimationContext.runAnimationGroup{ context in
                context.duration = 0.8
                context.allowsImplicitAnimation = true
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                self.containerView.alphaValue = 0
                self.containerView.layer?.setAffineTransform(initialScale)
            } completionHandler: {
                self.isPresented = false
                self.containerView.removeFromSuperview()
                self.delegate?.toastDidHide()
            }
        } else {
            self.containerView.alphaValue = 0
            self.containerView.layer?.setAffineTransform(initialScale)
            self.isPresented = false
            self.containerView.removeFromSuperview()
            delegate?.toastDidHide()
        }
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        hideToast(false)
    }

    private func layoutView(relativeTo view: NSView) {
        self.containerView.translatesAutoresizingMaskIntoConstraints = false
        self.containerView.heightAnchor.constraint(equalToConstant: height).isActive = true
        self.containerView.widthAnchor.constraint(equalToConstant: width).isActive = true
        self.containerView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true

        self.containerView.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -18
        ).isActive = true
    }

    private func rootView() -> NSView {
        self.presentingViewController?.view ??
        self.view.window?.contentView ??
        self.view
    }

    private func toolbarHeight() -> CGFloat {
        self.view.window?.toolbar?.visibleItems?.first?.view?.frame.height ?? 0
    }
}

struct ToastView: NSViewControllerRepresentable {

    @Binding var isPresented: Bool

    private let label: String
    private let image: NSImage?
    private let duration: Duration?

    init(
        isPresented: Binding<Bool>,
        label: String,
        image: NSImage?,
        duration: Duration? = .seconds(1.9)
    ) {
        self._isPresented = isPresented
        self.label = label
        self.image = image
        self.duration = duration
    }

    init(
        isPresented: Binding<Bool>,
        label: String,
        systemImage: String,
        duration: Duration? = .seconds(1.9)
    ) {
        self.init(
            isPresented: isPresented,
            label: label,
            image: NSImage(systemSymbolName: systemImage, accessibilityDescription: nil),
            duration: duration
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSViewController(context: Context) -> ToastViewController {
        let controller = ToastViewController(
            label: self.label,
            image: self.image
        )
        controller.delegate = context.coordinator
        return controller
    }

    func updateNSViewController(_ nsViewController: ToastViewController, context: Context) {
        if isPresented {
            nsViewController.showToast()
            if let duration {
                Task { @MainActor in
                    try? await Task.sleep(for: duration)
                    nsViewController.hideToast()
                }
            }
        } else {
            nsViewController.hideToast()
        }
    }

    class Coordinator: ToastViewControllerDelegate {
        private let parent: ToastView

        init(_ parent: ToastView) {
            self.parent = parent
        }

        func toastDidHide() {
            parent.isPresented = false
        }
    }
}

struct ToastViewModifier: ViewModifier {
    @Binding var isPresented: Bool

    var label: String
    var systemImage: String
    var hasAdditionalBottomBar: Bool = false

    func body(content: Content) -> some View {
        content
            .overlay {
                ToastView(
                    isPresented: $isPresented,
                    label: "Playing Next",
                    systemImage: "text.line.first.and.arrowtriangle.forward"
                )
                .allowsHitTesting(false)
            }
    }
}
#else
private class ToastUIView: UIView {
    var stackView = UIStackView()
    var effectView = UIVisualEffectView()
    var imageView = UIImageView()
    var label = UILabel()

    init() {
        super.init(frame: .zero)
        self.alpha = 0;
        self.transform = initialScale

        self.effectView = UIVisualEffectView(frame: CGRect(x: 0, y: 0, width: height, height: width))
        self.effectView.layer.cornerCurve = .continuous
        self.effectView.layer.cornerRadius = self.effectView.frame.size.height / 16
        self.effectView.layer.masksToBounds = true
        self.effectView.effect = UIBlurEffect(style: .systemMaterial)

        self.stackView = UIStackView()
        self.stackView.axis = .horizontal
        self.stackView.alignment = .fill
        self.stackView.distribution = .fillProportionally
        self.stackView.spacing = 5
        self.stackView.isLayoutMarginsRelativeArrangement = true
        self.stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 0,
            leading: padding,
            bottom: 0,
            trailing: padding
        )

        self.imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        self.imageView.tintColor = .label
        self.imageView.contentMode = .scaleAspectFit
        self.stackView.addArrangedSubview(self.imageView)
        self.imageView.widthAnchor.constraint(equalToConstant: 20).isActive = true

        let labelWidth = width
        self.label = UILabel()
        self.label.frame = CGRect(x: 0, y: 0, width: labelWidth, height: 40)
        self.label.textColor = .label
        self.label.text = ""
        self.label.font = .boldSystemFont(ofSize: 16)
        self.label.lineBreakMode = .byTruncatingTail
        self.label.numberOfLines = 2
        self.label.textAlignment = .center
        self.stackView.addArrangedSubview(self.label)

        self.addSubview(self.stackView)
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.stackView.heightAnchor.constraint(equalToConstant: height).isActive = true
        self.stackView.widthAnchor.constraint(equalToConstant: width).isActive = true
        self.stackView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true

        self.insertSubview(self.effectView, at: 0)
        self.effectView.translatesAutoresizingMaskIntoConstraints = false
        self.effectView.heightAnchor.constraint(equalTo: self.stackView.heightAnchor).isActive = true
        self.effectView.widthAnchor.constraint(equalTo: self.stackView.widthAnchor).isActive = true
        self.effectView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("\(#function) has not been implemented") }
}

class ToastViewController: UIViewController {
    var label: String
    var image: UIImage?

    var feedbackType: UINotificationFeedbackGenerator.FeedbackType
    var hasAdditionalBottomBar: Bool

    var delegate: ToastViewControllerDelegate?

    private var isPresented = false
    private var containerView = ToastUIView()

    init(
        label: String,
        image: UIImage?,
        feedbackType: UINotificationFeedbackGenerator.FeedbackType,
        hasAdditionalBottomBar: Bool
    ) {
        self.label = label
        self.image = image
        self.feedbackType = feedbackType
        self.hasAdditionalBottomBar = hasAdditionalBottomBar

        super.init(nibName: nil, bundle: nil)

        self.containerView.frame = CGRect(x: 0, y: 0, width: height, height: height)
        self.containerView.label.text = self.label
        self.containerView.imageView.image = self.image
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("\(#function) has not been implemented") }

    func showToast() {
        guard !isPresented else { return }
        let rootView = self.rootView()
        if self.containerView.superview == nil {
            rootView.addSubview(self.containerView)
        }
        layoutView(relativeTo: rootView)
        self.delegate?.toastWillShow()
        UINotificationFeedbackGenerator().notificationOccurred(feedbackType)
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.2) {
            self.containerView.alpha = 1
            self.containerView.transform = CGAffineTransform(scaleX: 1, y: 1)
        } completion: {
            self.isPresented = $0
            self.delegate?.toastDidShow()
        }
    }

    func hideToast(_ animated: Bool = true) {
        guard isPresented else { return }
        delegate?.toastWillHide()
        if animated {
            UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.2) {
                self.containerView.alpha = 0
                self.containerView.transform = initialScale
            } completion: { finished in
                self.isPresented = !finished
                if finished { self.containerView.removeFromSuperview() }
                self.delegate?.toastDidHide()
            }
        } else {
            self.containerView.alpha = 0
            self.containerView.transform = initialScale
            self.isPresented = false
            self.containerView.removeFromSuperview()
            delegate?.toastDidHide()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        hideToast(animated)
    }

    private func layoutView(relativeTo view: UIView) {
        self.containerView.translatesAutoresizingMaskIntoConstraints = false
        self.containerView.heightAnchor.constraint(equalToConstant: height).isActive = true
        self.containerView.widthAnchor.constraint(equalToConstant: width).isActive = true
        self.containerView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true

        self.containerView.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: hasAdditionalBottomBar ? -toolbarHeight() - 18 : -18
        ).isActive = true
    }

    private func rootView() -> UIView {
        self.navigationController?.view ??
        self.tabBarController?.view ??
        self.presentationController?.containerView ??
        self.view.window?.rootViewController?.view ??
        self.view!
    }

    private func toolbarHeight() -> CGFloat {
        self.navigationController?.toolbar.frame.size.height ?? 0
    }
}

struct ToastView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool

    private let label: String
    private let image: UIImage?
    private let duration: Duration?

    private let feedbackType: UINotificationFeedbackGenerator.FeedbackType
    private let hasAdditionalBottomBar: Bool

    init(
        isPresented: Binding<Bool>,
        label: String,
        image: UIImage?,
        duration: Duration? = .seconds(1.9),
        feedbackType: UINotificationFeedbackGenerator.FeedbackType = .success,
        hasAdditionalBottomBar: Bool = false
    ) {
        self._isPresented = isPresented
        self.label = label
        self.image = image
        self.duration = duration
        self.feedbackType = feedbackType
        self.hasAdditionalBottomBar = hasAdditionalBottomBar
    }

    init(
        isPresented: Binding<Bool>,
        label: String,
        systemImage: String,
        duration: Duration? = .seconds(1.9),
        feedbackType: UINotificationFeedbackGenerator.FeedbackType = .success,
        hasAdditionalBottomBar: Bool = false
    ) {
        self.init(
            isPresented: isPresented,
            label: label,
            image: UIImage(systemName: systemImage),
            duration: duration,
            feedbackType: feedbackType,
            hasAdditionalBottomBar: hasAdditionalBottomBar
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> ToastViewController {
        let controller = ToastViewController(
            label: self.label,
            image: self.image,
            feedbackType: self.feedbackType,
            hasAdditionalBottomBar: self.hasAdditionalBottomBar
        )
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: ToastViewController, context: Context) {
        if isPresented {
            uiViewController.showToast()
            if let duration {
                Task { @MainActor in
                    try? await Task.sleep(for: duration)
                    uiViewController.hideToast()
                }
            }
        } else {
            uiViewController.hideToast()
        }
    }

    class Coordinator: ToastViewControllerDelegate {
        private let parent: ToastView

        init(_ parent: ToastView) {
            self.parent = parent
        }

        func toastDidHide() {
            parent.isPresented = false
        }
    }
}

struct ToastViewModifier: ViewModifier {
    @Binding var isPresented: Bool

    var label: String
    var systemImage: String
    var feedbackType: UINotificationFeedbackGenerator.FeedbackType = .success
    var hasAdditionalBottomBar: Bool = false

    func body(content: Content) -> some View {
        content
            .overlay {
                ToastView(
                    isPresented: $isPresented,
                    label: "Playing Next",
                    systemImage: "text.line.first.and.arrowtriangle.forward",
                    feedbackType: feedbackType,
                    hasAdditionalBottomBar: hasAdditionalBottomBar
                )
                .allowsHitTesting(false)
            }
    }
}
#endif

struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        ToastView(isPresented: .constant(true), label: "Added to Library", systemImage: "checkmark.circle.fill")
        HStack {
            Color.green.frame(width: 50, height: 100)
                .toast(isPresented: .constant(true), label: "Added to Library", systemImage: "checkmark.circle.fill")
            Spacer()
        }
    }
}

extension View {
    @available(iOS, introduced: 16)
    func toast(
        isPresented: Binding<Bool>,
        label: String,
        systemImage: String,
        hasAdditionalBottomBar: Bool = false
    ) -> some View {
        modifier(
            ToastViewModifier(
                isPresented: isPresented,
                label: label,
                systemImage: systemImage,
                hasAdditionalBottomBar: hasAdditionalBottomBar
            )
        )
    }
}


struct ContentView: View {
    @State private var isShowingToast = false

    var body: some View {
        TabView {
            NavigationStack {
                #if os(macOS)
                content()
                #else
                content()
                    .toolbar {
                        ToolbarItem(placement: .bottomBar) {
                            Text("Hello")
                        }
                    }
                #endif
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
        }
    }

    @ViewBuilder func content() -> some View {
        VStack {
            Button {
                withAnimation {
                    isShowingToast = true
                }
            } label: {
                Text("Hello, world!")
            }
        }
        .toast(
            isPresented: $isShowingToast,
            label: "Playing Next",
            systemImage: "text.line.first.and.arrowtriangle.forward",
            hasAdditionalBottomBar: true
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
