---
name: database-migrations
description: 跨 PostgreSQL、MySQL 和常见 ORM（Prisma、Drizzle、Kysely、Django、TypeORM、golang-migrate）的数据库迁移最佳实践，涵盖模式变更、数据迁移、回滚和零停机部署。
origin: ECC
---

# 数据库迁移模式

为生产系统提供安全、可逆的数据库模式变更。

## 何时激活

- 创建或修改数据库表
- 添加/删除列或索引
- 运行数据迁移（回填、转换）
- 规划零停机模式变更
- 为新项目设置迁移工具

## 核心原则

1. **每次变更都是一个迁移** — 绝不手动修改生产数据库
2. **生产中迁移只能向前** — 回滚使用新的前向迁移
3. **模式迁移和数据迁移分开** — 绝不在一个迁移中混合 DDL 和 DML
4. **在生产级数据上测试迁移** — 100 行上工作的迁移在 1000 万行上可能锁定
5. **迁移一旦部署就不可变** — 绝不编辑已在生产中运行的迁移

## 迁移安全检查清单

应用任何迁移之前：

- [ ] 迁移有 UP 和 DOWN（或明确标记为不可逆）
- [ ] 大表上没有全表锁定（使用并发操作）
- [ ] 新列有默认值或可为空（绝不添加没有默认值的 NOT NULL）
- [ ] 索引并发创建（对现有表不内联 CREATE TABLE）
- [ ] 数据回填是与模式变更分开的迁移
- [ ] 已在生产数据副本上测试
- [ ] 已记录回滚计划

## PostgreSQL 模式

### 安全地添加列

```sql
-- 好：可为空的列，无锁
ALTER TABLE users ADD COLUMN avatar_url TEXT;

-- 好：带默认值的列（Postgres 11+ 即时完成，无需重写）
ALTER TABLE users ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT true;

-- 差：在现有表上没有默认值的 NOT NULL（需要完全重写）
ALTER TABLE users ADD COLUMN role TEXT NOT NULL;
-- 这会锁定表并重写每一行
```

### 无停机添加索引

```sql
-- 差：在大表上阻塞写入
CREATE INDEX idx_users_email ON users (email);

-- 好：非阻塞，允许并发写入
CREATE INDEX CONCURRENTLY idx_users_email ON users (email);

-- 注意：CONCURRENTLY 不能在事务块内运行
-- 大多数迁移工具需要对此做特殊处理
```

### 重命名列（零停机）

绝不在生产中直接重命名。使用扩展-收缩模式：

```sql
-- 步骤 1：添加新列（迁移 001）
ALTER TABLE users ADD COLUMN display_name TEXT;

-- 步骤 2：回填数据（迁移 002，数据迁移）
UPDATE users SET display_name = username WHERE display_name IS NULL;

-- 步骤 3：更新应用代码同时读写两列
-- 部署应用变更

-- 步骤 4：停止写入旧列，删除它（迁移 003）
ALTER TABLE users DROP COLUMN username;
```

### 安全地删除列

```sql
-- 步骤 1：移除所有对该列的应用引用
-- 步骤 2：部署不含该列引用的应用
-- 步骤 3：在下一次迁移中删除列
ALTER TABLE orders DROP COLUMN legacy_status;

-- 对于 Django：使用 SeparateDatabaseAndState 从模型中移除
-- 而不生成 DROP COLUMN（然后在下次迁移中删除）
```

### 大型数据迁移

```sql
-- 差：在一个事务中更新所有行（锁定表）
UPDATE users SET normalized_email = LOWER(email);

-- 好：带进度的批量更新
DO $$
DECLARE
  batch_size INT := 10000;
  rows_updated INT;
BEGIN
  LOOP
    UPDATE users
    SET normalized_email = LOWER(email)
    WHERE id IN (
      SELECT id FROM users
      WHERE normalized_email IS NULL
      LIMIT batch_size
      FOR UPDATE SKIP LOCKED
    );
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    RAISE NOTICE '已更新 % 行', rows_updated;
    EXIT WHEN rows_updated = 0;
    COMMIT;
  END LOOP;
END $$;
```

## Prisma（TypeScript/Node.js）

### 工作流

```bash
# 从模式变更创建迁移
npx prisma migrate dev --name add_user_avatar

# 在生产中应用待处理的迁移
npx prisma migrate deploy

# 重置数据库（仅开发）
npx prisma migrate reset

# 模式变更后生成客户端
npx prisma generate
```

### Schema 示例

```prisma
model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String?
  avatarUrl String?  @map("avatar_url")
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")
  orders    Order[]

  @@map("users")
  @@index([email])
}
```

### 自定义 SQL 迁移

对于 Prisma 无法表达的操作（并发索引、数据回填）：

```bash
# 创建空迁移，然后手动编辑 SQL
npx prisma migrate dev --create-only --name add_email_index
```

```sql
-- migrations/20240115_add_email_index/migration.sql
-- Prisma 无法生成 CONCURRENTLY，所以手动编写
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_email ON users (email);
```

## Drizzle（TypeScript/Node.js）

### 工作流

```bash
# 从模式变更生成迁移
npx drizzle-kit generate

# 应用迁移
npx drizzle-kit migrate

# 直接推送模式（仅开发，无迁移文件）
npx drizzle-kit push
```

### Schema 示例

```typescript
import { pgTable, text, timestamp, uuid, boolean } from "drizzle-orm/pg-core";

export const users = pgTable("users", {
  id: uuid("id").primaryKey().defaultRandom(),
  email: text("email").notNull().unique(),
  name: text("name"),
  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});
```

## Kysely（TypeScript/Node.js）

### 工作流（kysely-ctl）

```bash
# 初始化配置文件（kysely.config.ts）
kysely init

# 创建新迁移文件
kysely migrate make add_user_avatar

# 应用所有待处理迁移
kysely migrate latest

# 回滚最后一次迁移
kysely migrate down

# 显示迁移状态
kysely migrate list
```

### 迁移文件

```typescript
// migrations/2024_01_15_001_create_user_profile.ts
import { type Kysely, sql } from 'kysely'

// 重要：始终使用 Kysely<any>，不要使用你类型化的 DB 接口。
// 迁移在时间上被冻结，不能依赖当前模式类型。
export async function up(db: Kysely<any>): Promise<void> {
  await db.schema
    .createTable('user_profile')
    .addColumn('id', 'serial', (col) => col.primaryKey())
    .addColumn('email', 'varchar(255)', (col) => col.notNull().unique())
    .addColumn('avatar_url', 'text')
    .addColumn('created_at', 'timestamp', (col) =>
      col.defaultTo(sql`now()`).notNull()
    )
    .execute()

  await db.schema
    .createIndex('idx_user_profile_avatar')
    .on('user_profile')
    .column('avatar_url')
    .execute()
}

export async function down(db: Kysely<any>): Promise<void> {
  await db.schema.dropTable('user_profile').execute()
}
```

### 编程式迁移器

```typescript
import { Migrator, FileMigrationProvider } from 'kysely'
import { promises as fs } from 'fs'
import * as path from 'path'
// 仅 ESM — CJS 可直接使用 __dirname
import { fileURLToPath } from 'url'
const migrationFolder = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  './migrations',
)

// `db` 是你的 Kysely<any> 数据库实例
const migrator = new Migrator({
  db,
  provider: new FileMigrationProvider({
    fs,
    path,
    migrationFolder,
  }),
  // 警告：仅在开发中启用。禁用时间戳排序验证，
  // 可能导致环境间的模式漂移。
  // allowUnorderedMigrations: true,
})

const { error, results } = await migrator.migrateToLatest()

results?.forEach((it) => {
  if (it.status === 'Success') {
    console.log(`迁移 "${it.migrationName}" 执行成功`)
  } else if (it.status === 'Error') {
    console.error(`迁移 "${it.migrationName}" 执行失败`)
  }
})

if (error) {
  console.error('迁移失败', error)
  process.exit(1)
}
```

## Django（Python）

### 工作流

```bash
# 从模型变更生成迁移
python manage.py makemigrations

# 应用迁移
python manage.py migrate

# 显示迁移状态
python manage.py showmigrations

# 为自定义 SQL 生成空迁移
python manage.py makemigrations --empty app_name -n description
```

### 数据迁移

```python
from django.db import migrations

def backfill_display_names(apps, schema_editor):
    User = apps.get_model("accounts", "User")
    batch_size = 5000
    users = User.objects.filter(display_name="")
    while users.exists():
        batch = list(users[:batch_size])
        for user in batch:
            user.display_name = user.username
        User.objects.bulk_update(batch, ["display_name"], batch_size=batch_size)

def reverse_backfill(apps, schema_editor):
    pass  # 数据迁移，无需反向操作

class Migration(migrations.Migration):
    dependencies = [("accounts", "0015_add_display_name")]

    operations = [
        migrations.RunPython(backfill_display_names, reverse_backfill),
    ]
```

### SeparateDatabaseAndState

从 Django 模型中移除列而不立即从数据库中删除：

```python
class Migration(migrations.Migration):
    operations = [
        migrations.SeparateDatabaseAndState(
            state_operations=[
                migrations.RemoveField(model_name="user", name="legacy_field"),
            ],
            database_operations=[],  # 暂不触碰数据库
        ),
    ]
```

## golang-migrate（Go）

### 工作流

```bash
# 创建迁移对
migrate create -ext sql -dir migrations -seq add_user_avatar

# 应用所有待处理迁移
migrate -path migrations -database "$DATABASE_URL" up

# 回滚最后一次迁移
migrate -path migrations -database "$DATABASE_URL" down 1

# 强制版本（修复脏状态）
migrate -path migrations -database "$DATABASE_URL" force VERSION
```

### 迁移文件

```sql
-- migrations/000003_add_user_avatar.up.sql
ALTER TABLE users ADD COLUMN avatar_url TEXT;
CREATE INDEX CONCURRENTLY idx_users_avatar ON users (avatar_url) WHERE avatar_url IS NOT NULL;

-- migrations/000003_add_user_avatar.down.sql
DROP INDEX IF EXISTS idx_users_avatar;
ALTER TABLE users DROP COLUMN IF EXISTS avatar_url;
```

## 零停机迁移策略

对于关键生产变更，遵循扩展-收缩模式：

```
阶段 1：扩展
  - 添加新列/表（可为空或有默认值）
  - 部署：应用同时写入新旧两处
  - 回填现有数据

阶段 2：迁移
  - 部署：应用从新处读取，写入新旧两处
  - 验证数据一致性

阶段 3：收缩
  - 部署：应用仅使用新的
  - 在单独的迁移中删除旧列/表
```

### 时间线示例

```
第 1 天：迁移添加 new_status 列（可为空）
第 1 天：部署应用 v2 — 同时写入 status 和 new_status
第 2 天：运行回填迁移处理现有行
第 3 天：部署应用 v3 — 仅从 new_status 读取
第 7 天：迁移删除旧 status 列
```

## 反模式

| 反模式 | 为什么会失败 | 更好的方法 |
|-------------|-------------|-----------------|
| 在生产中手动执行 SQL | 没有审计跟踪，不可重复 | 始终使用迁移文件 |
| 编辑已部署的迁移 | 导致环境间漂移 | 创建新迁移替代 |
| 没有默认值的 NOT NULL | 锁定表，重写所有行 | 先添加可为空的列，回填，然后添加约束 |
| 在大表上内联索引 | 构建期间阻塞写入 | CREATE INDEX CONCURRENTLY |
| 一个迁移中的模式 + 数据 | 难以回滚，长事务 | 分离迁移 |
| 在移除代码之前删除列 | 应用因缺少列出错 | 先移除代码，下次部署再删列 |
