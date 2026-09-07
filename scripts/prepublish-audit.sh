#!/usr/bin/env bash
set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

fail=0
exclude=(--hidden --glob '!.git/**' --glob '!scripts/prepublish-audit.sh')

scan_content() {
  local label="$1"
  local pattern="$2"
  local matches

  matches="$(rg -n -i "${exclude[@]}" -- "$pattern" . 2>/dev/null || true)"
  if [[ -n "$matches" ]]; then
    echo "[FAIL] $label"
    printf '%s\n' "$matches"
    fail=1
  else
    echo "[PASS] $label"
  fi
}

scan_content "private key or certificate block" '-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----|-----BEGIN CERTIFICATE-----'
scan_content "common access-token prefix" 'AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9]{20,}'
scan_content "JWT-like token" 'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
scan_content "credential-style assignment" '(password|passwd|api[_-]?key|access[_-]?token|client[_-]?secret)[[:space:]]*[:=][[:space:]]*[^<{[:space:]][^[:space:]]{3,}'
scan_content "email address" '[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}'
scan_content "SSH public key" 'ssh-(rsa|ed25519)[[:space:]]+[A-Za-z0-9+/]{40,}'
scan_content "embedded credentials in URL" 'https?://[^[:space:]/]+:[^[:space:]@]+@'
scan_content "RFC1918 IPv4 address" '10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}'
scan_content "MAC address" '([0-9A-F]{2}[:-]){5}[0-9A-F]{2}'
scan_content "local macOS user path" '/Users/[^/[:space:]]+/'
scan_content "Notion page or workspace URL" 'https?://[^[:space:])]*notion\.(so|site|com)'

risky_files="$(find . -type f -not -path './.git/*' -not -path './scripts/prepublish-audit.sh' -print | rg -i '/(id_rsa|id_ed25519|\.env($|\.)|credentials|secrets|.*\.(key|pem|p12|pfx|jks|keystore|pcap|pcapng|dump|sql|ova|ovf|qcow2|vmdk|vdi)$)' || true)"
if [[ -n "$risky_files" ]]; then
  echo "[FAIL] risky filename"
  printf '%s\n' "$risky_files"
  fail=1
else
  echo "[PASS] risky filename"
fi

if [[ "$fail" -ne 0 ]]; then
  echo "Pre-publication audit failed. Review every finding before publishing."
  exit 1
fi

echo "Pre-publication audit passed. Complete the manual image and Git-history review before publishing."
