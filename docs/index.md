# Documentação Amasso

Bem-vindo à documentação técnica completa da plataforma **Amasso** - uma plataforma de vídeos com sistema de afiliados e comissionamento automatizado.

## O que é o Amasso?

O Amasso é uma plataforma inovadora que permite:

- **Venda de vídeos exclusivos** por criadores de conteúdo
- **Sistema de afiliados** onde promoters ganham comissão por vendas
- **Comissionamento automático** para influencers que participam dos vídeos
- **Pagamentos seguros** via Iugu com split automático
- **Gestão de KYC** para compliance financeiro

## Stack Tecnológico

| Componente | Tecnologia |
|------------|------------|
| **Backend API** | .NET 8, Entity Framework Core, PostgreSQL |
| **Email API** | .NET 8, Hangfire, SMTP, Z-API WhatsApp |
| **Frontend** | React 18, TypeScript, Redux Toolkit |
| **Banco de Dados** | PostgreSQL 16 |
| **Gateway de Pagamento** | Iugu (Conta Master + Subcontas) |
| **CDN de Vídeos** | Cloudinary |

## Quick Start

### Para Desenvolvedores

1. **Clone o repositório**
   ```bash
   git clone https://github.com/seu-usuario/amasso-monorepo.git
   cd amasso-monorepo
   ```

2. **Configure o Backend**
   ```bash
   cd backend-api
   dotnet restore
   dotnet ef database update
   dotnet run
   ```

3. **Configure o Frontend**
   ```bash
   cd frontend-react
   npm install
   npm run dev
   ```

4. **Configure o Email API**
   ```bash
   cd email-api
   dotnet restore
   dotnet run
   ```

Consulte a seção [Guias > Configuração do Ambiente](guias/configuracao-ambiente/requisitos.md) para instruções detalhadas.

## Navegação da Documentação

### 🎯 [Visão Geral](visao-geral/introducao.md)
Entenda o propósito da plataforma, conceitos principais e glossário de termos.

### 🏗️ [Arquitetura](arquitetura/visao-geral.md)
Explore a arquitetura dos três projetos e como eles se comunicam.

### 💳 [Pagamentos Iugu](pagamentos/visao-geral-iugu.md)
Aprenda sobre o sistema de conta master/subcontas, KYC e split de pagamento.

### 🗄️ [Banco de Dados](banco-de-dados/visao-geral.md)
Consulte o modelo ER completo e documentação de todas as tabelas.

### 👥 [Perfis de Usuário](perfis-de-usuario/admin.md)
Entenda os 4 perfis: Admin, Default, Promoter e Influencer.

### 🔄 [Fluxos de Negócio](fluxos-de-negocio/autenticacao.md)
Veja os fluxos completos: autenticação, compra, KYC, comissões e mais.

### 🔌 [APIs](apis/backend-api/visao-geral.md)
Referência completa dos endpoints do Backend API e Email API.

### 📚 [Guias](guias/configuracao-ambiente/requisitos.md)
Tutoriais passo a passo para setup, desenvolvimento e boas práticas.

### 📋 [Casos de Uso](casos-de-uso/usuario-compra-video.md)
Jornadas completas com código de exemplo para cada cenário.

## Principais Funcionalidades

### Sistema de Vídeos
- Upload e armazenamento via Cloudinary
- Trailers públicos e conteúdo premium pago
- Configuração de preços e promoções
- Agendamento de lançamentos

### Sistema de Comissões
- Configuração por vídeo (admin define %)
- Vídeos com 0% para promoter não aparecem para links
- Split automático no pagamento
- Relatórios de income por perfil

### Sistema de Afiliados
- Links únicos por promoter
- Rastreamento de conversões
- Comissão automática nas vendas
- Dashboard com métricas

### Sistema de Pagamentos
- Integração completa com Iugu
- Conta master (plataforma) + subcontas (promoters/influencers)
- Split automático no momento do pagamento
- Webhooks para confirmação

### KYC e Compliance
- Processo de aprovação para promoters e influencers
- Validação de documentos pelo admin
- Criação de subcontas Iugu após aprovação
- Status: Pendente, Aprovado, Rejeitado

## Contribuindo

Esta documentação é mantida em conjunto com o código. Para contribuir:

1. Edite os arquivos markdown em `documentation/docs/`
2. Teste localmente: `mkdocs serve`
3. Commit e push - o GitHub Actions fará o deploy automático

## Suporte

Para dúvidas sobre a plataforma ou esta documentação:

- Abra uma issue no repositório
- Entre em contato com a equipe técnica
- Consulte os casos de uso para exemplos práticos

---

**Última atualização**: Esta documentação é automaticamente atualizada via Git.

