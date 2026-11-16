#!/bin/sh
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS="$ROOT/.tools"
TOMCAT_VERSION="9.0.124"
TOMCAT_HOME="$TOOLS/apache-tomcat-$TOMCAT_VERSION"

if [ -x "$TOMCAT_HOME/bin/catalina.sh" ]; then
    "$TOMCAT_HOME/bin/catalina.sh" stop >/dev/null 2>&1 || true
fi

echo "Tomcat stopped."
