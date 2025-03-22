import Cocoa

class WallpaperChanger: NSObject, NSApplicationDelegate {
    let workspace = NSWorkspace.shared
    var timer: Timer?
    let folderPath = "/var/tmp/yearprogress/wallpaper/"
    var sleeping = false

    override init() {
        super.init()
        // Create the directory if it doesn't exist
        createWorkingDirectory()

        // Set up the application delegate
        NSApplication.shared.delegate = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Application did finish launching!")

        // Using NotificationCenter.default observers with modern closure syntax
        NotificationCenter.default.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.timer?.fireDate = Date.distantFuture
        }

        NotificationCenter.default.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.timer?.fireDate = Date()
        }

        // Start the wallpaper changer
        self.start()
    }

    let center = NSWorkspace.shared.notificationCenter

    private func createWorkingDirectory() {
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(atPath: folderPath, withIntermediateDirectories: true)
        } catch {
            print("Error creating directory: \(error)")
        }
    }

    private func cleanDirectory() {
        let fileManager = FileManager.default
        do {
            let files = try fileManager.contentsOfDirectory(atPath: folderPath)
            for file in files {
                let filePath = (folderPath as NSString).appendingPathComponent(file)
                try fileManager.removeItem(atPath: filePath)
            }
        } catch {
            print("Error cleaning directory: \(error)")
        }
    }

    func getImageText() -> String {
        let now = Date()
        let calendar = Calendar.current

        // Get year start and end
        let currentYear = calendar.component(.year, from: now)
        let yearStart = calendar.date(from: DateComponents(year: currentYear))!
        let yearEnd = calendar.date(from: DateComponents(year: currentYear + 1))!

        // Calculate progress
        let totalSeconds = yearEnd.timeIntervalSince(yearStart)
        let elapsedSeconds = now.timeIntervalSince(yearStart)
        let percentage = (elapsedSeconds / totalSeconds) * 100

        // Format to 2 decimal places
        return String(format: "%.6f%%", percentage)
    }

    func createImage() -> NSImage {
        let text = getImageText()
        let font = NSFont.monospacedSystemFont(ofSize: 60, weight: .bold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white,
        ]

        // Calculate text size
        let textSize = text.size(withAttributes: attributes)

        // Add some padding around the text
        let padding: CGFloat = 20
        let imageSize = NSSize(
            width: textSize.width + (padding * 2),
            height: textSize.height + (padding * 2)
        )

        // Create an image context
        let image = NSImage(size: imageSize)

        image.lockFocus()

        // Set background
        NSColor.black.setFill()
        NSRect(origin: .zero, size: imageSize).fill()

        // Draw text centered in the padded area
        text.draw(
            at: NSPoint(x: padding, y: padding),
            withAttributes: attributes
        )

        image.unlockFocus()

        return image
    }

    func start() {
        self.changeWallpaper()

        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            if let unwrappedSelf = self, !unwrappedSelf.sleeping {
                unwrappedSelf.changeWallpaper()
            }
        }
        RunLoop.current.add(timer!, forMode: .common)
    }

    func changeWallpaper() {
        do {
            // Clean the directory first
            cleanDirectory()

            let image = createImage()

            // Create filename with current timestamp
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
            let timestamp = dateFormatter.string(from: Date())
            let filename = "wallpaper-\(timestamp).png"

            print(filename)

            // Create full path
            let tempURL = URL(fileURLWithPath: folderPath).appendingPathComponent(filename)

            if let tiffData = image.tiffRepresentation,
                let bitmapImage = NSBitmapImageRep(data: tiffData),
                let pngData = bitmapImage.representation(using: .png, properties: [:])
            {
                try pngData.write(to: tempURL)
            }

            let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
                .imageScaling: NSImageScaling.scaleNone.rawValue,
                .fillColor: NSColor.black,
            ]

            for screen in NSScreen.screens {
                try workspace.setDesktopImageURL(tempURL, for: screen, options: options)
            }
        } catch {
            print("Detailed error: \(error)")
        }
    }
}

// Usage
let app = NSApplication.shared
let changer = WallpaperChanger()

signal(SIGINT) { _ in
    print("\nShutting down gracefully...")
    exit(0)
}

signal(SIGTERM) { _ in
    print("\nShutting down gracefully...")
    exit(0)
}

// Keep the script running
app.run()
