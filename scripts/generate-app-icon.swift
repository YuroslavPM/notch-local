#!/usr/bin/env swift
import AppKit
import Foundation

let canvas = 1024
let args = CommandLine.arguments
let sourceURL = URL(fileURLWithPath: args.count > 1 ? args[1] : "icon-source.jpg")
let outputPNG = URL(fileURLWithPath: args.count > 2 ? args[2] : "Resources/AppIcon-1024.png")

guard let source = NSImage(contentsOf: sourceURL) else {
    fatalError("Missing source image at \(sourceURL.path)")
}

func squircle(in rect: CGRect) -> CGPath {
    let path = CGMutablePath()
    let r = min(rect.width, rect.height) * 0.223
    path.addRoundedRect(in: rect, cornerWidth: r, cornerHeight: r)
    return path
}

let scaleFactor = 2
let pixels = canvas * scaleFactor
guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: pixels,
    pixelsHigh: pixels,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fatalError("bitmap")
}
rep.size = NSSize(width: canvas, height: canvas)

NSGraphicsContext.saveGraphicsState()
guard let gc = NSGraphicsContext(bitmapImageRep: rep) else {
    fatalError("graphics context")
}
NSGraphicsContext.current = gc
gc.imageInterpolation = .high
gc.shouldAntialias = true

let ctx = gc.cgContext
ctx.setFillColor(CGColor(gray: 0, alpha: 0))
ctx.fill(CGRect(x: 0, y: 0, width: canvas, height: canvas))

let body = CGRect(x: 0, y: 0, width: canvas, height: canvas)
ctx.saveGState()
ctx.addPath(squircle(in: body))
ctx.clip()

let zoom: CGFloat = 1.14
let extra = CGFloat(canvas) * (zoom - 1)
source.draw(
    in: CGRect(
        x: -extra / 2,
        y: -extra / 2,
        width: CGFloat(canvas) * zoom,
        height: CGFloat(canvas) * zoom
    ),
    from: .zero,
    operation: .copy,
    fraction: 1
)
ctx.restoreGState()

NSGraphicsContext.restoreGraphicsState()

guard let data = rep.representation(using: .png, properties: [:]) else {
    fatalError("png")
}
try FileManager.default.createDirectory(at: outputPNG.deletingLastPathComponent(), withIntermediateDirectories: true)
try data.write(to: outputPNG)
print("Wrote \(outputPNG.path)")
