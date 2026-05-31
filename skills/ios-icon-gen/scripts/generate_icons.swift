#!/usr/bin/env swift

import AppKit
import Foundation

// MARK: - 配置

struct IconSpec {
    let symbolName: String
    let assetName: String
    let baseSize: CGFloat
    let color: NSColor
    let weight: NSFont.Weight
}

func parseColor(_ hex: String) -> NSColor {
    var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    if hex.hasPrefix("#") { hex.removeFirst() }
    guard hex.count == 6, let value = UInt64(hex, radix: 16) else {
        return NSColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1.0)
    }
    return NSColor(
        red: CGFloat((value >> 16) & 0xFF) / 255,
        green: CGFloat((value >> 8) & 0xFF) / 255,
        blue: CGFloat(value & 0xFF) / 255,
        alpha: 1.0
    )
}

func parseWeight(_ name: String) -> NSFont.Weight {
    switch name.lowercased() {
    case "ultralight": return .ultraLight
    case "thin": return .thin
    case "light": return .light
    case "regular": return .regular
    case "medium": return .medium
    case "semibold": return .semibold
    case "bold": return .bold
    case "heavy": return .heavy
    case "black": return .black
    default: return .thin
    }
}

// MARK: - 生成

enum IconError: Error, CustomStringConvertible {
    case directoryCreation(String)
    case symbolNotFound(String)
    case configurationFailed(String)
    case pngCreation(String)
    case fileWrite(String)

    var description: String {
        switch self {
        case .directoryCreation(let msg): return msg
        case .symbolNotFound(let msg): return msg
        case .configurationFailed(let msg): return msg
        case .pngCreation(let msg): return msg
        case .fileWrite(let msg): return msg
        }
    }
}

func generateIcon(_ spec: IconSpec, outputDir: String) throws {
    let dir = "\(outputDir)/\(spec.assetName).imageset"
    do {
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
    } catch {
        throw IconError.directoryCreation("无法创建输出目录 '\(dir)'：\(error.localizedDescription)")
    }

    let scales: [(suffix: String, multiplier: CGFloat)] = [("", 1), ("@2x", 2), ("@3x", 3)]

    for scale in scales {
        let pixelSize = spec.baseSize * scale.multiplier
        let imageSize = NSSize(width: pixelSize, height: pixelSize)

        let config = NSImage.SymbolConfiguration(
            pointSize: pixelSize * 0.40,
            weight: spec.weight,
            scale: .large
        )

        guard let symbol = NSImage(systemSymbolName: spec.symbolName, accessibilityDescription: nil) else {
            throw IconError.symbolNotFound("SF Symbol '\(spec.symbolName)' 未找到。运行 'SF Symbols' 应用浏览可用名称。")
        }

        guard let configured = symbol.withSymbolConfiguration(config) else {
            throw IconError.configurationFailed("无法将符号配置应用到 '\(spec.symbolName)'")
        }

        let image = NSImage(size: imageSize, flipped: false) { rect in
            let symSize = configured.size
            let x = (rect.width - symSize.width) / 2
            let y = (rect.height - symSize.height) / 2
            let drawRect = NSRect(x: x, y: y, width: symSize.width, height: symSize.height)

            let tinted = NSImage(size: symSize, flipped: false) { tintRect in
                configured.draw(in: tintRect)
                spec.color.set()
                tintRect.fill(using: .sourceAtop)
                return true
            }

            tinted.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0)
            return true
        }

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw IconError.pngCreation("无法为 \(spec.assetName)\(scale.suffix) 创建 PNG")
        }

        let fileName = "\(spec.assetName)\(scale.suffix).png"
        do {
            try pngData.write(toFile: "\(dir)/\(fileName)")
        } catch {
            throw IconError.fileWrite("无法写入 \(fileName)：\(error.localizedDescription)")
        }
        print("  \(fileName) (\(Int(pixelSize))x\(Int(pixelSize)))")
    }

    // 写入 Contents.json
    let json = """
    {
      "images" : [
        {
          "filename" : "\(spec.assetName).png",
          "idiom" : "universal",
          "scale" : "1x"
        },
        {
          "filename" : "\(spec.assetName)@2x.png",
          "idiom" : "universal",
          "scale" : "2x"
        },
        {
          "filename" : "\(spec.assetName)@3x.png",
          "idiom" : "universal",
          "scale" : "3x"
        }
      ],
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }
    """
    do {
        try json.write(toFile: "\(dir)/Contents.json", atomically: true, encoding: .utf8)
    } catch {
        throw IconError.fileWrite("无法写入 Contents.json：\(error.localizedDescription)")
    }
}

func requireOptionValue(_ args: [String], at index: Int, flag: String) -> String {
    guard index < args.count else {
        fputs("错误：\(flag) 缺少值\n", stderr)
        exit(1)
    }
    let value = args[index]
    if value.hasPrefix("--") {
        fputs("错误：\(flag) 缺少值\n", stderr)
        exit(1)
    }
    return value
}

// MARK: - CLI

let args = CommandLine.arguments

if args.count < 3 || args.contains("--help") || args.contains("-h") {
    print("""
    用法：generate_icons.swift <sf-symbol-name> <asset-name> [选项]

    选项：
      --size <pt>       基本大小（点）（默认：68）
      --color <hex>     颜色十六进制代码（默认：8E8E93）
      --weight <name>   字体粗细：ultralight|thin|light|regular|medium|semibold|bold|heavy|black（默认：thin）
      --output <dir>    输出目录（默认：/tmp/icons）

    示例：
      generate_icons.swift doc.text.below.ecg editTool_expenseReport
      generate_icons.swift person.crop.rectangle editTool_businessCard --color 007AFF --weight regular
      generate_icons.swift receipt myReceipt --size 48 --output ./Assets.xcassets/icons

    浏览 SF Symbol 名称：打开 SF Symbols 应用（来自 Apple，免费）或 https://developer.apple.com/sf-symbols/
    """)
    exit(0)
}

let symbolName = args[1]
let assetName = args[2]

var baseSize: CGFloat = 68
var colorHex = "8E8E93"
var weightName = "thin"
var outputDir = "/tmp/icons"

var i = 3
while i < args.count {
    switch args[i] {
    case "--size":
        let raw = requireOptionValue(args, at: i + 1, flag: "--size")
        guard let size = Double(raw), size > 0 else {
            fputs("错误：--size 必须是正数\n", stderr)
            exit(1)
        }
        baseSize = CGFloat(size)
        i += 2
        continue
    case "--color":
        colorHex = requireOptionValue(args, at: i + 1, flag: "--color")
        let stripped = colorHex.hasPrefix("#") ? String(colorHex.dropFirst()) : colorHex
        guard stripped.count == 6, UInt64(stripped, radix: 16) != nil else {
            fputs("错误：--color 必须是 6 位十六进制代码（例如 007AFF）\n", stderr)
            exit(1)
        }
        i += 2
        continue
    case "--weight":
        weightName = requireOptionValue(args, at: i + 1, flag: "--weight")
        let validWeights = ["ultralight", "thin", "light", "regular", "medium", "semibold", "bold", "heavy", "black"]
        guard validWeights.contains(weightName.lowercased()) else {
            fputs("错误：--weight 必须是以下之一：\(validWeights.joined(separator: ", "))\n", stderr)
            exit(1)
        }
        i += 2
        continue
    case "--output":
        outputDir = requireOptionValue(args, at: i + 1, flag: "--output")
        i += 2
        continue
    default:
        fputs("警告：未知选项 \(args[i])\n", stderr)
    }
    i += 1
}

let spec = IconSpec(
    symbolName: symbolName,
    assetName: assetName,
    baseSize: baseSize,
    color: parseColor(colorHex),
    weight: parseWeight(weightName)
)

print("正在从 SF Symbol '\(symbolName)' 生成 \(assetName)：")
do {
    try generateIcon(spec, outputDir: outputDir)
    print("输出：\(outputDir)/\(assetName).imageset/")
} catch {
    fputs("错误：\(error)\n", stderr)
    exit(1)
}
