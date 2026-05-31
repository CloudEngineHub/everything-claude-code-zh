---
name: laravel-verification
description: "Laravel 项目验证循环：环境检查、代码风格检查、静态分析、带覆盖率的测试、安全扫描和部署就绪检查。"
origin: ECC
---

# Laravel 验证循环

在提交 PR、重大变更后和部署前运行。

## 何时使用

- 在为 Laravel 项目提交 Pull Request 之前
- 重大重构或依赖升级之后
- 预发布（staging 或生产）验证
- 运行完整的 风格检查 -> 测试 -> 安全 -> 部署就绪 检查流水线

## 工作原理

- 按顺序从环境检查到部署就绪运行各阶段，使每层建立在前一层之上。
- 环境和 Composer 检查是其他所有步骤的前提；如果失败则立即停止。
- 代码风格检查/静态分析应在运行完整测试和覆盖率之前通过。
- 安全和迁移审查在测试之后进行，以便在数据或发布步骤之前验证行为。
- 构建/部署就绪和队列/调度器检查是最终关卡；任何失败都会阻止发布。

## 阶段 1：环境检查

```bash
php -v
composer --version
php artisan --version
```

- 验证 `.env` 存在且必需的键已配置
- 确认生产环境中 `APP_DEBUG=false`
- 确认 `APP_ENV` 与目标部署环境匹配（`production`、`staging`）

如果本地使用 Laravel Sail：

```bash
./vendor/bin/sail php -v
./vendor/bin/sail artisan --version
```

## 阶段 1.5：Composer 和自动加载

```bash
composer validate
composer dump-autoload -o
```

## 阶段 2：代码风格检查和静态分析

```bash
vendor/bin/pint --test
vendor/bin/phpstan analyse
```

如果项目使用 Psalm 而非 PHPStan：

```bash
vendor/bin/psalm
```

## 阶段 3：测试和覆盖率

```bash
php artisan test
```

覆盖率（CI）：

```bash
XDEBUG_MODE=coverage php artisan test --coverage
```

CI 示例（格式化 -> 静态分析 -> 测试）：

```bash
vendor/bin/pint --test
vendor/bin/phpstan analyse
XDEBUG_MODE=coverage php artisan test --coverage
```

## 阶段 4：安全和依赖检查

```bash
composer audit
```

## 阶段 5：数据库和迁移

```bash
php artisan migrate --pretend
php artisan migrate:status
```

- 仔细审查破坏性迁移
- 确保迁移文件名遵循 `Y_m_d_His_*` 格式（例如 `2025_03_14_154210_create_orders_table.php`）并清晰描述变更
- 确保可以回滚
- 验证 `down()` 方法，避免在没有显式备份的情况下造成不可逆的数据丢失

## 阶段 6：构建和部署就绪

```bash
php artisan optimize:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

- 确保在生产配置下缓存预热成功
- 验证队列工作者和调度器已配置
- 确认 `storage/` 和 `bootstrap/cache/` 在目标环境中可写

## 阶段 7：队列和调度器检查

```bash
php artisan schedule:list
php artisan queue:failed
```

如果使用 Horizon：

```bash
php artisan horizon:status
```

如果有 `queue:monitor` 可用，使用它检查积压而不处理任务：

```bash
php artisan queue:monitor default --max=100
```

主动验证（仅限 staging）：向专用队列分发一个空操作任务，并运行单个工作者处理（确保配置了非 `sync` 的队列连接）。

```bash
php artisan tinker --execute="dispatch((new App\\Jobs\\QueueHealthcheck())->onQueue('healthcheck'))"
php artisan queue:work --once --queue=healthcheck
```

验证任务产生了预期的副作用（日志条目、健康检查表记录或指标）。

仅在处理测试任务安全的非生产环境中运行。

## 示例

最小化流程：

```bash
php -v
composer --version
php artisan --version
composer validate
vendor/bin/pint --test
vendor/bin/phpstan analyse
php artisan test
composer audit
php artisan migrate --pretend
php artisan config:cache
php artisan queue:failed
```

CI 风格流水线：

```bash
composer validate
composer dump-autoload -o
vendor/bin/pint --test
vendor/bin/phpstan analyse
XDEBUG_MODE=coverage php artisan test --coverage
composer audit
php artisan migrate --pretend
php artisan optimize:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan schedule:list
```
