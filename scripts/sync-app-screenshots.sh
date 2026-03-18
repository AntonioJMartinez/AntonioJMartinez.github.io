#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCREENSHOTS_ROOT="$ROOT_DIR/images/apps/screenshots"
MANIFEST_PATH="$ROOT_DIR/js/app-screenshot-manifest.js"
SCREENSHOT_LIMIT=4

APPS=(
  '6502008343|solora|https://apps.apple.com/es/app/atardecer-amanecer-solora/id6502008343'
  '6752911194|cogno|https://apps.apple.com/us/app/movie-diary-book-tracker-cogno/id6752911194'
  '6651860798|olamar|https://apps.apple.com/us/app/marine-weather-beaches-olamar/id6651860798'
  '916525681|dinata|https://apps.apple.com/us/app/aac-text-to-speech-tts-dinata/id916525681'
  '6740244417|wige|https://apps.apple.com/es/app/sorteo-amigo-invisible-wige/id6740244417'
  '1182999726|nimblit|https://apps.apple.com/es/app/nimblit-juegos-mentales/id1182999726'
)

mkdir -p "$SCREENSHOTS_ROOT" "$(dirname "$MANIFEST_PATH")"

manifest_entries=()

for app in "${APPS[@]}"; do
  IFS='|' read -r app_id slug page_url <<< "$app"

  app_dir="$SCREENSHOTS_ROOT/$slug"
  rm -rf "$app_dir"
  mkdir -p "$app_dir"

  html="$(curl -L -s "$page_url")"
  urls_text="$(printf '%s' "$html" | node -e '
let html = "";
process.stdin.on("data", (chunk) => {
  html += chunk;
});
process.stdin.on("end", () => {
  const limit = Number.parseInt(process.argv[1], 10);
  const mediaSectionStart = html.indexOf("<section id=\"product_media");
  const mediaHtml = mediaSectionStart >= 0 ? html.slice(mediaSectionStart) : html;
  const matches = [...mediaHtml.matchAll(/<source[^>]+srcset="([^"]+)"[^>]*type="image\/jpeg"/gi)];
  const map = new Map();

  const parseSrcset = (srcset) =>
    srcset
      .split(",")
      .map((entry) => {
        const [url, descriptor] = entry.trim().split(/\s+/);
        const width = Number.parseInt((descriptor || "").replace("w", ""), 10) || 0;
        const sizeMatch = url.match(/\/(\d+)x(\d+)bb(?:-\d+)?\.(?:png|webp|jpe?g)$/i);
        const renderedWidth = sizeMatch ? Number.parseInt(sizeMatch[1], 10) : 0;
        const renderedHeight = sizeMatch ? Number.parseInt(sizeMatch[2], 10) : 0;

        return { url, width, renderedWidth, renderedHeight };
      })
      .filter(({ url, renderedWidth, renderedHeight }) =>
        Boolean(url) &&
        !/Placeholder|AppIcon/i.test(url) &&
        renderedHeight > renderedWidth &&
        renderedWidth >= 150
      );

  const getBaseImageUrl = (url) =>
    url.replace(/\/\d+x\d+bb(?:-\d+)?\.(?:png|webp|jpe?g)$/i, "");

  for (const [, srcset] of matches) {
    const bestCandidate = parseSrcset(srcset).reduce((largest, candidate) => {
      if (!largest || candidate.width > largest.width) {
        return candidate;
      }

      return largest;
    }, null);

    if (!bestCandidate) {
      continue;
    }

    const baseImageUrl = getBaseImageUrl(bestCandidate.url);
    const existing = map.get(baseImageUrl);

    if (!existing || bestCandidate.width > existing.width) {
      map.set(baseImageUrl, bestCandidate);
    }
  }

  process.stdout.write(
    [...map.values()]
      .slice(0, limit)
      .map(({ url }) => url)
      .join("\n")
  );
});
' "$SCREENSHOT_LIMIT")"
  urls=("${(@f)urls_text}")

  local_paths=()
  index=1

  for url in "${urls[@]}"; do
    [[ -z "$url" ]] && continue

    filename="$(printf '%02d.jpg' "$index")"
    relative_path="images/apps/screenshots/$slug/$filename"

    curl -L -s "$url" -o "$app_dir/$filename"
    local_paths+=("\"$relative_path\"")
    ((index++))
  done

  manifest_entries+=("  \"$app_id\": [${(j:, :)local_paths}]")
  echo "$slug: ${#local_paths[@]} screenshots"
done

{
  echo 'window.APP_SCREENSHOT_MANIFEST = {'

  for i in "${!manifest_entries[@]}"; do
    entry="${manifest_entries[$i]}"

    if (( i < ${#manifest_entries[@]} - 1 )); then
      echo "$entry,"
    else
      echo "$entry"
    fi
  done

  echo '};'
} > "$MANIFEST_PATH"

echo "Manifest written to ${MANIFEST_PATH#$ROOT_DIR/}"
