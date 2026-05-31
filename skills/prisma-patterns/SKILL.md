---
name: prisma-patterns
description: TypeScript 后端的 Prisma ORM 模式 —— 模式设计、查询优化、事务、分页以及关键陷阱，如 updateMany 返回计数而非记录、$transaction 超时、migrate dev 重置数据库、@updatedAt 在批量写入时跳过、以及无服务器连接耗尽。
origin: ECC
---

# Prisma 模式

TypeScript 后端中 Prisma ORM 的生产模式和不易察觉的陷阱。
针对 Prisma 5.x 和 6.x 测试。某些行为与 Prisma 4 不同。

在应用版本特定模式之前检查 Prisma 版本：

```bash
npx prisma --version
```

Prisma 5 引入了 `relationJoins`，可以根据查询策略和配置通过 JOIN 而非单独查询加载关系。还添加了 `omit` 字段修饰符和 `prisma.$extends` Client Extensions API。注意：`relationJoins` 在大型 1:N 关系或深度嵌套的 `include` 上可能导致行爆炸 —— 当每个父行的关系可能返回多行时，对两种方法进行基准测试。

## 何时激活

- 设计或修改 Prisma 模式模型和关系
- 编写查询、事务或分页逻辑
- 使用 `updateMany`、`deleteMany` 或任何批量操作
- 运行或规划数据库迁移
- 部署到无服务器环境（Vercel、Lambda、Cloudflare Workers）
- 实现软删除或多租户行过滤

## 核心概念

### ID 策略

| 策略 | 何时使用 | 何时避免 |
|---|---|---|
| `@default(cuid())` | 默认选择 —— URL 安全、可排序、无冲突 | 外部系统需要顺序 ID |
| `@default(uuid())` | 需要与非 Prisma 系统互操作 | 高写入表（随机 UUID 使 B-tree 索引碎片化） |
| `@default(autoincrement())` | 内部连接表、审计日志 | 面向公众的 ID（暴露记录数量） |

### 模式默认值

```prisma
model User {
  id        String    @id @default(cuid())
  email     String    @unique  // @unique 已创建索引 —— 不需要 @@index
  name      String
  role      Role      @default(USER)
  posts     Post[]
  createdAt DateTime  @default(now())
  updatedAt DateTime  @updatedAt
  deletedAt DateTime?

  @@index([createdAt])
  @@index([deletedAt, createdAt]) // 用于软删除 + 排序查询的复合索引
}
```

- 在每个外键和用于 `WHERE` 或 `ORDER BY` 的列上添加 `@@index`。
- 当软删除是可预见的需求时，预先声明 `deletedAt DateTime?` —— 之后添加需要在活跃表上进行迁移。
- `updatedAt @updatedAt` 仅在 Prisma 的 `update` 和 `upsert` 上自动设置（参见反模式中的批量更新陷阱）。

### `include` 与 `select`

| | `include` | `select` |
|---|---|---|
| 返回 | 所有标量字段 + 指定关系 | 仅指定字段 |
| 何时使用 | 需要大多数字段加一个关系时 | 热路径、大表、避免过度获取 |
| 性能 | 可能在宽表上过度获取 | 最小负载，大数据集上更快 |
| Prisma 5 注意 | 默认使用 JOIN（`relationJoins`） | 相同 |

```ts
// include — 所有列 + 关系
const user = await prisma.user.findUnique({
  where: { id },
  include: { posts: { select: { id: true, title: true } } },
});

// select — 显式允许列表
const user = await prisma.user.findUnique({
  where: { id },
  select: { id: true, email: true, name: true },
});
```

永远不要从 API 响应中返回原始 Prisma 实体 —— 映射到响应 DTO 以控制暴露的字段：

```ts
// 不好的做法：泄漏 passwordHash、deletedAt、内部字段
return await prisma.user.findUniqueOrThrow({ where: { id } });

// 好的做法：显式 DTO 映射
const user = await prisma.user.findUniqueOrThrow({ where: { id } });
return { id: user.id, name: user.name, email: user.email };
```

### 事务形式选择

| 情况 | 使用 |
|---|---|
| 独立操作，无相互依赖 | 数组形式 |
| 后续步骤依赖前面结果 | 交互式形式 |
| 涉及外部调用（邮件、HTTP） | 完全在事务之外 |

```ts
// 数组形式 — 在一次往返中批量执行
const [user, post] = await prisma.$transaction([
  prisma.user.update({ where: { id }, data: { name } }),
  prisma.post.create({ data: { title, authorId: id } }),
]);

// 交互式形式 — 仅使用 tx 客户端，从不使用外部 prisma 客户端
const post = await prisma.$transaction(async (tx) => {
  const user = await tx.user.findUniqueOrThrow({ where: { id } });
  if (user.role !== 'ADMIN') throw new Error('Forbidden');
  return tx.post.create({ data: { title, authorId: user.id } });
});
```

### PrismaClient 单例

每个 `PrismaClient` 实例打开自己的连接池。只实例化一次。

```ts
// lib/prisma.ts
import { PrismaClient } from '@prisma/client';

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: process.env.NODE_ENV === 'development' ? ['query', 'error'] : ['error'],
  });

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;
```

`globalThis` 模式防止热重载期间创建重复实例（Next.js、nodemon、ts-node-dev）。

### N+1 问题

在循环内加载关系会为每行发出一个查询。

```ts
// 不好的做法：N+1 — 每个用户一个额外查询
const users = await prisma.user.findMany();
for (const user of users) {
  const posts = await prisma.post.findMany({ where: { authorId: user.id } });
}

// 好的做法：单个查询
const users = await prisma.user.findMany({ include: { posts: true } });
```

使用 Prisma 5+ 的 `relationJoins`，`include` 形式使用单个 JOIN。在大型 1:N 集合上这可能增加结果集大小 —— 如果每个父行的关系可能返回多行，对两种方法进行基准测试。

## 代码示例

### 游标分页（推荐用于信息流和大数据集）

```ts
async function getPosts(cursor?: string, limit = 20) {
  const items = await prisma.post.findMany({
    where: { published: true },
    orderBy: [
      { createdAt: 'desc' },
      { id: 'desc' }, // 次要排序防止重复时间戳上的不稳定分页
    ],
    take: limit + 1,
    ...(cursor && { cursor: { id: cursor }, skip: 1 }),
  });

  const hasNextPage = items.length > limit;
  if (hasNextPage) items.pop();

  return { items, nextCursor: hasNextPage ? items[items.length - 1].id : null };
}
```

获取 `limit + 1` 并弹出 —— 检测 `hasNextPage` 的规范方法，无需额外的计数查询。始终包含一个唯一字段（如 `id`）作为次要 `orderBy`，以防止多行共享相同时间戳时的不稳定分页。仅在用户需要跳转到任意页面时使用偏移分页（管理表）。

### 软删除

```ts
// 始终显式过滤 — 不依赖中间件（隐藏行为，难以调试）
const activeUsers = await prisma.user.findMany({ where: { deletedAt: null } });

await prisma.user.update({ where: { id }, data: { deletedAt: new Date() } });
await prisma.user.update({ where: { id }, data: { deletedAt: null } }); // 恢复
```

### 错误处理

```ts
import { Prisma } from '@prisma/client';

try {
  await prisma.user.create({ data: { email } });
} catch (e) {
  if (e instanceof Prisma.PrismaClientKnownRequestError) {
    if (e.code === 'P2002') throw new ConflictError('邮箱已存在');
    if (e.code === 'P2025') throw new NotFoundError('记录未找到');
    if (e.code === 'P2003') throw new BadRequestError('引用的记录不存在');
  }
  throw e;
}
```

常见错误码：`P2002` 唯一约束违反 · `P2025` 未找到 · `P2003` 外键违反。

在服务边界捕获并转换为领域错误。永远不要向 API 消费者暴露原始 Prisma 消息。

### 连接池 — 无服务器

直接在 `DATABASE_URL` 中嵌入连接参数 —— 如果 URL 已有查询参数（如 `?schema=public`），字符串拼接会出错：

```bash
# .env — 推荐：在 URL 中嵌入参数
DATABASE_URL="postgresql://user:pass@host/db?connection_limit=1&pool_timeout=20"

# 使用外部连接池（PgBouncer、Supabase pooler）
DATABASE_URL="postgresql://user:pass@host/db?pgbouncer=true&connection_limit=1"
```

```ts
// Vercel、AWS Lambda 和类似的无服务器运行时：将池限制为每个实例 1 个连接
// connection_limit 和 pool_timeout 通过 DATABASE_URL 控制
const prisma = new PrismaClient();
```

## 反模式

### `updateMany` 返回计数，而非记录

```ts
// 不好的做法：结果是 { count: 2 } — users[0] 是 undefined
const users = await prisma.user.updateMany({ where: { role: 'GUEST' }, data: { role: 'USER' } });

// 好的做法：先捕获 ID，然后更新，再只获取受影响的行
const targets = await prisma.user.findMany({
  where: { role: 'GUEST' },
  select: { id: true },
});
const ids = targets.map((u) => u.id);
await prisma.user.updateMany({ where: { id: { in: ids } }, data: { role: 'USER' } });
const updated = await prisma.user.findMany({ where: { id: { in: ids } } });
```

`deleteMany` 同理 —— 返回 `{ count: n }`，永远不是被删除的行。

### `$transaction` 交互式形式在 5 秒后超时

```ts
// 不好的做法：事务内的外部调用超过 5 秒默认值 → "Transaction already closed"
await prisma.$transaction(async (tx) => {
  const user = await tx.user.findUniqueOrThrow({ where: { id } });
  await sendWelcomeEmail(user.email); // 外部调用
  await tx.user.update({ where: { id }, data: { emailSent: true } });
});

// 好的做法：外部调用在事务之外
const user = await prisma.user.findUniqueOrThrow({ where: { id } });
await sendWelcomeEmail(user.email);
await prisma.user.update({ where: { id }, data: { emailSent: true } });

// 仅在批量处理确实需要时才提高超时
await prisma.$transaction(async (tx) => { ... }, { timeout: 30_000 });
```

### `migrate dev` 可能重置数据库

`migrate dev` 检测模式漂移，可能提示重置 DB，删除所有数据。

```bash
# 永远不要在共享开发、预发布或生产环境上使用
npx prisma migrate dev --name add_column

# 除本地单独开发外的所有环境都安全
npx prisma migrate deploy

# 检查漂移但不应用
npx prisma migrate diff \
  --from-migrations ./prisma/migrations \
  --to-schema-datamodel ./prisma/schema.prisma \
  --shadow-database-url "$SHADOW_DATABASE_URL"
```

### 手动编辑迁移文件会破坏未来的部署

Prisma 对每个迁移文件进行校验和。应用后编辑会在原始文件已运行的每个环境中导致 `P3006 checksum mismatch`。改为创建新的迁移。

### 破坏性模式变更需要多步骤迁移

在一个迁移中向现有列添加 `NOT NULL` 或重命名列会锁定表或删除数据。使用扩展-收缩策略：

```bash
# 步骤 1：在本地创建迁移，然后部署
npx prisma migrate dev --name add_new_column   # 仅本地
npx prisma migrate deploy                       # 预发布 / 生产
```

```ts
// 步骤 2：回填数据（在脚本或迁移任务中运行，不在 shell 中）
await prisma.user.updateMany({ data: { newColumn: derivedValue } });
```

```bash
# 步骤 3：在本地创建 NOT NULL 约束迁移，然后部署
npx prisma migrate dev --name make_new_column_required  # 仅本地
npx prisma migrate deploy                               # 预发布 / 生产
```

### `@updatedAt` 在 `updateMany` 上不触发

`@updatedAt` 仅在 `update` 和 `upsert` 上自动设置。批量写入使其保持过时。

```ts
// 不好的做法：updatedAt 保持旧值
await prisma.post.updateMany({ where: { authorId }, data: { published: true } });

// 好的做法
await prisma.post.updateMany({
  where: { authorId },
  data: { published: true, updatedAt: new Date() },
});
```

### 软删除 + `findUniqueOrThrow` 泄漏已删除记录

`findUniqueOrThrow` 仅当行在 DB 中不存在时抛出 `P2025`。软删除的行仍然存在并被无错误地返回。

`findUniqueOrThrow` 要求 `where` 中有唯一约束字段 —— 在 `id` 旁边添加 `deletedAt: null` 会破坏类型，因为 `{ id, deletedAt }` 不是复合唯一约束。改用 `findFirstOrThrow`。

```ts
// 不好的做法：返回软删除的用户
const user = await prisma.user.findUniqueOrThrow({ where: { id } });

// 不好的做法：Prisma 类型错误 — { id, deletedAt } 不是唯一约束
const user = await prisma.user.findUniqueOrThrow({ where: { id, deletedAt: null } });

// 好的做法：findFirstOrThrow 支持任意 where 条件
const user = await prisma.user.findFirstOrThrow({ where: { id, deletedAt: null } });
```

### 不带 `where` 的 `deleteMany` 删除每一行

```ts
// 不好的做法：静默清空表
await prisma.post.deleteMany();

// 好的做法
await prisma.post.deleteMany({ where: { authorId: userId } });
```

## 最佳实践

| 规则 | 原因 |
|---|---|
| CI/CD 中使用 `migrate deploy`，仅本地使用 `migrate dev` | `migrate dev` 可能在漂移时重置 DB |
| 将实体映射到响应 DTO | 防止泄漏内部字段 |
| 在服务边界捕获 `PrismaClientKnownRequestError` | 转换为领域错误 |
| 优先使用 `*OrThrow` 方法而非手动 null 检查 | 自动抛出 P2025；过滤非唯一字段时使用 `findFirstOrThrow` |
| 无服务器中 `connection_limit=1` + 外部连接池 | 防止连接耗尽 |
| 在 `deleteMany` 上始终提供 `where` | 防止意外清空表 |
| 在 `updateMany` 中手动设置 `updatedAt: new Date()` | `@updatedAt` 跳过批量写入 |

## 相关技能

- `nestjs-patterns` —— 集成 Prisma 的 NestJS 服务层
- `postgres-patterns` —— PostgreSQL 级别的索引和连接调优
- `database-migrations` —— 生产环境的多步骤迁移规划
- `backend-patterns` —— 通用 API 和服务层设计
