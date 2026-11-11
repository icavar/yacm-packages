#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 The YACM Authors.
#
# Builds the apt and dnf repository for pkg.yacm.app.
#
#   build.sh IN OUT VERSION
#
# IN holds the yacm-*-linux-amd64.deb and .rpm of one release (it may be
# empty: the repository is then valid and has no packages). OUT gets the
# site: the static files from site/, apt/ and rpm/. The signing key must be
# in gpg's keyring; KEY names it, and PASSPHRASE_FILE holds its passphrase
# (an empty file for a key without one).
set -euo pipefail

IN=$1 OUT=$2 VERSION=$3
KEY=${KEY:?KEY is the signing key id}
PF=${PASSPHRASE_FILE:?PASSPHRASE_FILE is the passphrase file}
HERE=$(cd "$(dirname "$0")" && pwd)

sign() { gpg --batch --yes --pinentry-mode loopback --passphrase-file "$PF" --local-user "$KEY" "$@"; }

rm -rf "$OUT"
mkdir -p "$OUT"
cp -r "$HERE/site/." "$OUT/"
echo "$VERSION" >"$OUT/release.txt"

shopt -s nullglob

# dnf: signed packages, repodata, and a signed repomd.xml (repo_gpgcheck).
mkdir -p "$OUT/rpm"
for f in "$IN"/yacm-*-linux-amd64.rpm; do
	cp "$f" "$OUT/rpm/"
	rpmsign --addsign \
		--define "_gpg_name $KEY" \
		--define "_gpg_sign_cmd_extra_args --pinentry-mode loopback --passphrase-file $PF" \
		"$OUT/rpm/$(basename "$f")" >/dev/null
done
createrepo_c --quiet --no-database "$OUT/rpm"
sign --armor --detach-sign -o "$OUT/rpm/repodata/repomd.xml.asc" "$OUT/rpm/repodata/repomd.xml"

# apt: suite stable, component main, amd64.
APT=$OUT/apt
mkdir -p "$APT/pool/main/y/yacm" "$APT/dists/stable/main/binary-amd64"
for f in "$IN"/yacm-*-linux-amd64.deb; do
	cp "$f" "$APT/pool/main/y/yacm/"
done
(cd "$APT" && apt-ftparchive packages pool >dists/stable/main/binary-amd64/Packages)
gzip -9kn "$APT/dists/stable/main/binary-amd64/Packages"
apt-ftparchive \
	-o APT::FTPArchive::Release::Origin=YACM \
	-o APT::FTPArchive::Release::Label=YACM \
	-o APT::FTPArchive::Release::Suite=stable \
	-o APT::FTPArchive::Release::Codename=stable \
	-o APT::FTPArchive::Release::Architectures=amd64 \
	-o APT::FTPArchive::Release::Components=main \
	-o "APT::FTPArchive::Release::Description=YACM packages" \
	release "$APT/dists/stable" >"$OUT/Release.tmp"
mv "$OUT/Release.tmp" "$APT/dists/stable/Release"
sign --clearsign -o "$APT/dists/stable/InRelease" "$APT/dists/stable/Release"
sign --armor --detach-sign -o "$APT/dists/stable/Release.gpg" "$APT/dists/stable/Release"

echo "built $VERSION: $(ls "$APT/pool/main/y/yacm" "$OUT/rpm" | grep -c '\.\(deb\|rpm\)$') packages"
