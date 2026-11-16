# Caving-log

A Java Servlet + JSP web application that lets cavers log and manage their caving activity. Each registered caver can record the trips they go on, keep track of their group's trips, and maintain a current status (e.g. `safe`, `not caving`).

> **Note on scope:** The original idea also included *calling for rescue* if a group fails to return from a trip. That feature is not yet implemented in the current codebase — today the app covers caver registration and trip logging (CRUD). See [Known limitations](#known-limitations).

---

## Features

- **Caver management**
  - Register new cavers with a name, status, and phone number
  - View all cavers in a table with a **live client-side search** (by name, phone, or status)
  - Update or delete caver records
- **Trip logging**
  - Each caver can log trips with cave name, start/end time, group size, and max trip length
  - View, add, update, and delete trips for a specific caver
- **Validation** on both the client side (HTML `pattern` attributes) and server side (regex in the servlets)
- **PostgreSQL persistence** via a JNDI data source, accessed through a `DaoFile` data-access object

---

## Tech stack

| Layer      | Technology                                                        |
|------------|-------------------------------------------------------------------|
| Language   | Java 8                                                             |
| Web        | Java Servlets (javax.servlet 3.0.1), JSP                          |
| Build      | Maven (packaged as a WAR)                                          |
| Database   | PostgreSQL                                                         |
| Conn. pool | JNDI `DataSource` (`jdbc/dbcp`) via `org.nfis:db` connection manager |
| Logging    | tinylog 2.3.2                                                      |
| Testing    | JUnit 5 (Jupiter), Mockito                                          |

---

## Project structure

```
Caving-log/
├── README.md
├── .gitignore
└── webApp/                              # Maven WAR module
    ├── pom.xml                          # Build config (warName: "simple", Java 1.8)
    ├── WebContent/                      # WAR source root (frontend + config)
    │   ├── META-INF/
    │   │   ├── MANIFEST.MF
    │   │   └── context.xml              # JNDI datasource (DB credentials live here)
    │   ├── WEB-INF/
    │   │   └── web.xml                  # Servlet mappings, welcome page
    │   ├── registration.jsp             # Add a caver
    │   ├── read_handler.jsp             # List/search cavers
    │   ├── update_caver.jsp             # Edit a caver
    │   ├── register_trip.jsp            # Add a trip
    │   ├── view_trips.jsp               # List trips for a caver
    │   ├── update_trip.jsp              # Edit a trip
    │   ├── read_style.css               # Shared styles
    │   ├── search_bar_styles.css        # Search input styles
    │   ├── search_bar.js                # Caver table search
    │   ├── search_bar_trips.js          # Trip table search (unused — see limitations)
    │   └── validate_form.js             # Button hover effects
    ├── database/
    │   └── sql/
    │       ├── base-ddl.sql             # Drop/create schema + seed data
    │       ├── base-data.sql            # Sample data only
    │       └── crud-operations-examples.txt  # Hand-written SQL examples
    └── src/
        ├── main/java/simple/
        │   ├── Caver.java               # Caver model
        │   ├── Trip.java                # Trip model
        │   ├── DaoFile.java             # Data access object (JDBC CRUD)
        │   ├── CrudServlet.java         # Caver CRUD endpoint
        │   └── TripCrudServlet.java     # Trip CRUD endpoint
        └── test/java/simple/
            ├── DaoFileTest.java
            ├── CrudServletTest.java
            └── TripCrudServletTest.java
```

---

## Getting started

### Prerequisites

- **Java 17** JDK (the app sources remain Java 8 compatible)
- **Maven 3.x** (or run `scripts/setup.sh`, which downloads Maven/Tomcat for you)
- **Apache Tomcat 9** (or run `scripts/setup.sh`)
- A **PostgreSQL** server (or run `scripts/setup.sh`, which creates a local `caving` database on port 5432)

### 1. Set up the database

Run the SQL scripts in order against your PostgreSQL database:

1. `webApp/database/sql/base-ddl.sql` — drops and recreates the `cavers` and `trips` tables and inserts sample data.
2. `webApp/database/sql/base-data.sql` — (optional) inserts additional sample rows.

If you only want the schema with a fresh start, `base-ddl.sql` already includes seed data.

The app connects through a JNDI data source named `jdbc/dbcp`, configured in `webApp/WebContent/META-INF/context.xml`. It currently points at a local dev database:

```xml
<Resource name="jdbc/dbcp" auth="Container"
    type="javax.sql.DataSource"
    username="caving" password="caving"
    driverClassName="org.postgresql.Driver"
    url="jdbc:postgresql://localhost:5432/caving"
    maxActive="15" maxIdle="10"
    validationQuery="SELECT 1" />
```

> ⚠️ `context.xml` contains **hardcoded dev credentials**. Replace them before any real deployment.

### 2. Build the WAR

```bash
cd webApp
mvn package
```

This produces `webApp/target/simple.war` (the `warName` is `simple` per `pom.xml`).

### 3. Deploy

Deploy `simple.war` to your Tomcat `webapps` directory (or use the Tomcat Manager). The app should then be available at:

```
http://localhost:8080/simple/
```

`web.xml` sets the welcome page to `registration.jsp`, so the root URL opens the *Register New Caver* form.

### Quick start on this machine

```bash
cd Caving-log
./scripts/setup.sh   # downloads Maven + Tomcat, creates the local DB and loads the schema
./scripts/start.sh   # builds, deploys to Tomcat, and starts the server
# open http://localhost:8080/simple/
./scripts/stop.sh    # stop Tomcat when done
```

Tests:

```bash
cd Caving-log/webApp
mvn test
```

---

## How it works

The app has two servlet endpoints:

| URL pattern      | Servlet           | Purpose            |
|------------------|-------------------|--------------------|
| `/CrudServlet`   | `CrudServlet`     | Caver CRUD         |
| `/TripCrudServlet` | `TripCrudServlet` | Trip CRUD          |

Both servlets delegate to `DaoFile`, which opens connections from the JNDI data source and runs `PreparedStatement`-based SQL (no concatenated queries — safe from SQL injection).

### Managing cavers

1. Open the app — you land on the **Register New Caver** form (`registration.jsp`).
2. Fill in name, status, and phone, then **Add Caver**. You're taken to the caver list.
3. From the **Cavers** table you can:
   - **Search** — start typing in the search box to filter by name, phone, or status.
   - **View Trips** — see that caver's logged trips.
   - **Update** — edit the pre-filled form and save.
   - **Delete** — remove the caver. Because the `trips` table uses `ON DELETE CASCADE`, their trips are removed too.

### Logging trips

1. From the caver list, click **View Trips** on a caver. You see only that caver's trips.
2. Click **Add Trip**, fill in the details, and submit.
3. Each trip row supports **Update** and **Delete**.
4. **Back to Cavers** returns you to the caver list.

---

## Input validation

Validation happens on both the browser (HTML `pattern`) and the server (regex in the servlets). If server-side validation fails, an error message is written to the response.

| Field            | Format                                                     |
|------------------|------------------------------------------------------------|
| Name             | Letters and spaces only, 1–100 chars (`^[A-Za-z\s]{1,100}$`) |
| Status           | Letters and spaces only, 1–100 chars                       |
| Phone            | `NNN-NNN-NNNN` (`^[0-9]{3}-[0-9]{3}-[0-9]{4}$`)            |
| Cave name        | Letters and spaces only, 1–100 chars                       |
| Start / end time | `YYYY-MM-DD HH:MM:SS` (`^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$`) |
| Group size       | Non-negative integer (`^\d+$`)                             |
| Max trip length  | Non-negative decimal (`^\d*[\.]?[\d]*$`), in hours         |

---

## Database schema

```sql
CREATE TABLE cavers (
  caver_id SERIAL PRIMARY KEY,   -- auto-increments
  name     VARCHAR(50),
  status   VARCHAR(50),
  phone    VARCHAR(50)
);

CREATE TABLE trips (
  trip_id         SERIAL PRIMARY KEY,   -- auto-increments
  caver_id        INT,
  cave_name       VARCHAR(50),
  start_time      TIMESTAMP,
  end_time        TIMESTAMP,
  group_size      INT,
  max_trip_length REAL,
  FOREIGN KEY (caver_id) REFERENCES cavers(caver_id) ON DELETE CASCADE
);
```

---

## Running the tests

```bash
cd webApp
mvn test
```

The test suite covers:

- **`DaoFileTest`** — CRUD SQL behavior against mocked JDBC objects (verifies prepared-statement parameters, execution, and resource closing, plus the SQL-exception path).
- **`CrudServletTest`** — GET and POST (insert/update/delete) flows for cavers, including invalid-input handling.
- **`TripCrudServletTest`** — GET and POST (insert/update/delete) flows for trips, including invalid-input handling.

---

## Known limitations

- **No rescue / emergency feature** — the "call for rescue" behaviour from the original description is not implemented. The `status` field on a caver is free text and could be used to indicate safety, but nothing automated reads it.
- **No authentication** — anyone can add, update, or delete cavers and trips.
- **`search_bar_trips.js` is not wired up** — `view_trips.jsp` doesn't include a search box or the script, so trips can't be filtered client-side.
- **Minor pre-fill bug** — `read_handler.jsp` passes the caver status as `previous_Status`, but `update_caver.jsp` reads `previous_status`, so the status field isn't pre-filled when editing a caver.
- **DB credentials are hardcoded** in `WebContent/META-INF/context.xml` (see [Setup](#1-set-up-the-database)).
