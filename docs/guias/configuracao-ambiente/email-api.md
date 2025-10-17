# Configuração: Email API

## Requisitos

- .NET SDK 8.0+
- PostgreSQL 16+ (compartilhado com Backend API)
- Conta SMTP (Gmail, SendGrid, etc.)
- Conta Z-API (para WhatsApp)

## Passo a Passo

### 1. Navegar para o Diretório

```bash
cd amasso-monorepo/email-api
```

### 2. Configurar appsettings.json

Crie `appsettings.Development.json`:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=pay4tru;Username=postgres;Password=postgres"
  },
  "Smtp": {
    "Host": "smtp.gmail.com",
    "Port": 587,
    "Username": "noreply@amasso.com.br",
    "Password": "app-password-aqui",
    "FromEmail": "noreply@amasso.com.br",
    "FromName": "Amasso",
    "EnableSsl": true
  },
  "ZApi": {
    "BaseUrl": "https://api.z-api.io",
    "InstanceId": "your-instance-id",
    "Token": "your-token"
  },
  "Hangfire": {
    "DashboardPath": "/dashboard",
    "DashboardUsername": "admin",
    "DashboardPassword": "admin123"
  }
}
```

### 3. Instalar Dependências

```bash
dotnet restore
```

### 4. Executar Aplicação

```bash
dotnet run
```

A API estará disponível em:
- HTTP: `http://localhost:5014`
- Dashboard Hangfire: `http://localhost:5014/dashboard`

### 5. Testar Dashboard

Acesse `http://localhost:5014/dashboard` e faça login com as credenciais configuradas.

## Configuração SMTP Gmail

### 1. Habilitar "Verificação em duas etapas"

1. Acesse https://myaccount.google.com/security
2. Ative "Verificação em duas etapas"

### 2. Criar App Password

1. Acesse https://myaccount.google.com/apppasswords
2. Crie uma nova senha de app
3. Use esta senha no `appsettings.json`

```json
{
  "Smtp": {
    "Host": "smtp.gmail.com",
    "Port": 587,
    "Username": "seu-email@gmail.com",
    "Password": "senha-de-app-gerada",
    "FromEmail": "seu-email@gmail.com",
    "FromName": "Amasso"
  }
}
```

## Configuração Z-API

### 1. Criar Conta

1. Acesse https://www.z-api.io/
2. Crie uma conta e instância

### 2. Conectar WhatsApp

1. Escaneie o QR Code
2. Copie Instance ID e Token

```json
{
  "ZApi": {
    "BaseUrl": "https://api.z-api.io",
    "InstanceId": "3DABC123",
    "Token": "A1B2C3D4E5F6"
  }
}
```

## Jobs Hangfire

### Jobs Configurados

| Job | Frequência | Descrição |
|-----|------------|-----------|
| `process-pending-notifications` | 1 min | Processa notificações pendentes |
| `cleanup-old-notifications` | Diário 03:00 | Remove notificações antigas |

### Monitoramento

Dashboard Hangfire mostra:
- Jobs executados com sucesso
- Jobs com falha
- Jobs agendados
- Servidores ativos
- Fila de processamento

## Testar Envio

### 1. Criar Notificação Manualmente

```sql
INSERT INTO notifications (type, channel, email, metadata_json, created_at)
VALUES (
    'UserActivation',
    'Email',
    'teste@example.com',
    '{"Code": "123456"}',
    NOW()
);
```

### 2. Aguardar Processamento

O job executará em até 1 minuto e:
- Renderizará template
- Enviará email
- Marcará como enviado

### 3. Verificar Logs

```bash
tail -f email-api.log
```

## Troubleshooting

### Email não envia

**Verificar SMTP:**
```bash
telnet smtp.gmail.com 587
```

**Verificar senha:**
- Gmail requer "App Password"
- Não use senha normal da conta

### WhatsApp não envia

**Verificar conexão:**
- Acesse dashboard Z-API
- Verifique se instância está conectada
- Reescanear QR Code se necessário

### Jobs não executam

**Verificar Hangfire:**
- Acesse `/dashboard`
- Veja guia "Servers"
- Verificar se há servidor ativo

## Logs

```bash
# Ver logs em tempo real
tail -f email-api.log

# Buscar erros
grep ERROR email-api.log

# Últimas 100 linhas
tail -n 100 email-api.log
```

## Próximos Passos

- [Configurar Backend](backend.md)
- [Templates de Email](../../apis/email-api/templates.md)
- [Hangfire Jobs](../../apis/email-api/hangfire-jobs.md)

