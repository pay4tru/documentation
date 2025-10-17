# Configuração: Frontend React

## Requisitos

- Node.js 18+ e npm
- Backend API rodando

## Passo a Passo

### 1. Navegar para o Diretório

```bash
cd amasso-monorepo/frontend-react
```

### 2. Instalar Dependências

```bash
npm install
```

### 3. Configurar Variáveis de Ambiente

Crie `.env`:

```env
VITE_API_URL=http://localhost:7080
VITE_CLOUDINARY_CLOUD_NAME=seu_cloud_name
```

### 4. Executar em Desenvolvimento

```bash
npm run dev
```

O frontend estará disponível em:
- `http://localhost:5173`

### 5. Build para Produção

```bash
npm run build
```

Os arquivos estarão em `dist/`.

### 6. Preview da Build

```bash
npm run preview
```

## Estrutura de Pastas

```
frontend-react/
├── src/
│   ├── assets/          # Imagens, fontes
│   ├── components/      # Componentes reutilizáveis
│   ├── pages/          # Páginas/rotas
│   ├── services/       # APIs e utilitários
│   │   ├── api/       # Chamadas HTTP
│   │   └── httpClient.ts
│   ├── store/         # Redux Toolkit
│   │   └── slices/
│   ├── styles/        # CSS/SCSS global
│   ├── types/         # TypeScript types
│   ├── App.tsx        # Componente raiz
│   └── main.tsx       # Entry point
├── public/            # Assets estáticos
├── index.html
├── vite.config.ts
└── package.json
```

## Scripts Disponíveis

| Script | Descrição |
|--------|-----------|
| `npm run dev` | Desenvolvimento com hot reload |
| `npm run build` | Build de produção |
| `npm run preview` | Preview da build |
| `npm run lint` | Executar ESLint |
| `npm run type-check` | Verificar tipos TypeScript |

## Configuração do Vite

```typescript
// vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:7080',
        changeOrigin: true,
      },
    },
  },
})
```

## Principais Bibliotecas

| Biblioteca | Versão | Uso |
|------------|--------|-----|
| React | ^18.2.0 | Framework UI |
| TypeScript | ^5.0.0 | Tipagem |
| Redux Toolkit | ^2.0.0 | State management |
| React Router | ^6.20.0 | Rotas |
| Axios | ^1.6.0 | HTTP client |
| React Query | ^5.0.0 | Cache de dados |
| React Hook Form | ^7.48.0 | Formulários |
| Zod | ^3.22.0 | Validação |
| Tailwind CSS | ^3.3.0 | Estilização |
| Lucide React | ^0.292.0 | Ícones |

## HTTP Client

```typescript
// src/services/httpClient.ts
import axios from 'axios'

export const httpClient = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
})

// Interceptor para adicionar token
httpClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Interceptor para tratar erros
httpClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token')
      window.location.href = '/auth/login'
    }
    return Promise.reject(error)
  }
)
```

## Rotas Principais

| Rota | Componente | Descrição |
|------|-----------|-----------|
| `/` | `Home` | Página inicial |
| `/auth/login` | `Login` | Login |
| `/auth/register` | `Register` | Cadastro |
| `/dashboard` | `Dashboard` | Dashboard do usuário |
| `/videos` | `VideoList` | Catálogo de vídeos |
| `/videos/:id` | `VideoDetail` | Detalhes do vídeo |
| `/videos/:id/watch` | `VideoPlayer` | Assistir vídeo |
| `/my-videos` | `MyVideos` | Vídeos comprados |
| `/promoter/dashboard` | `PromoterDashboard` | Dashboard do promoter |
| `/influencer/dashboard` | `InfluencerDashboard` | Dashboard do influencer |
| `/admin/*` | `Admin*` | Área administrativa |

## Troubleshooting

### Erro: Cannot connect to API

Verificar se Backend API está rodando:

```bash
curl http://localhost:7080/health
```

### Erro: CORS

Verificar configuração CORS no Backend API.

### Erro: Módulo não encontrado

```bash
rm -rf node_modules package-lock.json
npm install
```

## Próximos Passos

- [Configurar Backend](backend.md)
- [Adicionar Endpoint](../desenvolvimento/adicionar-endpoint.md)
- [Padrões de Código](../desenvolvimento/padroes-codigo.md)

