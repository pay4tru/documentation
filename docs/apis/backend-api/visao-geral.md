# Backend API - Visão Geral

## Descrição

A Backend API é construída com **ASP.NET Core 8** usando **Minimal APIs** e fornece todos os endpoints para o frontend React se comunicar com o sistema.

## Tecnologias

- **.NET 8**: Framework
- **Minimal APIs**: Arquitetura de endpoints
- **Entity Framework Core**: ORM
- **Npgsql**: Driver PostgreSQL
- **JWT Bearer**: Autenticação
- **BCrypt**: Hash de senhas
- **Cloudinary**: Armazenamento de mídia
- **Iugu SDK**: Gateway de pagamento

## Base URL

```
Desenvolvimento: http://localhost:7080
Produção: https://api.amasso.com.br
```

## Autenticação

Todos os endpoints protegidos requerem um **JWT Token** no header:

```http
Authorization: Bearer {token}
```

### Obter Token

```http
POST /api/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "senha123"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "firstName": "João",
    "lastName": "Silva",
    "type": "Default"
  }
}
```

## Estrutura de Endpoints

Os endpoints são organizados por domínio:

| Domínio | Arquivo | Endpoints |
|---------|---------|-----------|
| Autenticação | `LoginEndpoints.cs` | `/api/login`, `/api/signup` |
| MFA | `MfaEndpoints.cs` | `/api/login/verify-mfa` |
| Usuários | `UserEndpoints.cs` | `/api/users/*` |
| Vídeos | `VideoEndpoints.cs` | `/api/videos/*` |
| Pedidos | `OrderEndpoints.cs` | `/api/orders/*` |
| Pagamentos | `PaymentEndpoints.cs` | `/api/payments/*` |
| Webhooks | `WebHookEndpoint.cs` | `/api/webhooks/iugu` |
| Admin | `AdminEndpoints.cs` | `/api/admin/*` |
| Owners | `OwnerEndpoints.cs` | `/api/owners/*` |
| Promoter | `PromoterEndpoint.cs` | `/api/promoter/*` |
| Influencer | `InfluencerDashboardEndpoints.cs` | `/api/influencer/*` |

## Padrão de Response

### Sucesso

```json
{
  "data": { ... },
  "message": "Operação realizada com sucesso"
}
```

### Erro

```json
{
  "error": "Mensagem de erro",
  "details": { ... }
}
```

## Status Codes

| Código | Significado |
|--------|-------------|
| 200 OK | Sucesso |
| 201 Created | Recurso criado |
| 400 Bad Request | Dados inválidos |
| 401 Unauthorized | Não autenticado |
| 403 Forbidden | Sem permissão |
| 404 Not Found | Não encontrado |
| 500 Internal Server Error | Erro no servidor |

## Paginação

Endpoints que retornam listas suportam paginação:

```http
GET /api/videos?page=1&perPage=20
```

**Response:**
```json
{
  "data": [...],
  "page": 1,
  "perPage": 20,
  "total": 150,
  "totalPages": 8
}
```

## Filtros e Ordenação

```http
GET /api/videos?sortBy=price&direction=asc&minPrice=10&maxPrice=100
```

## CORS

A API permite requisições do frontend:

```csharp
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins("http://localhost:5173", "https://amasso.com.br")
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});
```

## Rate Limiting

- **Por IP**: 100 requisições/minuto
- **Login**: 5 tentativas/15 minutos

## Logs

Todas as requisições são logadas com:
- Timestamp
- User ID (se autenticado)
- Endpoint
- Status Code
- Duração

## Próximos Passos

- Veja [Autenticação](autenticacao.md) para endpoints de login
- Consulte [Vídeos](endpoints/video.md) para catálogo
- Entenda [Orders](endpoints/order.md) para compras

