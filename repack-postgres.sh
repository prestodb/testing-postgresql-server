#!/bin/bash

set -eu

# forked from https://github.com/opentable/otj-pg-embedded

# https://www.enterprisedb.com/products-services-training/pgbindownload

VERSION=9.6.3-1
BASEURL="https://get.enterprisedb.com/postgresql"

# requires advance-toolchain-at10.0-runtime
PPC64LE_BASEURL="https://yum.postgresql.org/9.6/redhat/rhel-7-ppc64le"

TAR=tar
command -v gtar > /dev/null && TAR=gtar

if ! $TAR --version | grep -q "GNU tar"
then
    echo "GNU tar is required."
    echo "Hint: brew install gnu-tar"
    $TAR --version
    exit 100
fi

set -x

cd $(dirname $0)

RESOURCES=target/generated-resources

mkdir -p dist $RESOURCES

LINUX_NAME=postgresql-$VERSION-linux-x64-binaries.tar.gz
LINUX_DIST=dist/$LINUX_NAME

LINUX_PPC64LE_PGSERVER=postgresql96-server-9.6.18-1PGDG.rhel7.ppc64le.rpm
LINUX_PPC64LE_PGCONTRIB=postgresql96-contrib-9.6.18-1PGDG.rhel7.ppc64le.rpm
LINUX_PPC64LE_DIST_PGSERVER=dist/$LINUX_PPC64LE_PGSERVER
LINUX_PPC64LE_DIST_PGCONTRIB=dist/$LINUX_PPC64LE_PGCONTRIB

OSX_NAME=postgresql-$VERSION-osx-binaries.zip
OSX_DIST=dist/$OSX_NAME

test -e $LINUX_DIST || curl -o $LINUX_DIST "$BASEURL/$LINUX_NAME"
test -e $LINUX_PPC64LE_DIST_PGSERVER || curl -L -o $LINUX_PPC64LE_DIST_PGSERVER "$PPC64LE_BASEURL/$LINUX_PPC64LE_PGSERVER"
test -e $LINUX_PPC64LE_DIST_PGCONTRIB || curl -L -o $LINUX_PPC64LE_DIST_PGCONTRIB "$PPC64LE_BASEURL/$LINUX_PPC64LE_PGCONTRIB"
test -e $OSX_DIST || curl -o $OSX_DIST "$BASEURL/$OSX_NAME"

PACKDIR=$(mktemp -d "${TMPDIR:-/tmp}/pg.XXXXXXXXXX")
tar -xzf $LINUX_DIST -C $PACKDIR
pushd $PACKDIR/pgsql
$TAR -czf $OLDPWD/$RESOURCES/postgresql-Linux-amd64.tar.gz \
  share/postgresql \
  lib \
  bin/initdb \
  bin/pg_ctl \
  bin/postgres
popd
rm -rf $PACKDIR

PACKDIR=$(mktemp -d "${TMPDIR:-/tmp}/pg.XXXXXXXXXX")
cp $LINUX_PPC64LE_DIST_PGSERVER $PACKDIR/
cp $LINUX_PPC64LE_DIST_PGCONTRIB $PACKDIR/
pushd $PACKDIR
rpm2cpio $LINUX_PPC64LE_PGSERVER | cpio -idm
rpm2cpio $LINUX_PPC64LE_PGCONTRIB | cpio -idm
mkdir -p postgresql-Linux-ppc64le/bin postgresql-Linux-ppc64le/lib postgresql-Linux-ppc64le/share
cp usr/pgsql-9.6/bin/pg_ctl postgresql-Linux-ppc64le/bin/
cp usr/pgsql-9.6/bin/postgres postgresql-Linux-ppc64le/bin/
cp usr/pgsql-9.6/bin/initdb postgresql-Linux-ppc64le/bin/
cp -r usr/pgsql-9.6/lib/* postgresql-Linux-ppc64le/lib/
cp -r usr/pgsql-9.6/share/* postgresql-Linux-ppc64le/share/
$TAR -C postgresql-Linux-ppc64le -czf $OLDPWD/$RESOURCES/postgresql-Linux-ppc64le.tar.gz bin lib share
popd
rm -rf $PACKDIR

PACKDIR=$(mktemp -d "${TMPDIR:-/tmp}/pg.XXXXXXXXXX")
unzip -q -d $PACKDIR $OSX_DIST
pushd $PACKDIR/pgsql
$TAR -czf $OLDPWD/$RESOURCES/postgresql-Mac_OS_X-x86_64.tar.gz \
  share/postgresql \
  lib/libiconv.2.dylib \
  lib/libxml2.2.dylib \
  lib/libssl.1.0.0.dylib \
  lib/libcrypto.1.0.0.dylib \
  lib/libuuid.1.1.dylib \
  lib/postgresql/*.so \
  bin/initdb \
  bin/pg_ctl \
  bin/postgres
popd
rm -rf $PACKDIR
