#!/bin/sh
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WEBAPP="$ROOT/webApp"
TOOLS="$ROOT/.tools"
MAVEN_VERSION="3.9.16"
TOMCAT_VERSION="9.0.124"
MAVEN_HOME="$TOOLS/apache-maven-$MAVEN_VERSION"
TOMCAT_HOME="$TOOLS/apache-tomcat-$TOMCAT_VERSION"

if [ ! -x "$MAVEN_HOME/bin/mvn" ] || [ ! -x "$TOMCAT_HOME/bin/catalina.sh" ]; then
    echo "Run ./scripts/setup.sh first." >&2
    exit 1
fi

echo "==> Building WAR ..."
"$MAVEN_HOME/bin/mvn" -f "$WEBAPP/pom.xml" -q package

echo "==> Deploying to Tomcat ..."
"$TOMCAT_HOME/bin/catalina.sh" stop >/dev/null 2>&1 || true
rm -rf "$TOMCAT_HOME/webapps/simple" "$TOMCAT_HOME/webapps/simple.war"
cp "$WEBAPP/target/simple.war" "$TOMCAT_HOME/webapps/simple.war"

echo "==> Starting Tomcat ..."
"$TOMCAT_HOME/bin/catalina.sh" start

echo "==> App is running at http://localhost:8080/simple/"
