# Fluxo: Comissões

## Descrição

Sistema de cálculo e distribuição de comissões entre Plataforma, Influencers e Promoters, configurado por vídeo através da tabela `video_revenue_configs`.

## Modelo de Comissões

### Configuração por Vídeo

Cada vídeo tem uma configuração específica de distribuição de receita:

```
video_revenue_configs
- video_id
- platform_percentage (ex: 20%)
- owner_percentage (ex: 50%)
- promoter_percentage (ex: 30%)
```

**Regra**: `platform_percentage + owner_percentage + promoter_percentage = 100%`

## Cenários

### Cenário 1: Venda com Promoter

**Vídeo**: R$ 100,00  
**Config**: Plataforma 20% | Influencer 50% | Promoter 30%

```
Plataforma: R$ 20,00 (income com owner_id = NULL)
Influencer: R$ 50,00 (income com owner_id = influencer_id, type = Owner)
Promoter:   R$ 30,00 (income com owner_id = promoter_id, type = Promoter)
```

### Cenário 2: Venda sem Promoter

**Vídeo**: R$ 100,00  
**Config**: Plataforma 20% | Influencer 50% | Promoter 30%

```
Plataforma: R$ 20,00 (income com owner_id = NULL)
Influencer: R$ 80,00 (income com owner_id = influencer_id, type = Owner)
           [recebe sua parte + a parte do promoter]
```

### Cenário 3: Promoter % = 0%

**Vídeo**: R$ 100,00  
**Config**: Plataforma 30% | Influencer 70% | Promoter 0%

- Vídeo **NÃO aparece** para promoters gerarem links
- Apenas vendas diretas
- Influencer recebe 70% sempre

```
Plataforma: R$ 30,00
Influencer: R$ 70,00
```

## Cálculo no Backend

```csharp
public async Task<Order> CreateOrderAsync(CreateOrderDto dto, long userId)
{
    var video = await _context.Videos
        .Include(v => v.VideoRevenueConfig)
        .Include(v => v.OwnerVideos)
        .ThenInclude(ov => ov.Owner)
        .FirstAsync(v => v.Id == dto.VideoId);
    
    var config = video.VideoRevenueConfig;
    var totalCents = (int)(video.Price * 100);
    
    // Calcular valores base
    var platformCents = (int)(totalCents * config.PlatformPercentage / 100);
    var ownerCents = (int)(totalCents * config.OwnerPercentage / 100);
    var promoterCents = (int)(totalCents * config.PromoterPercentage / 100);
    
    // Se tem promoter (via link afiliado)
    Owner? promoter = null;
    if (!string.IsNullOrEmpty(dto.AffiliateCode))
    {
        var link = await _context.VideoAffiliateLinks
            .Include(l => l.Owner)
            .FirstOrDefaultAsync(l => l.UniqueCode == dto.AffiliateCode &&
                                      l.VideoId == dto.VideoId);
        
        if (link != null && 
            link.Owner.SubAccountStatus == OwnerSubAccountStatusEnum.Approved &&
            config.PromoterPercentage > 0)
        {
            promoter = link.Owner;
        }
    }
    
    // Se NÃO tem promoter, owner recebe a parte do promoter
    if (promoter == null)
    {
        ownerCents += promoterCents;
        promoterCents = 0;
    }
    
    // Ajustar arredondamento (diferença vai pro owner)
    var totalCalculated = platformCents + ownerCents + promoterCents;
    if (totalCalculated != totalCents)
    {
        ownerCents += (totalCents - totalCalculated);
    }
    
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
    
    return order;
}
```

## Criação de Incomes

Após webhook confirmar pagamento:

```csharp
public async Task CreateIncomesForOrderAsync(long orderId)
{
    var order = await _context.Orders
        .Include(o => o.Video)
        .ThenInclude(v => v.OwnerVideos)
        .ThenInclude(ov => ov.Owner)
        .FirstAsync(o => o.Id == orderId);
    
    var incomes = new List<Income>();
    
    // 1. Plataforma
    incomes.Add(new Income
    {
        OrderId = order.Id,
        OwnerId = null, // NULL = plataforma
        Amount = order.PlatformAmount,
        Type = IncomeTypeEnum.Platform,
        Description = "Comissão da plataforma",
        CreatedAt = DateTime.UtcNow
    });
    
    // 2. Owner/Influencer
    var owner = order.Video.OwnerVideos.First().Owner;
    incomes.Add(new Income
    {
        OrderId = order.Id,
        OwnerId = owner.Id,
        Amount = order.OwnerAmount,
        Type = IncomeTypeEnum.Owner,
        Description = $"Venda do vídeo: {order.Video.Title}",
        CreatedAt = DateTime.UtcNow
    });
    
    // 3. Promoter (se houver)
    if (order.PromoterId.HasValue && order.PromoterAmount > 0)
    {
        incomes.Add(new Income
        {
            OrderId = order.Id,
            OwnerId = order.PromoterId.Value,
            Amount = order.PromoterAmount,
            Type = IncomeTypeEnum.Promoter,
            Description = $"Comissão por divulgação: {order.Video.Title}",
            CreatedAt = DateTime.UtcNow
        });
    }
    
    await _context.Incomes.AddRangeAsync(incomes);
    await _context.SaveChangesAsync();
}
```

## Split no Iugu

O valor já é dividido no momento da criação da invoice:

```csharp
var splits = new List<IuguSplitRule>();

// Owner
splits.Add(new IuguSplitRule
{
    ReceiverAccountId = owner.IuguAccountId,
    AmountCents = order.OwnerAmount
});

// Promoter (se houver)
if (order.PromoterId.HasValue)
{
    splits.Add(new IuguSplitRule
    {
        ReceiverAccountId = promoter.IuguAccountId,
        AmountCents = order.PromoterAmount
    });
}

// Plataforma recebe o resto automaticamente
var invoice = await _iuguService.CreateInvoiceAsync(new
{
    Email = user.Email,
    Items = new[] { new { Description = video.Title, PriceCents = order.Amount } },
    Splits = splits
});
```

## Relatórios

### Comissões da Plataforma

```sql
SELECT 
    SUM(amount) / 100.0 as total_comissao,
    COUNT(*) as total_vendas
FROM incomes
WHERE owner_id IS NULL;
```

### Comissões de um Influencer

```sql
SELECT 
    v.title,
    COUNT(i.id) as vendas,
    SUM(i.amount) / 100.0 as total_comissao
FROM incomes i
INNER JOIN orders o ON o.id = i.order_id
INNER JOIN videos v ON v.id = o.video_id
WHERE i.owner_id = 123
  AND i.type = 'Owner'
GROUP BY v.id, v.title
ORDER BY total_comissao DESC;
```

### Comissões de um Promoter

```sql
SELECT 
    v.title,
    COUNT(i.id) as conversoes,
    SUM(i.amount) / 100.0 as total_comissao
FROM incomes i
INNER JOIN orders o ON o.id = i.order_id
INNER JOIN videos v ON v.id = o.video_id
WHERE i.owner_id = 456
  AND i.type = 'Promoter'
GROUP BY v.id, v.title
ORDER BY total_comissao DESC;
```

## Validações

- **Soma = 100%**: Platform + Owner + Promoter = 100
- **Values > 0**: Todos os percentuais >= 0
- **Arredondamento**: Diferença de centavos vai para owner
- **KYC aprovado**: Promoter/Influencer devem ter KYC aprovado para receber

## Próximos Passos

- Veja [Split de Pagamento](../pagamentos/split-pagamento.md)
- Consulte [Tabela Income](../banco-de-dados/tabelas/income.md)
- Entenda [Gestão de Vídeos](gestao-videos.md)

