# Documentação Amasso

Documentação técnica completa da plataforma Amasso, construída com MkDocs e publicada automaticamente no GitHub Pages.

## 🚀 Visualizar Documentação

**Produção**: [https://seu-usuario.github.io/amasso-monorepo](https://seu-usuario.github.io/amasso-monorepo)

**Local**: Veja instruções abaixo para rodar localmente.

## 📚 O que está Documentado?

Esta documentação cobre todos os aspectos da plataforma Amasso:

### 🎯 Visão Geral
- Introdução à plataforma
- Conceitos principais (vídeos, comissões, KYC, split)
- Glossário completo de termos

### 🏗️ Arquitetura
- Visão geral dos 3 projetos (Backend API, Email API, Frontend)
- Detalhamento de cada componente
- Comunicação entre sistemas
- Diagramas de arquitetura

### 💳 Pagamentos Iugu
- Sistema de conta master e subcontas
- Processo KYC completo
- Split de pagamento automático
- Webhooks e integrações

### 🗄️ Banco de Dados
- PostgreSQL 16 - visão geral
- Modelo Entidade-Relacionamento completo
- Documentação de todas as 17 tabelas
- Relacionamentos e queries

### 👥 Perfis de Usuário
- Admin (gerenciamento total)
- Default (comprador de vídeos)
- Promoter (links de afiliado)
- Influencer (criador de conteúdo)

### 🔄 Fluxos de Negócio
- Autenticação e MFA
- Cadastro de usuários
- Processo KYC
- Compra de vídeos com split
- Links de afiliado
- Sistema de comissões

### 🔌 APIs
- Backend API - endpoints completos
- Email API - notificações
- Autenticação JWT
- Exemplos de requests/responses

### 📚 Guias
- Configuração de ambiente
- Desenvolvimento (padrões, estrutura)
- Como adicionar endpoints e entidades
- Criar migrations

### 📋 Casos de Uso
- Compra de vídeo (fluxo completo com código)
- Geração de link de afiliado
- Aprovação de KYC
- Recebimento de comissões
- Gestão administrativa

## 🛠️ Executar Localmente

### Pré-requisitos

```bash
# Python 3.x
python --version

# pip
pip --version
```

### Instalação

```bash
# 1. Entrar no diretório da documentação
cd documentation

# 2. Instalar dependências
pip install -r requirements.txt

# Ou instalar manualmente:
pip install mkdocs-material
pip install mkdocs-mermaid2-plugin
pip install mkdocs-git-revision-date-localized-plugin
```

### Rodar Servidor Local

```bash
# Iniciar servidor de desenvolvimento
mkdocs serve

# Acessar em:
# http://127.0.0.1:8000
```

O servidor recarrega automaticamente quando você edita os arquivos `.md`.

### Build para Produção

```bash
# Gerar site estático
mkdocs build

# Arquivos gerados em: documentation/site/
```

## 📝 Estrutura de Arquivos

```
documentation/
├── mkdocs.yml              # Configuração do MkDocs
├── requirements.txt        # Dependências Python
├── README.md              # Este arquivo
├── docs/                  # Arquivos markdown
│   ├── index.md          # Página inicial
│   ├── visao-geral/
│   │   ├── introducao.md
│   │   ├── conceitos-principais.md
│   │   └── glossario.md
│   ├── arquitetura/
│   │   ├── visao-geral.md
│   │   ├── backend-api.md
│   │   ├── email-api.md
│   │   ├── frontend.md
│   │   └── comunicacao-entre-sistemas.md
│   ├── pagamentos/
│   │   ├── visao-geral-iugu.md
│   │   ├── conta-master-subcontas.md
│   │   ├── processo-kyc.md
│   │   ├── split-pagamento.md
│   │   └── webhooks.md
│   ├── banco-de-dados/
│   │   ├── visao-geral.md
│   │   ├── modelo-entidade-relacionamento.md
│   │   ├── tabelas/
│   │   └── relacionamentos.md
│   ├── perfis-de-usuario/
│   │   ├── admin.md
│   │   ├── default.md
│   │   ├── promoter.md
│   │   └── influencer.md
│   ├── fluxos-de-negocio/
│   ├── apis/
│   ├── guias/
│   └── casos-de-uso/
└── site/                  # Gerado pelo build (não versionar)
```

## ✍️ Contribuir com a Documentação

### Adicionar Nova Página

1. Criar arquivo `.md` em `docs/` na pasta apropriada
2. Adicionar ao `nav` em `mkdocs.yml`
3. Usar formato Markdown + Mermaid para diagramas

### Exemplo de Página

```markdown
# Título da Página

## Introdução

Texto explicativo...

## Diagrama

\```mermaid
graph TD
    A[Início] --> B[Fim]
\```

## Código

\```csharp
public class Example 
{
    public int Id { get; set; }
}
\```
```

### Mermaid para Diagramas

A documentação suporta diagramas Mermaid:

- **Flowcharts**: Fluxogramas
- **Sequence Diagrams**: Diagramas de sequência
- **ER Diagrams**: Modelo entidade-relacionamento
- **State Diagrams**: Diagramas de estado
- **Class Diagrams**: Diagramas de classe

Veja exemplos em: https://mermaid.js.org/intro/

### Testar Localmente

Sempre teste suas alterações localmente antes de comitar:

```bash
mkdocs serve
# Verifique em http://127.0.0.1:8000
```

## 🚀 Deploy Automático

O deploy é automático via GitHub Actions:

1. Edite arquivos em `documentation/docs/`
2. Commit e push para `main`
3. GitHub Actions detecta mudanças em `documentation/**`
4. Executa build do MkDocs
5. Publica no GitHub Pages automaticamente

**Workflow**: `.github/workflows/docs.yml`

## 📦 Dependências

| Pacote | Versão | Uso |
|--------|--------|-----|
| mkdocs-material | >=9.0.0 | Tema Material Design |
| mkdocs-mermaid2-plugin | >=1.0.0 | Suporte a diagramas Mermaid |
| mkdocs-git-revision-date-localized-plugin | >=1.2.0 | Datas de atualização |

## 🎨 Tema e Customização

**Tema**: Material for MkDocs com customizações:
- **Cores**: Pink (primary e accent)
- **Idioma**: pt-BR
- **Features**: Tabs, sections, search, code copy
- **Markdown Extensions**: Highlight, superfences, tables, TOC

## 🔍 Busca

A documentação inclui busca integrada (plugin `search`):
- Digite qualquer termo no campo de busca
- Resultados instantâneos
- Highlighting automático

## 📱 Responsiva

A documentação é totalmente responsiva:
- ✅ Desktop
- ✅ Tablet
- ✅ Mobile

## 🐛 Problemas Conhecidos

### Build Falha

```bash
# Limpar cache
rm -rf site/

# Rebuild
mkdocs build --clean
```

### Plugin Não Encontrado

```bash
# Reinstalar dependências
pip install -r requirements.txt --force-reinstall
```

## 📞 Suporte

- **Issues**: Abrir issue no repositório
- **Pull Requests**: Sempre bem-vindos!
- **Dúvidas**: Contatar equipe técnica

## 📄 Licença

Mesma licença do projeto principal.

---

**Última atualização**: Gerada automaticamente pelo git-revision-date-localized-plugin
