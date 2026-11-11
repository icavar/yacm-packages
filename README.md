# yacm-packages

The apt and dnf repository for [YACM](https://github.com/icavar/yacm),
published at <https://pkg.yacm.app>.

The `.deb` and `.rpm` packages of YACM add this repository when they are
installed, so `apt upgrade` and `dnf upgrade` bring new versions. To add it by
hand, see <https://pkg.yacm.app>.

## How it is built

`.github/workflows/publish.yml` runs every three hours, after a push to
`main`, and from *Actions > Publish > Run workflow*:

1. It takes the latest YACM release (not drafts or release candidates) and
   stops if that version is already published.
2. It downloads `yacm-<version>-linux-amd64.deb` and `.rpm` and checks with
   `gh attestation verify` that they were built by the YACM release workflow.
3. `build.sh` signs the `.rpm`, writes the apt index (suite `stable`,
   component `main`) and the dnf repodata, and signs both indexes.
4. GitHub Pages publishes the result. No package is kept in git.

Only the latest version is in the repository. A release without Linux
packages gives a valid, empty repository.

## Signing key

"YACM packages <support@yacm.app>", fingerprint
`9C9A 2975 7D17 AFD5 51B6  0BFB 1FA9 9EB2 609B DAAF`
([site/yacm.asc](site/yacm.asc)). The private key is kept only in the
environment `signing` of this repository (secrets `PKG_GPG_KEY` and
`PKG_GPG_PASSPHRASE`), which only `main` may use.

## Licence

GPL-3.0-or-later, like YACM.
