# Migration Guide: Firebase → Node.js Backend

**Estimated Time:** 3-5 days  
**Effort Level:** Medium-High  
**Risk Level:** Low (if you followed the architecture)

## Overview

Migrate to a custom Node.js backend with PostgreSQL for maximum control and lowest long-term costs.

### Why Node.js?

| Factor | Firebase | Node.js |
|--------|----------|---------|
| **Cost at 100k users** | $10,000+/month | $100-500/month |
| **Control** | Limited | Full |
| **Scalability** | Auto | Manual but cheap |
| **Tech Stack** | Firebase-specific | Standard web stack |
| **Time to Setup** | 30 min | 3-5 days |

## Phase 1: Setup Node.js Backend (Day 1-2)

### 1.1 Create Node.js Project

```bash
mkdir shree-krishna-backend
cd shree-krishna-backend
npm init -y
npm install express cors dotenv pg jsonwebtoken bcryptjs
npm install --save-dev nodemon typescript @types/node
```

### 1.2 Project Structure

```
shree-krishna-backend/
├── src/
│   ├── config/
│   │   └── database.ts
│   ├── routes/
│   │   ├── auth.routes.ts
│   │   └── users.routes.ts
│   ├── controllers/
│   │   ├── auth.controller.ts
│   │   └── users.controller.ts
│   ├── middleware/
│   │   ├── auth.middleware.ts
│   │   └── error.middleware.ts
│   ├── models/
│   │   └── user.model.ts
│   └── app.ts
├── .env
├── .gitignore
├── package.json
└── tsconfig.json
```

### 1.3 Setup Database (PostgreSQL)

On DigitalOcean or similar:

```bash
# Install PostgreSQL
sudo apt-get install postgresql postgresql-contrib

# Create database
sudo -u postgres createdb shree_krishna_app

# Create user
sudo -u postgres createuser app_user
sudo -u postgres psql -c "ALTER USER app_user WITH PASSWORD 'strong_password';"
```

### 1.4 Create Database Schema

```sql
-- Create users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(255),
  photo_url VARCHAR(500),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index
CREATE INDEX idx_users_email ON users(email);

-- Create admin_users junction (for admin privileges)
CREATE TABLE admin_users (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(50) DEFAULT 'admin',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id)
);
```

### 1.5 Create Database Config

```typescript
// src/config/database.ts
import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const pool = new Pool({
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME,
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle client', err);
});

export default pool;
```

### 1.6 Create API Server

```typescript
// src/app.ts
import express, { Express, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import userRoutes from './routes/users.routes';
import authRoutes from './routes/auth.routes';

dotenv.config();

const app: Express = express();

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);

// Health check
app.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'ok' });
});

// Error handling
app.use((err: any, req: Request, res: Response, next: NextFunction) => {
  console.error(err);
  res.status(err.status || 500).json({
    error: err.message || 'Internal server error',
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

export default app;
```

### 1.7 User Model

```typescript
// src/models/user.model.ts
import pool from '../config/database';
import { v4 as uuidv4 } from 'uuid';

export interface User {
  id: string;
  email: string;
  password_hash: string;
  name?: string;
  photo_url?: string;
  is_active: boolean;
  created_at: Date;
  updated_at: Date;
}

export class UserModel {
  static async getUserById(id: string): Promise<User | null> {
    const result = await pool.query(
      'SELECT * FROM users WHERE id = $1',
      [id]
    );
    return result.rows[0] || null;
  }

  static async getUserByEmail(email: string): Promise<User | null> {
    const result = await pool.query(
      'SELECT * FROM users WHERE email = $1',
      [email]
    );
    return result.rows[0] || null;
  }

  static async getAllUsers(limit: number = 20, offset: number = 0): Promise<User[]> {
    const result = await pool.query(
      'SELECT id, email, name, photo_url, is_active, created_at, updated_at FROM users ORDER BY created_at DESC LIMIT $1 OFFSET $2',
      [limit, offset]
    );
    return result.rows;
  }

  static async createUser(email: string, passwordHash: string, name?: string): Promise<User> {
    const id = uuidv4();
    const result = await pool.query(
      'INSERT INTO users (id, email, password_hash, name) VALUES ($1, $2, $3, $4) RETURNING *',
      [id, email, passwordHash, name]
    );
    return result.rows[0];
  }

  static async updateUser(id: string, data: Partial<User>): Promise<User | null> {
    const updates: string[] = [];
    const values: any[] = [];
    let paramIndex = 1;

    if (data.name) {
      updates.push(`name = $${paramIndex}`);
      values.push(data.name);
      paramIndex++;
    }
    if (data.photo_url) {
      updates.push(`photo_url = $${paramIndex}`);
      values.push(data.photo_url);
      paramIndex++;
    }
    if (typeof data.is_active === 'boolean') {
      updates.push(`is_active = $${paramIndex}`);
      values.push(data.is_active);
      paramIndex++;
    }

    if (updates.length === 0) return null;

    values.push(id);
    const query = `UPDATE users SET ${updates.join(', ')}, updated_at = CURRENT_TIMESTAMP WHERE id = $${paramIndex} RETURNING *`;
    const result = await pool.query(query, values);
    return result.rows[0] || null;
  }

  static async deleteUser(id: string): Promise<boolean> {
    const result = await pool.query('DELETE FROM users WHERE id = $1', [id]);
    return result.rowCount! > 0;
  }

  static async searchUsers(query: string): Promise<User[]> {
    const result = await pool.query(
      'SELECT id, email, name, photo_url, is_active, created_at, updated_at FROM users WHERE name ILIKE $1 OR email ILIKE $1 LIMIT 20',
      [`%${query}%`]
    );
    return result.rows;
  }
}
```

### 1.8 Authentication Controller

```typescript
// src/controllers/auth.controller.ts
import { Request, Response } from 'express';
import bcryptjs from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { UserModel } from '../models/user.model';

export class AuthController {
  static async register(req: Request, res: Response) {
    try {
      const { email, password, name } = req.body;

      if (!email || !password) {
        return res.status(400).json({ error: 'Email and password required' });
      }

      const existing = await UserModel.getUserByEmail(email);
      if (existing) {
        return res.status(400).json({ error: 'Email already exists' });
      }

      const passwordHash = await bcryptjs.hash(password, 10);
      const user = await UserModel.createUser(email, passwordHash, name);

      const token = jwt.sign(
        { userId: user.id, email: user.email },
        process.env.JWT_SECRET!,
        { expiresIn: '7d' }
      );

      res.status(201).json({
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
        },
        token,
      });
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  }

  static async login(req: Request, res: Response) {
    try {
      const { email, password } = req.body;

      if (!email || !password) {
        return res.status(400).json({ error: 'Email and password required' });
      }

      const user = await UserModel.getUserByEmail(email);
      if (!user) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      const validPassword = await bcryptjs.compare(password, user.password_hash);
      if (!validPassword) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      const token = jwt.sign(
        { userId: user.id, email: user.email },
        process.env.JWT_SECRET!,
        { expiresIn: '7d' }
      );

      res.json({
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
        },
        token,
      });
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  }
}
```

### 1.9 Users Controller

```typescript
// src/controllers/users.controller.ts
import { Request, Response } from 'express';
import { UserModel } from '../models/user.model';

export class UsersController {
  static async getUser(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const user = await UserModel.getUserById(id);

      if (!user) {
        return res.status(404).json({ error: 'User not found' });
      }

      res.json({
        id: user.id,
        email: user.email,
        name: user.name,
        photo_url: user.photo_url,
        created_at: user.created_at,
      });
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  }

  static async getAllUsers(req: Request, res: Response) {
    try {
      const limit = parseInt(req.query.limit as string) || 20;
      const offset = parseInt(req.query.offset as string) || 0;

      const users = await UserModel.getAllUsers(limit, offset);

      res.json({
        users: users.map(u => ({
          id: u.id,
          email: u.email,
          name: u.name,
          photo_url: u.photo_url,
          created_at: u.created_at,
        })),
        total: users.length,
      });
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  }

  static async updateUser(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const { name, photo_url } = req.body;

      const user = await UserModel.updateUser(id, { name, photo_url } as any);

      if (!user) {
        return res.status(404).json({ error: 'User not found' });
      }

      res.json({
        id: user.id,
        email: user.email,
        name: user.name,
        photo_url: user.photo_url,
        updated_at: user.updated_at,
      });
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  }

  static async deleteUser(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const success = await UserModel.deleteUser(id);

      if (!success) {
        return res.status(404).json({ error: 'User not found' });
      }

      res.json({ message: 'User deleted' });
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  }

  static async searchUsers(req: Request, res: Response) {
    try {
      const { q } = req.query;

      if (!q) {
        return res.status(400).json({ error: 'Search query required' });
      }

      const users = await UserModel.searchUsers(q as string);

      res.json({
        results: users.map(u => ({
          id: u.id,
          email: u.email,
          name: u.name,
          photo_url: u.photo_url,
        })),
      });
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  }
}
```

### 1.10 Routes

```typescript
// src/routes/users.routes.ts
import { Router } from 'express';
import { UsersController } from '../controllers/users.controller';
import { authMiddleware } from '../middleware/auth.middleware';

const router = Router();

router.get('/:id', authMiddleware, UsersController.getUser);
router.get('/', authMiddleware, UsersController.getAllUsers);
router.put('/:id', authMiddleware, UsersController.updateUser);
router.delete('/:id', authMiddleware, UsersController.deleteUser);
router.get('/search', authMiddleware, UsersController.searchUsers);

export default router;
```

```typescript
// src/routes/auth.routes.ts
import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';

const router = Router();

router.post('/register', AuthController.register);
router.post('/login', AuthController.login);

export default router;
```

### 1.11 Auth Middleware

```typescript
// src/middleware/auth.middleware.ts
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

export interface AuthRequest extends Request {
  userId?: string;
}

export const authMiddleware = (
  req: AuthRequest,
  res: Response,
  next: NextFunction
) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or invalid token' });
  }

  const token = authHeader.slice(7);

  try {
    const decoded: any = jwt.verify(token, process.env.JWT_SECRET!);
    req.userId = decoded.userId;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' });
  }
};
```

### 1.12 Environment File

```bash
# .env
NODE_ENV=development
PORT=3000

# Database
DB_HOST=localhost
DB_PORT=5432
DB_USER=app_user
DB_PASSWORD=strong_password
DB_NAME=shree_krishna_app

# JWT
JWT_SECRET=your_super_secret_jwt_key_change_this

# API
API_URL=https://yourdomain.com
```

### 1.13 Deploy to Production

Use DigitalOcean, Railway, or similar:

```bash
# Install pm2 for process management
npm install -g pm2

# Start server
pm2 start "npm start" --name "shree-krishna-api"
pm2 save
pm2 startup
```

## Phase 2: Update Flutter App (Day 3)

### 2.1 Create Node.js DataSource

Replace `ApiUserDataSource` with actual Node.js endpoints:

```dart
// lib/data/datasources/api_user_datasource.dart
class ApiUserDataSource implements UserDataSource {
  final Dio _dio;
  final String _baseUrl;
  final String? _token;

  ApiUserDataSource({
    required Dio dio,
    String baseUrl = 'https://api.yourapp.com',
    String? token,
  })  : _dio = dio,
        _baseUrl = baseUrl,
        _token = token {
    // Add token to headers
    if (_token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
    }
  }

  // ... rest of datasource implementation matches earlier
}
```

### 2.2 Setup Service Locator

```dart
// lib/core/di/service_locator.dart
void setupServiceLocator() {
  // HTTP client
  getIt.registerSingleton<Dio>(
    Dio(BaseOptions(
      baseUrl: 'https://api.yourapp.com',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    )),
  );

  // Data sources
  getIt.registerSingleton<UserDataSource>(
    ApiUserDataSource(dio: getIt()),
  );

  // Repositories
  getIt.registerSingleton<UserRepository>(
    UserRepositoryImpl(dataSource: getIt()),
  );

  // Use cases & BLoCs...
}
```

### 2.3 Handle Authentication

```dart
class AuthService {
  final Dio _dio;
  final String _baseUrl;
  static const String _tokenKey = 'auth_token';

  AuthService({required Dio dio, String baseUrl = 'https://api.yourapp.com'})
      : _dio = dio,
        _baseUrl = baseUrl;

  Future<String> loginWithEmail(String email, String password) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/auth/login',
        data: {'email': email, 'password': password},
      );

      final token = response.data['token'] as String;
      
      // Save token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);

      // Add to headers
      _dio.options.headers['Authorization'] = 'Bearer $token';

      return token;
    } catch (e) {
      throw ServerException(message: 'Login failed: $e');
    }
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }
}
```

## Phase 3: Test & Deploy (Day 4-5)

### 3.1 Test All Endpoints

```bash
# Test register
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","name":"Test User"}'

# Test login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Test get user
curl -X GET http://localhost:3000/api/users/user-id \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 3.2 Update Flutter App

Update all API calls to use new Node.js endpoints.

### 3.3 Run Flutter App Tests

```bash
flutter test
```

### 3.4 Stage Rollout

1. Internal testing
2. Beta user testing
3. Gradual production rollout

## Cost Breakdown

| Item | Cost |
|------|------|
| DigitalOcean Droplet ($5) | $5/month |
| PostgreSQL Database | Included |
| Bandwidth (10GB) | Included |
| **Total** | **$5/month** |

vs. Firebase at same scale: $300-500/month

## Performance Tips

1. Add database indexes
2. Use connection pooling
3. Implement caching (Redis)
4. Use CDN for static files
5. Monitor with tools like Datadog

## Next Steps

1. Monitor API performance
2. Scale database if needed
3. Add more features (payments, notifications, etc.)
4. Consider Kubernetes for auto-scaling

## Resources

- [Express.js Docs](https://expressjs.com)
- [PostgreSQL Docs](https://www.postgresql.org/docs)
- [JWT Authentication](https://jwt.io)
- [DigitalOcean Tutorials](https://www.digitalocean.com/community/tutorials)
