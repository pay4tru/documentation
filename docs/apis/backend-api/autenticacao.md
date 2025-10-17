# Backend API - Autenticação

## Endpoints

### POST /api/signup

Cria uma nova conta de usuário.

**Request:**
```http
POST /api/signup
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "Senha@123",
  "firstName": "João",
  "lastName": "Silva",
  "cpf": "12345678901",
  "birthDate": "1990-01-15",
  "telephone": "11987654321",
  "type": "Default"
}
```

**Response (200):**
```json
{
  "message": "Cadastro realizado! Verifique seu email."
}
```

**Errors:**
- `400`: Email já cadastrado
- `400`: CPF inválido
- `400`: Menor de 18 anos

### POST /api/signup/activate

Ativa a conta do usuário com código recebido por email.

**Request:**
```http
POST /api/signup/activate
Content-Type: application/json

{
  "email": "user@example.com",
  "code": "123456"
}
```

**Response (200):**
```json
{
  "message": "Conta ativada com sucesso!"
}
```

### POST /api/login

Autentica um usuário e retorna JWT token.

**Request:**
```http
POST /api/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "Senha@123"
}
```

**Response (200) - Sem MFA:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "firstName": "João",
    "lastName": "Silva",
    "type": "Default"
  }
}
```

**Response (200) - Com MFA:**
```json
{
  "requireMfa": true,
  "message": "Código MFA enviado para seu email"
}
```

### POST /api/login/verify-mfa

Verifica código MFA e retorna token.

**Request:**
```http
POST /api/login/verify-mfa
Content-Type: application/json

{
  "email": "user@example.com",
  "code": "123456"
}
```

**Response (200):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": { ... }
}
```

### POST /api/forgot-password

Inicia processo de recuperação de senha.

**Request:**
```http
POST /api/forgot-password
Content-Type: application/json

{
  "email": "user@example.com"
}
```

**Response (200):**
```json
{
  "message": "Código enviado para seu email"
}
```

### POST /api/reset-password

Redefine a senha com código recebido.

**Request:**
```http
POST /api/reset-password
Content-Type: application/json

{
  "email": "user@example.com",
  "code": "123456",
  "newPassword": "NovaSenha@123"
}
```

**Response (200):**
```json
{
  "message": "Senha alterada com sucesso!"
}
```

## Exemplos com cURL

### Cadastro
```bash
curl -X POST http://localhost:7080/api/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Senha@123",
    "firstName": "Teste",
    "lastName": "Usuario",
    "cpf": "12345678901",
    "birthDate": "1990-01-01",
    "telephone": "11999999999",
    "type": "Default"
  }'
```

### Login
```bash
curl -X POST http://localhost:7080/api/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Senha@123"
  }'
```

## Segurança

- Senhas com hash bcrypt
- JWT com expiração de 24h
- Rate limiting (5 tentativas/15min)
- Códigos MFA expiram em 5 minutos
- Códigos de ativação expiram em 24 horas

