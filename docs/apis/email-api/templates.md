# Templates de Notificação

## Descrição

Templates para renderização de emails (HTML) e mensagens WhatsApp (TXT) utilizando variáveis dinâmicas do `metadata_json`.

## Localização

```
email-api/
└── wwwroot/
    └── Templates/
        ├── Email/
        │   ├── MfaCode.html
        │   ├── UserActivation.html
        │   ├── ForgotPassword.html
        │   ├── PaymentConfirmed.html
        │   ├── VideoReleaseSchedule.html
        │   ├── KycApproved.html
        │   ├── KycRejected.html
        │   └── NewSale.html
        └── WhatsApp/
            ├── MfaCode.txt
            ├── UserActivation.txt
            ├── ForgotPassword.txt
            ├── PaymentConfirmed.txt
            ├── VideoReleaseSchedule.txt
            ├── KycApproved.txt
            ├── KycRejected.txt
            └── NewSale.txt
```

## Templates HTML (Email)

### MfaCode.html

```html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Código MFA - Amasso</title>
</head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
    <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
        <h1 style="color: white; margin: 0;">Código de Autenticação</h1>
    </div>
    
    <div style="background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px;">
        <p>Olá,</p>
        <p>Seu código de autenticação MFA é:</p>
        
        <div style="background: white; padding: 20px; text-align: center; border: 2px dashed #667eea; border-radius: 5px; margin: 20px 0;">
            <h2 style="color: #667eea; font-size: 36px; letter-spacing: 8px; margin: 0;">{{Code}}</h2>
        </div>
        
        <p style="color: #666; font-size: 14px;">
            <strong>⏰ Este código expira em {{ExpiresIn}} minutos.</strong>
        </p>
        
        <p>Se você não solicitou este código, ignore este email.</p>
        
        <hr style="border: none; border-top: 1px solid #ddd; margin: 30px 0;">
        
        <p style="color: #999; font-size: 12px; text-align: center;">
            Amasso - Plataforma de Vídeos Exclusivos<br>
            Este é um email automático, não responda.
        </p>
    </div>
</body>
</html>
```

### PaymentConfirmed.html

```html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <title>Pagamento Confirmado - Amasso</title>
</head>
<body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
    <div style="background: #4caf50; padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
        <h1 style="color: white; margin: 0;">✓ Pagamento Confirmado!</h1>
    </div>
    
    <div style="background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px;">
        <p>Olá <strong>{{UserName}}</strong>,</p>
        
        <p>Seu pagamento foi confirmado com sucesso! 🎉</p>
        
        <div style="background: white; padding: 20px; border-left: 4px solid #4caf50; margin: 20px 0;">
            <h3 style="margin-top: 0;">Detalhes da Compra</h3>
            <p><strong>Vídeo:</strong> {{VideoTitle}}</p>
            <p><strong>Valor:</strong> R$ {{Amount}}</p>
            <p><strong>Pedido:</strong> #{{OrderId}}</p>
        </div>
        
        <p>Você já pode assistir ao vídeo! Acesse sua área de vídeos comprados:</p>
        
        <div style="text-align: center; margin: 30px 0;">
            <a href="{{AppUrl}}/my-videos" style="background: #4caf50; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;">
                Ver Meus Vídeos
            </a>
        </div>
        
        <p>Obrigado por sua compra!</p>
        
        <hr style="border: none; border-top: 1px solid #ddd; margin: 30px 0;">
        
        <p style="color: #999; font-size: 12px; text-align: center;">
            Amasso - Plataforma de Vídeos Exclusivos
        </p>
    </div>
</body>
</html>
```

### KycRejected.html

```html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <title>KYC Rejeitado - Amasso</title>
</head>
<body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
    <div style="background: #f44336; padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
        <h1 style="color: white; margin: 0;">❌ Documentos Rejeitados</h1>
    </div>
    
    <div style="background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px;">
        <p>Olá,</p>
        
        <p>Infelizmente seus documentos KYC foram rejeitados.</p>
        
        <div style="background: #fff3cd; padding: 15px; border-left: 4px solid #ff9800; margin: 20px 0;">
            <p style="margin: 0;"><strong>Motivo da rejeição:</strong></p>
            <p style="margin: 10px 0 0 0;">{{Reason}}</p>
        </div>
        
        <p>Por favor, revise os documentos e envie novamente:</p>
        
        <div style="text-align: center; margin: 30px 0;">
            <a href="{{AppUrl}}/owner/kyc" style="background: #667eea; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;">
                Reenviar Documentos
            </a>
        </div>
        
        <p>Se tiver dúvidas, entre em contato conosco.</p>
        
        <hr style="border: none; border-top: 1px solid #ddd; margin: 30px 0;">
        
        <p style="color: #999; font-size: 12px; text-align: center;">
            Amasso - Plataforma de Vídeos Exclusivos
        </p>
    </div>
</body>
</html>
```

## Templates TXT (WhatsApp)

### MfaCode.txt

```
🔐 *Código MFA - Amasso*

Seu código de autenticação é:

*{{Code}}*

⏰ Expira em {{ExpiresIn}} minutos.

Se você não solicitou, ignore esta mensagem.
```

### PaymentConfirmed.txt

```
✅ *Pagamento Confirmado!*

Olá {{UserName}},

Seu pagamento foi confirmado! 🎉

📹 *Vídeo:* {{VideoTitle}}
💰 *Valor:* R$ {{Amount}}
🆔 *Pedido:* #{{OrderId}}

Acesse agora: {{AppUrl}}/my-videos

Obrigado pela compra!

_Amasso - Plataforma de Vídeos Exclusivos_
```

### NewSale.txt

```
💰 *Nova Venda!*

Parabéns! Você recebeu uma nova comissão:

📹 *Vídeo:* {{VideoTitle}}
👤 *Comprador:* {{BuyerName}}
💵 *Sua comissão:* R$ {{Commission}}

Acesse seu dashboard: {{AppUrl}}/dashboard

_Amasso - Plataforma de Vídeos Exclusivos_
```

## Variáveis Disponíveis

| Variável | Descrição | Exemplo |
|----------|-----------|---------|
| `{{Code}}` | Código numérico | 123456 |
| `{{UserName}}` | Nome do usuário | João Silva |
| `{{VideoTitle}}` | Título do vídeo | Vídeo Exclusivo |
| `{{Amount}}` | Valor em reais | 99.90 |
| `{{OrderId}}` | ID do pedido | 789 |
| `{{Commission}}` | Comissão | 29.97 |
| `{{BuyerName}}` | Nome do comprador | Maria Santos |
| `{{Reason}}` | Motivo (rejeição) | Documentos ilegíveis |
| `{{ExpiresIn}}` | Tempo de expiração | 5 |
| `{{AppUrl}}` | URL da aplicação | https://amasso.com.br |

## Renderização de Templates

```csharp
// email-api/Services/TemplateRenderer.cs
public class TemplateRenderer
{
    private readonly IWebHostEnvironment _env;
    private readonly IConfiguration _config;
    
    public async Task<string> RenderAsync(Notification notification)
    {
        var folderName = notification.Channel == NotificationChannelEnum.Email 
            ? "Email" 
            : "WhatsApp";
        
        var extension = notification.Channel == NotificationChannelEnum.Email 
            ? "html" 
            : "txt";
        
        var templatePath = Path.Combine(
            _env.WebRootPath, 
            "Templates", 
            folderName,
            $"{notification.Type}.{extension}"
        );
        
        if (!File.Exists(templatePath))
        {
            throw new FileNotFoundException($"Template not found: {templatePath}");
        }
        
        var template = await File.ReadAllTextAsync(templatePath);
        
        // Adicionar AppUrl
        var metadata = JsonSerializer.Deserialize<Dictionary<string, object>>(
            notification.MetadataJson ?? "{}");
        
        metadata["AppUrl"] = _config["App:BaseUrl"];
        
        // Substituir variáveis
        foreach (var kvp in metadata)
        {
            var value = kvp.Value?.ToString() ?? "";
            template = template.Replace($"{{{{{kvp.Key}}}}}", value);
        }
        
        return template;
    }
}
```

## EmailSender

```csharp
// email-api/Services/EmailSender.cs
public class EmailSender
{
    private readonly SmtpClient _smtpClient;
    private readonly TemplateRenderer _renderer;
    private readonly IConfiguration _config;
    
    public async Task SendAsync(Notification notification)
    {
        var html = await _renderer.RenderAsync(notification);
        
        var message = new MailMessage
        {
            From = new MailAddress(
                _config["Smtp:FromEmail"], 
                _config["Smtp:FromName"]
            ),
            Subject = GetSubject(notification.Type),
            Body = html,
            IsBodyHtml = true
        };
        
        message.To.Add(notification.Email);
        
        await _smtpClient.SendMailAsync(message);
    }
    
    private string GetSubject(NotificationTypeEnum type)
    {
        return type switch
        {
            NotificationTypeEnum.MfaCode => "Código de Autenticação - Amasso",
            NotificationTypeEnum.UserActivation => "Ative sua conta - Amasso",
            NotificationTypeEnum.ForgotPassword => "Recuperar senha - Amasso",
            NotificationTypeEnum.PaymentConfirmed => "Pagamento Confirmado - Amasso",
            NotificationTypeEnum.VideoReleaseSchedule => "Novo vídeo chegando! - Amasso",
            NotificationTypeEnum.KycApproved => "KYC Aprovado - Amasso",
            NotificationTypeEnum.KycRejected => "KYC Rejeitado - Amasso",
            NotificationTypeEnum.NewSale => "Nova Venda! - Amasso",
            _ => "Notificação - Amasso"
        };
    }
}
```

## WhatsAppSender

```csharp
// email-api/Services/WhatsAppSender.cs
public class WhatsAppSender
{
    private readonly HttpClient _httpClient;
    private readonly TemplateRenderer _renderer;
    private readonly IConfiguration _config;
    
    public async Task SendAsync(Notification notification)
    {
        var text = await _renderer.RenderAsync(notification);
        
        var instanceId = _config["ZApi:InstanceId"];
        var token = _config["ZApi:Token"];
        var url = $"{_config["ZApi:BaseUrl"]}/instances/{instanceId}/token/{token}/send-text";
        
        var payload = new
        {
            phone = notification.Phone.Replace("+", ""),
            message = text
        };
        
        var response = await _httpClient.PostAsJsonAsync(url, payload);
        response.EnsureSuccessStatusCode();
    }
}
```

## Como Criar Novo Template

1. **Criar arquivo HTML/TXT**:
```bash
# Email
touch email-api/wwwroot/Templates/Email/NovoTipo.html

# WhatsApp
touch email-api/wwwroot/Templates/WhatsApp/NovoTipo.txt
```

2. **Adicionar variáveis** com `{{NomeVariavel}}`

3. **Adicionar tipo ao enum**:
```csharp
public enum NotificationTypeEnum
{
    // ... existentes
    NovoTipo
}
```

4. **Criar notificação** com metadata:
```csharp
var notification = new Notification
{
    Type = NotificationTypeEnum.NovoTipo,
    Channel = NotificationChannelEnum.Email,
    Email = "user@example.com",
    MetadataJson = JsonSerializer.Serialize(new
    {
        NomeVariavel = "valor"
    }),
    CreatedAt = DateTime.UtcNow
};
```

## Próximos Passos

- [Notificações](notificacoes.md) - Sistema de notificações
- [Hangfire Jobs](hangfire-jobs.md) - Processamento assíncrono
- [Visão Geral](visao-geral.md) - Arquitetura Email API

