# Guia: Criar Migration

## Comandos Básicos

### Criar Migration

```bash
dotnet ef migrations add NomeDaMigration
```

**Exemplos:**
```bash
dotnet ef migrations add AddVideoCommentsTable
dotnet ef migrations add AddPriceColumnToVideos
dotnet ef migrations add UpdateUserEmailIndex
```

### Aplicar Migrations

```bash
# Aplicar todas pendentes
dotnet ef database update

# Aplicar até uma específica
dotnet ef database update NomeDaMigration

# Reverter todas
dotnet ef database update 0
```

### Listar Migrations

```bash
dotnet ef migrations list
```

### Remover Última Migration (não aplicada)

```bash
dotnet ef migrations remove
```

### Gerar Script SQL

```bash
# Gerar SQL de todas as migrations
dotnet ef migrations script

# Gerar SQL de uma migration específica
dotnet ef migrations script PreviousMigration TargetMigration

# Gerar SQL idempotente (com IF NOT EXISTS)
dotnet ef migrations script --idempotent
```

## Tipos de Migrations

### 1. Criar Tabela

```csharp
public partial class AddVideoCommentsTable : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateTable(
            name: "video_comments",
            columns: table => new
            {
                id = table.Column<long>(nullable: false)
                    .Annotation("Npgsql:ValueGenerationStrategy", 
                        NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                video_id = table.Column<long>(nullable: false),
                comment = table.Column<string>(maxLength: 1000, nullable: false),
                created_at = table.Column<DateTime>(nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_video_comments", x => x.id);
                table.ForeignKey(
                    name: "FK_video_comments_videos_video_id",
                    column: x => x.video_id,
                    principalTable: "videos",
                    principalColumn: "id",
                    onDelete: ReferentialAction.Restrict);
            });
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropTable(name: "video_comments");
    }
}
```

### 2. Adicionar Coluna

```csharp
public partial class AddDiscountToVideos : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<decimal>(
            name: "discount_percentage",
            table: "videos",
            type: "numeric(5,2)",
            nullable: true,
            defaultValue: 0);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropColumn(
            name: "discount_percentage",
            table: "videos");
    }
}
```

### 3. Modificar Coluna

```csharp
public partial class UpdateVideoTitleLength : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AlterColumn<string>(
            name: "title",
            table: "videos",
            type: "character varying(300)",
            maxLength: 300,
            nullable: false,
            oldClrType: typeof(string),
            oldType: "character varying(200)",
            oldMaxLength: 200);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AlterColumn<string>(
            name: "title",
            table: "videos",
            type: "character varying(200)",
            maxLength: 200,
            nullable: false,
            oldClrType: typeof(string),
            oldType: "character varying(300)",
            oldMaxLength: 300);
    }
}
```

### 4. Criar Índice

```csharp
public partial class AddEmailIndexToUsers : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateIndex(
            name: "IX_users_email",
            table: "users",
            column: "email",
            unique: true);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropIndex(
            name: "IX_users_email",
            table: "users");
    }
}
```

### 5. Migration com Dados

```csharp
public partial class SeedInitialData : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.InsertData(
            table: "users",
            columns: new[] { "email", "password_hash", "first_name", "last_name", "type" },
            values: new object[] 
            { 
                "admin@amasso.com", 
                "hashed_password_here", 
                "Admin", 
                "User", 
                "Admin" 
            });
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DeleteData(
            table: "users",
            keyColumn: "email",
            keyValue: "admin@amasso.com");
    }
}
```

### 6. Migration com SQL Customizado

```csharp
public partial class AddVideoFullTextSearch : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(@"
            ALTER TABLE videos 
            ADD COLUMN search_vector tsvector 
            GENERATED ALWAYS AS (
                to_tsvector('portuguese', coalesce(title, '') || ' ' || coalesce(description, ''))
            ) STORED;
            
            CREATE INDEX idx_videos_search_vector ON videos USING GIN (search_vector);
        ");
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(@"
            DROP INDEX idx_videos_search_vector;
            ALTER TABLE videos DROP COLUMN search_vector;
        ");
    }
}
```

## Boas Práticas

### Nomenclatura

✅ **Bom:**
- `AddVideoCommentsTable`
- `AddPriceColumnToVideos`
- `UpdateUserEmailIndex`
- `RemoveOldPaymentMethods`

❌ **Ruim:**
- `Migration1`
- `Update`
- `Fix`
- `Changes`

### Reversibilidade

Sempre implemente `Down()` para permitir rollback:

```csharp
protected override void Down(MigrationBuilder migrationBuilder)
{
    // Reverter TODAS as mudanças do Up()
    migrationBuilder.DropTable(name: "nova_tabela");
}
```

### Dados de Produção

⚠️ **Cuidado** ao:
- Remover colunas (dados serão perdidos)
- Alterar tipos (pode falhar se dados incompatíveis)
- Adicionar colunas `NOT NULL` sem default

**Solução**: Migration em 2 etapas

```csharp
// Etapa 1: Adicionar coluna nullable
protected override void Up(MigrationBuilder migrationBuilder)
{
    migrationBuilder.AddColumn<string>(
        name: "new_field",
        table: "users",
        nullable: true);
}

// Etapa 2 (próxima migration): Popular dados e tornar NOT NULL
protected override void Up(MigrationBuilder migrationBuilder)
{
    migrationBuilder.Sql("UPDATE users SET new_field = 'default' WHERE new_field IS NULL");
    
    migrationBuilder.AlterColumn<string>(
        name: "new_field",
        table: "users",
        nullable: false);
}
```

## Troubleshooting

### Erro: Migration pendente

```bash
dotnet ef migrations list
dotnet ef database update
```

### Erro: Conflito de migration

```bash
# Listar migrations aplicadas
dotnet ef migrations list

# Reverter para migration anterior
dotnet ef database update PreviousMigration

# Remover migration conflitante
dotnet ef migrations remove

# Recriar migration
dotnet ef migrations add FixedMigration
```

### Erro: Cannot drop column (FK constraint)

```csharp
// 1. Remover FK primeiro
migrationBuilder.DropForeignKey("FK_orders_videos", "orders");

// 2. Remover coluna
migrationBuilder.DropColumn("video_id", "orders");
```

## Ambientes

### Desenvolvimento

```bash
dotnet ef database update
```

### Staging/Produção

```bash
# Gerar script SQL
dotnet ef migrations script --idempotent --output migrations.sql

# Executar via psql
psql -h host -U user -d database -f migrations.sql
```

## Próximos Passos

- [Adicionar Entidade](adicionar-entidade.md)
- [Adicionar Endpoint](adicionar-endpoint.md)
- [Banco de Dados](../../banco-de-dados/visao-geral.md)

