# Hangfire Jobs

## Descrição

**Hangfire** é utilizado para processamento de jobs em background, incluindo envio de notificações e limpeza de dados antigos.

## Dashboard

Acesse: `http://localhost:5014/dashboard`

### Autenticação

```csharp
// email-api/Program.cs
app.UseHangfireDashboard("/dashboard", new DashboardOptions
{
    Authorization = new[]
    {
        new HangfireAuthorizationFilter()
    },
    DashboardTitle = "Amasso - Email API Jobs"
});

public class HangfireAuthorizationFilter : IDashboardAuthorizationFilter
{
    public bool Authorize(DashboardContext context)
    {
        var httpContext = context.GetHttpContext();
        
        // Básico: usuário/senha
        var auth = httpContext.Request.Headers["Authorization"].ToString();
        
        if (string.IsNullOrEmpty(auth))
        {
            httpContext.Response.StatusCode = 401;
            httpContext.Response.Headers["WWW-Authenticate"] = "Basic realm=\"Hangfire Dashboard\"";
            return false;
        }
        
        // Decode Basic Auth
        var encodedCreds = auth.Replace("Basic ", "");
        var decodedCreds = Encoding.UTF8.GetString(Convert.FromBase64String(encodedCreds));
        var credentials = decodedCreds.Split(':');
        
        var username = credentials[0];
        var password = credentials[1];
        
        var configUsername = context.GetHttpContext().RequestServices
            .GetRequiredService<IConfiguration>()["Hangfire:DashboardUsername"];
        
        var configPassword = context.GetHttpContext().RequestServices
            .GetRequiredService<IConfiguration>()["Hangfire:DashboardPassword"];
        
        return username == configUsername && password == configPassword;
    }
}
```

**appsettings.json:**
```json
{
  "Hangfire": {
    "DashboardUsername": "admin",
    "DashboardPassword": "senha-forte-aqui"
  }
}
```

## Jobs Configurados

### 1. ProcessPendingNotifications

**Frequência**: A cada 1 minuto  
**Descrição**: Processa notificações pendentes de envio

```csharp
// email-api/Program.cs
RecurringJob.AddOrUpdate(
    "process-pending-notifications",
    () => notificationService.ProcessPendingNotificationsAsync(),
    Cron.Minutely
);
```

**Service:**
```csharp
// email-api/Services/NotificationService.cs
[AutomaticRetry(Attempts = 3)]
public async Task ProcessPendingNotificationsAsync()
{
    var pendingNotifications = await _context.Notifications
        .Where(n => !n.IsSent &&
                    n.SendAttempts < 3 &&
                    (n.ScheduledToSend == null || n.ScheduledToSend <= DateTime.UtcNow))
        .OrderBy(n => n.CreatedAt)
        .Take(50)
        .ToListAsync();
    
    _logger.LogInformation("Processing {Count} pending notifications", pendingNotifications.Count);
    
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

### 2. CleanupOldNotifications

**Frequência**: Diariamente às 03:00  
**Descrição**: Remove notificações antigas (>90 dias)

```csharp
// email-api/Program.cs
RecurringJob.AddOrUpdate(
    "cleanup-old-notifications",
    () => logCleanupService.CleanupOldNotificationsAsync(),
    Cron.Daily(3) // 03:00 AM
);
```

**Service:**
```csharp
// email-api/Services/LogCleanupService.cs
public async Task CleanupOldNotificationsAsync()
{
    var cutoffDate = DateTime.UtcNow.AddDays(-90);
    
    var oldNotifications = await _context.Notifications
        .Where(n => n.CreatedAt < cutoffDate)
        .ToListAsync();
    
    _logger.LogInformation("Cleaning up {Count} old notifications", oldNotifications.Count);
    
    _context.Notifications.RemoveRange(oldNotifications);
    await _context.SaveChangesAsync();
    
    _logger.LogInformation("Cleanup completed successfully");
}
```

## Cron Expressions

| Expressão | Descrição |
|-----------|-----------|
| `Cron.Minutely` | A cada minuto |
| `Cron.Hourly` | A cada hora |
| `Cron.Daily` | Diariamente à meia-noite |
| `Cron.Daily(3)` | Diariamente às 03:00 |
| `Cron.Weekly` | Semanalmente aos domingos |
| `Cron.Monthly` | Mensalmente no dia 1 |
| `"*/5 * * * *"` | A cada 5 minutos |
| `"0 */2 * * *"` | A cada 2 horas |
| `"0 0 * * 1"` | Toda segunda-feira à meia-noite |

## Como Adicionar Novo Job

### 1. Criar Service

```csharp
// email-api/Services/MyNewService.cs
public class MyNewService
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<MyNewService> _logger;
    
    public MyNewService(ApplicationDbContext context, ILogger<MyNewService> logger)
    {
        _context = context;
        _logger = logger;
    }
    
    [AutomaticRetry(Attempts = 3)]
    public async Task DoSomethingAsync()
    {
        _logger.LogInformation("Starting job...");
        
        try
        {
            // Lógica do job aqui
            
            _logger.LogInformation("Job completed successfully");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in job");
            throw;
        }
    }
}
```

### 2. Registrar Service

```csharp
// email-api/Program.cs
builder.Services.AddScoped<MyNewService>();
```

### 3. Agendar Job

```csharp
// email-api/Program.cs
using (var scope = app.Services.CreateScope())
{
    var recurringJobManager = scope.ServiceProvider.GetRequiredService<IRecurringJobManager>();
    var myService = scope.ServiceProvider.GetRequiredService<MyNewService>();
    
    RecurringJob.AddOrUpdate(
        "my-new-job",
        () => myService.DoSomethingAsync(),
        Cron.Hourly
    );
}
```

## Fire-and-Forget Jobs

Para jobs que executam uma vez:

```csharp
// Enfileirar job para execução imediata
BackgroundJob.Enqueue(() => myService.DoSomethingAsync());

// Agendar para daqui 1 hora
BackgroundJob.Schedule(
    () => myService.DoSomethingAsync(),
    TimeSpan.FromHours(1)
);
```

## Monitoramento

### Via Dashboard

- **Succeeded Jobs**: Jobs executados com sucesso
- **Failed Jobs**: Jobs que falharam
- **Recurring Jobs**: Jobs agendados
- **Processing**: Jobs em execução
- **Scheduled**: Jobs agendados para futuro
- **Enqueued**: Jobs na fila

### Via Logs

```csharp
_logger.LogInformation("Job started: {JobName} at {Time}", 
    "process-pending-notifications", DateTime.UtcNow);

_logger.LogInformation("Processed {Count} items in {Duration}ms", 
    count, stopwatch.ElapsedMilliseconds);

_logger.LogError(ex, "Job failed: {JobName}", "process-pending-notifications");
```

### Queries SQL

```sql
-- Jobs executados hoje
SELECT * FROM hangfire.job
WHERE createdat >= CURRENT_DATE
ORDER BY createdat DESC;

-- Jobs com falha
SELECT * FROM hangfire.job
WHERE statename = 'Failed'
ORDER BY createdat DESC
LIMIT 20;

-- Tempo médio de execução
SELECT 
    AVG(EXTRACT(EPOCH FROM (statechangedat - createdat))) as avg_duration_seconds
FROM hangfire.job
WHERE statename = 'Succeeded'
  AND createdat >= NOW() - INTERVAL '24 hours';
```

## Configuração Avançada

### Threads e Workers

```csharp
// email-api/Program.cs
builder.Services.AddHangfire(config =>
{
    config.UsePostgreSqlStorage(connectionString);
    config.UseSimpleAssemblyNameTypeSerializer();
    config.UseRecommendedSerializerSettings();
});

builder.Services.AddHangfireServer(options =>
{
    options.WorkerCount = 5; // Número de workers paralelos
    options.ServerName = "EmailAPI-Worker";
    options.Queues = new[] { "default", "emails", "critical" };
});
```

### Filas Prioritárias

```csharp
// Job crítico (fila "critical")
BackgroundJob.Enqueue(
    () => criticalService.DoSomethingAsync(),
    new BackgroundJobOptions
    {
        Queue = "critical"
    }
);

// Job de email (fila "emails")
BackgroundJob.Enqueue(
    () => emailService.SendAsync(notification),
    new BackgroundJobOptions
    {
        Queue = "emails"
    }
);
```

### Retry Policy

```csharp
[AutomaticRetry(Attempts = 5, DelaysInSeconds = new[] { 30, 60, 300, 600, 1800 })]
public async Task SendCriticalEmailAsync(Notification notification)
{
    // Tenta 5 vezes com delays crescentes
    // 30s, 1min, 5min, 10min, 30min
}
```

## Troubleshooting

### Job não executa

1. Verificar se Hangfire Server está rodando
2. Verificar logs da aplicação
3. Verificar dashboard para erros
4. Verificar conexão com PostgreSQL

### Job falha sempre

1. Ver detalhes no dashboard (Failed Jobs)
2. Ver stack trace completo
3. Verificar logs
4. Reprocessar manualmente no dashboard

### Performance

```csharp
// Processar em batch
var notifications = await _context.Notifications
    .Where(n => !n.IsSent)
    .Take(100) // <-- Limitar quantidade
    .ToListAsync();

// Usar transação
using var transaction = await _context.Database.BeginTransactionAsync();
try
{
    // Processar
    await _context.SaveChangesAsync();
    await transaction.CommitAsync();
}
catch
{
    await transaction.RollbackAsync();
    throw;
}
```

## Próximos Passos

- [Notificações](notificacoes.md) - Sistema de notificações
- [Templates](templates.md) - Templates de email/WhatsApp
- [Visão Geral](visao-geral.md) - Arquitetura Email API

