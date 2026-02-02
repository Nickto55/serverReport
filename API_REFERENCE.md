# API Reference

## Base URL
`http://localhost:3000/api`

## Authentication Endpoints

### Register
```
POST /auth/register
Content-Type: application/json

{
  "username": "string (3+ chars)",
  "email": "string (valid email)",
  "password": "string (6+ chars)"
}

Response 201:
{
  "user": {
    "id": 1,
    "username": "testuser",
    "email": "test@example.com",
    "role": "user"
  },
  "token": "jwt_token_here"
}
```

### Login
```
POST /auth/login
Content-Type: application/json

{
  "email": "string",
  "password": "string"
}

Response 200:
{
  "user": {
    "id": 1,
    "username": "testuser",
    "email": "test@example.com",
    "role": "user"
  },
  "token": "jwt_token_here"
}
```

## Report Endpoints

### Create Report
```
POST /reports
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "string (5+ chars)",
  "description": "string (10+ chars)",
  "category": "string (optional)",
  "priority": "low|medium|high|critical (optional)",
  "source": "string (optional, auto-set to 'website')"
}

Response 201:
{
  "id": 1,
  "user_id": 1,
  "title": "Bug Report",
  "description": "Description of bug",
  "status": "open",
  "priority": "medium",
  "category": "bug",
  "source": "website",
  "created_at": "2024-01-01T12:00:00Z",
  "updated_at": "2024-01-01T12:00:00Z"
}
```

### Get User's Reports
```
GET /reports
Authorization: Bearer <token>

Response 200:
[
  {
    "id": 1,
    "user_id": 1,
    "title": "Bug Report",
    "description": "Description",
    "status": "open",
    "priority": "medium",
    "category": "bug",
    "source": "website",
    "created_at": "2024-01-01T12:00:00Z",
    "updated_at": "2024-01-01T12:00:00Z"
  }
]
```

### Get Report Details
```
GET /reports/:id
Authorization: Bearer <token>

Response 200: Report object
Response 404: { "message": "Report not found" }
```

### Update Report
```
PUT /reports/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "string (optional)",
  "description": "string (optional)",
  "category": "string (optional)",
  "priority": "string (optional)",
  "status": "string (optional)"
}

Response 200: Updated report object
Response 404: { "message": "Report not found" }
```

### Delete Report
```
DELETE /reports/:id
Authorization: Bearer <token>

Response 200: { "message": "Report deleted successfully" }
Response 404: { "message": "Report not found" }
```

## Admin Endpoints

All admin endpoints require:
- Authorization header with valid JWT token
- User role must be "admin"

### Get All Users
```
GET /admin/users
Authorization: Bearer <token>

Response 200:
[
  {
    "id": 1,
    "username": "testuser",
    "email": "test@example.com",
    "role": "user",
    "status": "active",
    "created_at": "2024-01-01T12:00:00Z"
  }
]
```

### Get User's Reports
```
GET /admin/users/:userId/reports
Authorization: Bearer <token>

Response 200: Array of report objects
```

### Get All Reports (with filters)
```
GET /admin/reports?status=open&priority=high
Authorization: Bearer <token>

Query Parameters:
- status: "open|in_progress|closed|resolved" (optional)
- priority: "low|medium|high|critical" (optional)

Response 200: Array of report objects with username field
```

### Update Report Status
```
PUT /admin/reports/:reportId/status
Authorization: Bearer <token>
Content-Type: application/json

{
  "status": "open|in_progress|closed|resolved"
}

Response 200: Updated report object
Response 400: { "message": "Invalid status" }
Response 404: { "message": "Report not found" }
```

### Get System Statistics
```
GET /admin/stats
Authorization: Bearer <token>

Response 200:
{
  "totalUsers": 10,
  "totalReports": 25,
  "openReports": 5,
  "discordIntegrations": 3,
  "telegramIntegrations": 2
}
```

## Error Responses

### 400 Bad Request
```json
{
  "errors": [
    {
      "param": "field_name",
      "msg": "Validation error message"
    }
  ]
}
```

### 401 Unauthorized
```json
{
  "message": "No token provided" | "Invalid token"
}
```

### 403 Forbidden
```json
{
  "message": "Admin access required"
}
```

### 404 Not Found
```json
{
  "message": "Resource not found"
}
```

### 409 Conflict
```json
{
  "message": "Username or email already exists"
}
```

### 500 Internal Server Error
```json
{
  "message": "Operation failed"
}
```

## Usage Examples

### With curl
```bash
# Login
TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"testpass"}' | jq -r '.token')

# Create report
curl -X POST http://localhost:3000/api/reports \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"Test","description":"Test report"}'

# Get reports
curl http://localhost:3000/api/reports \
  -H "Authorization: Bearer $TOKEN"
```

### With JavaScript/Node.js
```javascript
const fetch = require('node-fetch');

const API_URL = 'http://localhost:3000/api';

// Login
const loginRes = await fetch(`${API_URL}/auth/login`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    email: 'test@example.com',
    password: 'testpass'
  })
});

const { token } = await loginRes.json();

// Create report
const reportRes = await fetch(`${API_URL}/reports`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  },
  body: JSON.stringify({
    title: 'Test Report',
    description: 'This is a test',
    priority: 'high'
  })
});

const report = await reportRes.json();
console.log(report);
```

## Rate Limiting

Currently, no rate limiting is implemented. Consider implementing rate limiting in production.

## CORS

CORS is enabled for all origins in development. Update for production.

## Notes

- JWT tokens expire after 24 hours
- All timestamps are in ISO 8601 format
- Database IDs are auto-incrementing integers
- User roles: "user" or "admin"
- Report statuses: "open", "in_progress", "closed", "resolved"
- Report priorities: "low", "medium", "high", "critical"
