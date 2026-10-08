#!/bin/bash
id="$1"; R=${AA_ROOT:-$(git rev-parse --show-toplevel)}; safe=$(echo "$id" | tr '/' '_')
export PATH=${GNATPROVE_BIN:-$(ls -d $HOME/.local/alr/gnatprove_* | head -1)/bin}:${GPRBUILD_BIN:-$(ls -d $HOME/.local/alr/gprbuild_* | head -1)/bin}:/usr/bin:/bin
W=${AA_PROVE_WORK:-/tmp/aa_prove}/$safe; rm -rf "$W"; mkdir -p "$W"; lev=$(dirname "$R/$id")
deps=$( [ -f "${AA_DEPS:-}" ] && python3 -c "import json,sys;print(' '.join(json.load(open(sys.argv[2])).get(sys.argv[1],[])))" "$id" "$AA_DEPS" )
cp -r "$R/$id"/. "$W/"; rm -rf "$W/obj" "$W/bin" "$W/gnatprove"
for f in $deps; do cp "$lev/$f" "$W/"; done
cd "$W"
gpr=""; how=""
if [ -f Makefile ]; then
  g=$(grep -E '^PROOF_PROJECT\s*:?=' Makefile | head -1 | sed 's/.*=\s*//;s/\s*$//')
  [ -n "$g" ] && [ -f "$g" ] && { gpr=$g; how=makefile_proof_project; }
fi
[ -z "$gpr" ] && { g=$(ls proof*.gpr 2>/dev/null | head -1); [ -n "$g" ] && { gpr=$g; how=proof_gpr; }; }
if [ -z "$gpr" ] && [ -f Makefile ]; then
  g=$(grep -oE '(-P\s*|PROJECT\s*:?=\s*)[A-Za-z0-9_.-]+\.gpr' Makefile | head -1 | sed -E 's/^(-P\s*|PROJECT\s*:?=\s*)//')
  [ -n "$g" ] && [ -f "$g" ] && { gpr=$g; how=makefile_project; }
fi
[ -z "$gpr" ] && { n=$(ls *.gpr 2>/dev/null | wc -l); [ "$n" -ge 1 ] && { gpr=$(ls *.gpr | head -1); how=only_gpr; [ "$n" -gt 1 ] && how=first_of_$n; }; }
if [ -z "$gpr" ]; then
  files=$(ls *.ads *.adb 2>/dev/null | grep -v '^test' | sed 's/.*/"&"/' | paste -sd, -)
  [ -z "$files" ] && { echo "{\"id\":\"$id\",\"status\":\"no_sources\",\"gpr\":\"\",\"how\":\"\"}"; exit; }
  printf 'project AA_Generated is\n   for Source_Dirs use (".");\n   for Source_Files use (%s);\n   for Object_Dir use "obj";\nend AA_Generated;\n' "$files" > aa_generated.gpr
  gpr=aa_generated.gpr; how=generated
fi
start=$(date +%s)
timeout 1500 gnatprove -P "$gpr" --mode=silver --level=2 -j1 --output=oneline -k > prove.log 2>&1; rc=$?
echo "{\"id\":\"$id\",\"status\":\"done\",\"rc\":$rc,\"secs\":$(( $(date +%s)-start )),\"gpr\":\"$gpr\",\"how\":\"$how\"}"
