# Glossário

## A

### Admin
Administrador da plataforma com acesso total ao sistema. Responsável por aprovar KYC, configurar vídeos e gerenciar usuários.

### Afiliado
Sinônimo de Promoter. Usuário que divulga vídeos através de links rastreáveis e recebe comissão por vendas.

### API
Application Programming Interface. Interface de comunicação entre sistemas.

## C

### Cloudinary
Serviço de CDN (Content Delivery Network) usado para armazenar e distribuir vídeos da plataforma.

### Comissão
Percentual do valor da venda destinado a um beneficiário (plataforma, owner, promoter).

### Conta Master
Conta principal do Iugu pertencente à plataforma Amasso. Recebe todos os pagamentos e distribui para subcontas.

### CPF
Cadastro de Pessoa Física. Documento brasileiro de identificação exigido no processo de KYC.

## D

### Dashboard
Painel de controle com métricas e informações relevantes para cada perfil de usuário.

### Default
Perfil de usuário padrão que compra vídeos para assistir. Não recebe comissões e não precisa de KYC.

### DTO
Data Transfer Object. Objeto usado para transferir dados entre camadas da aplicação.

## E

### Entity Framework Core
ORM (Object-Relational Mapper) usado no backend para interagir com o banco de dados PostgreSQL.

### Endpoint
URL específica de uma API que responde a requisições HTTP.

## F

### Frontend
Aplicação React + TypeScript que roda no navegador do usuário.

## H

### Hangfire
Framework .NET para processamento de jobs em background, usado na Email API para enviar notificações.

## I

### Income
Registro de renda/comissão recebida por um beneficiário (plataforma, owner ou promoter).

### Influencer
Criador de conteúdo que participa dos vídeos. Recebe comissão quando seus vídeos são vendidos. Precisa de KYC aprovado.

### Iugu
Gateway de pagamento brasileiro usado pela plataforma. Oferece sistema de conta master e subcontas com split automático.

## J

### JWT
JSON Web Token. Formato de token usado para autenticação na API.

## K

### KYC
Know Your Customer (Conheça Seu Cliente). Processo de verificação de identidade exigido para usuários que recebem dinheiro (Promoters e Influencers).

## M

### MFA
Multi-Factor Authentication (Autenticação em Múltiplos Fatores). Sistema de segurança que requer código adicional além da senha.

### Migration
Arquivo que descreve mudanças na estrutura do banco de dados. Usado pelo Entity Framework para versionar o schema.

## N

### Notification
Notificação enviada ao usuário via email ou WhatsApp.

### Npgsql
Driver .NET para conexão com banco de dados PostgreSQL.

## O

### Order
Pedido de compra de um vídeo. Contém informações do usuário, vídeo, valores e promoter (se houver).

### Owner
Termo genérico para usuários que possuem dados adicionais: Promoters, Influencers, Partners, Agents. Tabela que armazena dados de KYC e subconta Iugu.

### OwnerVideo
Relacionamento entre Owner (Influencer) e Video. Indica quais influencers participam de quais vídeos.

## P

### Payment
Pagamento de um pedido. Contém status, ID da fatura Iugu e dados do webhook.

### PostgreSQL
Sistema de gerenciamento de banco de dados relacional usado pela plataforma.

### Promoter
Usuário que divulga vídeos através de links de afiliado e recebe comissão por vendas. Precisa de KYC aprovado. **Só vê vídeos com comissão configurada > 0%**.

## R

### Redux Toolkit
Biblioteca de gerenciamento de estado global usada no frontend React.

### Revenue
Receita ou renda gerada por vendas de vídeos.

## S

### SMTP
Simple Mail Transfer Protocol. Protocolo usado para envio de emails.

### Split de Pagamento
Divisão automática do valor de uma venda entre múltiplos beneficiários no momento da transação.

### Subconta
Conta secundária vinculada à conta master no Iugu. Criada para Promoters e Influencers após aprovação do KYC.

## T

### Trailer
Prévia gratuita de um vídeo, disponível publicamente para divulgação.

### TypeScript
Linguagem de programação usada no frontend. Superconjunto do JavaScript com tipagem estática.

## U

### User
Entidade que representa todos os usuários da plataforma. Tipos: Admin, Default, Promoter, Influencer.

## V

### VideoAffiliateLink
Link único gerado por um promoter para divulgar um vídeo específico.

### VideoRevenueConfig
Configuração que define os percentuais de comissão para cada vídeo:
- % Plataforma
- % Owner
- % Promoter (se 0%, vídeo não aparece para geração de links)

### VideoTrailer
Vídeo de prévia/trailer associado a um vídeo principal.

## W

### Webhook
Mecanismo de notificação automática. O Iugu envia webhooks para informar mudanças de status de pagamento.

### WhatsApp
Canal de notificação adicional ao email. Integração via Z-API.

## Z

### Z-API
Serviço de integração com WhatsApp usado para enviar notificações.

## Siglas Técnicas

| Sigla | Significado | Descrição |
|-------|-------------|-----------|
| API | Application Programming Interface | Interface de comunicação entre sistemas |
| CDN | Content Delivery Network | Rede de distribuição de conteúdo |
| CORS | Cross-Origin Resource Sharing | Mecanismo de segurança HTTP |
| DTO | Data Transfer Object | Objeto de transferência de dados |
| EF Core | Entity Framework Core | ORM para .NET |
| ER | Entity-Relationship | Modelo Entidade-Relacionamento |
| HTTP | HyperText Transfer Protocol | Protocolo de comunicação web |
| JWT | JSON Web Token | Padrão de token de autenticação |
| KYC | Know Your Customer | Verificação de identidade |
| MFA | Multi-Factor Authentication | Autenticação em múltiplos fatores |
| ORM | Object-Relational Mapper | Mapeador objeto-relacional |
| SMTP | Simple Mail Transfer Protocol | Protocolo de envio de email |
| UI | User Interface | Interface do usuário |
| UX | User Experience | Experiência do usuário |

## Termos de Negócio

### Conversão
Quando um clique em um link de afiliado resulta em uma venda.

### Comissionamento
Processo de calcular e distribuir comissões aos beneficiários.

### Compliance
Conformidade com leis e regulamentações, especialmente financeiras (KYC).

### Marketplace
Modelo de negócio onde a plataforma conecta vendedores (creators) e compradores.

### Monetização
Geração de receita a partir de conteúdo.

### Split
Divisão de um pagamento entre múltiplas partes.

## Próximos Passos

- Volte à [Introdução](introducao.md) para visão geral
- Explore os [Conceitos Principais](conceitos-principais.md) em detalhes
- Veja a [Arquitetura](../arquitetura/visao-geral.md) do sistema

