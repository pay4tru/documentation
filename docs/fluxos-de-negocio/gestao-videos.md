# Fluxo: Gestão de Vídeos

## Descrição

Administradores gerenciam o catálogo de vídeos: upload, configuração de preços e comissões, vinculação com influencers e publicação.

## Diagrama de Processo

```mermaid
flowchart TD
    A[Admin acessa dashboard] --> B[Clica "Novo Vídeo"]
    B --> C[Preenche formulário]
    C --> D[Upload de vídeo para Cloudinary]
    D --> E[Salvar vídeo no banco]
    E --> F[Configurar VideoRevenueConfig]
    F --> G{Promoter % > 0?}
    G -->|Sim| H[Vídeo aparece para promoters]
    G -->|Não| I[Vídeo NÃO aparece para promoters]
    H --> J[Vincular influencers]
    I --> J
    J --> K[Definir datas]
    K --> L[Publicar vídeo]
    L --> M[Vídeo disponível para venda]
```

## Upload para Cloudinary

### Frontend

```typescript
const handleVideoUpload = async (file: File) => {
  const formData = new FormData();
  formData.append("video", file);
  formData.append("title", videoTitle);
  formData.append("description", description);
  formData.append("price", price.toString());
  
  const response = await adminApi.uploadVideo(formData);
  return response.data;
};
```

### Backend

```csharp
app.MapPost("/api/admin/videos/upload", async (
    HttpRequest request,
    ICloudinaryService cloudinary,
    ApplicationDbContext context) =>
{
    var form = await request.ReadFormAsync();
    var videoFile = form.Files["video"];
    
    // Upload para Cloudinary
    var uploadParams = new VideoUploadParams
    {
        File = new FileDescription(videoFile.FileName, videoFile.OpenReadStream()),
        PublicId = $"videos/{Guid.NewGuid()}",
        ResourceType = ResourceType.Video,
        Folder = "amasso-videos",
        Overwrite = false
    };
    
    var result = await cloudinary.UploadVideoAsync(uploadParams);
    
    // Criar vídeo no banco
    var video = new Video
    {
        Title = form["title"],
        Description = form["description"],
        CloudinaryPublicId = result.PublicId,
        DurationSeconds = result.Duration,
        ThumbImgUrl = result.SecureUrl.Replace("/upload/", "/upload/c_thumb,w_300/"),
        Price = decimal.Parse(form["price"]),
        IsActive = false, // Inativo até configurar comissões
        CreatedAt = DateTime.UtcNow
    };
    
    await context.Videos.AddAsync(video);
    await context.SaveChangesAsync();
    
    return Results.Ok(video);
})
.RequireAuthorization("Admin")
.DisableAntiforgery();
```

## Configuração de Comissões

```typescript
const handleConfigureRevenue = async (videoId: number, config: RevenueConfig) => {
  await adminApi.configureVideoRevenue(videoId, {
    platformPercentage: config.platformPercentage,
    ownerPercentage: config.ownerPercentage,
    promoterPercentage: config.promoterPercentage
  });
};

// Validação: soma deve ser 100%
const total = platformPercentage + ownerPercentage + promoterPercentage;
if (total !== 100) {
  toast.error("A soma das porcentagens deve ser 100%");
  return;
}
```

```csharp
app.MapPost("/api/admin/videos/{videoId:long}/revenue-config", async (
    long videoId,
    VideoRevenueConfigDto dto,
    ApplicationDbContext context) =>
{
    // Validar soma = 100%
    if (dto.PlatformPercentage + dto.OwnerPercentage + dto.PromoterPercentage != 100)
        return Results.BadRequest("Soma deve ser 100%");
    
    // Criar ou atualizar config
    var config = await context.VideoRevenueConfigs
        .FirstOrDefaultAsync(c => c.VideoId == videoId);
    
    if (config == null)
    {
        config = new VideoRevenueConfig
        {
            VideoId = videoId,
            PlatformPercentage = dto.PlatformPercentage,
            OwnerPercentage = dto.OwnerPercentage,
            PromoterPercentage = dto.PromoterPercentage,
            CreatedAt = DateTime.UtcNow
        };
        await context.VideoRevenueConfigs.AddAsync(config);
    }
    else
    {
        config.PlatformPercentage = dto.PlatformPercentage;
        config.OwnerPercentage = dto.OwnerPercentage;
        config.PromoterPercentage = dto.PromoterPercentage;
        config.UpdatedAt = DateTime.UtcNow;
    }
    
    await context.SaveChangesAsync();
    
    return Results.Ok(config);
})
.RequireAuthorization("Admin");
```

## Vinculação com Influencers

```typescript
const handleAddInfluencer = async (videoId: number, influencerId: number) => {
  await adminApi.addInfluencerToVideo(videoId, { influencerId });
  toast.success("Influencer adicionado!");
};
```

```csharp
app.MapPost("/api/admin/videos/{videoId:long}/add-influencer", async (
    long videoId,
    AddInfluencerDto dto,
    ApplicationDbContext context) =>
{
    var owner = await context.Owners
        .FirstOrDefaultAsync(o => o.Id == dto.InfluencerId &&
                                  o.Type == OwnerTypeEnum.Influencer);
    
    if (owner == null)
        return Results.BadRequest("Influencer não encontrado");
    
    if (owner.SubAccountStatus != OwnerSubAccountStatusEnum.Approved)
        return Results.BadRequest("KYC do influencer não aprovado");
    
    var ownerVideo = new OwnerVideo
    {
        VideoId = videoId,
        OwnerId = dto.InfluencerId,
        CreatedAt = DateTime.UtcNow
    };
    
    await context.OwnerVideos.AddAsync(ownerVideo);
    await context.SaveChangesAsync();
    
    return Results.Ok();
})
.RequireAuthorization("Admin");
```

## Datas de Publicação

```typescript
const dateConfig = {
  releaseDate: "2025-12-01", // Lançamento
  expirationSaleDate: "2025-12-31", // Fim das vendas
  expirationViewDate: "2026-01-31" // Fim da visualização
};

await adminApi.updateVideo(videoId, dateConfig);
```

- **ReleaseDate**: Vídeo só aparece no catálogo após esta data
- **ExpirationSaleDate**: Até esta data pode ser comprado
- **ExpirationViewDate**: Até esta data pode ser assistido (por quem comprou)

## Regra: Promoter % = 0%

```csharp
// Endpoint para listar vídeos disponíveis para promoters
app.MapGet("/api/videos/for-promoters", async (ApplicationDbContext context) =>
{
    var videos = await context.Videos
        .Include(v => v.VideoRevenueConfig)
        .Where(v => v.IsActive &&
                    v.VideoRevenueConfig.PromoterPercentage > 0 && // <--- Filtro
                    (v.ReleaseDate == null || v.ReleaseDate <= DateTime.Today) &&
                    (v.ExpirationSaleDate == null || v.ExpirationSaleDate >= DateTime.Today))
        .ToListAsync();
    
    return Results.Ok(videos);
});
```

Se `promoter_percentage = 0%`, o vídeo **não aparece** na lista de vídeos disponíveis para promoters gerarem links de afiliado.

## Fluxo Completo no Admin

```typescript
const handleCreateVideo = async (data: VideoForm) => {
  // 1. Upload do vídeo
  const video = await adminApi.uploadVideo(data.videoFile, data);
  
  // 2. Configurar comissões
  await adminApi.configureVideoRevenue(video.id, {
    platformPercentage: 20,
    ownerPercentage: 50,
    promoterPercentage: 30
  });
  
  // 3. Adicionar influencers
  for (const influencerId of data.influencerIds) {
    await adminApi.addInfluencerToVideo(video.id, { influencerId });
  }
  
  // 4. Definir datas
  await adminApi.updateVideo(video.id, {
    releaseDate: data.releaseDate,
    expirationSaleDate: data.expirationSaleDate,
    expirationViewDate: data.expirationViewDate
  });
  
  // 5. Ativar vídeo
  await adminApi.updateVideo(video.id, { isActive: true });
  
  toast.success("Vídeo publicado com sucesso!");
};
```

## Validações

- **Título**: Mínimo 3 caracteres
- **Preço**: Maior que 0
- **VideoRevenueConfig**: Soma = 100%
- **Influencer**: Deve ter KYC aprovado
- **CloudinaryPublicId**: Obrigatório
- **Datas**: ExpirationSaleDate >= ReleaseDate

## Próximos Passos

- Veja [Perfil Admin](../perfis-de-usuario/admin.md)
- Consulte [Comissões](comissoes.md)
- Entenda [Banco: Videos](../banco-de-dados/tabelas/videos.md)

