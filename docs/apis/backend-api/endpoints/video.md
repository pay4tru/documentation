# Endpoints: Video

## Descrição

Endpoints relacionados ao catálogo de vídeos.

## GET /api/videos

Lista todos os vídeos disponíveis com filtros opcionais.

**Auth**: Opcional (pública)

**Query Parameters:**

| Parâmetro | Tipo | Descrição | Padrão |
|-----------|------|-----------|--------|
| `page` | int | Página atual | 1 |
| `perPage` | int | Itens por página (max 100) | 20 |
| `search` | string | Busca no título/descrição | - |
| `minPrice` | decimal | Preço mínimo | - |
| `maxPrice` | decimal | Preço máximo | - |
| `sortBy` | string | Ordenação: `newest`, `oldest`, `price_asc`, `price_desc` | `newest` |

**Request:**
```http
GET /api/videos?page=1&perPage=20&sortBy=newest
```

**Response (200):**
```json
{
  "data": [
    {
      "id": 1,
      "title": "Vídeo Exclusivo",
      "description": "Descrição do vídeo",
      "thumbImgUrl": "https://cloudinary.com/...",
      "price": 99.90,
      "durationSeconds": 3600,
      "releaseDate": "2025-01-01",
      "expirationSaleDate": "2025-12-31",
      "isActive": true
    }
  ],
  "page": 1,
  "perPage": 20,
  "total": 150,
  "totalPages": 8
}
```

**Exemplo cURL:**
```bash
# Buscar vídeos
curl "http://localhost:7080/api/videos?search=exclusivo&minPrice=50&maxPrice=200"

# Ordenar por preço
curl "http://localhost:7080/api/videos?sortBy=price_asc"
```

**Código Backend:**
```csharp
// backend-api/Endpoints/VideoEndpoints.cs
app.MapGet("/api/videos", async (
    ApplicationDbContext context,
    int page = 1,
    int perPage = 20,
    string? search = null,
    decimal? minPrice = null,
    decimal? maxPrice = null,
    string sortBy = "newest") =>
{
    var query = context.Videos
        .Include(v => v.VideoRevenueConfig)
        .Where(v => v.IsActive &&
                    (v.ReleaseDate == null || v.ReleaseDate <= DateTime.Today) &&
                    (v.ExpirationSaleDate == null || v.ExpirationSaleDate >= DateTime.Today));
    
    // Filtros
    if (!string.IsNullOrEmpty(search))
    {
        query = query.Where(v => v.Title.Contains(search) || 
                                 v.Description.Contains(search));
    }
    
    if (minPrice.HasValue)
        query = query.Where(v => v.Price >= minPrice.Value);
    
    if (maxPrice.HasValue)
        query = query.Where(v => v.Price <= maxPrice.Value);
    
    // Ordenação
    query = sortBy switch
    {
        "oldest" => query.OrderBy(v => v.CreatedAt),
        "price_asc" => query.OrderBy(v => v.Price),
        "price_desc" => query.OrderByDescending(v => v.Price),
        _ => query.OrderByDescending(v => v.CreatedAt)
    };
    
    var total = await query.CountAsync();
    var videos = await query
        .Skip((page - 1) * perPage)
        .Take(perPage)
        .ToListAsync();
    
    return Results.Ok(new
    {
        Data = videos.Select(v => new VideoListDto
        {
            Id = v.Id,
            Title = v.Title,
            Description = v.Description,
            ThumbImgUrl = v.ThumbImgUrl,
            Price = v.Price,
            DurationSeconds = v.DurationSeconds,
            ReleaseDate = v.ReleaseDate,
            ExpirationSaleDate = v.ExpirationSaleDate,
            IsActive = v.IsActive
        }),
        Page = page,
        PerPage = perPage,
        Total = total,
        TotalPages = (int)Math.Ceiling((double)total / perPage)
    });
})
.AllowAnonymous()
.WithName("ListVideos");
```

## GET /api/videos/:id

Retorna detalhes completos de um vídeo específico.

**Auth**: Opcional (pública)

**Request:**
```http
GET /api/videos/123
```

**Response (200):**
```json
{
  "id": 123,
  "title": "Vídeo Exclusivo",
  "description": "Descrição completa do vídeo",
  "cloudinaryPublicId": "videos/abc123",
  "thumbImgUrl": "https://cloudinary.com/...",
  "price": 99.90,
  "durationSeconds": 3600,
  "releaseDate": "2025-01-01",
  "expirationSaleDate": "2025-12-31",
  "expirationViewDate": "2026-01-31",
  "videoRevenueConfig": {
    "platformPercentage": 20,
    "ownerPercentage": 50,
    "promoterPercentage": 30
  },
  "influencers": [
    {
      "id": 5,
      "name": "João Silva",
      "percentage": 50
    }
  ],
  "trailers": [
    {
      "url": "https://cloudinary.com/trailer123",
      "durationSeconds": 30
    }
  ]
}
```

**Errors:**
- `404 Not Found`: Vídeo não encontrado ou inativo

**Código Backend:**
```csharp
// backend-api/Endpoints/VideoEndpoints.cs
app.MapGet("/api/videos/{id:long}", async (
    long id,
    ApplicationDbContext context) =>
{
    var video = await context.Videos
        .Include(v => v.VideoRevenueConfig)
        .Include(v => v.OwnerVideos)
        .ThenInclude(ov => ov.Owner)
        .ThenInclude(o => o.User)
        .Include(v => v.VideoTrailers)
        .FirstOrDefaultAsync(v => v.Id == id && v.IsActive);
    
    if (video == null)
        return Results.NotFound();
    
    return Results.Ok(new VideoDetailDto
    {
        Id = video.Id,
        Title = video.Title,
        Description = video.Description,
        CloudinaryPublicId = video.CloudinaryPublicId,
        ThumbImgUrl = video.ThumbImgUrl,
        Price = video.Price,
        DurationSeconds = video.DurationSeconds,
        ReleaseDate = video.ReleaseDate,
        ExpirationSaleDate = video.ExpirationSaleDate,
        ExpirationViewDate = video.ExpirationViewDate,
        VideoRevenueConfig = new RevenueConfigDto
        {
            PlatformPercentage = video.VideoRevenueConfig.PlatformPercentage,
            OwnerPercentage = video.VideoRevenueConfig.OwnerPercentage,
            PromoterPercentage = video.VideoRevenueConfig.PromoterPercentage
        },
        Influencers = video.OwnerVideos.Select(ov => new InfluencerDto
        {
            Id = ov.Owner.Id,
            Name = $"{ov.Owner.User.FirstName} {ov.Owner.User.LastName}",
            Percentage = video.VideoRevenueConfig.OwnerPercentage
        }).ToList(),
        Trailers = video.VideoTrailers.Select(vt => new TrailerDto
        {
            Url = vt.CloudinaryPublicId,
            DurationSeconds = vt.DurationSeconds
        }).ToList()
    });
})
.AllowAnonymous()
.WithName("GetVideoDetails");
```

## GET /api/videos/:id/check-access

Verifica se o usuário logado tem acesso ao vídeo (comprou).

**Auth**: Requerido (JWT)

**Request:**
```http
GET /api/videos/123/check-access
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "hasAccess": true,
  "purchasedAt": "2025-01-10T15:30:00Z",
  "canWatch": true,
  "expirationViewDate": "2026-01-31"
}
```

**Código Backend:**
```csharp
// backend-api/Endpoints/VideoEndpoints.cs
app.MapGet("/api/videos/{id:long}/check-access", async (
    long id,
    HttpRequest request,
    ApplicationDbContext context) =>
{
    var userId = GetUserIdFromToken(request);
    
    var order = await context.Orders
        .Include(o => o.Payment)
        .Include(o => o.Video)
        .FirstOrDefaultAsync(o => o.UserId == userId &&
                                  o.VideoId == id &&
                                  o.Payment.Status == PaymentStatusEnum.Paid);
    
    if (order == null)
    {
        return Results.Ok(new
        {
            HasAccess = false,
            CanWatch = false
        });
    }
    
    var canWatch = order.Video.ExpirationViewDate == null ||
                   order.Video.ExpirationViewDate >= DateTime.Today;
    
    return Results.Ok(new
    {
        HasAccess = true,
        PurchasedAt = order.Payment.IuguPaidAt,
        CanWatch = canWatch,
        ExpirationViewDate = order.Video.ExpirationViewDate
    });
})
.RequireAuthorization()
.WithName("CheckVideoAccess");
```

## Frontend - Exemplo de Uso

```typescript
// frontend-react/src/services/api/videoApi.ts
export const videoApi = {
  getAll: async (params?: VideoFilters) => {
    const response = await httpClient.get('/api/videos', { params })
    return response.data
  },
  
  getById: async (id: number) => {
    const response = await httpClient.get(`/api/videos/${id}`)
    return response.data
  },
  
  checkAccess: async (id: number) => {
    const response = await httpClient.get(`/api/videos/${id}/check-access`)
    return response.data
  }
}

// frontend-react/src/pages/Videos/VideoList.tsx
const VideoList = () => {
  const [filters, setFilters] = useState<VideoFilters>({
    search: '',
    sortBy: 'newest'
  })
  
  const { data } = useQuery({
    queryKey: ['videos', filters],
    queryFn: () => videoApi.getAll(filters)
  })
  
  return (
    <div>
      <input
        value={filters.search}
        onChange={(e) => setFilters({ ...filters, search: e.target.value })}
        placeholder="Buscar vídeos..."
      />
      
      <select
        value={filters.sortBy}
        onChange={(e) => setFilters({ ...filters, sortBy: e.target.value })}
      >
        <option value="newest">Mais Recentes</option>
        <option value="price_asc">Menor Preço</option>
        <option value="price_desc">Maior Preço</option>
      </select>
      
      <VideoGrid videos={data.data} />
      
      <Pagination
        currentPage={data.page}
        totalPages={data.totalPages}
      />
    </div>
  )
}
```

## Regras de Negócio

1. **Vídeos públicos**: Listagem não requer autenticação
2. **ReleaseDate**: Vídeo só aparece após esta data
3. **ExpirationSaleDate**: Vídeo não aparece se passada esta data
4. **ExpirationViewDate**: Usuário que comprou não pode assistir após esta data
5. **IsActive**: Apenas vídeos ativos aparecem

## Próximos Passos

- [Orders](order.md) - Como comprar vídeos
- [Fluxo de Compra](../../../fluxos-de-negocio/compra-video.md)
- [Gestão de Vídeos](../../../fluxos-de-negocio/gestao-videos.md)

