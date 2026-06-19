# 🌙 Luna Track

A period tracking mobile app built with **Flutter** (frontend) and **Spring Boot** (backend), featuring AI-powered cycle predictions and symptom analysis.

---

## 📱 Features

- Cycle ring visualization with phase tracking
- Daily symptom & mood logging
- Calendar view with on-cycle toggle
- Insights with charts (cycle history, symptoms, mood)
- JWT authentication (register / login / logout)
- Local backup with Hive when offline
- Profile with cycle length settings
- Spring Boot REST API + Microsoft SQL Server

---

## 🗂 Project Structure

```
LunaTrack/
├── flutter/          ← Flutter mobile app
└── spring-boot/      ← Spring Boot REST API
```

---

## ⚙️ Prerequisites

| Tool | Version |
|------|---------|
| Flutter | 3.x+ |
| Dart | 3.x+ |
| Java | 17+ |
| Maven | 3.8+ |
| SQL Server | 2019+ |
| Android Studio / VS Code | Latest |

---

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/YOUR_USERNAME/luna-track.git
cd luna-track
```

---

## 🗄️ Backend Setup (Spring Boot)

### 1. Create the database

Open **SQL Server Management Studio (SSMS)** and run:

```sql
CREATE DATABASE lunatrack;
```

### 2. Configure `application.properties`

Open `spring-boot/src/main/resources/application.properties` and update:

```properties
# ── Database ──────────────────────────────────────────────────
spring.datasource.url=jdbc:sqlserver://localhost:1433;databaseName=lunatrack;encrypt=true;trustServerCertificate=true
spring.datasource.username=YOUR_SQL_USERNAME
spring.datasource.password=YOUR_SQL_PASSWORD
spring.datasource.driver-class-name=com.microsoft.sqlserver.jdbc.SQLServerDriver

# ── JPA ───────────────────────────────────────────────────────
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.SQLServerDialect
spring.jpa.properties.hibernate.format_sql=true

# ── Server ────────────────────────────────────────────────────
server.port=8080
server.address=0.0.0.0
spring.application.name=lunatrack-api

# ── JWT ───────────────────────────────────────────────────────
jwt.secret=lunatrack-super-secret-key-change-this-in-production
jwt.expiration=86400000
```

> ⚠️ If you use **Windows Authentication** instead of username/password:
> ```properties
> spring.datasource.url=jdbc:sqlserver://localhost:1433;databaseName=lunatrack;encrypt=true;trustServerCertificate=true;integratedSecurity=true
> spring.datasource.username=
> spring.datasource.password=
> ```

### 3. Run the backend

```bash
cd spring-boot
./mvnw spring-boot:run
```

You should see:
```
Tomcat started on port(s): 8080
Started ApiLunatrackingApplication
```

Tables are auto-created by Hibernate on first run:
- `users`
- `cycle_entries`
- `entry_moods`
- `entry_symptoms`

### 4. Allow port 8080 through Windows Firewall (for real device testing)

Run **Command Prompt as Administrator**:

```cmd
netsh advfirewall firewall add rule name="Spring Boot 8080" dir=in action=allow protocol=TCP localport=8080
```

---

## 📱 Flutter Setup

### 1. Find your PC's local IP

```cmd
ipconfig
```

Look for **IPv4 Address** under Wi-Fi, e.g. `192.168.1.173`

### 2. Update the API base URL

Open `flutter/lib/services/api_service.dart` and update:

```dart
// For Android emulator
static const String baseUrl = 'http://10.0.2.2:8080/api';

// For real Android device (use your PC's IP from ipconfig)
static const String baseUrl = 'http://192.168.1.xxx:8080/api';

// For iOS simulator
static const String baseUrl = 'http://localhost:8080/api';

// For Flutter web
static const String baseUrl = 'http://192.168.1.xxx:8080/api';
```

> ⚠️ Make sure your phone and PC are on the **same WiFi network**.

### 3. Install dependencies

```bash
cd flutter
flutter pub get
```

### 4. Generate Hive adapters

```bash
dart run build_runner build
```

### 5. Run the app

```bash
flutter run
```

---

## 🔑 API Endpoints

### Auth

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Login and get JWT token |

### Cycle Entries (requires JWT)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/entries` | Save or update a log |
| GET | `/api/entries` | Get all entries |
| GET | `/api/entries/{date}` | Get entry by date (yyyy-MM-dd) |
| GET | `/api/entries/range?start=&end=` | Get entries in date range |
| DELETE | `/api/entries/{date}` | Delete entry by date |

### Example: Login

```http
POST http://localhost:8080/api/auth/login
Content-Type: application/json

{
  "email": "test@example.com",
  "password": "password123"
}
```

Response:
```json
{
  "token": "eyJhbGci...",
  "name": "Test User",
  "email": "test@example.com"
}
```

### Example: Save a log (with JWT)

```http
POST http://localhost:8080/api/entries
Authorization: Bearer eyJhbGci...
Content-Type: application/json

{
  "date": "2026-05-28",
  "flow": "medium",
  "moods": ["Tired", "Calm"],
  "symptoms": ["Cramps"],
  "energy": "low",
  "sleep": "ok",
  "notes": "Feeling better today"
}
```

---

## 🧪 Testing the API

Import this into **Postman**:

1. Register → copy the `token` from response
2. In Postman, set **Authorization** → **Bearer Token** → paste token
3. Test all `/api/entries` endpoints

---

## 📦 Flutter Dependencies

| Package | Purpose |
|---------|---------|
| `hive_flutter` | Local offline storage |
| `provider` | State management |
| `http` | API calls |
| `shared_preferences` | Store JWT token & user info |
| `table_calendar` | Calendar widget |
| `fl_chart` | Charts in insights screen |
| `go_router` | Navigation |

---

## 🛠 Common Issues

### ❌ `ERR_CONNECTION_TIMED_OUT`
- Make sure Spring Boot is running
- Check your IP in `api_service.dart` matches `ipconfig` output
- Phone and PC must be on the same WiFi
- Run the firewall command above

### ❌ CORS error in browser
- Already handled in `SecurityConfig.java`
- If still occurring, restart Spring Boot

### ❌ `Dart SDK not found` in Android Studio
- Set Dart SDK path to: `C:\src\flutter\flutter\bin\cache\dart-sdk`

### ❌ `build_runner` errors
- Run: `dart run build_runner build --delete-conflicting-outputs`

### ❌ Tables not created
- Check `application.properties` has `spring.jpa.hibernate.ddl-auto=update`
- Verify SQL Server is running on port 1433

---

## 👥 Team

| Name | Role |
|------|------|
| | Flutter Developer |
| | Backend Developer |
| | UI/UX |

---

## 📄 License

This project is for educational purposes at FPT University.
