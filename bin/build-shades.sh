#!/usr/bin/env bash
# Author: Evan Wise
# Purpose: Builds src/shades and installs the binary as bin/shades

set -o errexit
set -o nounset

root=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)

cargo build --release --manifest-path "$root/src/shades/Cargo.toml"
install -m755 "$root/src/shades/target/release/shades" "$root/bin/shades"
echo "Installed $root/bin/shades"
