#!/bin/env bash

latest_commit=$(git log --oneline -1 | cut -d' ' -f1)

mkdir 5gc_sa_pkg_${latest_commit}
cp -r ../../5gc_sa_net_hot 5gc_sa_pkg_${latest_commit}
cp -r ../../config 5gc_sa_pkg_${latest_commit}

tar zcf 5gc_sa_pkg.tar.gz 5gc_sa_pkg_${latest_commit}

rm -rf 5gc_sa_pkg_${latest_commit}
mv 5gc_sa_pkg.tar.gz ~/
