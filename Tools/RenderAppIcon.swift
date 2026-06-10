// Renders the ocrumb app icon (light / dark / tinted) to 1024×1024 PNGs using
// SwiftUI's ImageRenderer, so the icon stays in sync with the in-app brand:
// the same `fork.knife` SF Symbol and the brand green from Theme.swift.
//
// Run:  swift Tools/RenderAppIcon.swift
// Output is written into ocrumb/Assets.xcassets/AppIcon.appiconset/.
import SwiftUI
import AppKit
import ImageIO
import UniformTypeIdentifiers

// Brand green (mirrors Theme / AccentColor light value, #2C7A52) plus a
// lighter top stop for a subtle vertical gradient.
let brandTop = Color(red: 0.22, green: 0.58, blue: 0.40)
let brandBottom = Color(red: 0.11, green: 0.38, blue: 0.26)
// Deeper forest green for the dark-appearance icon — keeps the brand colour
// while sitting comfortably on a dark home screen.
let darkTop = Color(red: 0.11, green: 0.32, blue: 0.22)
let darkBottom = Color(red: 0.05, green: 0.18, blue: 0.13)

enum Variant { case light, dark, tinted }

struct IconView: View {
    let variant: Variant

    private var glyphColor: Color {
        switch variant {
        case .light, .dark: return .white
        case .tinted: return .white          // grayscale; system applies the tint
        }
    }

    var body: some View {
        ZStack {
            switch variant {
            case .light:
                LinearGradient(colors: [brandTop, brandBottom],
                               startPoint: .top, endPoint: .bottom)
            case .dark:
                LinearGradient(colors: [darkTop, darkBottom],
                               startPoint: .top, endPoint: .bottom)
            case .tinted:
                Color.clear                  // grayscale glyph; system tints it
            }

            Image(systemName: "fork.knife")
                .font(.system(size: 450, weight: .medium))
                .foregroundStyle(glyphColor)
                .shadow(color: .black.opacity(variant == .tinted ? 0 : 0.18),
                        radius: 24, x: 0, y: 12)
        }
        .frame(width: 1024, height: 1024)
    }
}

@MainActor
func writePNG(_ view: some View, to url: URL) {
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1
    renderer.isOpaque = false
    guard let cg = renderer.cgImage else {
        FileHandle.standardError.write(Data("failed to render \(url.lastPathComponent)\n".utf8))
        return
    }
    guard let dest = CGImageDestinationCreateWithURL(
        url as CFURL, UTType.png.identifier as CFString, 1, nil
    ) else { return }
    CGImageDestinationAddImage(dest, cg, nil)
    CGImageDestinationFinalize(dest)
    print("wrote \(url.lastPathComponent) (\(cg.width)×\(cg.height))")
}

@MainActor
func main() {
    let dir = URL(fileURLWithPath: "ocrumb/Assets.xcassets/AppIcon.appiconset")
    writePNG(IconView(variant: .light),  to: dir.appendingPathComponent("AppIcon-1024.png"))
    writePNG(IconView(variant: .dark),   to: dir.appendingPathComponent("AppIcon-1024-dark.png"))
    writePNG(IconView(variant: .tinted), to: dir.appendingPathComponent("AppIcon-1024-tinted.png"))
}

MainActor.assumeIsolated { main() }
