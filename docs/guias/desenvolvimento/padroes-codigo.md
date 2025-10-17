# Padrões de Código

## Nomenclatura

### C# (Backend API / Email API)

**Classes, Interfaces e Enums**: `PascalCase`
```csharp
public class VideoService { }
public interface IEmailSender { }
public enum UserTypeEnum { }
```

**Métodos e Propriedades**: `PascalCase`
```csharp
public async Task<Video> GetVideoByIdAsync(long id) { }
public string FirstName { get; set; }
```

**Variáveis locais e parâmetros**: `camelCase`
```csharp
var videoId = 123;
public async Task CreateOrder(long userId, CreateOrderDto dto)
```

**Constantes**: `UPPER_SNAKE_CASE` ou `PascalCase`
```csharp
public const string DEFAULT_CURRENCY = "BRL";
public const int MaxRetryAttempts = 3;
```

**Private fields**: `_camelCase` (com underscore)
```csharp
private readonly ApplicationDbContext _context;
private readonly ILogger<VideoService> _logger;
```

### TypeScript (Frontend React)

**Componentes React**: `PascalCase`
```typescript
export const VideoCard = () => { }
export const UserDashboard = () => { }
```

**Funções e variáveis**: `camelCase`
```typescript
const handleSubmit = () => { }
const isLoading = false
```

**Interfaces e Types**: `PascalCase`
```typescript
interface User {
  id: number
  email: string
}

type VideoFilters = {
  search?: string
  minPrice?: number
}
```

**Constantes**: `UPPER_SNAKE_CASE`
```typescript
export const API_BASE_URL = 'http://localhost:7080'
export const MAX_FILE_SIZE = 100 * 1024 * 1024 // 100MB
```

**Arquivos**: `camelCase.tsx` ou `PascalCase.tsx`
```
videoCard.tsx          // componente pequeno
VideoCard.tsx          // componente principal
userService.ts         // service
apiClient.ts           // utility
```

### PostgreSQL (Database)

**Tabelas e colunas**: `snake_case`
```sql
CREATE TABLE video_affiliate_links (
    id BIGSERIAL PRIMARY KEY,
    owner_id BIGINT NOT NULL,
    video_id BIGINT NOT NULL,
    unique_code VARCHAR(50),
    created_at TIMESTAMP
);
```

**Índices**: `idx_[table]_[columns]`
```sql
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_payments_iugu_invoice_id ON payments(iugu_invoice_id);
```

**Foreign Keys**: `fk_[table]_[referenced_table]`
```sql
CONSTRAINT fk_orders_users FOREIGN KEY (user_id) REFERENCES users(id)
```

## DTOs vs Entities

### Entities (Banco de Dados)

```csharp
// backend-api/Data/Entities/User.cs
public class User
{
    public long Id { get; set; }
    public string Email { get; set; }
    public string PasswordHash { get; set; }  // Nunca expor!
    public UserTypeEnum Type { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public DateTime? DeletedAt { get; set; }
    
    // Navigation Properties
    public ICollection<Order> Orders { get; set; }
}
```

### DTOs (Data Transfer Objects)

```csharp
// backend-api/Data/Dtos/UserDto.cs
public record UserDto
{
    public long Id { get; init; }
    public string Email { get; init; }
    public string FirstName { get; init; }
    public string LastName { get; init; }
    public UserTypeEnum Type { get; init; }
    public bool IsActive { get; init; }
    // Sem PasswordHash!
    // Sem DeletedAt!
}

// Input DTO
public record CreateUserDto
{
    public string Email { get; init; }
    public string Password { get; init; }
    public string FirstName { get; init; }
    public string LastName { get; init; }
}
```

**Regra**: Nunca retornar Entity diretamente. Sempre usar DTO para APIs.

## Async/Await

**Sempre** usar `async`/`await` para operações I/O (banco, HTTP, arquivos).

✅ **Correto:**
```csharp
public async Task<Video> GetVideoByIdAsync(long id)
{
    var video = await _context.Videos
        .Include(v => v.VideoRevenueConfig)
        .FirstOrDefaultAsync(v => v.Id == id);
    
    return video;
}
```

❌ **Incorreto:**
```csharp
public Video GetVideoById(long id)
{
    // Bloqueando thread!
    var video = _context.Videos.FirstOrDefault(v => v.Id == id);
    return video;
}
```

**Nomenclatura**: Métodos async devem terminar com `Async`.

## Try/Catch

### Backend (C#)

Sempre usar `try/catch` para:
- Operações externas (HTTP, Iugu, Cloudinary)
- Operações críticas (pagamentos)

```csharp
public async Task<Invoice> CreateInvoiceAsync(Order order)
{
    try
    {
        var response = await _httpClient.PostAsJsonAsync(url, payload);
        response.EnsureSuccessStatusCode();
        
        var invoice = await response.Content.ReadFromJsonAsync<Invoice>();
        return invoice;
    }
    catch (HttpRequestException ex)
    {
        _logger.LogError(ex, "Failed to create Iugu invoice for order {OrderId}", order.Id);
        throw new InvalidOperationException("Erro ao criar invoice no Iugu", ex);
    }
}
```

### Frontend (TypeScript)

```typescript
const handleCheckout = async () => {
  try {
    setIsLoading(true)
    
    const order = await orderApi.create({ videoId })
    
    window.location.href = order.payment.iuguSecureUrl
  } catch (error: any) {
    const message = error.response?.data?.error || 'Erro ao criar pedido'
    toast.error(message)
  } finally {
    setIsLoading(false)
  }
}
```

## Validações

### Backend com FluentValidation

```csharp
// backend-api/Data/Validations/CreateOrderDtoValidator.cs
public class CreateOrderDtoValidator : AbstractValidator<CreateOrderDto>
{
    public CreateOrderDtoValidator()
    {
        RuleFor(x => x.VideoId)
            .GreaterThan(0)
            .WithMessage("VideoId deve ser maior que 0");
        
        RuleFor(x => x.AffiliateCode)
            .MaximumLength(50)
            .When(x => !string.IsNullOrEmpty(x.AffiliateCode))
            .WithMessage("Código de afiliado deve ter no máximo 50 caracteres");
    }
}

// Registrar no Program.cs
builder.Services.AddValidatorsFromAssemblyContaining<CreateOrderDtoValidator>();
```

### Frontend com Zod

```typescript
import { z } from 'zod'

const createOrderSchema = z.object({
  videoId: z.number().min(1, 'Vídeo inválido'),
  affiliateCode: z.string().max(50).optional()
})

type CreateOrderDto = z.infer<typeof createOrderSchema>

// Uso
const result = createOrderSchema.safeParse(data)
if (!result.success) {
  toast.error(result.error.errors[0].message)
  return
}
```

## Comentários

**Comentar apenas quando necessário**.

✅ **Bom (explica "por quê"):**
```csharp
// Ajustar arredondamento para garantir que split = total
var diff = totalCents - (platformCents + ownerCents + promoterCents);
if (diff != 0) ownerCents += diff;
```

✅ **Bom (explica lógica complexa):**
```csharp
// Webhook pode chegar múltiplas vezes, verificar idempotência
if (payment.Status == PaymentStatusEnum.Paid)
{
    _logger.LogInformation("Payment already processed");
    return Results.Ok(new { AlreadyProcessed = true });
}
```

❌ **Ruim (óbvio):**
```csharp
// Incrementa contador
counter++;

// Retorna o vídeo
return video;
```

## Logging

### Níveis

- `LogInformation`: Operações normais
- `LogWarning`: Situações anormais mas recuperáveis
- `LogError`: Erros que impedem operação

```csharp
_logger.LogInformation("Processing order {OrderId} for user {UserId}", 
    order.Id, userId);

_logger.LogWarning("Invalid affiliate code {Code} for video {VideoId}", 
    affiliateCode, videoId);

_logger.LogError(ex, "Failed to confirm payment {PaymentId}", 
    payment.Id);
```

### Structured Logging

✅ **Correto:**
```csharp
_logger.LogInformation("User {UserId} purchased video {VideoId} for {Amount}", 
    userId, videoId, amount);
```

❌ **Incorreto:**
```csharp
_logger.LogInformation($"User {userId} purchased video {videoId} for {amount}");
```

## Queries Eficientes

### Usar Include para evitar N+1

❌ **N+1 Problem:**
```csharp
var orders = await _context.Orders.ToListAsync();
foreach (var order in orders)
{
    // Faz 1 query por order!
    var video = await _context.Videos.FindAsync(order.VideoId);
}
```

✅ **Correto:**
```csharp
var orders = await _context.Orders
    .Include(o => o.Video)
    .Include(o => o.Payment)
    .Include(o => o.User)
    .ToListAsync();
```

### Projetar apenas campos necessários

❌ **Busca tudo:**
```csharp
var videos = await _context.Videos.ToListAsync();
```

✅ **Seleciona apenas necessário:**
```csharp
var videos = await _context.Videos
    .Select(v => new VideoListDto
    {
        Id = v.Id,
        Title = v.Title,
        Price = v.Price,
        ThumbImgUrl = v.ThumbImgUrl
    })
    .ToListAsync();
```

## Segurança

### Nunca expor senhas

❌ **NUNCA:**
```csharp
return Results.Ok(user); // Contém PasswordHash!
```

✅ **Sempre usar DTO:**
```csharp
return Results.Ok(new UserDto
{
    Id = user.Id,
    Email = user.Email,
    // Sem PasswordHash!
});
```

### Validar JWT

```csharp
private long GetUserIdFromToken(HttpRequest request)
{
    var userIdClaim = request.HttpContext.User
        .FindFirst(ClaimTypes.NameIdentifier);
    
    if (userIdClaim == null)
        throw new UnauthorizedAccessException("Token inválido");
    
    return long.Parse(userIdClaim.Value);
}
```

### SQL Injection - EF Core protege

✅ **Seguro (EF Core parametriza):**
```csharp
var videos = await _context.Videos
    .Where(v => v.Title.Contains(search))
    .ToListAsync();
```

❌ **NUNCA usar SQL raw com concatenação:**
```csharp
var sql = $"SELECT * FROM videos WHERE title LIKE '%{search}%'";
var videos = await _context.Videos.FromSqlRaw(sql).ToListAsync();
```

## Testes

### Nomenclatura

```csharp
[Fact]
public async Task CreateOrder_WithValidData_ShouldReturnOrder()
{
    // Arrange
    var dto = new CreateOrderDto { VideoId = 1 };
    
    // Act
    var result = await _service.CreateOrderAsync(dto, userId);
    
    // Assert
    Assert.NotNull(result);
    Assert.Equal(1, result.VideoId);
}
```

Padrão: `MethodName_Scenario_ExpectedBehavior`

## Próximos Passos

- [Estrutura de Projeto](estrutura-projeto.md)
- [Adicionar Endpoint](adicionar-endpoint.md)
- [Adicionar Entidade](adicionar-entidade.md)

