Q_TITLE="Find a package across 3 images, then SPDX (bom) + CycloneDX (trivy) reports"
Q_TAGS="cluster host"
Q15_NS=sbom-lab; Q15_POD=three-images
Q15_IMAGES="alpine:3.20 alpine:3.21 alpine:3.22"

q_setup() {
  local d; d=$(labdir q15)
  need_bin docker "Docker is required to inspect the images."
  step "pulling the three images"
  local img
  for img in $Q15_IMAGES; do docker pull -q "$img" >/dev/null 2>&1 || warn "could not pull $img"; done

  # Discover the real libcrypto3 version in each image, then pick a target.
  # Doing it dynamically keeps the question correct as Alpine updates.
  step "determining the target package version from the real images"
  : > "$d/.pkgmap"
  for img in $Q15_IMAGES; do
    local v
    v=$(docker run --rm "$img" apk info -v -i -e -a 2>/dev/null | grep -m1 '^libcrypto3' || true)
    printf '%s %s\n' "$img" "${v:-none}" >> "$d/.pkgmap"
  done
  # target = the LAST image's version (deterministic, and distinct in practice)
  local timg tver
  timg=$(tail -1 "$d/.pkgmap" | awk '{print $1}')
  tver=$(tail -1 "$d/.pkgmap" | awk '{print $2}')
  if [ "$tver" = "none" ] || [ -z "$tver" ]; then
    warn "could not read libcrypto3 from $timg; falling back to a static target"
    timg="alpine:3.22"; tver="libcrypto3-3.5.8-r0"
  fi
  local tnum; tnum=${tver#libcrypto3-}
  printf '%s\n%s\n%s\n' "$timg" "$tver" "$tnum" > "$d/.target"

  # setup is a fresh start: discard any reports from a previous attempt
  rm -rf "$d/out"
  kq create ns "$Q15_NS"
  kq -n "$Q15_NS" delete pod "$Q15_POD"
  local i=1 containers=""
  for img in $Q15_IMAGES; do
    containers="$containers
  - name: c$i
    image: $img
    command: [\"sh\",\"-c\",\"sleep 86400\"]"
    i=$((i+1))
  done
  k apply -f - >/dev/null <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: $Q15_POD
  namespace: $Q15_NS
spec:
  containers:$containers
EOF
  k -n "$Q15_NS" wait --for=condition=Ready "pod/$Q15_POD" --timeout=300s >/dev/null 2>&1 \
    || warn "pod not Ready yet"
  mkdir -p "$d/out"

  cat > "$d/TASK.md" <<EOF
Pod "$Q15_POD" in namespace "$Q15_NS" runs THREE containers on three different
images.

1. Find which of the three images contains the package:
       libcrypto3   version $tnum

   e.g.  kubectl --context $KCTX -n $Q15_NS exec $Q15_POD -c c1 -- apk info -v -i -e -a | grep libcrypto3

2. For THAT image, generate an SBOM in SPDX format using 'bom' and save it to:
       $d/out/sbom.spdx.json

3. For the SAME image, generate a CycloneDX report using 'trivy' and save it to:
       $d/out/report.cdx.json

Notes:
 - 'bom' only accepts --format values: tag-value | json | spdx3-json
   There is NO 'spdx-json' value; --format json IS SPDX 2.3 JSON.
 - Install if needed:  brew install bom trivy

Grade with:  ./cks verify 15
EOF
  step "target: $tver in $timg"
  step "task in $d/TASK.md"
}

q_verify() {
  start_checks
  local d="$LAB/q15"
  [ -f "$d/.target" ] || { no "question is set up" "./cks setup 15"; report; return; }
  local timg tver tnum
  timg=$(sed -n 1p "$d/.target"); tver=$(sed -n 2p "$d/.target"); tnum=$(sed -n 3p "$d/.target")
  local spdx="$d/out/sbom.spdx.json" cdx="$d/out/report.cdx.json"

  # --- SPDX report ---
  if [ ! -s "$spdx" ]; then
    no "SPDX SBOM exists at out/sbom.spdx.json" "bom generate --format json --image $timg -o $spdx"
  else
    ok "SPDX SBOM exists at out/sbom.spdx.json"
    if python3 -c "import json,sys;json.load(open('$spdx'))" >/dev/null 2>&1; then
      ok "SPDX file is valid JSON"
      local sv
      sv=$(python3 -c "import json;print(json.load(open('$spdx')).get('spdxVersion',''))" 2>/dev/null)
      if printf '%s' "$sv" | grep -q '^SPDX-'; then
        ok "SPDX file declares spdxVersion ($sv)"
      else
        no "SPDX file declares spdxVersion" "got '${sv:-none}' -- is this really a bom/SPDX document?"
      fi
      # must describe the CORRECT image
      if grep -q "${timg%%:*}" "$spdx" && grep -q "${timg##*:}" "$spdx"; then
        ok "SPDX SBOM is for the correct image ($timg)"
      else
        no "SPDX SBOM is for the correct image ($timg)" \
           "the package $tnum lives in $timg -- you scanned a different one"
      fi
    else
      no "SPDX file is valid JSON" "truncated or wrong format"
    fi
  fi

  # --- CycloneDX report ---
  if [ ! -s "$cdx" ]; then
    no "CycloneDX report exists at out/report.cdx.json" "trivy image --format cyclonedx --output $cdx $timg"
  else
    ok "CycloneDX report exists at out/report.cdx.json"
    if python3 -c "import json,sys;json.load(open('$cdx'))" >/dev/null 2>&1; then
      ok "CycloneDX file is valid JSON"
      local bf
      bf=$(python3 -c "import json;print(json.load(open('$cdx')).get('bomFormat',''))" 2>/dev/null)
      [ "$bf" = "CycloneDX" ] && ok "CycloneDX file declares bomFormat=CycloneDX" \
        || no "CycloneDX file declares bomFormat=CycloneDX" "got '${bf:-none}' -- wrong --format?"
      if grep -q "${timg%%:*}" "$cdx" && grep -q "${timg##*:}" "$cdx"; then
        ok "CycloneDX report is for the correct image ($timg)"
      else
        no "CycloneDX report is for the correct image ($timg)" "expected $timg"
      fi
      # cross-check: the target package should appear in the SBOM
      if grep -q "$tnum" "$cdx" || grep -q 'libcrypto3' "$cdx"; then
        ok "CycloneDX report lists libcrypto3 (confirms the right image)"
      else
        no "CycloneDX report lists libcrypto3" "the correct image contains $tver"
      fi
    else
      no "CycloneDX file is valid JSON" "truncated or wrong format"
    fi
  fi

  # --- did they identify the right image at all? (independent check) ---
  if [ -s "$spdx" ] || [ -s "$cdx" ]; then
    local wrong="" img
    for img in $Q15_IMAGES; do
      [ "$img" = "$timg" ] && continue
      if { [ -s "$spdx" ] && grep -q "\"${img##*:}\"" "$spdx" 2>/dev/null; }; then wrong="$img"; fi
    done
    [ -z "$wrong" ] && ok "no report was generated for a wrong image" \
      || no "no report was generated for a wrong image" "found a reference to $wrong"
  fi
  report
}

q_solve() {
  local d="$LAB/q15"
  [ -f "$d/.target" ] || { warn "run ./cks setup 15 first"; return 1; }
  local timg; timg=$(sed -n 1p "$d/.target")
  mkdir -p "$d/out"
  command -v bom   >/dev/null 2>&1 || { warn "bom not installed: brew install bom"; }
  command -v trivy >/dev/null 2>&1 || { warn "trivy not installed: brew install trivy"; }
  command -v bom   >/dev/null 2>&1 && bom generate --format json --image "$timg" -o "$d/out/sbom.spdx.json" >/dev/null 2>&1
  command -v trivy >/dev/null 2>&1 && trivy image --format cyclonedx --output "$d/out/report.cdx.json" "$timg" >/dev/null 2>&1
  step "reports written for $timg"
}

q_reset() { kq -n "$Q15_NS" delete pod "$Q15_POD"; q_setup; }
