#!/usr/bin/env bash
set -euxo pipefail

rm -rf /data/log/
pushd /data/media/0/realdata/
rm -rf boot
find . -regex '.*[defq]camera.\(hevc\|ts\)$' -delete
find . -regex '.*qlog.*' -delete
find . -name rlog | xargs -t -I {} -P `nproc` bzip2 {}
popd