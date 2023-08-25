#!/usr/bin/env bash
set -euxo pipefail

pushd /data/media/0/realdata/
rm -rf boot
find . -name rlog | xargs -t -I {} -P `nproc` bzip2 {}
find . -regex '.*[fdq]camera.\(hevc\|ts\)$' -delete
find . -regex '.*qlog.*' -delete
popd
