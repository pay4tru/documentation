# Endpoints: Payment

## Descrição

Endpoint para receber webhooks do Iugu sobre status de pagamentos.

## POST /api/webhooks/iugu

Recebe notificações do Iugu sobre mudanças de status de invoice (pagamento).

**Auth**: Webhook (validação de assinatura)

**Headers:**
```
X-Iugu-Signature: sha256=abc123...
Content-Type: application/json
```

**Request:**
```json
{
  "event": "invoice.status_changed",
  "data": {
    "id": "ABC123XYZ",
    "status": "paid",
    "total_cents": 9990,
    "paid_at": "2025-01-15T11:00:00Z",
    "payer": {
      "email": "user@example.com",
      "name": "João Silva"
    }
  }
}
```

**Response (200):**
```json
{
  "received": true,
  "processed": true,
  "paymentId": 789
}
```

**Errors:**
- `401 Unauthorized`: Assinatura inválida
- `404 Not Found`: Payment não encontrado
- `200 OK`: Já processado (idempotência)

**Código Backend:**
```csharp
// backend-api/Endpoints/WebHookEndpoint.cs
app.MapPost("/api/webhooks/iugu", async (
    HttpRequest request,
    PaymentService service,
    IConfiguration config) =>
{
    // Ler body
    var body = await new StreamReader(request.Body).ReadToEndAsync();
    var signature = request.Headers["X-Iugu-Signature"].ToString();
    
    // Validar assinatura
    if (!ValidateSignature(body, signature, config["Iugu:WebhookSecret"]))
    {
        _logger.LogWarning("Invalid Iugu webhook signature");
        return Results.Unauthorized();
    }
    
    var webhook = JsonSerializer.Deserialize<IuguWebhook>(body);
    
    if (webhook.Event == "invoice.status_changed")
    {
        var processed = await service.HandleInvoiceStatusChangedAsync(webhook.Data);
        
        return Results.Ok(new
        {
            Received = true,
            Processed = processed.Success,
            PaymentId = processed.PaymentId
        });
    }
    
    return Results.Ok(new { Received = true, Processed = false });
})
.AllowAnonymous()
.WithName("IuguWebhook");

// Validação de assinatura HMAC SHA256
private bool ValidateSignature(string body, string signature, string secret)
{
    var expectedHash = signature.Replace("sha256=", "");
    
    using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(secret));
    var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(body));
    var computedHash = BitConverter.ToString(hash).Replace("-", "").ToLower();
    
    return computedHash.Equals(expectedHash, StringComparison.OrdinalIgnoreCase);
}
```

**Service - Processar Status:**
```csharp
// backend-api/Services/PaymentService.cs
public async Task<ProcessResult> HandleInvoiceStatusChangedAsync(IuguInvoiceData data)
{
    var payment = await _context.Payments
        .Include(p => p.Order)
        .ThenInclude(o => o.Video)
        .ThenInclude(v => v.OwnerVideos)
        .ThenInclude(ov => ov.Owner)
        .FirstOrDefaultAsync(p => p.IuguInvoiceId == data.Id);
    
    if (payment == null)
    {
        _logger.LogWarning("Payment not found for invoice {InvoiceId}", data.Id);
        return new ProcessResult { Success = false };
    }
    
    // Idempotência - não processar se já foi pago
    if (payment.Status == PaymentStatusEnum.Paid)
    {
        _logger.LogInformation("Payment {PaymentId} already processed", payment.Id);
        return new ProcessResult { Success = true, PaymentId = payment.Id };
    }
    
    using var transaction = await _context.Database.BeginTransactionAsync();
    
    try
    {
        if (data.Status == "paid")
        {
            await ConfirmPaymentAsync(payment);
        }
        else if (data.Status == "canceled")
        {
            payment.Status = PaymentStatusEnum.Cancelled;
            payment.UpdatedAt = DateTime.UtcNow;
        }
        else if (data.Status == "refunded")
        {
            payment.Status = PaymentStatusEnum.Refunded;
            payment.UpdatedAt = DateTime.UtcNow;
        }
        
        await _context.SaveChangesAsync();
        await transaction.CommitAsync();
        
        return new ProcessResult { Success = true, PaymentId = payment.Id };
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Error processing webhook for payment {PaymentId}", payment.Id);
        await transaction.RollbackAsync();
        throw;
    }
}

public async Task ConfirmPaymentAsync(Payment payment)
{
    // Atualizar payment
    payment.Status = PaymentStatusEnum.Paid;
    payment.IuguPaidAt = DateTime.UtcNow;
    payment.UpdatedAt = DateTime.UtcNow;
    
    // Criar incomes
    var incomes = new List<Income>();
    
    // 1. Plataforma
    incomes.Add(new Income
    {
        OrderId = payment.Order.Id,
        OwnerId = null,
        Amount = payment.Order.PlatformAmount,
        Type = IncomeTypeEnum.Platform,
        Description = "Comissão da plataforma",
        CreatedAt = DateTime.UtcNow
    });
    
    // 2. Owner
    var owner = payment.Order.Video.OwnerVideos.First().Owner;
    incomes.Add(new Income
    {
        OrderId = payment.Order.Id,
        OwnerId = owner.Id,
        Amount = payment.Order.OwnerAmount,
        Type = IncomeTypeEnum.Owner,
        Description = $"Venda do vídeo: {payment.Order.Video.Title}",
        CreatedAt = DateTime.UtcNow
    });
    
    // 3. Promoter (se houver)
    if (payment.Order.PromoterId.HasValue && payment.Order.PromoterAmount > 0)
    {
        incomes.Add(new Income
        {
            OrderId = payment.Order.Id,
            OwnerId = payment.Order.PromoterId.Value,
            Amount = payment.Order.PromoterAmount,
            Type = IncomeTypeEnum.Promoter,
            Description = $"Comissão por divulgação: {payment.Order.Video.Title}",
            CreatedAt = DateTime.UtcNow
        });
    }
    
    await _context.Incomes.AddRangeAsync(incomes);
    
    // Criar notificação
    var user = await _context.Users.FindAsync(payment.Order.UserId);
    
    var notification = new Notification
    {
        Type = NotificationTypeEnum.PaymentConfirmed,
        Channel = user.NotificationPreference ?? NotificationChannelEnum.Email,
        Email = user.Email,
        Phone = user.Telephone,
        MetadataJson = JsonSerializer.Serialize(new
        {
            OrderId = payment.Order.Id,
            VideoTitle = payment.Order.Video.Title,
            Amount = payment.Amount / 100m
        }),
        CreatedAt = DateTime.UtcNow
    };
    
    await _context.Notifications.AddAsync(notification);
    
    _logger.LogInformation("Payment {PaymentId} confirmed successfully", payment.Id);
}
```

## Idempotência

O webhook pode chegar **múltiplas vezes** para o mesmo evento. É crucial implementar idempotência:

```csharp
// Verificar se já foi processado
if (payment.Status == PaymentStatusEnum.Paid)
{
    _logger.LogInformation("Payment already processed");
    return Results.Ok(new { Received = true, AlreadyProcessed = true });
}
```

## Eventos Iugu

| Evento | Descrição | Ação |
|--------|-----------|------|
| `invoice.status_changed` (paid) | Pagamento confirmado | Confirmar payment, criar incomes |
| `invoice.status_changed` (canceled) | Pagamento cancelado | Atualizar status para Cancelled |
| `invoice.refunded` | Pagamento estornado | Atualizar status para Refunded |
| `invoice.payment_failed` | Falha no pagamento | Logar (opcional: notificar usuário) |

## Validação de Assinatura

**Importante**: SEMPRE validar a assinatura para garantir que o webhook veio realmente do Iugu.

```csharp
private bool ValidateSignature(string body, string signature, string secret)
{
    if (string.IsNullOrEmpty(signature))
        return false;
    
    var expectedHash = signature.Replace("sha256=", "");
    
    using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(secret));
    var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(body));
    var computedHash = BitConverter.ToString(hash).Replace("-", "").ToLower();
    
    return computedHash.Equals(expectedHash, StringComparison.OrdinalIgnoreCase);
}
```

## Configuração no Iugu

1. Acesse https://app.iugu.com/webhooks
2. Adicione URL: `https://seu-dominio.com/api/webhooks/iugu`
3. Selecione eventos: `invoice.status_changed`, `invoice.refunded`
4. Copie o **Webhook Secret** para `appsettings.json`:

```json
{
  "Iugu": {
    "ApiKey": "sua_api_key",
    "WebhookSecret": "seu_webhook_secret"
  }
}
```

## Logs

```csharp
_logger.LogInformation("Webhook received: {Event} for invoice {InvoiceId}", 
    webhook.Event, webhook.Data.Id);

_logger.LogWarning("Invalid webhook signature from IP {IP}", 
    request.HttpContext.Connection.RemoteIpAddress);

_logger.LogError(ex, "Error processing webhook for payment {PaymentId}", 
    payment.Id);
```

## Monitoramento

### Webhooks com Falha

```sql
SELECT 
    p.id,
    p.iugu_invoice_id,
    p.status,
    p.updated_at,
    EXTRACT(EPOCH FROM (NOW() - p.created_at))/3600 as hours_pending
FROM payments p
WHERE p.status = 'Pending'
  AND p.created_at < NOW() - INTERVAL '6 hours'
ORDER BY p.created_at;
```

### Reprocessar Manualmente

```csharp
// Criar endpoint admin para reprocessar
app.MapPost("/api/admin/payments/{id:long}/reprocess", async (
    long id,
    PaymentService service) =>
{
    var payment = await _context.Payments.FindAsync(id);
    
    if (payment == null)
        return Results.NotFound();
    
    // Buscar status no Iugu
    var invoice = await _iuguService.GetInvoiceAsync(payment.IuguInvoiceId);
    
    if (invoice.Status == "paid" && payment.Status != PaymentStatusEnum.Paid)
    {
        await service.ConfirmPaymentAsync(payment);
        await _context.SaveChangesAsync();
        
        return Results.Ok(new { message = "Payment reprocessed successfully" });
    }
    
    return Results.Ok(new { message = "No action needed" });
})
.RequireAuthorization("Admin");
```

## Teste Local com ngrok

Para testar webhooks localmente:

```bash
# Instalar ngrok
brew install ngrok

# Criar túnel
ngrok http 7080

# Usar URL gerada no Iugu
# https://abc123.ngrok.io/api/webhooks/iugu
```

## Próximos Passos

- [Orders](order.md) - Criar pedidos
- [Webhooks Iugu](../../../pagamentos/webhooks.md) - Detalhes completos
- [Split de Pagamento](../../../pagamentos/split-pagamento.md)

