# Configuração: Backend API

## Requisitos

- .NET SDK 8.0+
- PostgreSQL 16+
- Conta Iugu (API Key)
- Conta Cloudinary (API credentials)

## Passo a Passo

### 1. Clone do Repositório

```bash
cd amasso-monorepo/backend-api
```

### 2. Configurar appsettings.json

Crie `appsettings.Development.json`:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=pay4tru;Username=postgres;Password=postgres"
  },
  "Jwt": {
    "SecretKey": "sua-chave-secreta-muito-forte-aqui-com-pelo-menos-32-caracteres",
    "Issuer": "Amasso.API",
    "Audience": "Amasso.Frontend",
    "ExpirationHours": 24
  },
  "Iugu": {
    "ApiKey": "test_api_key_aqui",
    "BaseUrl": "https://api.iugu.com/v1",
    "MasterAccountId": "sua_conta_master_id"
  },
  "Cloudinary": {
    "CloudName": "seu_cloud_name",
    "ApiKey": "sua_api_key",
    "ApiSecret": "seu_api_secret"
  }
}
```

### 3. Instalar Dependências

```bash
dotnet restore
```

### 4. Executar Migrations

```bash
dotnet ef database update
```

### 5. Executar Aplicação

```bash
dotnet run
```

A API estará disponível em:
- HTTP: `http://localhost:7080`
- HTTPS: `https://localhost:7081`

### 6. Testar API

```bash
curl http://localhost:7080/health
```

## Variáveis de Ambiente

Alternativamente, configure via env vars:

```bash
export ConnectionStrings__DefaultConnection="Host=localhost;..."
export Jwt__SecretKey="sua-chave-secreta"
export Iugu__ApiKey="test_api_key"
export Cloudinary__CloudName="seu_cloud"
export Cloudinary__ApiKey="sua_key"
export Cloudinary__ApiSecret="seu_secret"
```

## Seed Data

Para popular banco com dados iniciais:

```bash
dotnet run --seed
```

Cria:
- Usuário admin (admin@amasso.com / Admin@123)
- 5 vídeos de exemplo
- 3 usuários de teste

## Desenvolvimento

### Hot Reload

```bash
dotnet watch run
```

### Logs

Configurar nível de log em `appsettings.json`:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning",
      "Microsoft.EntityFrameworkCore": "Information"
    }
  }
}
```

## Troubleshooting

### Erro: Cannot connect to PostgreSQL

Verificar se PostgreSQL está rodando:

```bash
pg_isready -h localhost -p 5432
```

### Erro: Migrations pendentes

```bash
dotnet ef database update
```

### Erro: Iugu API Key inválida

Verificar em https://app.iugu.com/settings/api

### Erro: Cloudinary upload falha

Verificar credenciais em https://console.cloudinary.com

## Próximos Passos

- [Configurar Email API](email-api.md)
- [Configurar Frontend](frontend.md)
- [Criar Migration](../desenvolvimento/criar-migration.md)

