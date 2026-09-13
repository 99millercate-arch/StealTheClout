#!/usr/bin/env bash
# Generate build/StealTheClout.rbxlx from src/ without Rojo (mirrors default.project.json).
# Usage: bash scripts/gen-rbxlx.sh   then open build/StealTheClout.rbxlx in Studio.
set -e
cd "$(dirname "$0")/.."   # run from repo root regardless of cwd
mkdir -p build
n=0
ref() { n=$((n+1)); echo "RBX$n"; }
item_open() { # class name
  echo "<Item class=\"$1\" referent=\"$(ref)\"><Properties><string name=\"Name\">$2</string></Properties>"
}
script_item() { # class name file
  echo "<Item class=\"$1\" referent=\"$(ref)\"><Properties><string name=\"Name\">$2</string><ProtectedString name=\"Source\"><![CDATA["
  cat "$3"
  echo "]]></ProtectedString></Properties></Item>"
}
# emit a directory: files become scripts, subdirs become Folders
emit_dir() {
  local dir="$1"
  for f in "$dir"/*; do
    [ -e "$f" ] || continue
    local base=$(basename "$f")
    if [ -d "$f" ]; then
      item_open Folder "$base"; emit_dir "$f"; echo "</Item>"
    else
      case "$base" in
        *.server.lua) script_item Script "${base%.server.lua}" "$f" ;;
        *.client.lua) script_item LocalScript "${base%.client.lua}" "$f" ;;
        *.lua)        script_item ModuleScript "${base%.lua}" "$f" ;;
      esac
    fi
  done
}
{
echo '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">'
item_open Workspace Workspace; echo "</Item>"
item_open ReplicatedStorage ReplicatedStorage; emit_dir src/ReplicatedStorage; echo "</Item>"
item_open ServerScriptService ServerScriptService; emit_dir src/ServerScriptService; echo "</Item>"
item_open StarterPlayer StarterPlayer
  item_open StarterPlayerScripts StarterPlayerScripts; emit_dir src/StarterPlayer/StarterPlayerScripts; echo "</Item>"
echo "</Item>"
echo '</roblox>'
} > build/StealTheClout.rbxlx
echo "wrote build/StealTheClout.rbxlx ($(wc -c < build/StealTheClout.rbxlx) bytes)"
