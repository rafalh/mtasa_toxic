#!/bin/sh
set -e
for f in *.xml ; do
    schema="xsd/${f%.*}.xsd"
    if [ -f "$schema" ] ; then
        xmllint "$schema" --noout
        xmllint -schema "$schema" "$f" --noout
    else
        xmllint "$f" --noout
    fi
done
