#!/usr/bin/env bash
#
# gen-trust-test-fixtures.sh
#
# Regenerates the certificate fixtures used by SEBBrowserControllerTrustTests.swift.
# The fixtures verify the embedded-certificate / public-key-pinning server-trust
# decision in +[SEBBrowserController shouldAuthorizeServerTrust:...] and guard the
# removed authorizedHosts substring bypass (CWE-295).
#
# Output: base64 (single line) of DER certificates, printed to stdout. Copy the
# values into the `Fixtures` constants in SEBBrowserControllerTrustTests.swift.
# (Every run creates fresh keys, so replace ALL six constants together.)
#
# Apple's SSL trust policy imposes requirements that the fixtures must satisfy so
# the "valid" leaves are actually accepted:
#   * leaf certificates need EKU serverAuth and a Subject Alternative Name, and
#   * TLS server (leaf) certificates must be valid for <= 398 days.
# So leaves are issued for 397 days (NOT far-future); only the root CA is long
# lived. The expired leaf is intentionally already expired.
#
# Requires OpenSSL 3.x (the expired leaf is issued via `openssl ca -startdate
# -enddate`, which works on 3.1; the 3.2-only -not_before/-not_after is avoided).
#
set -euo pipefail

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cd "$work"

CA_DAYS=36500   # ~100 years (root anchor lifetime is not bound by the 398-day rule)
LEAF_DAYS=397   # <= 398 days, required by Apple's TLS policy for server certs

der_b64() { openssl x509 -in "$1" -outform DER | base64 | tr -d '\n'; }
emit() { printf '\n===== %s =====\n%s\n' "$1" "$(der_b64 "$2")"; }

# Leaf extensions: SAN + non-CA + serverAuth EKU (required for the SSL policy).
leaf_ext() {
  printf "subjectAltName=DNS:%s\nbasicConstraints=critical,CA:FALSE\nkeyUsage=critical,digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth\n" "$1"
}

# --- Test CA (self-signed root, CA:TRUE) -----------------------------------
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout ca.key -out ca.crt -days "$CA_DAYS" \
  -subj "/CN=SEB Test Root CA" \
  -addext "basicConstraints=critical,CA:TRUE" \
  -addext "keyUsage=critical,keyCertSign,cRLSign" >/dev/null 2>&1

# Helper: create a CA-signed leaf. $1=cn/dns $2=outbase
sign_leaf() {
  local dns="$1" out="$2"
  openssl req -newkey rsa:2048 -nodes -keyout "$out.key" -out "$out.csr" \
    -subj "/CN=$dns" >/dev/null 2>&1
  openssl x509 -req -in "$out.csr" -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out "$out.crt" -days "$LEAF_DAYS" \
    -extfile <(leaf_ext "$dns") >/dev/null 2>&1
}

# --- Valid leaves chaining to the test CA ----------------------------------
sign_leaf "example.test"     valid_example
sign_leaf "sub.example.test" valid_sub

# --- Wrong-host leaf (CA-signed, otherwise valid, but SAN=other.test) ------
sign_leaf "other.test"       wronghost

# --- Expired leaf for example.test (CA-signed, notAfter in the past) --------
# Valid 2000-01-01 .. 2001-01-01, issued via `openssl ca` for explicit dates.
mkdir -p demoCA/newcerts
: > demoCA/index.txt
echo 01 > demoCA/serial
cat > ca.cnf <<EOF
[ ca ]
default_ca = CA_default
[ CA_default ]
dir              = ./demoCA
database         = \$dir/index.txt
new_certs_dir    = \$dir/newcerts
serial           = \$dir/serial
certificate      = ./ca.crt
private_key      = ./ca.key
default_md       = sha256
policy           = policy_any
email_in_dn      = no
rand_serial      = no
unique_subject   = no
[ policy_any ]
commonName       = supplied
EOF
openssl req -newkey rsa:2048 -nodes -keyout expired.key -out expired.csr \
  -subj "/CN=example.test" >/dev/null 2>&1
openssl ca -batch -config ca.cnf -in expired.csr -out expired.crt \
  -startdate 20000101000000Z -enddate 20010101000000Z \
  -extfile <(leaf_ext "example.test") >/dev/null 2>&1

# --- Self-signed leaf for example.test (unknown CA) ------------------------
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout selfsigned.key -out selfsigned.crt -days "$LEAF_DAYS" \
  -subj "/CN=example.test" \
  -addext "subjectAltName=DNS:example.test" \
  -addext "basicConstraints=critical,CA:FALSE" \
  -addext "keyUsage=critical,digitalSignature,keyEncipherment" \
  -addext "extendedKeyUsage=serverAuth" >/dev/null 2>&1

emit "CA"                     ca.crt
emit "VALID example.test"     valid_example.crt
emit "VALID sub.example.test" valid_sub.crt
emit "WRONG-HOST other.test"  wronghost.crt
emit "EXPIRED example.test"   expired.crt
emit "SELF-SIGNED example.test" selfsigned.crt
