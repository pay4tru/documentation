# Endpoints: User

## Descrição

Endpoints relacionados ao perfil do usuário logado.

## GET /api/users/me

Retorna o perfil do usuário autenticado.

**Auth**: Requerido (JWT)

**Request:**
```http
GET /api/users/me
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "id": 1,
  "email": "user@example.com",
  "firstName": "João",
  "lastName": "Silva",
  "type": "Default",
  "cpf": "12345678901",
  "birthDate": "1990-01-15",
  "telephone": "11987654321",
  "notificationPreference": "All",
  "isActive": true,
  "createdAt": "2025-01-01T10:00:00Z"
}
```

**Exemplo cURL:**
```bash
curl -X GET http://localhost:7080/api/users/me \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**Código Backend:**
```csharp
// backend-api/Endpoints/UserEndpoints.cs
app.MapGet("/api/users/me", async (
    HttpRequest request,
    ApplicationDbContext context) =>
{
    var userId = GetUserIdFromToken(request);
    
    var user = await context.Users
        .FirstOrDefaultAsync(u => u.Id == userId);
    
    if (user == null)
        return Results.NotFound();
    
    return Results.Ok(new UserDto
    {
        Id = user.Id,
        Email = user.Email,
        FirstName = user.FirstName,
        LastName = user.LastName,
        Type = user.Type,
        Cpf = user.Cpf,
        BirthDate = user.BirthDate,
        Telephone = user.Telephone,
        NotificationPreference = user.NotificationPreference,
        IsActive = user.IsActive,
        CreatedAt = user.CreatedAt
    });
})
.RequireAuthorization()
.WithName("GetMyProfile");
```

## PUT /api/users/me

Atualiza o perfil do usuário autenticado.

**Auth**: Requerido (JWT)

**Request:**
```http
PUT /api/users/me
Authorization: Bearer {token}
Content-Type: application/json

{
  "firstName": "João",
  "lastName": "Silva",
  "telephone": "11987654321",
  "notificationPreference": "Email"
}
```

**Response (200):**
```json
{
  "id": 1,
  "email": "user@example.com",
  "firstName": "João",
  "lastName": "Silva",
  "telephone": "11987654321",
  "notificationPreference": "Email",
  "updatedAt": "2025-01-15T14:30:00Z"
}
```

**Errors:**
- `400 Bad Request`: Dados inválidos
- `401 Unauthorized`: Token inválido
- `404 Not Found`: Usuário não encontrado

**Exemplo cURL:**
```bash
curl -X PUT http://localhost:7080/api/users/me \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "João",
    "lastName": "Silva",
    "telephone": "11987654321",
    "notificationPreference": "Email"
  }'
```

**Código Backend:**
```csharp
// backend-api/Endpoints/UserEndpoints.cs
app.MapPut("/api/users/me", async (
    UpdateUserDto dto,
    HttpRequest request,
    ApplicationDbContext context) =>
{
    var userId = GetUserIdFromToken(request);
    
    var user = await context.Users.FindAsync(userId);
    
    if (user == null)
        return Results.NotFound();
    
    user.FirstName = dto.FirstName;
    user.LastName = dto.LastName;
    user.Telephone = dto.Telephone;
    user.NotificationPreference = dto.NotificationPreference;
    user.UpdatedAt = DateTime.UtcNow;
    
    await context.SaveChangesAsync();
    
    return Results.Ok(new UserDto
    {
        Id = user.Id,
        Email = user.Email,
        FirstName = user.FirstName,
        LastName = user.LastName,
        Telephone = user.Telephone,
        NotificationPreference = user.NotificationPreference,
        UpdatedAt = user.UpdatedAt
    });
})
.RequireAuthorization()
.WithName("UpdateMyProfile");
```

**DTO:**
```csharp
// backend-api/Data/Dtos/UpdateUserDto.cs
public record UpdateUserDto
{
    public string FirstName { get; init; }
    public string LastName { get; init; }
    public string? Telephone { get; init; }
    public NotificationChannelEnum? NotificationPreference { get; init; }
}
```

## Frontend - Exemplo de Uso

```typescript
// frontend-react/src/services/api/userApi.ts
export const userApi = {
  getMe: async () => {
    const response = await httpClient.get('/api/users/me')
    return response.data
  },
  
  updateMe: async (data: UpdateUserDto) => {
    const response = await httpClient.put('/api/users/me', data)
    return response.data
  }
}

// frontend-react/src/pages/Profile/EditProfile.tsx
const EditProfile = () => {
  const { data: user } = useQuery({
    queryKey: ['user-profile'],
    queryFn: userApi.getMe
  })
  
  const { register, handleSubmit } = useForm<UpdateUserDto>({
    defaultValues: user
  })
  
  const onSubmit = async (data: UpdateUserDto) => {
    await userApi.updateMe(data)
    toast.success('Perfil atualizado!')
  }
  
  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('firstName')} />
      <input {...register('lastName')} />
      <input {...register('telephone')} />
      <select {...register('notificationPreference')}>
        <option value="Email">Email</option>
        <option value="WhatsApp">WhatsApp</option>
        <option value="All">Ambos</option>
      </select>
      <button type="submit">Salvar</button>
    </form>
  )
}
```

## Regras de Negócio

1. **Email**: Não pode ser alterado via este endpoint
2. **Type**: Não pode ser alterado (definido no cadastro)
3. **NotificationPreference**: Opcional (null = sem preferência)
4. **Telephone**: Formato: DDD + número (10-11 dígitos)

## Próximos Passos

- [Autenticação](../autenticacao.md)
- [Perfis de Usuário](../../../perfis-de-usuario/default.md)

