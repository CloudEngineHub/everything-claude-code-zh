#!/bin/bash
#
# 从 Iconify API（275k+ 开源图标）生成 iOS icon imagesets
# 使用：curl（下载 SVG）+ sips（SVG->PNG 转换，内置于 macOS）
#
# 用法：
#   iconify_gen.sh <icon-id> <asset-name> [选项]
#   iconify_gen.sh search <query> [--prefix <collection>] [--limit <n>]
#
# 示例：
#   iconify_gen.sh mdi:receipt-text-outline myExpenseIcon
#   iconify_gen.sh search "business card"
#   iconify_gen.sh search receipt --prefix mdi

set -euo pipefail

API_BASE="https://api.iconify.design"
readonly CURL_OPTS=(--fail --silent --show-error --connect-timeout 10 --max-time 30)

# 默认值
SIZE=68
COLOR="8E8E93"
OUTPUT="/tmp/icons"
LIMIT=20

require_value() {
    local flag="$1"
    local value="${2-}"
    if [[ -z "$value" || "$value" == --* ]]; then
        echo "错误：${flag} 需要一个值" >&2
        exit 1
    fi
}

usage() {
    cat <<'EOF'
用法：
  iconify_gen.sh <icon-id> <asset-name> [选项]    生成图标 imageset
  iconify_gen.sh search <query> [选项]             搜索图标
  iconify_gen.sh preview <icon-id>                下载预览 SVG
  iconify_gen.sh collections                          列出流行图标集合

生成选项：
  --size <pt>       基本大小（点）（默认：68）
  --color <hex>     颜色十六进制不带 #（默认：8E8E93）
  --output <dir>   输出目录（默认：/tmp/icons）

搜索选项：
  --prefix <name>   按集合过滤（例如：mdi、lucide、tabler、ph）
  --limit <n>       最大结果数（默认：20）

图标 ID 格式：<collection>:<icon-name>
  示例：mdi:receipt-text-outline、lucide:credit-card、ph:address-book

流行集合：
  mdi      Material Design Icons（7400+ 图标）
  lucide   Lucide（1700+ 图标）
  tabler   Tabler Icons（6000+ 图标）
  ph       Phosphor（9000+ 图标）
  ri       Remix Icon（2800+ 图标）
  carbon   Carbon（2100+ 图标）
EOF
    exit 0
}

search_icons() {
    local query="$1"
    shift
    local prefix=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --prefix) require_value --prefix "${2-}"; prefix="$2"; shift 2 ;;
            --limit) require_value --limit "${2-}"; LIMIT="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    local encoded_query
    encoded_query="$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$query")"
    local url="${API_BASE}/search?query=${encoded_query}&limit=${LIMIT}"
    if [[ -n "$prefix" ]]; then
        url="${url}&prefix=${prefix}"
    fi

    local response
    response=$(curl "${CURL_OPTS[@]}" "$url") || { echo "错误：搜索请求失败"; exit 1; }

    local total
    total=$(echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('total',0))")

    echo "为 '${query}' 找到 ${total} 个图标："
    echo ""
    echo "$response" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for icon in data.get('icons', []):
    print(f'  {icon}')
"
    echo ""
    echo "生成命令：iconify_gen.sh <icon-id> <asset-name>"
    echo "预览命令：  iconify_gen.sh preview <icon-id>"
}

list_collections() {
    echo "流行的 Iconify 集合："
    echo ""
    local resp
    resp=$(curl "${CURL_OPTS[@]}" "${API_BASE}/collections") || { echo "错误：无法获取集合列表"; exit 1; }
    echo "$resp" | python3 -c "
import sys, json
data = json.load(sys.stdin)
popular = ['mdi','lucide','tabler','ph','ri','carbon','solar','heroicons','bi','octicon','ion','fe','charm','ci','iconoir','basil','uil','mingcute','flowbite','mynaui']
for k in popular:
    if k in data:
        v = data[k]
        name = v.get('name','')
        total = v.get('total',0)
        print(f'  {k:12s} {name} ({total} 图标)')
"
    echo ""
    echo "完整列表：https://icon-sets.iconify.design/"
}

preview_icon() {
    local icon_id="$1"
    local collection="${icon_id%%:*}"
    local name="${icon_id#*:}"
    local url="${API_BASE}/${collection}/${name}.svg?width=136&height=136&color=%23${COLOR}"
    local outfile="/tmp/iconify_preview_${collection}_${name}.svg"

    curl "${CURL_OPTS[@]}" "$url" -o "$outfile" || { echo "错误：未找到图标 '${icon_id}'"; exit 1; }
    echo "预览 SVG：${outfile}"
    echo "URL：${url}"

    # 也转换为 PNG 以进行视觉检查
    local pngfile="/tmp/iconify_preview_${collection}_${name}.png"
    sips -s format png "$outfile" --out "$pngfile" >/dev/null 2>&1 || echo "警告：sips 转换失败；PNG 可能不正确"
    echo "预览 PNG：${pngfile}"
}

generate_icon() {
    local icon_id="$1"
    local asset_name="$2"
    shift 2

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --size) require_value --size "${2-}"; SIZE="$2"; shift 2 ;;
            --color) require_value --color "${2-}"; COLOR="$2"; shift 2 ;;
            --output) require_value --output "${2-}"; OUTPUT="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    local collection="${icon_id%%:*}"
    local name="${icon_id#*:}"
    local imageset_dir="${OUTPUT}/${asset_name}.imageset"

    mkdir -p "$imageset_dir"

    echo "正在从 Iconify '${icon_id}' 生成 ${asset_name}："

    local scales=("1:${SIZE}" "2:$((SIZE * 2))" "3:$((SIZE * 3))")

    for scale_info in "${scales[@]}"; do
        local scale="${scale_info%%:*}"
        local px="${scale_info#*:}"
        local suffix=""
        [[ "$scale" != "1" ]] && suffix="@${scale}x"

        local svg_url="${API_BASE}/${collection}/${name}.svg?width=${px}&height=${px}&color=%23${COLOR}"
        local svg_file="${imageset_dir}/${asset_name}${suffix}.svg"
        local png_file="${imageset_dir}/${asset_name}${suffix}.png"

        curl "${CURL_OPTS[@]}" "$svg_url" -o "$svg_file" || { echo "错误：无法下载图标 '${icon_id}'"; exit 1; }
        sips -s format png "$svg_file" --out "$png_file" >/dev/null 2>&1 || echo "警告：${svg_file} 的 sips 转换可能失败"
        rm "$svg_file"

        echo "  ${asset_name}${suffix}.png (${px}x${px})"
    done

    # 写入 Contents.json
    cat > "${imageset_dir}/Contents.json" <<JSONEOF
{
  "images" : [
    {
      "filename" : "${asset_name}.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "${asset_name}@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "${asset_name}@3x.png",
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSONEOF

    echo "输出：${imageset_dir}/"
}

# 主程序
[[ $# -eq 0 ]] && usage
[[ "$1" == "--help" || "$1" == "-h" ]] && usage

case "$1" in
    search)
        shift
        [[ $# -eq 0 ]] && { echo "用法：iconify_gen.sh search <query>"; exit 1; }
        search_icons "$@"
        ;;
    preview)
        shift
        [[ $# -eq 0 ]] && { echo "用法：iconify_gen.sh preview <icon-id>"; exit 1; }
        preview_icon "$1"
        ;;
    collections)
        list_collections
        ;;
    *)
        [[ $# -lt 2 ]] && { echo "用法：iconify_gen.sh <icon-id> <asset-name> [选项]"; exit 1; }
        generate_icon "$@"
        ;;
esac
