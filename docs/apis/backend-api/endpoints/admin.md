# Endpoints: Admin

## Descrição

Endpoints administrativos para gerenciar a plataforma. Requerem tipo de usuário `Admin`.

## POST /api/admin/videos

Cria um novo vídeo na plataforma.

**Auth**: Requerido (Admin)

**Request:**
```http
POST /api/admin/videos
Authorization: Bearer {token}
Content-Type: multipart/form-data

{
  "title": "Vídeo Exclusivo",
  "description": "Descrição do vídeo",
  "price": 99.90,
  "videoFile": <file>,
  "releaseDate": "2025-12-01",
  "expirationSaleDate": "2025-12-31",
  "expirationViewDate": "2026-01-31"
}
```

**Response (201):**
```json
{
  "id": 123,
  "title": "Vídeo Exclusivo",
  "cloudinaryPublicId": "videos/abc123",
  "price": 99.90,
  "isActive": false,
  "createdAt": "2025-01-15T10:00:00Z"
}
```

**Código Backend:**
```csharp
// backend-api/Endpoints/AdminEndpoints.cs
app.MapPost("/api/admin/videos", async (
    HttpRequest request,
    ICloudinaryService cloudinary,
    ApplicationDbContext context) =>
{
    var form = await request.ReadFormAsync();
    var videoFile = form.Files["videoFile"];
    
    // Upload para Cloudinary
    var uploadResult = await cloudinary.UploadVideoAsync(videoFile);
    
    // Criar vídeo
    var video = new Video
    {
        Title = form["title"],
        Description = form["description"],
        CloudinaryPublicId = uploadResult.PublicId,
        DurationSeconds = uploadResult.Duration,
        ThumbImgUrl = uploadResult.ThumbnailUrl,
        Price = decimal.Parse(form["price"]),
        ReleaseDate = DateTime.Parse(form["releaseDate"]),
        ExpirationSaleDate = DateTime.Parse(form["expirationSaleDate"]),
        ExpirationViewDate = DateTime.Parse(form["expirationViewDate"]),
        IsActive = false, // Ativar após configurar comissões
        CreatedAt = DateTime.UtcNow
    };
    
    await context.Videos.AddAsync(video);
    await context.SaveChangesAsync();
    
    return Results.Created($"/api/videos/{video.Id}", video);
})
.RequireAuthorization("Admin")
.DisableAntiforgery()
.WithName("CreateVideo");
```

## POST /api/admin/videos/:id/revenue-config

Configura as comissões do vídeo.

**Auth**: Requerido (Admin)

**Request:**
```http
POST /api/admin/videos/123/revenue-config
Authorization: Bearer {token}
Content-Type: application/json

{
  "platformPercentage": 20,
  "ownerPercentage": 50,
  "promoterPercentage": 30
}
```

**Response (200):**
```json
{
  "videoId": 123,
  "platformPercentage": 20,
  "ownerPercentage": 50,
  "promoterPercentage": 30,
  "createdAt": "2025-01-15T10:05:00Z"
}
```

**Validação:**
- Soma deve ser 100%
- Todos >= 0

**Código Backend:**
```csharp
app.MapPost("/api/admin/videos/{id:long}/revenue-config", async (
    long id,
    VideoRevenueConfigDto dto,
    ApplicationDbContext context) =>
{
    // Validar soma = 100%
    if (dto.PlatformPercentage + dto.OwnerPercentage + dto.PromoterPercentage != 100)
        return Results.BadRequest("Soma deve ser 100%");
    
    var config = new VideoRevenueConfig
    {
        VideoId = id,
        PlatformPercentage = dto.PlatformPercentage,
        OwnerPercentage = dto.OwnerPercentage,
        PromoterPercentage = dto.PromoterPercentage,
        CreatedAt = DateTime.UtcNow
    };
    
    await context.VideoRevenueConfigs.AddAsync(config);
    
    // Ativar vídeo
    var video = await context.Videos.FindAsync(id);
    video.IsActive = true;
    video.UpdatedAt = DateTime.UtcNow;
    
    await context.SaveChangesAsync();
    
    return Results.Ok(config);
})
.RequireAuthorization("Admin");
```

## GET /api/admin/kyc/pending

Lista KYCs pendentes de aprovação.

**Auth**: Requerido (Admin)

**Response (200):**
```json
[
  {
    "ownerId": 5,
    "userId": 10,
    "userName": "João Silva",
    "email": "joao@example.com",
    "type": "Promoter",
    "cpf": "123.456.789-01",
    "submittedAt": "2025-01-10T14:00:00Z",
    "documents": {
      "cpfUrl": "https://cloudinary.com/cpf123",
      "rgUrl": "https://cloudinary.com/rg123",
      "addressProofUrl": "https://cloudinary.com/address123",
      "selfieUrl": "https://cloudinary.com/selfie123"
    }
  }
]
```

**Código Backend:**
```csharp
app.MapGet("/api/admin/kyc/pending", async (ApplicationDbContext context) =>
{
    var pendingKyc = await context.Owners
        .Include(o => o.User)
        .Where(o => o.SubAccountStatus == OwnerSubAccountStatusEnum.Pending)
        .OrderBy(o => o.UpdatedAt)
        .Select(o => new
        {
            OwnerId = o.Id,
            UserId = o.UserId,
            UserName = $"{o.User.FirstName} {o.User.LastName}",
            Email = o.User.Email,
            Type = o.Type,
            Cpf = o.CpfCnpj,
            SubmittedAt = o.UpdatedAt,
            Documents = new
            {
                CpfUrl = o.DocumentCpfUrl,
                RgUrl = o.DocumentRgUrl,
                AddressProofUrl = o.DocumentAddressProofUrl,
                SelfieUrl = o.DocumentSelfieUrl
            }
        })
        .ToListAsync();
    
    return Results.Ok(pendingKyc);
})
.RequireAuthorization("Admin")
.WithName("GetPendingKyc");
```

## POST /api/admin/kyc/:id/approve

Aprova o KYC de um promoter/influencer.

**Auth**: Requerido (Admin)

**Request:**
```http
POST /api/admin/kyc/5/approve
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "ownerId": 5,
  "status": "Approved",
  "approvedAt": "2025-01-15T10:30:00Z"
}
```

**Código Backend:**
```csharp
app.MapPost("/api/admin/kyc/{id:long}/approve", async (
    long id,
    AdminService service,
    HttpRequest request) =>
{
    var adminUserId = GetUserIdFromToken(request);
    
    await service.ApproveKycAsync(id, adminUserId);
    
    return Results.Ok(new
    {
        OwnerId = id,
        Status = "Approved",
        ApprovedAt = DateTime.UtcNow
    });
})
.RequireAuthorization("Admin")
.WithName("ApproveKyc");
```

## POST /api/admin/kyc/:id/reject

Rejeita o KYC com motivo.

**Auth**: Requerido (Admin)

**Request:**
```http
POST /api/admin/kyc/5/reject
Authorization: Bearer {token}
Content-Type: application/json

{
  "reason": "Documentos ilegíveis. Por favor, envie fotos mais claras."
}
```

**Response (200):**
```json
{
  "ownerId": 5,
  "status": "Rejected",
  "reason": "Documentos ilegíveis. Por favor, envie fotos mais claras.",
  "rejectedAt": "2025-01-15T10:35:00Z"
}
```

**Código Backend:**
```csharp
app.MapPost("/api/admin/kyc/{id:long}/reject", async (
    long id,
    RejectKycDto dto,
    AdminService service,
    HttpRequest request) =>
{
    var adminUserId = GetUserIdFromToken(request);
    
    await service.RejectKycAsync(id, dto.Reason, adminUserId);
    
    return Results.Ok(new
    {
        OwnerId = id,
        Status = "Rejected",
        Reason = dto.Reason,
        RejectedAt = DateTime.UtcNow
    });
})
.RequireAuthorization("Admin")
.WithName("RejectKyc");
```

## POST /api/admin/videos/:id/add-influencer

Vincula um influencer a um vídeo.

**Auth**: Requerido (Admin)

**Request:**
```http
POST /api/admin/videos/123/add-influencer
Authorization: Bearer {token}
Content-Type: application/json

{
  "influencerId": 5
}
```

**Response (200):**
```json
{
  "videoId": 123,
  "influencerId": 5,
  "createdAt": "2025-01-15T11:00:00Z"
}
```

**Código Backend:**
```csharp
app.MapPost("/api/admin/videos/{videoId:long}/add-influencer", async (
    long videoId,
    AddInfluencerDto dto,
    ApplicationDbContext context) =>
{
    // Verificar se é influencer e tem KYC aprovado
    var owner = await context.Owners
        .FirstOrDefaultAsync(o => o.Id == dto.InfluencerId &&
                                  o.Type == OwnerTypeEnum.Influencer);
    
    if (owner == null)
        return Results.BadRequest("Influencer não encontrado");
    
    if (owner.SubAccountStatus != OwnerSubAccountStatusEnum.Approved)
        return Results.BadRequest("KYC do influencer não aprovado");
    
    // Verificar se já está vinculado
    var exists = await context.OwnerVideos
        .AnyAsync(ov => ov.VideoId == videoId && ov.OwnerId == dto.InfluencerId);
    
    if (exists)
        return Results.BadRequest("Influencer já vinculado a este vídeo");
    
    var ownerVideo = new OwnerVideo
    {
        VideoId = videoId,
        OwnerId = dto.InfluencerId,
        CreatedAt = DateTime.UtcNow
    };
    
    await context.OwnerVideos.AddAsync(ownerVideo);
    await context.SaveChangesAsync();
    
    return Results.Ok(ownerVideo);
})
.RequireAuthorization("Admin");
```

## Frontend - Exemplo de Uso

```typescript
// frontend-react/src/services/api/adminApi.ts
export const adminApi = {
  getPendingKyc: async () => {
    const response = await httpClient.get('/api/admin/kyc/pending')
    return response.data
  },
  
  approveKyc: async (ownerId: number) => {
    const response = await httpClient.post(`/api/admin/kyc/${ownerId}/approve`)
    return response.data
  },
  
  rejectKyc: async (ownerId: number, reason: string) => {
    const response = await httpClient.post(`/api/admin/kyc/${ownerId}/reject`, {
      reason
    })
    return response.data
  },
  
  createVideo: async (formData: FormData) => {
    const response = await httpClient.post('/api/admin/videos', formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })
    return response.data
  }
}

// frontend-react/src/pages/Admin/KycApprovals.tsx
const KycApprovals = () => {
  const { data: pendingKyc, refetch } = useQuery({
    queryKey: ['pending-kyc'],
    queryFn: adminApi.getPendingKyc
  })
  
  const handleApprove = async (ownerId: number) => {
    if (!confirm('Aprovar este KYC?')) return
    
    await adminApi.approveKyc(ownerId)
    toast.success('KYC aprovado!')
    refetch()
  }
  
  const handleReject = async (ownerId: number) => {
    const reason = prompt('Motivo da rejeição:')
    if (!reason) return
    
    await adminApi.rejectKyc(ownerId, reason)
    toast.success('KYC rejeitado')
    refetch()
  }
  
  return (
    <Table>
      {pendingKyc?.map(kyc => (
        <tr key={kyc.ownerId}>
          <td>{kyc.userName}</td>
          <td>{kyc.type}</td>
          <td>
            <Button onClick={() => window.open(kyc.documents.cpfUrl)}>
              Ver CPF
            </Button>
            <Button onClick={() => window.open(kyc.documents.rgUrl)}>
              Ver RG
            </Button>
          </td>
          <td>
            <Button onClick={() => handleApprove(kyc.ownerId)} color="green">
              Aprovar
            </Button>
            <Button onClick={() => handleReject(kyc.ownerId)} color="red">
              Rejeitar
            </Button>
          </td>
        </tr>
      ))}
    </Table>
  )
}
```

## Regras de Negócio

1. **Apenas Admins**: Todos os endpoints requerem tipo `Admin`
2. **KYC**: Influencer/Promoter deve ter KYC aprovado para operar
3. **Revenue Config**: Soma das porcentagens deve ser 100%
4. **Promoter %**: Se 0%, vídeo não aparece para promoters gerarem links
5. **Vídeo ativo**: Só fica ativo após configurar comissões

## Próximos Passos

- [Perfil Admin](../../../perfis-de-usuario/admin.md)
- [Processo KYC](../../../pagamentos/processo-kyc.md)
- [Gestão de Vídeos](../../../fluxos-de-negocio/gestao-videos.md)

