# Requisitos do Sistema

## Visão Geral

Este documento lista todos os requisitos de software e hardware necessários para desenvolver e executar a plataforma Amasso localmente.

## Hardware Recomendado

### Mínimo
- **CPU**: Dual-core 2.0 GHz
- **RAM**: 8 GB
- **Disco**: 20 GB livres (SSD recomendado)
- **Conexão**: Internet estável (para APIs externas)

### Recomendado
- **CPU**: Quad-core 2.5 GHz ou superior
- **RAM**: 16 GB ou mais
- **Disco**: 50 GB livres em SSD
- **Conexão**: Internet de alta velocidade

## Sistema Operacional

A plataforma pode ser desenvolvida em qualquer sistema operacional:

- ✅ **Windows** 10/11
- ✅ **macOS** 12 (Monterey) ou superior
- ✅ **Linux** (Ubuntu 20.04+, Debian, Fedora, etc.)

## Software Necessário

### 1. .NET SDK 8.0

**Backend API** e **Email API** são construídos com .NET 8.

#### Instalação

**Windows/macOS**:
```bash
# Baixar e instalar de:
https://dotnet.microsoft.com/download/dotnet/8.0
```

**Linux (Ubuntu/Debian)**:
```bash
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y dotnet-sdk-8.0
```

#### Verificar Instalação

```bash
dotnet --version
# Esperado: 8.0.x
```

### 2. Node.js 18+ e npm

**Frontend** é construído com React + TypeScript + Vite.

#### Instalação

**Windows/macOS**:
```bash
# Baixar e instalar de:
https://nodejs.org/

# Ou usar nvm (Node Version Manager)
nvm install 18
nvm use 18
```

**Linux**:
```bash
# Usando nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 18
nvm use 18
```

#### Verificar Instalação

```bash
node --version
# Esperado: v18.x.x ou superior

npm --version
# Esperado: 9.x.x ou superior
```

### 3. PostgreSQL 16

Banco de dados relacional.

#### Instalação

**Windows**:
```bash
# Baixar installer de:
https://www.postgresql.org/download/windows/
```

**macOS**:
```bash
brew install postgresql@16
brew services start postgresql@16
```

**Linux (Ubuntu/Debian)**:
```bash
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get install postgresql-16
```

#### Verificar Instalação

```bash
psql --version
# Esperado: psql (PostgreSQL) 16.x
```

#### Configurar Banco de Dados

```bash
# Conectar como postgres
sudo -u postgres psql

# Criar database
CREATE DATABASE pay4tru;

# Criar usuário (opcional)
CREATE USER amasso_dev WITH PASSWORD 'senha123';
GRANT ALL PRIVILEGES ON DATABASE pay4tru TO amasso_dev;

# Sair
\q
```

### 4. Git

Controle de versão.

#### Instalação

**Windows**:
```bash
# Baixar de:
https://git-scm.com/download/win
```

**macOS**:
```bash
brew install git
```

**Linux**:
```bash
sudo apt-get install git
```

#### Verificar Instalação

```bash
git --version
# Esperado: git version 2.x.x
```

### 5. Docker (Opcional)

Para executar PostgreSQL em container.

#### Instalação

**Windows/macOS**:
```bash
# Baixar Docker Desktop de:
https://www.docker.com/products/docker-desktop
```

**Linux**:
```bash
# Instalar Docker Engine
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Instalar Docker Compose
sudo apt-get install docker-compose-plugin
```

#### Verificar Instalação

```bash
docker --version
# Esperado: Docker version 24.x.x

docker-compose --version
# Esperado: Docker Compose version v2.x.x
```

## IDEs e Editores Recomendados

### Para Backend (.NET)

**Visual Studio 2022** (Windows/macOS)
- ✅ IntelliSense completo
- ✅ Debugger integrado
- ✅ Ferramentas EF Core
- 🔗 https://visualstudio.microsoft.com/

**JetBrains Rider** (Multiplataforma)
- ✅ Excelente performance
- ✅ Refactoring avançado
- ✅ Integração Git
- 🔗 https://www.jetbrains.com/rider/

**Visual Studio Code** (Multiplataforma)
- ✅ Leve e rápido
- ✅ Extensão C# Dev Kit
- ✅ Debugger
- 🔗 https://code.visualstudio.com/

**Extensões VSCode para .NET**:
```
- C# Dev Kit (Microsoft)
- C# (Microsoft)
- NuGet Package Manager
- vscode-solution-explorer
```

### Para Frontend (React + TypeScript)

**Visual Studio Code** (Recomendado)
- ✅ Suporte TypeScript nativo
- ✅ IntelliSense para React
- ✅ Integração Vite

**Extensões VSCode para React**:
```
- ES7+ React/Redux/React-Native snippets
- ESLint
- Prettier - Code formatter
- Auto Rename Tag
- Tailwind CSS IntelliSense (se usar)
- TypeScript Vue Plugin (Volar)
```

**WebStorm** (JetBrains)
- ✅ IntelliSense poderoso
- ✅ Refactoring avançado
- 🔗 https://www.jetbrains.com/webstorm/

## Ferramentas de Desenvolvimento

### 1. Postman ou Insomnia

Testar APIs REST.

**Postman**:
```bash
# Download: https://www.postman.com/downloads/
```

**Insomnia**:
```bash
# Download: https://insomnia.rest/download
```

### 2. pgAdmin ou DBeaver

Gerenciar banco de dados PostgreSQL.

**pgAdmin**:
```bash
# Geralmente instalado com PostgreSQL
# Ou download: https://www.pgadmin.org/download/
```

**DBeaver** (Recomendado):
```bash
# Download: https://dbeaver.io/download/
# Suporta múltiplos bancos, gratuito, multiplataforma
```

### 3. Git Client (Opcional)

**GitKraken**:
```bash
# Download: https://www.gitkraken.com/
# Interface visual para Git
```

**SourceTree**:
```bash
# Download: https://www.sourcetreeapp.com/
# Gratuito da Atlassian
```

## Contas e Credenciais Necessárias

### Desenvolvimento Local

Para desenvolvimento local completo, você precisará de:

1. **Iugu (Sandbox)**
   - Criar conta gratuita: https://iugu.com
   - Obter API Token de teste
   - Configurar Webhook URL (usar ngrok)

2. **Cloudinary (Free Tier)**
   - Criar conta: https://cloudinary.com
   - Obter: Cloud Name, API Key, API Secret
   - Limite free: 25 GB armazenamento, 25 GB banda

3. **Z-API (WhatsApp) - Opcional**
   - Para testar notificações WhatsApp
   - Plano free disponível: https://www.z-api.io/

4. **AWS SES (Email) - Opcional**
   - Para envio de emails em dev
   - Alternativa: usar SMTP local (Mailpit, Mailtrap)

### Ferramentas de Teste Locais

**Mailpit** (Email local):
```bash
# Instalar
brew install mailpit  # macOS
# ou
docker run -d -p 1025:1025 -p 8025:8025 axllent/mailpit

# Configurar SMTP:
# Host: localhost
# Port: 1025
# Interface: http://localhost:8025
```

**ngrok** (Expor localhost):
```bash
# Instalar
brew install ngrok  # macOS
# ou
snap install ngrok  # Linux
# ou download: https://ngrok.com/download

# Usar
ngrok http 7080
# Copiar URL gerada e configurar no Iugu como Webhook URL
```

## Configurações do Sistema

### Variáveis de Ambiente

Criar arquivo `.env` ou configurar no sistema:

**Backend API**:
```env
ASPNETCORE_ENVIRONMENT=Development
DATABASE_LOCAL=true
DATABASE_URL=Host=localhost;Database=pay4tru;Username=postgres;Password=senha123
IUGU_API_TOKEN=seu_token_aqui
IUGU_MASTER_ACCOUNT_ID=seu_account_id
CLOUDINARY_CLOUD_NAME=seu_cloud_name
CLOUDINARY_API_KEY=seu_api_key
CLOUDINARY_API_SECRET=seu_api_secret
JWT_SECRET=super_secret_key_min_32_chars_here
```

**Frontend**:
```env
VITE_API_URL=http://localhost:7080
VITE_CLOUDINARY_CLOUD_NAME=seu_cloud_name
```

**Email API**:
```env
ASPNETCORE_ENVIRONMENT=Development
DATABASE_LOCAL=true
SMTP_HOST=localhost
SMTP_PORT=1025
SMTP_USER=
SMTP_PASS=
ZAPI_INSTANCE_ID=seu_instance_id
ZAPI_TOKEN=seu_token
```

### Portas Utilizadas

| Serviço | Porta | URL |
|---------|-------|-----|
| Backend API | 7080 | http://localhost:7080 |
| Email API | 5014 | http://localhost:5014 |
| Frontend | 5173 | http://localhost:5173 |
| PostgreSQL | 5432 | localhost:5432 |
| Mailpit UI | 8025 | http://localhost:8025 |
| Hangfire Dashboard | 5014/dashboard | http://localhost:5014/dashboard |

## Verificação Final

Execute estes comandos para verificar se tudo está instalado:

```bash
# .NET
dotnet --version

# Node.js
node --version
npm --version

# PostgreSQL
psql --version

# Git
git --version

# Docker (opcional)
docker --version
docker-compose --version

# Clone do repositório
git clone https://github.com/seu-usuario/amasso-monorepo.git
cd amasso-monorepo
```

## Próximos Passos

Agora que você tem todos os requisitos instalados:

1. Configure o [Backend](backend.md)
2. Configure o [Email API](email-api.md)
3. Configure o [Frontend](frontend.md)
4. Configure o [Banco de Dados](banco-dados.md)

## Problemas Comuns

### PostgreSQL não inicia

```bash
# macOS
brew services restart postgresql@16

# Linux
sudo systemctl restart postgresql

# Windows
# Services > PostgreSQL 16 > Restart
```

### Porta já em uso

```bash
# Verificar o que está usando a porta
# macOS/Linux
lsof -i :7080

# Windows
netstat -ano | findstr :7080

# Matar processo
kill -9 <PID>  # macOS/Linux
taskkill /PID <PID> /F  # Windows
```

### Migrations não aplicam

```bash
cd backend-api
dotnet ef database drop --force
dotnet ef database update
```

## Suporte

Se encontrar problemas:
1. Consulte a [documentação oficial](../..)
2. Verifique os logs da aplicação
3. Entre em contato com a equipe

