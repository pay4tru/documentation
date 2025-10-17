# Endpoints: Order

## Descrição

Endpoints relacionados a pedidos de compra de vídeos.

## POST /api/orders

Cria um novo pedido de compra de vídeo.

**Auth**: Requerido (JWT)

**Request:**
```http
POST /api/orders
Authorization: Bearer {token}
Content-Type: application/json

{
  "videoId": 123,
  "affiliateCode": "ABC12345"
}
```

**Response (201):**
```json
{
  "orderId": 456,
  "videoId": 123,
  "amount": 9990,
  "platformAmount": 1998,
  "ownerAmount": 4995,
  "promoterAmount": 2997,
  "payment": {
    "id": 789,
    "iuguInvoiceId": "ABC123XYZ",
    "iuguSecureUrl": "https://faturas.iugu.com/abc123",
    "status": "Pending",
    "amount": 9990
  },
  "createdAt": "2025-01-15T10:30:00Z"
}
```

**Errors:**
- `400 Bad Request`: Dados inválidos ou vídeo já comprado
- `401 Unauthorized`: Token inválido
- `404 Not Found`: Vídeo não encontrado

**Exemplo cURL:**
```bash
# Compra direta (sem promoter)
curl -X POST http://localhost:7080/api/orders \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "videoId": 123
  }'

# Compra via link de afiliado
curl -X POST http://localhost:7080/api/orders \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "videoId": 123,
    "affiliateCode": "ABC12345"
  }'
```

**Código Backend:**
```csharp
// backend-api/Endpoints/OrderEndpoints.cs
app.MapPost("/api/orders", async (
    CreateOrderDto dto,
    HttpRequest request,
    OrderService service) =>
{
    var userId = GetUserIdFromToken(request);
    
    try
    {
        var order = await service.CreateOrderAsync(dto, userId);
        
        return Results.Created($"/api/orders/{order.Id}", new
        {
            OrderId = order.Id,
            VideoId = order.VideoId,
            Amount = order.Amount,
            PlatformAmount = order.PlatformAmount,
            OwnerAmount = order.OwnerAmount,
            PromoterAmount = order.PromoterAmount,
            Payment = new
            {
                Id = order.Payment.Id,
                IuguInvoiceId = order.Payment.IuguInvoiceId,
                IuguSecureUrl = order.Payment.IuguSecureUrl,
                Status = order.Payment.Status,
                Amount = order.Payment.Amount
            },
            CreatedAt = order.CreatedAt
        });
    }
    catch (InvalidOperationException ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
})
.RequireAuthorization()
.WithName("CreateOrder");
```

**Service:**
```csharp
// backend-api/Services/OrderService.cs
public async Task<Order> CreateOrderAsync(CreateOrderDto dto, long userId)
{
    // Verificar se já comprou
    var alreadyPurchased = await _context.Orders
        .Include(o => o.Payment)
        .AnyAsync(o => o.UserId == userId &&
                      o.VideoId == dto.VideoId &&
                      o.Payment.Status == PaymentStatusEnum.Paid);
    
    if (alreadyPurchased)
        throw new InvalidOperationException("Você já possui este vídeo");
    
    // Buscar vídeo
    var video = await _context.Videos
        .Include(v => v.VideoRevenueConfig)
        .Include(v => v.OwnerVideos)
        .ThenInclude(ov => ov.Owner)
        .FirstAsync(v => v.Id == dto.VideoId);
    
    var config = video.VideoRevenueConfig;
    var totalCents = (int)(video.Price * 100);
    
    // Calcular split
    var platformCents = (int)(totalCents * config.PlatformPercentage / 100);
    var ownerCents = (int)(totalCents * config.OwnerPercentage / 100);
    var promoterCents = (int)(totalCents * config.PromoterPercentage / 100);
    
    // Buscar promoter (se houver)
    Owner? promoter = null;
    if (!string.IsNullOrEmpty(dto.AffiliateCode))
    {
        var link = await _context.VideoAffiliateLinks
            .Include(l => l.Owner)
            .FirstOrDefaultAsync(l => l.UniqueCode == dto.AffiliateCode);
        
        if (link != null && 
            link.Owner.SubAccountStatus == OwnerSubAccountStatusEnum.Approved)
        {
            promoter = link.Owner;
        }
    }
    
    // Se não tem promoter, owner recebe a parte
    if (promoter == null)
    {
        ownerCents += promoterCents;
        promoterCents = 0;
    }
    
    // Ajustar arredondamento
    var diff = totalCents - (platformCents + ownerCents + promoterCents);
    if (diff != 0) ownerCents += diff;
    
    // Criar order
    var order = new Order
    {
        UserId = userId,
        VideoId = dto.VideoId,
        PromoterId = promoter?.Id,
        Amount = totalCents,
        PlatformAmount = platformCents,
        OwnerAmount = ownerCents,
        PromoterAmount = promoterCents,
        CreatedAt = DateTime.UtcNow
    };
    
    await _context.Orders.AddAsync(order);
    await _context.SaveChangesAsync();
    
    // Criar invoice no Iugu com split
    var invoice = await _iuguService.CreateInvoiceWithSplitAsync(order);
    
    // Criar payment
    var payment = new Payment
    {
        OrderId = order.Id,
        IuguInvoiceId = invoice.Id,
        IuguSecureUrl = invoice.SecureUrl,
        Status = PaymentStatusEnum.Pending,
        Amount = order.Amount,
        CreatedAt = DateTime.UtcNow
    };
    
    await _context.Payments.AddAsync(payment);
    await _context.SaveChangesAsync();
    
    order.Payment = payment;
    
    return order;
}
```

## GET /api/orders/my-orders

Lista todos os pedidos do usuário logado.

**Auth**: Requerido (JWT)

**Query Parameters:**

| Parâmetro | Tipo | Descrição | Padrão |
|-----------|------|-----------|--------|
| `status` | string | Filtrar por status: `Pending`, `Paid`, `Cancelled` | - |

**Request:**
```http
GET /api/orders/my-orders?status=Paid
Authorization: Bearer {token}
```

**Response (200):**
```json
[
  {
    "orderId": 456,
    "video": {
      "id": 123,
      "title": "Vídeo Exclusivo",
      "thumbImgUrl": "https://cloudinary.com/..."
    },
    "amount": 9990,
    "payment": {
      "status": "Paid",
      "iuguPaidAt": "2025-01-15T11:00:00Z"
    },
    "promoter": {
      "id": 5,
      "name": "João Silva"
    },
    "createdAt": "2025-01-15T10:30:00Z"
  }
]
```

**Código Backend:**
```csharp
// backend-api/Endpoints/OrderEndpoints.cs
app.MapGet("/api/orders/my-orders", async (
    HttpRequest request,
    ApplicationDbContext context,
    string? status = null) =>
{
    var userId = GetUserIdFromToken(request);
    
    var query = context.Orders
        .Include(o => o.Video)
        .Include(o => o.Payment)
        .Include(o => o.Promoter)
        .ThenInclude(p => p.User)
        .Where(o => o.UserId == userId);
    
    if (!string.IsNullOrEmpty(status) && Enum.TryParse<PaymentStatusEnum>(status, out var statusEnum))
    {
        query = query.Where(o => o.Payment.Status == statusEnum);
    }
    
    var orders = await query
        .OrderByDescending(o => o.CreatedAt)
        .ToListAsync();
    
    return Results.Ok(orders.Select(o => new
    {
        OrderId = o.Id,
        Video = new
        {
            Id = o.Video.Id,
            Title = o.Video.Title,
            ThumbImgUrl = o.Video.ThumbImgUrl
        },
        Amount = o.Amount,
        Payment = new
        {
            Status = o.Payment.Status,
            IuguPaidAt = o.Payment.IuguPaidAt
        },
        Promoter = o.Promoter != null ? new
        {
            Id = o.Promoter.Id,
            Name = $"{o.Promoter.User.FirstName} {o.Promoter.User.LastName}"
        } : null,
        CreatedAt = o.CreatedAt
    }));
})
.RequireAuthorization()
.WithName("GetMyOrders");
```

## Frontend - Exemplo de Uso

```typescript
// frontend-react/src/services/api/orderApi.ts
export const orderApi = {
  create: async (data: CreateOrderDto) => {
    const response = await httpClient.post('/api/orders', data)
    return response.data
  },
  
  getMyOrders: async (status?: string) => {
    const response = await httpClient.get('/api/orders/my-orders', {
      params: { status }
    })
    return response.data
  }
}

// frontend-react/src/pages/Checkout/VideoCheckout.tsx
const VideoCheckout = () => {
  const { videoId } = useParams()
  const navigate = useNavigate()
  
  const handleCheckout = async () => {
    try {
      // Pegar affiliate code do localStorage (se houver)
      const affiliateCode = localStorage.getItem('affiliateRef')
      
      const order = await orderApi.create({
        videoId: parseInt(videoId),
        affiliateCode
      })
      
      // Remover affiliate code
      localStorage.removeItem('affiliateRef')
      
      // Redirecionar para Iugu
      window.location.href = order.payment.iuguSecureUrl
    } catch (error: any) {
      toast.error(error.response?.data?.error || 'Erro ao criar pedido')
    }
  }
  
  return (
    <div>
      <h1>Finalizar Compra</h1>
      <VideoSummary videoId={videoId} />
      <button onClick={handleCheckout}>
        Ir para Pagamento
      </button>
    </div>
  )
}
```

## Split de Valores - Exemplo

### Cenário: Vídeo R$ 100,00 com Promoter

**Config:** Platform 20% | Owner 50% | Promoter 30%

```json
{
  "amount": 10000,           // R$ 100,00
  "platformAmount": 2000,    // R$ 20,00 (20%)
  "ownerAmount": 5000,       // R$ 50,00 (50%)
  "promoterAmount": 3000     // R$ 30,00 (30%)
}
```

### Cenário: Vídeo R$ 100,00 sem Promoter

**Config:** Platform 20% | Owner 50% | Promoter 30%

```json
{
  "amount": 10000,           // R$ 100,00
  "platformAmount": 2000,    // R$ 20,00 (20%)
  "ownerAmount": 8000,       // R$ 80,00 (50% + 30%)
  "promoterAmount": 0        // R$ 0,00
}
```

## Regras de Negócio

1. **Compra única**: Usuário não pode comprar mesmo vídeo duas vezes
2. **Split calculado**: Valores já calculados no momento do order
3. **Affiliate code opcional**: Se inválido ou expirado, compra segue sem promoter
4. **KYC promoter**: Se promoter não tem KYC aprovado, link não funciona
5. **Arredondamento**: Diferença de centavos vai para owner
6. **Imutável**: Order não pode ser alterado após criado

## Próximos Passos

- [Payments](payment.md) - Webhooks e confirmação
- [Fluxo de Compra](../../../fluxos-de-negocio/compra-video.md)
- [Split de Pagamento](../../../pagamentos/split-pagamento.md)

