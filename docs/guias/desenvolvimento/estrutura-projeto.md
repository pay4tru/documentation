# Estrutura de Projeto

## Overview

O monorepo Amasso contém 3 projetos principais:

```
amasso-monorepo/
├── backend-api/          # API principal (.NET 8)
├── email-api/            # API de notificações (.NET 8 + Hangfire)
├── frontend-react/       # Interface web (React + TypeScript)
└── documentation/        # Documentação (MkDocs)
```

## Backend API (.NET 8)

### Estrutura de Pastas

```
backend-api/
├── Data/
│   ├── Configuration/      # EF Core Configurations (FluentAPI)
│   │   ├── UserConfiguration.cs
│   │   ├── VideoConfiguration.cs
│   │   └── OrderConfiguration.cs
│   │
│   ├── Context/
│   │   └── ApplicationDbContext.cs
│   │
│   ├── Dtos/              # Data Transfer Objects
│   │   ├── CreateOrderDto.cs
│   │   ├── UserDto.cs
│   │   └── VideoDto.cs
│   │
│   ├── Entities/          # Modelos do banco de dados
│   │   ├── User.cs
│   │   ├── Video.cs
│   │   ├── Order.cs
│   │   └── Payment.cs
│   │
│   ├── Enums/            # Enumerações
│   │   ├── UserTypeEnum.cs
│   │   ├── PaymentStatusEnum.cs
│   │   └── OwnerSubAccountStatusEnum.cs
│   │
│   └── Validations/      # FluentValidation
│       ├── CreateOrderDtoValidator.cs
│       └── UpdateUserDtoValidator.cs
│
├── Endpoints/            # Minimal APIs
│   ├── AdminEndpoints.cs
│   ├── VideoEndpoints.cs
│   ├── OrderEndpoints.cs
│   ├── UserEndpoints.cs
│   ├── PromoterEndpoint.cs
│   ├── OwnerEndpoints.cs
│   └── WebHookEndpoint.cs
│
├── Services/             # Lógica de negócio
│   ├── Admin/
│   │   ├── AdminService.cs
│   │   └── KycService.cs
│   │
│   ├── External/
│   │   ├── IuguService.cs
│   │   ├── CloudinaryService.cs
│   │   └── ZApiService.cs
│   │
│   ├── Promoter/
│   │   └── AffiliateLinkService.cs
│   │
│   ├── LoginService.cs
│   ├── UserService.cs
│   ├── VideoService.cs
│   ├── OrderService.cs
│   └── PaymentService.cs
│
├── Helpers/
│   ├── Constants.cs
│   │
│   ├── Extensions/
│   │   ├── DateTimeExtensions.cs
│   │   ├── StringExtensions.cs
│   │   └── QueryableExtensions.cs
│   │
│   ├── Logging/
│   │   └── LoggingMiddleware.cs
│   │
│   ├── Middlewares/
│   │   ├── ExceptionHandleMiddleware.cs
│   │   └── TokenAuthenticationMiddleware.cs
│   │
│   └── Wrappers/
│       └── Response.cs
│
├── Migrations/           # EF Core Migrations
│   ├── 20250101000000_InitialCreate.cs
│   └── 20250115000000_AddVideoRevenueConfig.cs
│
├── Models/
│   └── Configuration/    # Configurações de integração
│       ├── IuguConfig.cs
│       └── CloudinaryConfig.cs
│
├── appsettings.json
├── appsettings.Development.json
├── Program.cs
├── Usings.cs
└── Pay4Tru.Api.csproj
```

### Camadas e Responsabilidades

#### 1. Endpoints (Minimal APIs)

Definem rotas HTTP e validações básicas.

```csharp
// VideoEndpoints.cs
public static class VideoEndpoints
{
    public static void MapVideoEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapGet("/api/videos", GetAllVideos);
        app.MapGet("/api/videos/{id:long}", GetVideoById);
        app.MapPost("/api/videos", CreateVideo).RequireAuthorization("Admin");
    }
    
    private static async Task<IResult> GetAllVideos(
        VideoService service,
        int page = 1,
        int perPage = 20)
    {
        var videos = await service.GetAllAsync(page, perPage);
        return Results.Ok(videos);
    }
}
```

#### 2. Services

Contém lógica de negócio.

```csharp
// VideoService.cs
public class VideoService
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<VideoService> _logger;
    
    public async Task<List<VideoDto>> GetAllAsync(int page, int perPage)
    {
        var videos = await _context.Videos
            .Where(v => v.IsActive)
            .OrderByDescending(v => v.CreatedAt)
            .Skip((page - 1) * perPage)
            .Take(perPage)
            .Select(v => new VideoDto
            {
                Id = v.Id,
                Title = v.Title,
                Price = v.Price
            })
            .ToListAsync();
        
        return videos;
    }
}
```

#### 3. Entities

Modelos do banco de dados com EF Core.

```csharp
// Data/Entities/Video.cs
public class Video
{
    public long Id { get; set; }
    public string Title { get; set; }
    public string Description { get; set; }
    public decimal Price { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    
    // Navigation Properties
    public VideoRevenueConfig VideoRevenueConfig { get; set; }
    public ICollection<Order> Orders { get; set; }
}
```

#### 4. Configuration (FluentAPI)

Configurações de tabelas e relacionamentos.

```csharp
// Data/Configuration/VideoConfiguration.cs
public class VideoConfiguration : IEntityTypeConfiguration<Video>
{
    public void Configure(EntityTypeBuilder<Video> builder)
    {
        builder.ToTable("videos");
        
        builder.HasKey(v => v.Id);
        
        builder.Property(v => v.Title)
            .HasMaxLength(255)
            .IsRequired();
        
        builder.Property(v => v.Price)
            .HasColumnType("decimal(10,2)")
            .IsRequired();
        
        builder.HasOne(v => v.VideoRevenueConfig)
            .WithOne(vrc => vrc.Video)
            .HasForeignKey<VideoRevenueConfig>(vrc => vrc.VideoId);
    }
}
```

#### 5. DTOs

Objetos de transferência (input/output).

```csharp
// Data/Dtos/VideoDto.cs
public record VideoDto
{
    public long Id { get; init; }
    public string Title { get; init; }
    public decimal Price { get; init; }
}

// Data/Dtos/CreateVideoDto.cs
public record CreateVideoDto
{
    public string Title { get; init; }
    public string Description { get; init; }
    public decimal Price { get; init; }
}
```

## Email API (.NET 8 + Hangfire)

### Estrutura de Pastas

```
email-api/
├── Data/
│   ├── Context/
│   │   └── ApplicationDbContext.cs
│   │
│   ├── Entities/
│   │   └── Notification.cs
│   │
│   ├── Enums/
│   │   ├── NotificationTypeEnum.cs
│   │   └── NotificationChannelEnum.cs
│   │
│   └── Dtos/
│       └── NotificationDto.cs
│
├── Jobs/                 # Hangfire Jobs
│   ├── NotificationJob.cs
│   └── LogCleanupJob.cs
│
├── Services/
│   ├── NotificationService.cs
│   ├── EmailSender.cs
│   ├── WhatsAppSender.cs
│   ├── TemplateRenderer.cs
│   └── LogCleanupService.cs
│
├── Filters/
│   └── HangfireAuthorizationCustomFilter.cs
│
├── Middlewares/
│   └── ExceptionHandleMiddleware.cs
│
├── wwwroot/
│   ├── Templates/
│   │   ├── Email/
│   │   │   ├── MfaCode.html
│   │   │   ├── PaymentConfirmed.html
│   │   │   └── KycApproved.html
│   │   │
│   │   └── WhatsApp/
│   │       ├── MfaCode.txt
│   │       ├── PaymentConfirmed.txt
│   │       └── KycApproved.txt
│   │
│   └── Images/
│       └── logo.png
│
├── appsettings.json
├── Program.cs
└── Pay4Tru.JobEmails.csproj
```

### Responsabilidades

- **Jobs**: Processar notificações pendentes (Hangfire)
- **Services**: Enviar emails (SMTP) e WhatsApp (Z-API)
- **Templates**: Renderizar HTML/TXT com variáveis dinâmicas
- **Dashboard**: Monitoramento Hangfire (`/dashboard`)

## Frontend React (TypeScript)

### Estrutura de Pastas

```
frontend-react/
├── src/
│   ├── pages/            # Páginas/rotas
│   │   ├── Home/
│   │   │   ├── Home.tsx
│   │   │   └── Home.scss
│   │   │
│   │   ├── Videos/
│   │   │   ├── VideoList.tsx
│   │   │   ├── VideoDetail.tsx
│   │   │   └── VideoCheckout.tsx
│   │   │
│   │   ├── Auth/
│   │   │   ├── Login.tsx
│   │   │   └── Register.tsx
│   │   │
│   │   ├── Admin/
│   │   │   ├── AdminDashboard.tsx
│   │   │   ├── KycApprovals.tsx
│   │   │   └── VideoManagement.tsx
│   │   │
│   │   ├── Promoter/
│   │   │   ├── PromoterDashboard.tsx
│   │   │   └── AffiliateLinks.tsx
│   │   │
│   │   └── Influencer/
│   │       └── InfluencerDashboard.tsx
│   │
│   ├── components/       # Componentes reutilizáveis
│   │   ├── common/
│   │   │   ├── Button.tsx
│   │   │   ├── Card.tsx
│   │   │   ├── Input.tsx
│   │   │   └── Modal.tsx
│   │   │
│   │   ├── layout/
│   │   │   ├── Header.tsx
│   │   │   ├── Footer.tsx
│   │   │   └── Sidebar.tsx
│   │   │
│   │   └── video/
│   │       ├── VideoCard.tsx
│   │       ├── VideoPlayer.tsx
│   │       └── VideoGrid.tsx
│   │
│   ├── services/         # API e utilitários
│   │   ├── api/
│   │   │   ├── httpClient.ts
│   │   │   ├── videoApi.ts
│   │   │   ├── orderApi.ts
│   │   │   ├── userApi.ts
│   │   │   └── adminApi.ts
│   │   │
│   │   └── utils/
│   │       ├── formatters.ts
│   │       ├── validators.ts
│   │       └── storage.ts
│   │
│   ├── store/            # Redux Toolkit
│   │   ├── store.ts
│   │   │
│   │   ├── slices/
│   │   │   ├── authSlice.ts
│   │   │   ├── videoSlice.ts
│   │   │   └── cartSlice.ts
│   │   │
│   │   └── hooks.ts
│   │
│   ├── types/            # TypeScript types
│   │   ├── user.ts
│   │   ├── video.ts
│   │   └── order.ts
│   │
│   ├── routes/
│   │   ├── AppRoutes.tsx
│   │   └── ProtectedRoute.tsx
│   │
│   ├── App.tsx
│   ├── main.tsx
│   └── vite-env.d.ts
│
├── public/
│   ├── favicon.ico
│   └── robots.txt
│
├── index.html
├── package.json
├── tsconfig.json
└── vite.config.ts
```

### Organização por Feature

#### API Services

```typescript
// services/api/videoApi.ts
import httpClient from './httpClient'

export const videoApi = {
  getAll: async (params?: VideoFilters) => {
    const response = await httpClient.get('/api/videos', { params })
    return response.data
  },
  
  getById: async (id: number) => {
    const response = await httpClient.get(`/api/videos/${id}`)
    return response.data
  }
}
```

#### Redux Store

```typescript
// store/slices/authSlice.ts
import { createSlice, PayloadAction } from '@reduxjs/toolkit'

interface AuthState {
  user: User | null
  token: string | null
  isAuthenticated: boolean
}

const initialState: AuthState = {
  user: null,
  token: localStorage.getItem('token'),
  isAuthenticated: false
}

const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    setCredentials: (state, action: PayloadAction<{ user: User, token: string }>) => {
      state.user = action.payload.user
      state.token = action.payload.token
      state.isAuthenticated = true
      localStorage.setItem('token', action.payload.token)
    },
    logout: (state) => {
      state.user = null
      state.token = null
      state.isAuthenticated = false
      localStorage.removeItem('token')
    }
  }
})

export const { setCredentials, logout } = authSlice.actions
export default authSlice.reducer
```

#### Components

```typescript
// components/video/VideoCard.tsx
interface VideoCardProps {
  video: Video
  onClickBuy: (videoId: number) => void
}

export const VideoCard: React.FC<VideoCardProps> = ({ video, onClickBuy }) => {
  return (
    <div className="video-card">
      <img src={video.thumbImgUrl} alt={video.title} />
      <h3>{video.title}</h3>
      <p className="price">R$ {video.price.toFixed(2)}</p>
      <button onClick={() => onClickBuy(video.id)}>
        Comprar
      </button>
    </div>
  )
}
```

## Fluxo de Dados

### Backend → Frontend

```
1. Frontend faz request HTTP (Axios)
   ↓
2. Backend Endpoint recebe
   ↓
3. Service executa lógica
   ↓
4. DbContext acessa PostgreSQL
   ↓
5. Service retorna DTO
   ↓
6. Endpoint retorna JSON
   ↓
7. Frontend recebe response
```

### Exemplo Completo

```typescript
// Frontend
const handleBuyVideo = async (videoId: number) => {
  const order = await orderApi.create({ videoId })
  window.location.href = order.payment.iuguSecureUrl
}
```

```csharp
// Backend Endpoint
app.MapPost("/api/orders", async (CreateOrderDto dto, OrderService service) =>
{
    var order = await service.CreateOrderAsync(dto);
    return Results.Created($"/api/orders/{order.Id}", order);
});

// Backend Service
public async Task<OrderDto> CreateOrderAsync(CreateOrderDto dto)
{
    var order = new Order
    {
        VideoId = dto.VideoId,
        UserId = _currentUserId,
        Amount = video.Price * 100,
        CreatedAt = DateTime.UtcNow
    };
    
    await _context.Orders.AddAsync(order);
    await _context.SaveChangesAsync();
    
    // Criar invoice no Iugu
    var invoice = await _iuguService.CreateInvoiceAsync(order);
    
    return new OrderDto { /* ... */ };
}
```

## Próximos Passos

- [Padrões de Código](padroes-codigo.md)
- [Adicionar Endpoint](adicionar-endpoint.md)
- [Adicionar Entidade](adicionar-entidade.md)
- [Criar Migration](criar-migration.md)

