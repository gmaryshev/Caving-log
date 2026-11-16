#!/bin/sh
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WEBAPP="$ROOT/webApp"
TOOLS="$ROOT/.tools"
MAVEN_VERSION="3.9.16"
TOMCAT_VERSION="9.0.124"
MAVEN_HOME="$TOOLS/apache-maven-$MAVEN_VERSION"
TOMCAT_HOME="$TOOLS/apache-tomcat-$TOMCAT_VERSION"

mkdir -p "$TOOLS"

if [ ! -x "$MAVEN_HOME/bin/mvn" ]; then
    echo "==> Downloading Maven $MAVEN_VERSION ..."
    curl -fsSL "https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/$MAVEN_VERSION/apache-maven-$MAVEN_VERSION-bin.tar.gz" \
        | tar -xz -C "$TOOLS"
fi

if [ ! -x "$TOMCAT_HOME/bin/catalina.sh" ]; then
    echo "==> Downloading Tomcat $TOMCAT_VERSION ..."
    curl -fsSL "https://repo.maven.apache.org/maven2/org/apache/tomcat/tomcat/$TOMCAT_VERSION/tomcat-$TOMCAT_VERSION.tar.gz" \
        | tar -xz -C "$TOOLS"
fi

echo "==> Ensuring local PostgreSQL database ..."
if ! psql -d postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname = 'caving'" | grep -q 1; then
    psql -d postgres -v ON_ERROR_STOP=1 -c "CREATE ROLE caving LOGIN PASSWORD 'caving'"
else
    psql -d postgres -v ON_ERROR_STOP=1 -c "ALTER ROLE caving WITH LOGIN PASSWORD 'caving'"
fi

if [ "$(psql -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = 'caving'")" != "1" ]; then
    createdb -O caving caving
fi

if [ "$(PGPASSWORD=caving psql -h localhost -U caving -d caving -tAc "SELECT to_regclass('public.cavers')")" = "" ]; then
    echo "==> Loading database schema ..."
    PGPASSWORD=caving psql -h localhost -U caving -d caving -v ON_ERROR_STOP=1 -f "$WEBAPP/database/sql/base-ddl.sql"
else
    echo "==> Database schema already present."
fi

echo "==> Setup complete."
