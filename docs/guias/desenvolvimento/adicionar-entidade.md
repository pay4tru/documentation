# Guia: Adicionar Entidade

## Passo a Passo

### 1. Criar Classe Entity

```csharp
// backend-api/Data/Entities/VideoComment.cs
public class VideoComment : Base
{
    public long VideoId { get; set; }
    public long UserId { get; set; }
    public string Comment { get; set; }
    public int Rating { get; set; } // 1-5
    
    // Navigation properties
    public Video Video { get; set; }
    public User User { get; set; }
}
```

**Base Class:**
```csharp
public abstract class Base
{
    public long Id { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
    public DateTime? DeletedAt { get; set; }
}
```

### 2. Criar Configuration

```csharp
// backend-api/Data/Configuration/VideoCommentConfiguration.cs
public class VideoCommentConfiguration : IEntityTypeConfiguration<VideoComment>
{
    public void Configure(EntityTypeBuilder<VideoComment> builder)
    {
        builder.ToTable("video_comments");
        
        builder.HasKey(x => x.Id);
        
        builder.Property(x => x.Id)
            .HasColumnName("id")
            .ValueGeneratedOnAdd();
        
        builder.Property(x => x.VideoId)
            .HasColumnName("video_id")
            .IsRequired();
        
        builder.Property(x => x.UserId)
            .HasColumnName("user_id")
            .IsRequired();
        
        builder.Property(x => x.Comment)
            .HasColumnName("comment")
            .HasMaxLength(1000)
            .IsRequired();
        
        builder.Property(x => x.Rating)
            .HasColumnName("rating")
            .IsRequired();
        
        builder.Property(x => x.IsActive)
            .HasColumnName("is_active")
            .HasDefaultValue(true);
        
        builder.Property(x => x.CreatedAt)
            .HasColumnName("created_at")
            .HasDefaultValueSql("CURRENT_TIMESTAMP");
        
        builder.Property(x => x.UpdatedAt)
            .HasColumnName("updated_at");
        
        builder.Property(x => x.DeletedAt)
            .HasColumnName("deleted_at");
        
        // Relacionamentos
        builder.HasOne(x => x.Video)
            .WithMany()
            .HasForeignKey(x => x.VideoId)
            .OnDelete(DeleteBehavior.Restrict);
        
        builder.HasOne(x => x.User)
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Restrict);
        
        // Índices
        builder.HasIndex(x => x.VideoId);
        builder.HasIndex(x => x.UserId);
        builder.HasIndex(x => new { x.VideoId, x.UserId });
        
        // Query filter para soft delete
        builder.HasQueryFilter(x => x.DeletedAt == null);
    }
}
```

### 3. Adicionar DbSet no Context

```csharp
// backend-api/Data/Context/ApplicationDbContext.cs
public class ApplicationDbContext : DbContext
{
    // ... outros DbSets
    
    public DbSet<VideoComment> VideoComments { get; set; }
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // ... outras configurações
        
        modelBuilder.ApplyConfiguration(new VideoCommentConfiguration());
    }
}
```

### 4. Criar Migration

```bash
dotnet ef migrations add AddVideoCommentsTable
```

Isso gera:

```csharp
// Migrations/YYYYMMDDHHMMSS_AddVideoCommentsTable.cs
public partial class AddVideoCommentsTable : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateTable(
            name: "video_comments",
            columns: table => new
            {
                id = table.Column<long>(type: "bigint", nullable: false)
                    .Annotation("Npgsql:ValueGenerationStrategy", 
                        NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                video_id = table.Column<long>(type: "bigint", nullable: false),
                user_id = table.Column<long>(type: "bigint", nullable: false),
                comment = table.Column<string>(type: "character varying(1000)", 
                    maxLength: 1000, nullable: false),
                rating = table.Column<int>(type: "integer", nullable: false),
                is_active = table.Column<bool>(type: "boolean", nullable: false, 
                    defaultValue: true),
                created_at = table.Column<DateTime>(type: "timestamp with time zone", 
                    nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                updated_at = table.Column<DateTime>(type: "timestamp with time zone", 
                    nullable: true),
                deleted_at = table.Column<DateTime>(type: "timestamp with time zone", 
                    nullable: true)
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
                table.ForeignKey(
                    name: "FK_video_comments_users_user_id",
                    column: x => x.user_id,
                    principalTable: "users",
                    principalColumn: "id",
                    onDelete: ReferentialAction.Restrict);
            });

        migrationBuilder.CreateIndex(
            name: "IX_video_comments_video_id",
            table: "video_comments",
            column: "video_id");

        migrationBuilder.CreateIndex(
            name: "IX_video_comments_user_id",
            table: "video_comments",
            column: "user_id");

        migrationBuilder.CreateIndex(
            name: "IX_video_comments_video_id_user_id",
            table: "video_comments",
            columns: new[] { "video_id", "user_id" });
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropTable(
            name: "video_comments");
    }
}
```

### 5. Aplicar Migration

```bash
dotnet ef database update
```

### 6. Verificar no PostgreSQL

```sql
\d video_comments

-- Listar índices
\d+ video_comments

-- Verificar constraints
SELECT conname, contype FROM pg_constraint 
WHERE conrelid = 'video_comments'::regclass;
```

## Convenções

### Nomenclatura

| Conceito | C# | PostgreSQL |
|----------|-----|------------|
| Classe | `VideoComment` | `video_comments` |
| Propriedade | `VideoId` | `video_id` |
| Enum | `UserTypeEnum` | `varchar(50)` |

### Tipos de Dados

| C# | PostgreSQL |
|----|------------|
| `long` | `bigint` |
| `int` | `integer` |
| `string` | `varchar(n)` ou `text` |
| `decimal` | `numeric(10,2)` |
| `DateTime` | `timestamp with time zone` |
| `bool` | `boolean` |

### Padrões

1. **Herdar de Base**: Todas as entidades herdam `Base`
2. **Snake case**: Nomes de tabelas e colunas em snake_case
3. **Soft delete**: Usar `DeletedAt` + Query Filter
4. **Timestamps**: `CreatedAt` obrigatório, `UpdatedAt` opcional
5. **Foreign Keys**: Sempre com `OnDelete.Restrict`
6. **Índices**: Criar para FKs e campos de busca

## Boas Práticas

✅ **Fazer:**
- Herdar de `Base`
- Usar `IEntityTypeConfiguration`
- Aplicar Query Filter para soft delete
- Criar índices para FKs
- Usar `OnDelete.Restrict`

❌ **Evitar:**
- Deletar fisicamente (usar soft delete)
- Cascade delete (usar Restrict)
- Campos sem validação
- Tabelas sem índices

## Próximos Passos

- [Criar Migration](criar-migration.md)
- [Adicionar Endpoint](adicionar-endpoint.md)
- [Padrões de Código](padroes-codigo.md)

