# Endpoints: Owner

## Descrição

Endpoints para Promoters e Influencers gerenciarem seus dados como "owners" (donos de subcontas Iugu).

## POST /api/owners/kyc

Envia documentos KYC para aprovação.

**Auth**: Requerido (Promoter ou Influencer)

**Request:**
```http
POST /api/owners/kyc
Authorization: Bearer {token}
Content-Type: multipart/form-data

{
  "cpf": "12345678901",
  "rg": "123456789",
  "birthDate": "1990-01-15",
  "addressStreet": "Rua Exemplo",
  "addressNumber": "123",
  "addressComplement": "Apto 45",
  "addressNeighborhood": "Centro",
  "addressCity": "São Paulo",
  "addressState": "SP",
  "addressZipcode": "01234567",
  "bankCode": "001",
  "bankAgency": "1234",
  "bankAccount": "12345678",
  "bankAccountType": "corrente",
  "cpfFile": <file>,
  "rgFile": <file>,
  "addressProofFile": <file>,
  "selfieFile": <file>
}
```

**Response (200):**
```json
{
  "ownerId": 5,
  "iuguAccountId": "ABC123XYZ",
  "subAccountStatus": "Pending",
  "message": "Documentos enviados com sucesso! Aguarde aprovação do admin."
}
```

**Errors:**
- `400 Bad Request`: Documentos inválidos ou faltando
- `401 Unauthorized`: Token inválido

**Código Backend:**
```csharp
// backend-api/Endpoints/OwnerEndpoints.cs
app.MapPost("/api/owners/kyc", async (
    HttpRequest request,
    OwnerService service,
    ICloudinaryService cloudinary,
    IIuguService iugu) =>
{
    var userId = GetUserIdFromToken(request);
    var form = await request.ReadFormAsync();
    
    // Upload documentos para Cloudinary
    var cpfUrl = await cloudinary.UploadAsync(form.Files["cpfFile"]);
    var rgUrl = await cloudinary.UploadAsync(form.Files["rgFile"]);
    var addressProofUrl = await cloudinary.UploadAsync(form.Files["addressProofFile"]);
    var selfieUrl = await cloudinary.UploadAsync(form.Files["selfieFile"]);
    
    var dto = new SubmitKycDto
    {
        Cpf = form["cpf"],
        Rg = form["rg"],
        BirthDate = DateTime.Parse(form["birthDate"]),
        AddressStreet = form["addressStreet"],
        AddressNumber = form["addressNumber"],
        AddressComplement = form["addressComplement"],
        AddressNeighborhood = form["addressNeighborhood"],
        AddressCity = form["addressCity"],
        AddressState = form["addressState"],
        AddressZipcode = form["addressZipcode"],
        BankCode = form["bankCode"],
        BankAgency = form["bankAgency"],
        BankAccount = form["bankAccount"],
        BankAccountType = form["bankAccountType"],
        DocumentCpfUrl = cpfUrl,
        DocumentRgUrl = rgUrl,
        DocumentAddressProofUrl = addressProofUrl,
        DocumentSelfieUrl = selfieUrl
    };
    
    var owner = await service.SubmitKycAsync(userId, dto, iugu);
    
    return Results.Ok(new
    {
        OwnerId = owner.Id,
        IuguAccountId = owner.IuguAccountId,
        SubAccountStatus = owner.SubAccountStatus,
        Message = "Documentos enviados com sucesso! Aguarde aprovação do admin."
    });
})
.RequireAuthorization()
.DisableAntiforgery()
.WithName("SubmitKyc");
```

**Service:**
```csharp
// backend-api/Services/OwnerService.cs
public async Task<Owner> SubmitKycAsync(
    long userId, 
    SubmitKycDto dto, 
    IIuguService iugu)
{
    var user = await _context.Users.FindAsync(userId);
    
    // Verificar se é Promoter ou Influencer
    if (user.Type != UserTypeEnum.Promoter && 
        user.Type != UserTypeEnum.Influencer)
    {
        throw new InvalidOperationException("Apenas Promoters e Influencers podem enviar KYC");
    }
    
    var owner = await _context.Owners
        .FirstOrDefaultAsync(o => o.UserId == userId);
    
    if (owner == null)
    {
        owner = new Owner
        {
            UserId = userId,
            Type = user.Type == UserTypeEnum.Promoter 
                ? OwnerTypeEnum.Promoter 
                : OwnerTypeEnum.Influencer,
            CreatedAt = DateTime.UtcNow
        };
        
        await _context.Owners.AddAsync(owner);
        await _context.SaveChangesAsync();
    }
    
    // Atualizar dados
    owner.CpfCnpj = dto.Cpf;
    owner.Rg = dto.Rg;
    owner.BirthDate = dto.BirthDate;
    owner.AddressStreet = dto.AddressStreet;
    owner.AddressNumber = dto.AddressNumber;
    owner.AddressComplement = dto.AddressComplement;
    owner.AddressNeighborhood = dto.AddressNeighborhood;
    owner.AddressCity = dto.AddressCity;
    owner.AddressState = dto.AddressState;
    owner.AddressZipcode = dto.AddressZipcode;
    owner.BankCode = dto.BankCode;
    owner.BankAgency = dto.BankAgency;
    owner.BankAccount = dto.BankAccount;
    owner.BankAccountType = dto.BankAccountType;
    owner.DocumentCpfUrl = dto.DocumentCpfUrl;
    owner.DocumentRgUrl = dto.DocumentRgUrl;
    owner.DocumentAddressProofUrl = dto.DocumentAddressProofUrl;
    owner.DocumentSelfieUrl = dto.DocumentSelfieUrl;
    
    // Criar ou atualizar subconta Iugu
    if (string.IsNullOrEmpty(owner.IuguAccountId))
    {
        var subAccount = await iugu.CreateSubAccountAsync(owner);
        owner.IuguAccountId = subAccount.AccountId;
    }
    else
    {
        await iugu.UpdateSubAccountAsync(owner);
    }
    
    owner.SubAccountStatus = OwnerSubAccountStatusEnum.Pending;
    owner.UpdatedAt = DateTime.UtcNow;
    
    await _context.SaveChangesAsync();
    
    // Notificar admin
    await _notificationService.NotifyAdminKycPendingAsync(owner.Id);
    
    return owner;
}
```

## GET /api/owners/me

Retorna dados do owner (promoter/influencer) logado.

**Auth**: Requerido (Promoter ou Influencer)

**Request:**
```http
GET /api/owners/me
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "id": 5,
  "userId": 10,
  "type": "Promoter",
  "iuguAccountId": "ABC123XYZ",
  "subAccountStatus": "Approved",
  "cpfCnpj": "123.456.789-01",
  "bankAccount": "12345-6",
  "canOperate": true,
  "createdAt": "2025-01-10T10:00:00Z"
}
```

**Response (404):** Se usuário não é Promoter/Influencer

**Código Backend:**
```csharp
// backend-api/Endpoints/OwnerEndpoints.cs
app.MapGet("/api/owners/me", async (
    HttpRequest request,
    ApplicationDbContext context) =>
{
    var userId = GetUserIdFromToken(request);
    
    var owner = await context.Owners
        .FirstOrDefaultAsync(o => o.UserId == userId);
    
    if (owner == null)
        return Results.NotFound(new { message = "Owner not found" });
    
    return Results.Ok(new
    {
        Id = owner.Id,
        UserId = owner.UserId,
        Type = owner.Type,
        IuguAccountId = owner.IuguAccountId,
        SubAccountStatus = owner.SubAccountStatus,
        CpfCnpj = owner.CpfCnpj,
        BankAccount = $"{owner.BankAgency}-{owner.BankAccount}",
        CanOperate = owner.SubAccountStatus == OwnerSubAccountStatusEnum.Approved,
        CreatedAt = owner.CreatedAt
    });
})
.RequireAuthorization()
.WithName("GetMyOwner");
```

## Frontend - Exemplo de Uso

```typescript
// frontend-react/src/services/api/ownerApi.ts
export const ownerApi = {
  submitKyc: async (formData: FormData) => {
    const response = await httpClient.post('/api/owners/kyc', formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })
    return response.data
  },
  
  getMe: async () => {
    const response = await httpClient.get('/api/owners/me')
    return response.data
  }
}

// frontend-react/src/pages/Owner/KycSubmission.tsx
const KycSubmission = () => {
  const { register, handleSubmit } = useForm<KycForm>()
  const [isSubmitting, setIsSubmitting] = useState(false)
  
  const onSubmit = async (data: KycForm) => {
    setIsSubmitting(true)
    
    try {
      const formData = new FormData()
      
      // Dados pessoais
      formData.append('cpf', data.cpf)
      formData.append('rg', data.rg)
      formData.append('birthDate', data.birthDate)
      
      // Endereço
      formData.append('addressStreet', data.addressStreet)
      formData.append('addressNumber', data.addressNumber)
      formData.append('addressCity', data.addressCity)
      formData.append('addressState', data.addressState)
      formData.append('addressZipcode', data.addressZipcode)
      
      // Dados bancários
      formData.append('bankCode', data.bankCode)
      formData.append('bankAgency', data.bankAgency)
      formData.append('bankAccount', data.bankAccount)
      formData.append('bankAccountType', data.bankAccountType)
      
      // Documentos
      formData.append('cpfFile', data.cpfFile[0])
      formData.append('rgFile', data.rgFile[0])
      formData.append('addressProofFile', data.addressProofFile[0])
      formData.append('selfieFile', data.selfieFile[0])
      
      await ownerApi.submitKyc(formData)
      
      toast.success('Documentos enviados com sucesso! Aguarde aprovação.')
      navigate('/dashboard')
    } catch (error) {
      toast.error('Erro ao enviar documentos')
    } finally {
      setIsSubmitting(false)
    }
  }
  
  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <h1>Enviar Documentos KYC</h1>
      
      <input {...register('cpf')} placeholder="CPF" />
      <input {...register('rg')} placeholder="RG" />
      <input type="date" {...register('birthDate')} />
      
      {/* Endereço */}
      <input {...register('addressStreet')} placeholder="Rua" />
      <input {...register('addressNumber')} placeholder="Número" />
      
      {/* Dados bancários */}
      <input {...register('bankCode')} placeholder="Banco" />
      <input {...register('bankAgency')} placeholder="Agência" />
      <input {...register('bankAccount')} placeholder="Conta" />
      
      {/* Documentos */}
      <label>
        CPF (frente e verso):
        <input type="file" {...register('cpfFile')} accept="image/*,application/pdf" />
      </label>
      
      <label>
        RG (frente e verso):
        <input type="file" {...register('rgFile')} accept="image/*,application/pdf" />
      </label>
      
      <label>
        Comprovante de Endereço:
        <input type="file" {...register('addressProofFile')} accept="image/*,application/pdf" />
      </label>
      
      <label>
        Selfie com Documento:
        <input type="file" {...register('selfieFile')} accept="image/*" />
      </label>
      
      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Enviando...' : 'Enviar Documentos'}
      </button>
    </form>
  )
}
```

## Documentos Necessários

1. **CPF**: Frente e verso (imagem ou PDF)
2. **RG**: Frente e verso (imagem ou PDF)
3. **Comprovante de Endereço**: Máximo 3 meses
4. **Selfie com Documento**: Foto segurando documento

## Regras de Negócio

1. **Apenas Promoter/Influencer**: Outros tipos não podem enviar KYC
2. **Subconta Iugu**: Criada automaticamente ao enviar documentos
3. **Status Pending**: Aguarda aprovação do admin
4. **Reenvio**: Pode reenviar documentos se rejeitado
5. **Obrigatório para operar**: Sem KYC aprovado, não pode receber comissões

## Próximos Passos

- [Processo KYC](../../../pagamentos/processo-kyc.md)
- [Perfil Promoter](../../../perfis-de-usuario/promoter.md)
- [Perfil Influencer](../../../perfis-de-usuario/influencer.md)

