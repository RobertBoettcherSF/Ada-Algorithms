#!/bin/bash
# per-folder build+test on new layout. GNAT 14 = system (/usr/bin), GNAT 12 = Alire toolchain via PATH only.
id="$1"; R=${AA_ROOT:-$(git rev-parse --show-toplevel)}; safe=$(echo "$id" | tr '/' '_')
GPRB=${GPRBUILD_BIN:-$(ls -d $HOME/.local/alr/gprbuild_* | head -1)/bin}
G12=${GNAT12_BIN:-$(ls -d $HOME/.local/alr/gnat_native_12* | head -1)/bin}
W=${AA_WORK:-/tmp/aa_build}/$safe; rm -rf "$W"; mkdir -p "$W"; lev=$(dirname "$R/$id")
deps=$( [ -f "${AA_DEPS:-}" ] && python3 -c "import json,sys;print(' '.join(json.load(open(sys.argv[2])).get(sys.argv[1],[])))" "$id" "$AA_DEPS" )
for v in 14 12; do
  cp -r "$R/$id" "$W/m$v"; rm -rf "$W/m$v/obj" "$W/m$v/bin"
  for f in $deps; do cp "$lev/$f" "$W/m$v/"; done
done
if [ "$v" ]; then :; fi
P14=/usr/bin:/bin:$GPRB; P12=$G12:$GPRB:/usr/bin:/bin
# Refuse to record a result from the wrong compiler: the first line of `gnatmake --version` (and gcc's
# version, which gprbuild uses) must name GNAT 14 on P14 and GNAT 12 on P12. The version goes into the record.
ver14=$(PATH=$P14 gnatmake --version 2>/dev/null | head -1); ver12=$(PATH=$P12 gnatmake --version 2>/dev/null | head -1)
gcc14=$(PATH=$P14 gcc -dumpfullversion 2>/dev/null); gcc12=$(PATH=$P12 gcc -dumpfullversion 2>/dev/null)
case "$ver14|$gcc14" in "GNATMAKE 14."*"|14."*) ;; *) echo "{\"id\": \"$id\", \"error\": \"GNAT 14 expected, got $ver14 / gcc $gcc14\"}"; exit 2;; esac
case "$ver12|$gcc12" in "GNATMAKE 12."*"|12."*) ;; *) echo "{\"id\": \"$id\", \"error\": \"GNAT 12 expected, got $ver12 / gcc $gcc12\"}"; exit 2;; esac
MT=${AA_MAKE_TIMEOUT:-900}
mk=NA; mk12=NA
if [ -f "$W/m14/Makefile" ]; then
  ( cd "$W/m14" && PATH=$P14 timeout $MT make test ) > "$W/mk14.log" 2>&1; mk=$?
  ( cd "$W/m12" && PATH=$P12 timeout $MT make test GNAT=gnatmake ) > "$W/mk12.log" 2>&1; mk12=$?
fi
main=$(cd "$W/m14"; for c in tests.adb test*.adb tests/main.adb src/tests.adb; do [ -f "$c" ] && { echo "$c"; break; }; done)
INC=""; for dd in src tests; do [ -d "$W/m14/$dd" ] && INC="$INC -I$dd"; done
u14=NA; w14=NA; u12=NA; w12=NA; r14=NA; r12=NA
if [ -n "$main" ]; then
  cp -r "$R/$id" "$W/u"; for f in $deps; do cp "$lev/$f" "$W/u/"; done; rm -rf "$W/u/obj" "$W/u/bin"; find "$W/u" -name "*.ali" -delete -o -name "*.o" -delete; cd "$W/u"
  mkdir -p o14 o12
  PATH=$P14 timeout 300 gnatmake -gnatwa -gnat2022 $INC -D o14 -o t14 "$main" > ../u14.log 2>&1; u14=$?
  [ $u14 = 0 ] && { timeout 60 ./t14 > ../r14.log 2>&1; r14=$?; }
  PATH=$P12 timeout 300 gnatmake -gnatwa -gnat2022 $INC -D o12 -o t12 "$main" > ../u12.log 2>&1; u12=$?
  [ $u12 = 0 ] && { timeout 60 ./t12 > ../r12.log 2>&1; r12=$?; }
  w14=$(grep -c 'warning:' ../u14.log); w12=$(grep -c 'warning:' ../u12.log)
fi
python3 - "$id" "$mk" "$mk12" "$main" "$u14" "$w14" "$r14" "$u12" "$w12" "$r12" "$deps" "$W" "$ver14" "$ver12" <<'P'
import json,sys,re,os
a=sys.argv; W=a[12]
ok=re.compile(r'FAIL(ED|S|URES?)?\s*[:=]?\s*0\b|\b0\s+FAIL|FAILURE DISPROVED|0 failed|no FAIL',re.I)
def fl(p):
    if not os.path.exists(p): return None
    return sum(1 for l in open(p,errors='replace') if 'FAIL' in l and not ok.search(l))
def wall(*ps):   # distinct warnings over the uniform -gnatwa build and the folder's own make test build
    s=set()
    for p in ps:
        if os.path.exists(p):
            s |= {re.sub(r'^.*/','',l.strip()) for l in open(p,errors='replace') if 'warning:' in l}
    return len(s)
print(json.dumps(dict(id=a[1],mk14=a[2],mk12=a[3],main=a[4],u14=a[5],w14=a[6],r14=a[7],u12=a[8],w12=a[9],r12=a[10],shared=a[11].split(),
  fail_mk14=fl(W+'/mk14.log'),fail_mk12=fl(W+'/mk12.log'),fail_r14=fl(W+'/r14.log'),fail_r12=fl(W+'/r12.log'),ver14=a[13],ver12=a[14],wall14=wall(W+'/u14.log',W+'/mk14.log'),wall12=wall(W+'/u12.log',W+'/mk12.log'))))
P
