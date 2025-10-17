# Notificações

## Descrição

Sistema de notificações assíncronas por email e WhatsApp processadas pela **Email API** usando **Hangfire** para jobs em background.

## Tabela: notifications

```sql
CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    type VARCHAR(50) NOT NULL,
    channel VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    metadata_json TEXT,
    is_sent BOOLEAN DEFAULT FALSE,
    send_attempts INTEGER DEFAULT 0,
    scheduled_to_send TIMESTAMP,
    sent_at TIMESTAMP,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);
```

## NotificationTypeEnum

| Tipo | Descrição | Canal Padrão |
|------|-----------|--------------|
| `MfaCode` | Código de autenticação MFA | Email |
| `UserActivation` | Código de ativação de conta | Email |
| `ForgotPassword` | Código de recuperação de senha | Email |
| `PaymentConfirmed` | Confirmação de pagamento | Preferência usuário |
| `VideoReleaseSchedule` | Lançamento de vídeo agendado | Preferência usuário |
| `KycSubmitted` | KYC enviado (notifica admin) | Email |
| `KycApproved` | KYC aprovado | Preferência usuário |
| `KycRejected` | KYC rejeitado com motivo | Preferência usuário |
| `NewSale` | Nova venda (influencer/promoter) | Preferência usuário |

```csharp
// email-api/Data/Enums/NotificationTypeEnum.cs
public enum NotificationTypeEnum
{
    MfaCode,
    UserActivation,
    ForgotPassword,
    PaymentConfirmed,
    VideoReleaseSchedule,
    KycSubmitted,
    KycApproved,
    KycRejected,
    NewSale
}
```

## NotificationChannelEnum

| Canal | Descrição |
|-------|-----------|
| `Email` | Apenas email (SMTP) |
| `WhatsApp` | Apenas WhatsApp (Z-API) |
| `All` | Email + WhatsApp (ambos) |

```csharp
// email-api/Data/Enums/NotificationChannelEnum.cs
public enum NotificationChannelEnum
{
    Email,
    WhatsApp,
    All
}
```

## Metadata JSON por Tipo

### MfaCode
```json
{
  "Code": "123456",
  "ExpiresIn": 5
}
```

### UserActivation
```json
{
  "Code": "123456",
  "UserName": "João Silva"
}
```

### PaymentConfirmed
```json
{
  "OrderId": 789,
  "VideoTitle": "Vídeo Exclusivo",
  "Amount": 99.90
}
```

### VideoReleaseSchedule
```json
{
  "VideoId": 123,
  "VideoTitle": "Novo Vídeo",
  "ReleaseDate": "2025-12-01T00:00:00Z"
}
```

### KycApproved
```json
{
  "OwnerType": "Promoter"
}
```

### KycRejected
```json
{
  "OwnerType": "Promoter",
  "Reason": "Documentos ilegíveis"
}
```

### NewSale
```json
{
  "OrderId": 789,
  "VideoTitle": "Vídeo Exclusivo",
  "BuyerName": "João Silva",
  "Commission": 29.97
}
```

## Send Attempts e Retry

Sistema de retry automático para notificações que falharam:

- **Máximo 3 tentativas**
- **Intervalo**: Job roda a cada 1 minuto
- **Após 3 falhas**: Notificação é marcada como failed (não tenta mais)

```csharp
// email-api/Services/NotificationService.cs
public async Task ProcessPendingNotificationsAsync()
{
    var pendingNotifications = await _context.Notifications
        .Where(n => !n.IsSent &&
                    n.SendAttempts < 3 &&
                    (n.ScheduledToSend == null || n.ScheduledToSend <= DateTime.UtcNow))
        .OrderBy(n => n.CreatedAt)
        .Take(50)
        .ToListAsync();
    
    foreach (var notification in pendingNotifications)
    {
        try
        {
            notification.SendAttempts++;
            
            // Email
            if (notification.Channel == NotificationChannelEnum.Email ||
                notification.Channel == NotificationChannelEnum.All)
            {
                await _emailSender.SendAsync(notification);
            }
            
            // WhatsApp
            if (notification.Channel == NotificationChannelEnum.WhatsApp ||
                notification.Channel == NotificationChannelEnum.All)
            {
                await _whatsAppSender.SendAsync(notification);
            }
            
            notification.IsSent = true;
            notification.SentAt = DateTime.UtcNow;
            notification.UpdatedAt = DateTime.UtcNow;
            
            _logger.LogInformation("Notification {Id} sent successfully", notification.Id);
        }
        catch (Exception ex)
        {
            notification.ErrorMessage = ex.Message;
            notification.UpdatedAt = DateTime.UtcNow;
            
            _logger.LogError(ex, "Error sending notification {Id}", notification.Id);
        }
    }
    
    await _context.SaveChangesAsync();
}
```

## Criação de Notificações

### Backend API cria notificações

```csharp
// backend-api/Services/LoginService.cs
public async Task SendMfaCodeAsync(string email, string code)
{
    var notification = new Notification
    {
        Type = NotificationTypeEnum.MfaCode,
        Channel = NotificationChannelEnum.Email,
        Email = email,
        MetadataJson = JsonSerializer.Serialize(new
        {
            Code = code,
            ExpiresIn = 5
        }),
        CreatedAt = DateTime.UtcNow
    };
    
    await _context.Notifications.AddAsync(notification);
    await _context.SaveChangesAsync();
}

// backend-api/Services/PaymentService.cs
public async Task NotifyPaymentConfirmedAsync(Order order)
{
    var user = await _context.Users.FindAsync(order.UserId);
    
    var notification = new Notification
    {
        Type = NotificationTypeEnum.PaymentConfirmed,
        Channel = user.NotificationPreference ?? NotificationChannelEnum.Email,
        Email = user.Email,
        Phone = user.Telephone,
        MetadataJson = JsonSerializer.Serialize(new
        {
            OrderId = order.Id,
            VideoTitle = order.Video.Title,
            Amount = order.Amount / 100m
        }),
        CreatedAt = DateTime.UtcNow
    };
    
    await _context.Notifications.AddAsync(notification);
    await _context.SaveChangesAsync();
}
```

## Agendamento de Notificações

Notificações podem ser agendadas para envio futuro:

```csharp
// Enviar 24h antes do lançamento do vídeo
public async Task ScheduleVideoReleaseNotificationAsync(Video video)
{
    var releaseDate = video.ReleaseDate.Value;
    var sendAt = releaseDate.AddHours(-24);
    
    var users = await _context.Users
        .Where(u => u.IsActive && u.NotificationPreference != null)
        .ToListAsync();
    
    var notifications = users.Select(u => new Notification
    {
        Type = NotificationTypeEnum.VideoReleaseSchedule,
        Channel = u.NotificationPreference ?? NotificationChannelEnum.Email,
        Email = u.Email,
        Phone = u.Telephone,
        ScheduledToSend = sendAt, // <-- Agendada
        MetadataJson = JsonSerializer.Serialize(new
        {
            VideoId = video.Id,
            VideoTitle = video.Title,
            ReleaseDate = releaseDate
        }),
        CreatedAt = DateTime.UtcNow
    }).ToList();
    
    await _context.Notifications.AddRangeAsync(notifications);
    await _context.SaveChangesAsync();
}
```

## Entidade C#

```csharp
// email-api/Data/Entities/Notification.cs
public class Notification
{
    public long Id { get; set; }
    public NotificationTypeEnum Type { get; set; }
    public NotificationChannelEnum Channel { get; set; }
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? MetadataJson { get; set; }
    public bool IsSent { get; set; }
    public int SendAttempts { get; set; }
    public DateTime? ScheduledToSend { get; set; }
    public DateTime? SentAt { get; set; }
    public string? ErrorMessage { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
```

## Queries Úteis

### Notificações pendentes
```sql
SELECT * FROM notifications
WHERE is_sent = FALSE
  AND send_attempts < 3
  AND (scheduled_to_send IS NULL OR scheduled_to_send <= NOW())
ORDER BY created_at
LIMIT 50;
```

### Notificações com falha
```sql
SELECT 
    id,
    type,
    channel,
    email,
    send_attempts,
    error_message,
    created_at
FROM notifications
WHERE is_sent = FALSE
  AND send_attempts >= 3
ORDER BY created_at DESC;
```

### Taxa de sucesso
```sql
SELECT 
    type,
    COUNT(*) as total,
    SUM(CASE WHEN is_sent THEN 1 ELSE 0 END) as enviadas,
    ROUND(100.0 * SUM(CASE WHEN is_sent THEN 1 ELSE 0 END) / COUNT(*), 2) as taxa_sucesso
FROM notifications
GROUP BY type;
```

## Monitoramento

### Dashboard Hangfire

Acesse: `http://localhost:5014/dashboard`

- Visualizar jobs executados
- Ver notificações processadas
- Reprocessar manualmente

### Logs

```csharp
_logger.LogInformation("Notification {Id} sent successfully: {Type} to {Email}", 
    notification.Id, notification.Type, notification.Email);

_logger.LogError(ex, "Error sending notification {Id}: {Type}", 
    notification.Id, notification.Type);
```

## Próximos Passos

- [Templates](templates.md) - Como criar templates
- [Hangfire Jobs](hangfire-jobs.md) - Configuração de jobs
- [Visão Geral](visao-geral.md) - Arquitetura Email API

