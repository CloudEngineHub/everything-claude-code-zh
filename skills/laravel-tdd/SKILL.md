---
name: laravel-tdd
description: Laravel 测试驱动开发，使用 PHPUnit 和 Pest，包括工厂、数据库测试、伪造和覆盖率目标。
origin: ECC
---

# Laravel TDD 工作流

使用 PHPUnit 和 Pest 进行 Laravel 应用的测试驱动开发，目标覆盖率 80%+（单元 + 功能）。

## 何时使用

- Laravel 中的新功能或端点
- Bug 修复或重构
- 测试 Eloquent 模型、策略、任务和通知
- 新测试优先使用 Pest，除非项目已标准化使用 PHPUnit

## 工作原理

### 红-绿-重构循环

1) 编写一个失败的测试
2) 实现最小改动使其通过
3) 在保持测试通过的同时重构

### 测试层级

- **单元测试**：纯 PHP 类、值对象、服务
- **功能测试**：HTTP 端点、认证、验证、策略
- **集成测试**：数据库 + 队列 + 外部边界

根据范围选择层级：

- 对纯业务逻辑和服务使用**单元测试**。
- 对 HTTP、认证、验证和响应结构使用**功能测试**。
- 对需要联合验证数据库/队列/外部服务的场景使用**集成测试**。

### 数据库策略

- `RefreshDatabase` 用于大多数功能/集成测试（每次测试运行执行一次迁移，然后在支持事务的情况下将每个测试包装在事务中；内存数据库可能会在每个测试前重新迁移）
- `DatabaseTransactions` 当数据库结构已迁移且只需要每个测试的回滚时
- `DatabaseMigrations` 当你需要每个测试都完整迁移/刷新且能承受其开销时

将 `RefreshDatabase` 作为涉及数据库的测试的默认选择：对于支持事务的数据库，它通过静态标志每次测试运行执行一次迁移，并将每个测试包装在事务中；对于 `:memory:` SQLite 或不支持事务的连接，它会在每个测试前迁移。当数据库结构已迁移且只需要每个测试的回滚时使用 `DatabaseTransactions`。

### 测试框架选择

- 有 Pest 时，新测试**默认使用 Pest**。
- 仅当项目已标准化使用 PHPUnit 或需要 PHPUnit 特定工具时使用 **PHPUnit**。

## 示例

### PHPUnit 示例

```php
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

final class ProjectControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_owner_can_create_project(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)->postJson('/api/projects', [
            'name' => 'New Project',
        ]);

        $response->assertCreated();
        $this->assertDatabaseHas('projects', ['name' => 'New Project']);
    }
}
```

### 功能测试示例（HTTP 层）

```php
use App\Models\Project;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

final class ProjectIndexTest extends TestCase
{
    use RefreshDatabase;

    public function test_projects_index_returns_paginated_results(): void
    {
        $user = User::factory()->create();
        Project::factory()->count(3)->for($user)->create();

        $response = $this->actingAs($user)->getJson('/api/projects');

        $response->assertOk();
        $response->assertJsonStructure(['success', 'data', 'error', 'meta']);
    }
}
```

### Pest 示例

```php
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

use function Pest\Laravel\actingAs;
use function Pest\Laravel\assertDatabaseHas;

uses(RefreshDatabase::class);

test('owner can create project', function () {
    $user = User::factory()->create();

    $response = actingAs($user)->postJson('/api/projects', [
        'name' => 'New Project',
    ]);

    $response->assertCreated();
    assertDatabaseHas('projects', ['name' => 'New Project']);
});
```

### 功能测试 Pest 示例（HTTP 层）

```php
use App\Models\Project;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

use function Pest\Laravel\actingAs;

uses(RefreshDatabase::class);

test('projects index returns paginated results', function () {
    $user = User::factory()->create();
    Project::factory()->count(3)->for($user)->create();

    $response = actingAs($user)->getJson('/api/projects');

    $response->assertOk();
    $response->assertJsonStructure(['success', 'data', 'error', 'meta']);
});
```

### 工厂和状态

- 使用工厂创建测试数据
- 为边缘情况定义状态（已归档、管理员、试用）

```php
$user = User::factory()->state(['role' => 'admin'])->create();
```

### 数据库测试

- 使用 `RefreshDatabase` 获取干净状态
- 保持测试隔离和确定性
- 优先使用 `assertDatabaseHas` 而非手动查询

### 持久化测试示例

```php
use App\Models\Project;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

final class ProjectRepositoryTest extends TestCase
{
    use RefreshDatabase;

    public function test_project_can_be_retrieved_by_slug(): void
    {
        $project = Project::factory()->create(['slug' => 'alpha']);

        $found = Project::query()->where('slug', 'alpha')->firstOrFail();

        $this->assertSame($project->id, $found->id);
    }
}
```

### 副作用的伪造

- `Bus::fake()` 用于任务
- `Queue::fake()` 用于队列工作
- `Mail::fake()` 和 `Notification::fake()` 用于通知
- `Event::fake()` 用于领域事件

```php
use Illuminate\Support\Facades\Queue;

Queue::fake();

dispatch(new SendOrderConfirmation($order->id));

Queue::assertPushed(SendOrderConfirmation::class);
```

```php
use Illuminate\Support\Facades\Notification;

Notification::fake();

$user->notify(new InvoiceReady($invoice));

Notification::assertSentTo($user, InvoiceReady::class);
```

### 认证测试（Sanctum）

```php
use Laravel\Sanctum\Sanctum;

Sanctum::actingAs($user);

$response = $this->getJson('/api/projects');
$response->assertOk();
```

### HTTP 和外部服务

- 使用 `Http::fake()` 隔离外部 API
- 使用 `Http::assertSent()` 断言出站请求负载

### 覆盖率目标

- 强制单元 + 功能测试覆盖率达到 80%+
- 在 CI 中使用 `pcov` 或 `XDEBUG_MODE=coverage`

### 测试命令

- `php artisan test`
- `vendor/bin/phpunit`
- `vendor/bin/pest`

### 测试配置

- 使用 `phpunit.xml` 设置 `DB_CONNECTION=sqlite` 和 `DB_DATABASE=:memory:` 以加速测试
- 保持测试使用独立环境，避免影响开发/生产数据

### 授权测试

```php
use Illuminate\Support\Facades\Gate;

$this->assertTrue(Gate::forUser($user)->allows('update', $project));
$this->assertFalse(Gate::forUser($otherUser)->allows('update', $project));
```

### Inertia 功能测试

使用 Inertia.js 时，使用 Inertia 测试辅助方法断言组件名和 props。

```php
use App\Models\User;
use Inertia\Testing\AssertableInertia;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

final class DashboardInertiaTest extends TestCase
{
    use RefreshDatabase;

    public function test_dashboard_inertia_props(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)->get('/dashboard');

        $response->assertOk();
        $response->assertInertia(fn (AssertableInertia $page) => $page
            ->component('Dashboard')
            ->where('user.id', $user->id)
            ->has('projects')
        );
    }
}
```

优先使用 `assertInertia` 而非原始 JSON 断言，以保持测试与 Inertia 响应一致。
