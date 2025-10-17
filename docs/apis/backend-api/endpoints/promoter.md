# Endpoints: Promoter

## Descrição

Endpoints específicos para Promoters (afiliados) gerenciarem links e acompanharem conversões.

## POST /api/promoter/affiliate-links

Cria um novo link de afiliado para um vídeo.

**Auth**: Requerido (Promoter com KYC aprovado)

**Request:**
```http
POST /api/promoter/affiliate-links
Authorization: Bearer {token}
Content-Type: application/json

{
  "videoId": 123
}
```

**Response (201):**
```json
{
  "id": 456,
  "videoId": 123,
  "uniqueCode": "ABC12345",
  "fullLink": "https://amasso.com.br/videos/123?ref=ABC12345",
  "clicks": 0,
  "createdAt": "2025-01-15T10:00:00Z"
}
```

**Errors:**
- `400 Bad Request`: KYC não aprovado ou vídeo sem comissão
- `401 Unauthorized`: Token inválido
- `404 Not Found`: Vídeo não encontrado

**Código Backend:**
```csharp
// backend-api/Endpoints/PromoterEndpoint.cs
app.MapPost("/api/promoter/affiliate-links", async (
    CreateAffiliateLinkDto dto,
    HttpRequest request,
    ApplicationDbContext context,
    IConfiguration config) =>
{
    var userId = GetUserIdFromToken(request);
    
    var owner = await context.Owners
        .FirstAsync(o => o.UserId == userId);
    
    // Verificar KYC aprovado
    if (owner.SubAccountStatus != OwnerSubAccountStatusEnum.Approved)
    {
        return Results.BadRequest(new 
        { 
            error = "KYC não aprovado. Envie seus documentos primeiro." 
        });
    }
    
    // Verificar se vídeo tem comissão para promoters
    var video = await context.Videos
        .Include(v => v.VideoRevenueConfig)
        .FirstAsync(v => v.Id == dto.VideoId);
    
    if (video.VideoRevenueConfig.PromoterPercentage <= 0)
    {
        return Results.BadRequest(new 
        { 
            error = "Este vídeo não tem comissão para promoters" 
        });
    }
    
    // Verificar se já existe link
    var existingLink = await context.VideoAffiliateLinks
        .FirstOrDefaultAsync(l => l.OwnerId == owner.Id && 
                                  l.VideoId == dto.VideoId);
    
    if (existingLink != null)
    {
        var baseUrl = config["App:BaseUrl"];
        return Results.Ok(new
        {
            Id = existingLink.Id,
            VideoId = existingLink.VideoId,
            UniqueCode = existingLink.UniqueCode,
            FullLink = $"{baseUrl}/videos/{existingLink.VideoId}?ref={existingLink.UniqueCode}",
            Clicks = existingLink.Clicks,
            CreatedAt = existingLink.CreatedAt
        });
    }
    
    // Criar novo link
    var link = new VideoAffiliateLink
    {
        OwnerId = owner.Id,
        VideoId = dto.VideoId,
        UniqueCode = GenerateUniqueCode(),
        Clicks = 0,
        CreatedAt = DateTime.UtcNow
    };
    
    await context.VideoAffiliateLinks.AddAsync(link);
    await context.SaveChangesAsync();
    
    var fullLink = $"{config["App:BaseUrl"]}/videos/{link.VideoId}?ref={link.UniqueCode}";
    
    return Results.Created($"/api/promoter/affiliate-links/{link.Id}", new
    {
        Id = link.Id,
        VideoId = link.VideoId,
        UniqueCode = link.UniqueCode,
        FullLink = fullLink,
        Clicks = link.Clicks,
        CreatedAt = link.CreatedAt
    });
})
.RequireAuthorization()
.WithName("CreateAffiliateLink");

private string GenerateUniqueCode()
{
    return Convert.ToBase64String(Guid.NewGuid().ToByteArray())
        .Replace("+", "").Replace("/", "").Replace("=", "")
        .Substring(0, 8)
        .ToUpper();
}
```

## GET /api/promoter/affiliate-links

Lista todos os links de afiliado do promoter.

**Auth**: Requerido (Promoter)

**Response (200):**
```json
[
  {
    "id": 456,
    "video": {
      "id": 123,
      "title": "Vídeo Exclusivo",
      "price": 99.90,
      "promoterPercentage": 30
    },
    "uniqueCode": "ABC12345",
    "fullLink": "https://amasso.com.br/videos/123?ref=ABC12345",
    "clicks": 150,
    "conversions": 5,
    "conversionRate": 3.33,
    "totalCommission": 149.85,
    "createdAt": "2025-01-10T10:00:00Z"
  }
]
```

**Código Backend:**
```csharp
app.MapGet("/api/promoter/affiliate-links", async (
    HttpRequest request,
    ApplicationDbContext context,
    IConfiguration config) =>
{
    var userId = GetUserIdFromToken(request);
    var owner = await context.Owners.FirstAsync(o => o.UserId == userId);
    
    var links = await context.VideoAffiliateLinks
        .Include(l => l.Video)
        .ThenInclude(v => v.VideoRevenueConfig)
        .Where(l => l.OwnerId == owner.Id)
        .OrderByDescending(l => l.CreatedAt)
        .ToListAsync();
    
    var baseUrl = config["App:BaseUrl"];
    
    var result = links.Select(l =>
    {
        var conversions = context.Orders
            .Where(o => o.VideoAffiliateLinkId == l.Id &&
                       o.Payment.Status == PaymentStatusEnum.Paid)
            .Count();
        
        var totalCommission = context.Incomes
            .Where(i => i.OwnerId == owner.Id &&
                       i.Type == IncomeTypeEnum.Promoter &&
                       i.Order.VideoAffiliateLinkId == l.Id)
            .Sum(i => i.Amount) / 100m;
        
        return new
        {
            Id = l.Id,
            Video = new
            {
                Id = l.Video.Id,
                Title = l.Video.Title,
                Price = l.Video.Price,
                PromoterPercentage = l.Video.VideoRevenueConfig.PromoterPercentage
            },
            UniqueCode = l.UniqueCode,
            FullLink = $"{baseUrl}/videos/{l.VideoId}?ref={l.UniqueCode}",
            Clicks = l.Clicks,
            Conversions = conversions,
            ConversionRate = l.Clicks > 0 ? (decimal)conversions / l.Clicks * 100 : 0,
            TotalCommission = totalCommission,
            CreatedAt = l.CreatedAt
        };
    });
    
    return Results.Ok(result);
})
.RequireAuthorization()
.WithName("GetAffiliateLinks");
```

## GET /api/promoter/dashboard

Retorna dashboard com métricas do promoter.

**Auth**: Requerido (Promoter)

**Response (200):**
```json
{
  "totalEarnings": 1498.50,
  "totalConversions": 50,
  "totalClicks": 1500,
  "conversionRate": 3.33,
  "averageCommission": 29.97,
  "topVideos": [
    {
      "videoId": 123,
      "videoTitle": "Vídeo Exclusivo",
      "conversions": 20,
      "earnings": 599.40
    }
  ],
  "recentConversions": [
    {
      "orderId": 789,
      "videoTitle": "Vídeo Exclusivo",
      "amount": 99.90,
      "commission": 29.97,
      "paidAt": "2025-01-15T11:00:00Z"
    }
  ]
}
```

**Código Backend:**
```csharp
app.MapGet("/api/promoter/dashboard", async (
    HttpRequest request,
    ApplicationDbContext context) =>
{
    var userId = GetUserIdFromToken(request);
    var owner = await context.Owners.FirstAsync(o => o.UserId == userId);
    
    var incomes = await context.Incomes
        .Include(i => i.Order)
        .ThenInclude(o => o.Video)
        .Where(i => i.OwnerId == owner.Id &&
                    i.Type == IncomeTypeEnum.Promoter)
        .ToListAsync();
    
    var links = await context.VideoAffiliateLinks
        .Where(l => l.OwnerId == owner.Id)
        .ToListAsync();
    
    var totalClicks = links.Sum(l => l.Clicks);
    var totalConversions = incomes.Count;
    
    var dashboard = new
    {
        TotalEarnings = incomes.Sum(i => i.Amount) / 100m,
        TotalConversions = totalConversions,
        TotalClicks = totalClicks,
        ConversionRate = totalClicks > 0 
            ? (decimal)totalConversions / totalClicks * 100 
            : 0,
        AverageCommission = totalConversions > 0
            ? incomes.Average(i => i.Amount) / 100m
            : 0,
        TopVideos = incomes
            .GroupBy(i => i.Order.Video)
            .OrderByDescending(g => g.Sum(i => i.Amount))
            .Take(5)
            .Select(g => new
            {
                VideoId = g.Key.Id,
                VideoTitle = g.Key.Title,
                Conversions = g.Count(),
                Earnings = g.Sum(i => i.Amount) / 100m
            }),
        RecentConversions = incomes
            .OrderByDescending(i => i.CreatedAt)
            .Take(10)
            .Select(i => new
            {
                OrderId = i.OrderId,
                VideoTitle = i.Order.Video.Title,
                Amount = i.Order.Amount / 100m,
                Commission = i.Amount / 100m,
                PaidAt = i.Order.Payment.IuguPaidAt
            })
    };
    
    return Results.Ok(dashboard);
})
.RequireAuthorization()
.WithName("GetPromoterDashboard");
```

## GET /api/promoter/conversions

Lista todas as conversões (vendas) do promoter.

**Auth**: Requerido (Promoter)

**Query Parameters:**

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `startDate` | date | Data inicial |
| `endDate` | date | Data final |
| `videoId` | int | Filtrar por vídeo |

**Response (200):**
```json
[
  {
    "orderId": 789,
    "video": {
      "id": 123,
      "title": "Vídeo Exclusivo"
    },
    "buyer": {
      "name": "João Silva"
    },
    "orderAmount": 99.90,
    "commissionAmount": 29.97,
    "paidAt": "2025-01-15T11:00:00Z"
  }
]
```

**Código Backend:**
```csharp
app.MapGet("/api/promoter/conversions", async (
    HttpRequest request,
    ApplicationDbContext context,
    DateTime? startDate = null,
    DateTime? endDate = null,
    long? videoId = null) =>
{
    var userId = GetUserIdFromToken(request);
    var owner = await context.Owners.FirstAsync(o => o.UserId == userId);
    
    var query = context.Incomes
        .Include(i => i.Order)
        .ThenInclude(o => o.Video)
        .Include(i => i.Order)
        .ThenInclude(o => o.User)
        .Include(i => i.Order)
        .ThenInclude(o => o.Payment)
        .Where(i => i.OwnerId == owner.Id &&
                    i.Type == IncomeTypeEnum.Promoter);
    
    if (startDate.HasValue)
        query = query.Where(i => i.CreatedAt >= startDate.Value);
    
    if (endDate.HasValue)
        query = query.Where(i => i.CreatedAt <= endDate.Value);
    
    if (videoId.HasValue)
        query = query.Where(i => i.Order.VideoId == videoId.Value);
    
    var conversions = await query
        .OrderByDescending(i => i.CreatedAt)
        .Select(i => new
        {
            OrderId = i.OrderId,
            Video = new
            {
                Id = i.Order.Video.Id,
                Title = i.Order.Video.Title
            },
            Buyer = new
            {
                Name = $"{i.Order.User.FirstName} {i.Order.User.LastName}"
            },
            OrderAmount = i.Order.Amount / 100m,
            CommissionAmount = i.Amount / 100m,
            PaidAt = i.Order.Payment.IuguPaidAt
        })
        .ToListAsync();
    
    return Results.Ok(conversions);
})
.RequireAuthorization()
.WithName("GetPromoterConversions");
```

## Frontend - Exemplo de Uso

```typescript
// frontend-react/src/services/api/promoterApi.ts
export const promoterApi = {
  createAffiliateLink: async (videoId: number) => {
    const response = await httpClient.post('/api/promoter/affiliate-links', {
      videoId
    })
    return response.data
  },
  
  getAffiliateLinks: async () => {
    const response = await httpClient.get('/api/promoter/affiliate-links')
    return response.data
  },
  
  getDashboard: async () => {
    const response = await httpClient.get('/api/promoter/dashboard')
    return response.data
  },
  
  getConversions: async (filters?: ConversionFilters) => {
    const response = await httpClient.get('/api/promoter/conversions', {
      params: filters
    })
    return response.data
  }
}

// frontend-react/src/pages/Promoter/PromoterDashboard.tsx
const PromoterDashboard = () => {
  const { data: dashboard } = useQuery({
    queryKey: ['promoter-dashboard'],
    queryFn: promoterApi.getDashboard
  })
  
  const { data: links } = useQuery({
    queryKey: ['affiliate-links'],
    queryFn: promoterApi.getAffiliateLinks
  })
  
  const handleCopyLink = (link: string) => {
    navigator.clipboard.writeText(link)
    toast.success('Link copiado!')
  }
  
  return (
    <div>
      <h1>Dashboard do Promoter</h1>
      
      <Grid cols={4}>
        <Card>
          <h3>Total de Comissões</h3>
          <p className="text-3xl">R$ {dashboard?.totalEarnings.toFixed(2)}</p>
        </Card>
        
        <Card>
          <h3>Conversões</h3>
          <p className="text-3xl">{dashboard?.totalConversions}</p>
        </Card>
        
        <Card>
          <h3>Cliques</h3>
          <p className="text-3xl">{dashboard?.totalClicks}</p>
        </Card>
        
        <Card>
          <h3>Taxa de Conversão</h3>
          <p className="text-3xl">{dashboard?.conversionRate.toFixed(2)}%</p>
        </Card>
      </Grid>
      
      <h2>Meus Links</h2>
      <Table>
        {links?.map(link => (
          <tr key={link.id}>
            <td>{link.video.title}</td>
            <td>{link.clicks}</td>
            <td>{link.conversions}</td>
            <td>R$ {link.totalCommission.toFixed(2)}</td>
            <td>
              <Button onClick={() => handleCopyLink(link.fullLink)}>
                Copiar Link
              </Button>
            </td>
          </tr>
        ))}
      </Table>
    </div>
  )
}
```

## Regras de Negócio

1. **KYC aprovado**: Obrigatório para criar links
2. **Vídeos com comissão**: Apenas vídeos com `promoter_percentage > 0%`
3. **Link único**: 1 link por vídeo por promoter
4. **Rastreamento de cliques**: Incrementado automaticamente
5. **Comissões automáticas**: Creditadas quando pagamento confirmado

## Próximos Passos

- [Perfil Promoter](../../../perfis-de-usuario/promoter.md)
- [Fluxo de Link de Afiliado](../../../fluxos-de-negocio/link-afiliado.md)
- [Caso de Uso: Promoter Gera Link](../../../casos-de-uso/promoter-gera-link.md)

