# Comunicação Entre Sistemas

Este documento detalha como os três principais componentes da plataforma Amasso se comunicam entre si e com serviços externos.

## Visão Geral da Comunicação

```mermaid
graph LR
    FE[Frontend] -->|HTTP/REST| BE[Backend API]
    BE -->|SQL| DB[(PostgreSQL)]
    BE -->|INSERT notifications| DB
    EA[Email API] -->|SELECT notifications| DB
    EA -->|UPDATE notifications| DB
    BE -->|HTTP| Iugu[Iugu API]
    Iugu -->|Webhook| BE
    BE -->|HTTP| Cloud[Cloudinary]
    EA -->|SMTP| SES[AWS SES]
    EA -->|HTTP| ZApi[Z-API]
    
    style FE fill:#61dafb
    style BE fill:#512bd4
    style EA fill:#512bd4
    style DB fill:#336791
```

## 1. Frontend ↔ Backend API

### Protocolo
- **HTTP/REST** via Axios
- **JSON** para payloads
- **JWT** para autenticação

### Fluxo de Autenticação

```mermaid
sequenceDiagram
    participant F as Frontend
    participant B as Backend API
    participant D as Database
    participant E as Email API
    
    F->>B: POST /api/login {email, password}
    B->>D: SELECT user WHERE email
    B->>D: Verify password hash
    B->>D: Generate MFA code
    B->>D: INSERT INTO mfa_codes
    B->>D: INSERT INTO notifications (MfaCode)
    B-->>F: {requiresMfa: true}
    
    Note over E: Job agendado executa
    E->>D: SELECT notifications pendentes
    E->>F: Envia código por email/WhatsApp
    
    F->>B: POST /api/login/verify-mfa {code}
    B->>D: Validate MFA code
    B->>B: Generate JWT token
    B-->>F: {token, user}
    
    F->>F: Store token in localStorage
    F->>B: All future requests with<br/>Authorization: Bearer {token}
```

### Exemplo de Request

```typescript
// Frontend
const response = await axios.post('/api/login', {
  email: 'user@email.com',
  password: 'senha123',
  signInWith: 'Default'
});

if (response.data.requiresMfa) {
  // Mostrar tela de MFA
  const mfaResponse = await axios.post('/api/login/verify-mfa', {
    email: 'user@email.com',
    code: '123456'
  });
  
  const { token } = mfaResponse.data;
  localStorage.setItem('token', token);
  
  // Configurar axios para usar token
  axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
}
```

## 2. Backend API ↔ PostgreSQL

### Protocolo
- **Npgsql** (Driver .NET para PostgreSQL)
- **Entity Framework Core** como ORM

### Padrão de Acesso

```csharp
// 1. Definir entidade
public class Video : Base
{
    public string Title { get; set; }
    public decimal Price { get; set; }
    // ... outros campos
}

// 2. Configurar mapeamento
public class VideoConfiguration : IEntityTypeConfiguration<Video>
{
    public void Configure(EntityTypeBuilder<Video> entity)
    {
        entity.ToTable("videos");
        entity.HasKey(v => v.Id);
        entity.Property(v => v.Title).HasColumnName("title").IsRequired();
        // ...
    }
}

// 3. Usar no serviço
public class VideoService
{
    private readonly Pay4TruDb _context;
    
    public async Task<Video> GetByIdAsync(long id)
    {
        return await _context.Videos
            .Include(v => v.VideoRevenueConfig)
            .FirstOrDefaultAsync(v => v.Id == id && v.IsActive);
    }
}
```

### Transações

```csharp
// Operações atômicas
using var transaction = await _context.Database.BeginTransactionAsync();
try
{
    // 1. Criar order
    _context.Orders.Add(order);
    await _context.SaveChangesAsync();
    
    // 2. Criar payment
    _context.Payments.Add(payment);
    await _context.SaveChangesAsync();
    
    // 3. Criar notification
    _context.Notifications.Add(notification);
    await _context.SaveChangesAsync();
    
    await transaction.CommitAsync();
}
catch
{
    await transaction.RollbackAsync();
    throw;
}
```

## 3. Backend API ↔ Email API

### Comunicação Assíncrona via Database

**Não há comunicação HTTP direta**. A comunicação acontece através do banco de dados compartilhado:

```mermaid
sequenceDiagram
    participant B as Backend API
    participant D as PostgreSQL
    participant H as Hangfire
    participant E as Email API
    participant U as Usuário
    
    B->>D: INSERT INTO notifications<br/>(type, channel, metadata, status=pending)
    Note over D: Notification registrada
    
    loop A cada X minutos (cron)
        H->>E: Dispara Job
        E->>D: SELECT * FROM notifications<br/>WHERE status=pending AND type=X
        E->>E: Renderiza template
        E->>U: Envia email/WhatsApp
        E->>D: UPDATE notifications<br/>SET date_sent=now(), status=sent
    end
```

### Exemplo Completo

**Backend API cria notificação:**

```csharp
// Em qualquer Service do Backend API
var notification = new Notification
{
    Type = NotificationTypeEnum.VideoReleaseSchedule,
    Channel = user.NotificationPreference, // Email, WhatsApp ou All
    MetadataJson = JsonSerializer.Serialize(new
    {
        Email = user.Email,
        PhoneNumber = user.Telephone,
        Name = user.FirstName,
        VideoTitle = video.Title,
        VideoId = video.Id,
        Subject = "Novo vídeo disponível!"
    }),
    ScheduleDate = video.ReleaseDate, // Opcional: agendar para o futuro
    IsActive = true,
    CreatedAt = DateTime.UtcNow
};

await _context.Notifications.AddAsync(notification);
await _context.SaveChangesAsync();
// Pronto! Email API processará
```

**Email API processa (automaticamente via Hangfire):**

```csharp
// Job configurado no appsettings.json
// { "Type": "VideoReleaseSchedule", "Channel": "Email", "CronExpression": "*/5 * * * *" }

public async Task SendScheduledByTypeAndChannelAsync(
    NotificationTypeEnum.VideoReleaseSchedule,
    NotificationChannelEnum.Email)
{
    // 1. Busca notificações pendentes
    var notifications = await _context.Notifications
        .Where(n => n.Type == NotificationTypeEnum.VideoReleaseSchedule &&
                   n.Channel == NotificationChannelEnum.Email &&
                   n.DateSent == null &&
                   n.SendAttempts < 3)
        .ToListAsync();
    
    // 2. Processa cada uma
    foreach (var notification in notifications)
    {
        var metadata = JsonSerializer.Deserialize<Dictionary<string, string>>(
            notification.MetadataJson);
        
        // 3. Renderiza template
        var html = await _templateRenderer.RenderAsync(
            NotificationTypeEnum.VideoReleaseSchedule,
            metadata);
        
        // 4. Envia
        var success = await _emailSender.SendAsync(
            metadata["Email"],
            metadata["Subject"],
            html);
        
        // 5. Atualiza status
        notification.SendAttempts++;
        if (success)
        {
            notification.DateSent = DateTime.UtcNow;
        }
        else
        {
            notification.ErrorMessage = "Failed to send";
        }
    }
    
    await _context.SaveChangesAsync();
}
```

## 4. Backend API ↔ Iugu

### Criação de Invoice com Split

```mermaid
sequenceDiagram
    participant B as Backend API
    participant I as Iugu API
    participant D as Database
    
    B->>B: Calcula split baseado em<br/>VideoRevenueConfig
    B->>I: POST /v1/invoices<br/>{email, items, splits[]}
    Note over I: splits: [<br/>  {account_id: master, %},<br/>  {account_id: owner_sub, %},<br/>  {account_id: promoter_sub, %}<br/>]
    I-->>B: {id, secure_url, status: pending}
    B->>D: INSERT INTO payments<br/>(iugu_invoice_id, status)
    B-->>Frontend: {secure_url}
```

**Código do Backend:**

```csharp
public async Task<IuguInvoiceDto> CreateInvoiceWithSplitAsync(Order order)
{
    var owner = await GetOwnerForVideo(order.VideoId);
    var promoter = order.PromoterId.HasValue 
        ? await GetOwnerById(order.PromoterId.Value) 
        : null;
    
    // Montar splits
    var splits = new List<IuguSplitDto>
    {
        // Plataforma (conta master) - recebe o que sobrar
        new IuguSplitDto
        {
            recipient_account_id = _config.MasterAccountId,
            percent = order.PlatformAmount / (decimal)order.Amount * 100
        },
        // Owner/Influencer
        new IuguSplitDto
        {
            recipient_account_id = owner.IuguAccountId,
            percent = order.OwnerAmount / (decimal)order.Amount * 100
        }
    };
    
    // Promoter (se houver)
    if (promoter != null && order.PromoterAmount > 0)
    {
        splits.Add(new IuguSplitDto
        {
            recipient_account_id = promoter.IuguAccountId,
            percent = order.PromoterAmount / (decimal)order.Amount * 100
        });
    }
    
    var request = new CreateIuguInvoiceDto
    {
        email = order.User.Email,
        due_date = DateTime.Now.AddDays(3).ToString("yyyy-MM-dd"),
        items = new[]
        {
            new IuguItemDto
            {
                description = $"Vídeo: {order.Video.Title}",
                quantity = 1,
                price_cents = order.Amount
            }
        },
        splits = splits.ToArray()
    };
    
    var response = await _httpClient.PostAsJsonAsync(
        "https://api.iugu.com/v1/invoices",
        request);
    
    response.EnsureSuccessStatusCode();
    return await response.Content.ReadFromJsonAsync<IuguInvoiceDto>();
}
```

### Webhook de Confirmação

```mermaid
sequenceDiagram
    participant U as Usuário
    participant I as Iugu
    participant B as Backend API
    participant D as Database
    
    U->>I: Paga invoice
    I->>I: Executa split automático
    I->>Master: Transfere % plataforma
    I->>SubOwner: Transfere % owner
    I->>SubPromoter: Transfere % promoter
    
    I->>B: POST /api/webhook/iugu<br/>{event: invoice.paid, data: {...}}
    B->>B: Valida assinatura webhook
    B->>D: UPDATE payments<br/>SET status=paid, paid_at=now
    B->>D: INSERT INTO incomes (3x, uma por beneficiário)
    B->>D: INSERT INTO notifications<br/>(confirmação de compra)
    B-->>I: 200 OK
```

**Handler do Webhook:**

```csharp
[AllowAnonymous]
[HttpPost("/api/webhook/iugu")]
public async Task<IResult> HandleIuguWebhook(
    [FromBody] IuguWebhookDto webhook,
    [FromHeader(Name = "X-Iugu-Signature")] string signature)
{
    // 1. Validar assinatura (segurança)
    if (!ValidateSignature(webhook, signature))
        return Results.Unauthorized();
    
    // 2. Processar evento
    if (webhook.Event == "invoice.status_changed" && 
        webhook.Data.Status == "paid")
    {
        await _paymentService.ConfirmPaymentAsync(webhook.Data.Id);
    }
    
    return Results.Ok();
}
```

## 5. Backend API ↔ Cloudinary

### Upload de Vídeo

```csharp
public async Task<CloudinaryUploadResult> UploadVideoAsync(IFormFile file)
{
    var uploadParams = new VideoUploadParams()
    {
        File = new FileDescription(file.FileName, file.OpenReadStream()),
        PublicId = $"videos/{Guid.NewGuid()}",
        ResourceType = ResourceType.Video,
        Folder = "amasso-videos"
    };
    
    var result = await _cloudinary.UploadAsync(uploadParams);
    
    return new CloudinaryUploadResult
    {
        PublicId = result.PublicId,
        SecureUrl = result.SecureUrl,
        Format = result.Format,
        Duration = result.Duration
    };
}
```

## 6. Email API ↔ SMTP/Z-API

### SMTP (AWS SES)

```csharp
using var smtp = new SmtpClient("email-smtp.us-east-1.amazonaws.com", 587)
{
    Credentials = new NetworkCredential(username, password),
    EnableSsl = true
};

using var message = new MailMessage
{
    From = new MailAddress("noreply@amasso.com.br", "Amasso"),
    To = { new MailAddress(recipient) },
    Subject = subject,
    Body = htmlBody,
    IsBodyHtml = true
};

await smtp.SendMailAsync(message);
```

### Z-API (WhatsApp)

```csharp
var payload = new
{
    phone = phoneNumber, // ex: "5511999999999"
    message = textMessage
};

var endpoint = $"https://api.z-api.io/instances/{instanceId}/token/{token}/send-text";

_httpClient.DefaultRequestHeaders.Add("Client-Token", clientToken);

var response = await _httpClient.PostAsJsonAsync(endpoint, payload);
return response.IsSuccessStatusCode;
```

## Fluxo Completo: Compra de Vídeo

```mermaid
sequenceDiagram
    participant U as Usuário
    participant F as Frontend
    participant B as Backend API
    participant D as PostgreSQL
    participant I as Iugu
    participant E as Email API
    participant S as SMTP
    
    U->>F: Clica "Comprar Vídeo"
    F->>B: POST /api/orders {videoId, affiliateLinkId?}
    
    B->>D: BEGIN TRANSACTION
    B->>D: INSERT INTO orders
    B->>I: POST /invoices (com splits)
    I-->>B: {invoice_id, secure_url}
    B->>D: INSERT INTO payments
    B->>D: INSERT INTO notifications (pedido criado)
    B->>D: COMMIT
    
    B-->>F: {secure_url}
    F-->>U: Redireciona para Iugu
    
    U->>I: Paga
    I->>I: Executa split
    I->>B: Webhook: invoice.paid
    
    B->>D: BEGIN TRANSACTION
    B->>D: UPDATE payments SET status=paid
    B->>D: INSERT INTO incomes (3x)
    B->>D: INSERT INTO notifications (pagamento confirmado)
    B->>D: COMMIT
    
    B-->>I: 200 OK
    
    Note over E: Job executa (cron)
    E->>D: SELECT notifications pendentes
    E->>S: Envia email/WhatsApp
    S-->>U: Notificação
    E->>D: UPDATE notifications SET date_sent
```

## Segurança na Comunicação

### 1. Frontend ↔ Backend
- HTTPS obrigatório em produção
- JWT com expiration
- Refresh tokens
- CORS configurado

### 2. Backend ↔ Database
- Connection string com credenciais seguras
- Parameterized queries (EF Core)
- Migrations versionadas

### 3. Backend ↔ Iugu
- API Token em variáveis de ambiente
- Validação de assinatura em webhooks
- HTTPS para todas as chamadas

### 4. Email API ↔ External
- Token de autenticação para endpoints manuais
- SMTP com TLS
- Z-API com client token

## Próximos Passos

- Veja [Fluxos de Negócio](../fluxos-de-negocio/compra-video.md) para cenários detalhados
- Consulte [Pagamentos Iugu](../pagamentos/visao-geral-iugu.md) para entender splits
- Explore [Casos de Uso](../casos-de-uso/usuario-compra-video.md) com código completo

