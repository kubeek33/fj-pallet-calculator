#!/bin/bash
# Rebuilds ui.html for Figma plugin by inlining presets-default.js.
# Run this every time you update presets-default.js or ui.html.backup.
# Usage: ./rebuild-figma-ui.sh

set -e
cd "$(dirname "$0")"

PLUGIN_DIR="Forjars Pallet Calculator"
BACKUP="$PLUGIN_DIR/ui.html.backup"
PRESETS="presets-default.js"
OUT="$PLUGIN_DIR/ui.html"

if [ ! -f "$BACKUP" ]; then
  echo "❌ Не знайдено $BACKUP (потрібен як шаблон)"
  exit 1
fi

if [ ! -f "$PRESETS" ]; then
  echo "❌ Не знайдено $PRESETS"
  exit 1
fi

# Find loader block boundaries in backup (lines to replace)
START=$(grep -n "// Load built-in default presets" "$BACKUP" | head -1 | cut -d: -f1)
END=$(awk -v s="$START" 'NR>=s && /^\}\)\(\);$/ {print NR; exit}' "$BACKUP")

if [ -z "$START" ] || [ -z "$END" ]; then
  echo "❌ Не вдалося знайти межі лоадера у $BACKUP"
  exit 1
fi

echo "⚙  Перебудова ui.html (заміна рядків $START-$END)..."

{
  head -n $((START-1)) "$BACKUP"
  echo ""
  echo "// === INLINED PRESETS (no network, fully local) ==="
  cat "$PRESETS"
  echo ""
  echo "(()=>{"
  echo "  const defaults=window._FP_DEFAULTS;"
  echo "  if(window._FP_DEFAULTS)delete window._FP_DEFAULTS;"
  echo "  if(defaults){"
  echo "    let added=0;"
  echo "    Object.keys(defaults).forEach(sku=>{"
  echo "      if(!presets[sku]){presets[sku]=defaults[sku];added++;}"
  echo "    });"
  echo "    if(added>0)toast(\`\${added} products loaded\`);"
  echo "  }"
  echo "  _rebuildCatalog();"
  echo "  updPP();"
  echo "})();"
  tail -n +$((END+1)) "$BACKUP"
} > "$OUT"

SIZE=$(ls -lh "$OUT" | awk '{print $5}')
echo "✅ Готово: $OUT ($SIZE)"
echo "   Перезавантаж плагін у Figma: Plugins → Development → Reimport"
