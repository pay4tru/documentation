# Guia: Adicionar Endpoint

## Passo a Passo

### 1. Criar DTO (Data Transfer Object)

```csharp
// backend-api/Data/Dtos/CreateVideoDto.cs
public record CreateVideoDto
{
    public string Title { get; init; }
    public string Description { get; init; }
    public decimal Price { get; init; }
    public DateTime? ReleaseDate { get; init; }
}
```

### 2. Criar Validador (Opcional)

```csharp
// backend-api/Data/Validations/CreateVideoDtoValidator.cs
public class CreateVideoDtoValidator : AbstractValidator<CreateVideoDto>
{
    public CreateVideoDtoValidator()
    {
        RuleFor(x => x.Title).NotEmpty().MaximumLength(200);
        RuleFor(x => x.Price).GreaterThan(0);
    }
}
```

### 3. Criar Serviço

```csharp
// backend-api/Services/VideoService.cs
public class VideoService
{
    private readonly ApplicationDbContext _context;
    
    public async Task<Video> CreateVideoAsync(CreateVideoDto dto)
    {
        var video = new Video
        {
            Title = dto.Title,
            Description = dto.Description,
            Price = dto.Price,
            ReleaseDate = dto.ReleaseDate,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };
        
        await _context.Videos.AddAsync(video);
        await _context.SaveChangesAsync();
        
        return video;
    }
}
```

### 4. Criar Endpoint

```csharp
// backend-api/Endpoints/VideoEndpoints.cs
public static class VideoEndpoints
{
    public static void MapVideoEndpoints(this WebApplication app)
    {
        // Criar vídeo
        app.MapPost("/api/videos", async (
            CreateVideoDto dto,
            VideoService service) =>
        {
            var video = await service.CreateVideoAsync(dto);
            return Results.Created($"/api/videos/{video.Id}", video);
        })
        .RequireAuthorization("Admin")
        .WithName("CreateVideo")
        .WithOpenApi();
        
        // Listar vídeos
        app.MapGet("/api/videos", async (
            ApplicationDbContext context,
            int page = 1,
            int perPage = 20) =>
        {
            var videos = await context.Videos
                .Where(v => v.IsActive)
                .OrderByDescending(v => v.CreatedAt)
                .Skip((page - 1) * perPage)
                .Take(perPage)
                .ToListAsync();
            
            return Results.Ok(videos);
        })
        .AllowAnonymous()
        .WithName("ListVideos")
        .WithOpenApi();
    }
}
```

### 5. Registrar no Program.cs

```csharp
// backend-api/Program.cs

// Registrar serviço
builder.Services.AddScoped<VideoService>();

// ... após app build

// Registrar endpoints
app.MapVideoEndpoints();
```

### 6. Frontend - Criar Serviço de API

```typescript
// frontend-react/src/services/api/videoApi.ts
import { httpClient } from '../httpClient'

export interface CreateVideoDto {
  title: string
  description: string
  price: number
  releaseDate?: string
}

export const videoApi = {
  create: async (data: CreateVideoDto) => {
    const response = await httpClient.post('/api/videos', data)
    return response.data
  },
  
  getAll: async (page = 1, perPage = 20) => {
    const response = await httpClient.get('/api/videos', {
      params: { page, perPage }
    })
    return response.data
  },
  
  getById: async (id: number) => {
    const response = await httpClient.get(`/api/videos/${id}`)
    return response.data
  }
}
```

### 7. Frontend - Usar no Componente

```typescript
// frontend-react/src/pages/Videos/CreateVideo.tsx
import { useForm } from 'react-hook-form'
import { videoApi } from '@/services/api/videoApi'

export const CreateVideo = () => {
  const { register, handleSubmit } = useForm<CreateVideoDto>()
  const navigate = useNavigate()
  
  const onSubmit = async (data: CreateVideoDto) => {
    try {
      const video = await videoApi.create(data)
      toast.success('Vídeo criado!')
      navigate(`/videos/${video.id}`)
    } catch (error) {
      toast.error('Erro ao criar vídeo')
    }
  }
  
  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('title')} placeholder="Título" />
      <input {...register('description')} placeholder="Descrição" />
      <input type="number" {...register('price')} placeholder="Preço" />
      <button type="submit">Criar</button>
    </form>
  )
}
```

## Testes

### Backend - Testar com cURL

```bash
# Obter token
TOKEN=$(curl -s -X POST http://localhost:7080/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@amasso.com","password":"Admin@123"}' \
  | jq -r '.token')

# Criar vídeo
curl -X POST http://localhost:7080/api/videos \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Novo Vídeo",
    "description": "Descrição",
    "price": 50.00
  }'
```

### Frontend - Testar no navegador

```javascript
// Console do navegador
const videoApi = window.videoApi || await import('/src/services/api/videoApi')

await videoApi.create({
  title: 'Teste',
  description: 'Descrição',
  price: 100
})
```

## Boas Práticas

1. **DTOs**: Use para entrada/saída de dados
2. **Validação**: Sempre valide entrada
3. **Autorização**: Use `.RequireAuthorization()` quando necessário
4. **Async/Await**: Use operações assíncronas
5. **Try/Catch**: Trate erros adequadamente
6. **Status Codes**: Retorne códigos HTTP corretos
7. **OpenAPI**: Use `.WithOpenApi()` para documentação automática

## Próximos Passos

- [Adicionar Entidade](adicionar-entidade.md)
- [Criar Migration](criar-migration.md)
- [Padrões de Código](padroes-codigo.md)

