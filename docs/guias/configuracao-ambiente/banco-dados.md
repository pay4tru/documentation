# Configuração: Banco de Dados

## PostgreSQL 16

### Instalação

#### Windows

1. Baixe o instalador: https://www.postgresql.org/download/windows/
2. Execute e siga o wizard
3. Anote a senha do usuário `postgres`

#### macOS

```bash
# Com Homebrew
brew install postgresql@16
brew services start postgresql@16
```

#### Linux (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install postgresql-16 postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### Criar Database

```bash
# Conectar ao PostgreSQL
psql -U postgres

# Criar database
CREATE DATABASE pay4tru;

# Criar usuário (opcional)
CREATE USER amasso WITH PASSWORD 'senha123';
GRANT ALL PRIVILEGES ON DATABASE pay4tru TO amasso;

# Sair
\q
```

### Connection String

```
Host=localhost;Port=5432;Database=pay4tru;Username=postgres;Password=sua_senha
```

## Docker Compose (Recomendado)

### 1. Criar docker-compose.yml

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: amasso-postgres
    environment:
      POSTGRES_DB: pay4tru
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
```

### 2. Iniciar Container

```bash
docker-compose up -d
```

### 3. Verificar

```bash
docker-compose ps
docker-compose logs postgres
```

### 4. Conectar

```bash
docker exec -it amasso-postgres psql -U postgres -d pay4tru
```

## Executar Migrations

### Backend API

```bash
cd backend-api
dotnet ef database update
```

### Email API

```bash
cd email-api
dotnet ef database update
```

## Verificar Estrutura

### Listar Tabelas

```sql
\dt
```

### Ver Estrutura de Tabela

```sql
\d users
\d videos
\d orders
```

### Contar Registros

```sql
SELECT 
  schemaname,
  tablename,
  (SELECT COUNT(*) FROM pg_catalog.pg_class c WHERE c.relname = tablename) as row_count
FROM pg_catalog.pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
```

## Seed Data

### Criar Usuário Admin

```sql
INSERT INTO users (email, password_hash, first_name, last_name, type, is_active, created_at)
VALUES (
  'admin@amasso.com',
  '$2a$11$hashed_password_here', -- Use hash bcrypt real
  'Admin',
  'User',
  'Admin',
  TRUE,
  NOW()
);
```

### Criar Vídeo de Teste

```sql
INSERT INTO videos (title, description, cloudinary_public_id, price, is_active, created_at)
VALUES (
  'Vídeo Teste',
  'Descrição do vídeo teste',
  'test_video_id',
  99.90,
  TRUE,
  NOW()
);

-- Configurar comissões
INSERT INTO video_revenue_configs (video_id, platform_percentage, owner_percentage, promoter_percentage, created_at)
VALUES (
  (SELECT id FROM videos WHERE title = 'Vídeo Teste'),
  20,
  50,
  30,
  NOW()
);
```

## Backup e Restore

### Backup

```bash
# Backup completo
pg_dump -U postgres -d pay4tru > backup.sql

# Backup apenas dados
pg_dump -U postgres -d pay4tru --data-only > data_backup.sql

# Backup apenas schema
pg_dump -U postgres -d pay4tru --schema-only > schema_backup.sql

# Com Docker
docker exec amasso-postgres pg_dump -U postgres pay4tru > backup.sql
```

### Restore

```bash
# Restore completo
psql -U postgres -d pay4tru < backup.sql

# Com Docker
docker exec -i amasso-postgres psql -U postgres -d pay4tru < backup.sql
```

## Comandos Úteis

### PostgreSQL

```sql
-- Listar databases
\l

-- Conectar a database
\c pay4tru

-- Listar tabelas
\dt

-- Descrever tabela
\d users

-- Listar índices
\di

-- Ver tamanho das tabelas
SELECT 
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Vacuum (otimizar)
VACUUM ANALYZE;

-- Ver conexões ativas
SELECT * FROM pg_stat_activity WHERE datname = 'pay4tru';
```

## Performance

### Índices Recomendados

```sql
-- Já criados pelas migrations, mas para referência:

-- Users
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_type ON users(type);

-- Orders
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_video_id ON orders(video_id);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);

-- Payments
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_iugu_paid_at ON payments(iugu_paid_at);

-- Incomes
CREATE INDEX idx_incomes_owner_id ON incomes(owner_id);
CREATE INDEX idx_incomes_type ON incomes(type);
```

### Query Performance

```sql
-- Analisar query
EXPLAIN ANALYZE SELECT * FROM orders WHERE user_id = 1;

-- Ver queries lentas
SELECT 
  query,
  calls,
  total_time,
  mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;
```

## Troubleshooting

### Conexão recusada

```bash
# Verificar se PostgreSQL está rodando
pg_isready -h localhost -p 5432

# Ver status
sudo systemctl status postgresql

# Iniciar
sudo systemctl start postgresql
```

### Senha incorreta

```bash
# Resetar senha do postgres
sudo -u postgres psql
ALTER USER postgres PASSWORD 'nova_senha';
```

### Database não existe

```bash
psql -U postgres
CREATE DATABASE pay4tru;
```

## Próximos Passos

- [Configurar Backend](backend.md)
- [Configurar Email API](email-api.md)
- [Criar Migration](../desenvolvimento/criar-migration.md)

