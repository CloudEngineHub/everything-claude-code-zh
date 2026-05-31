---
name: perl-testing
description: Perl 测试模式，使用 Test2::V0、Test::More、prove 运行器、mocking、Devel::Cover 覆盖率和 TDD 方法论。
origin: ECC
---

# Perl 测试模式

使用 Test2::V0、Test::More、prove 和 TDD 方法论的 Perl 应用程序全面测试策略。

## 何时激活

- 编写新的 Perl 代码（遵循 TDD：红、绿、重构）
- 为 Perl 模块或应用程序设计测试套件
- 审查 Perl 测试覆盖率
- 设置 Perl 测试基础设施
- 从 Test::More 迁移测试到 Test2::V0
- 调试失败的 Perl 测试

## TDD 工作流

始终遵循 红-绿-重构 循环。

```perl
# 步骤 1：红 —— 编写一个失败的测试
# t/unit/calculator.t
use v5.36;
use Test2::V0;

use lib 'lib';
use Calculator;

subtest '加法' => sub {
    my $calc = Calculator->new;
    is($calc->add(2, 3), 5, '两个数相加');
    is($calc->add(-1, 1), 0, '处理负数');
};

done_testing;

# 步骤 2：绿 —— 编写最小实现
# lib/Calculator.pm
package Calculator;
use v5.36;
use Moo;

sub add($self, $a, $b) {
    return $a + $b;
}

1;

# 步骤 3：重构 —— 在测试保持绿色的同时改进
# 运行：prove -lv t/unit/calculator.t
```

## Test::More 基础

标准 Perl 测试模块 —— 广泛使用，随核心发布。

### 基本断言

```perl
use v5.36;
use Test::More;

# 预先计划或使用 done_testing
# plan tests => 5;  # 固定计划（可选）

# 相等性
is($result, 42, '返回正确的值');
isnt($result, 0, '不为零');

# 布尔值
ok($user->is_active, '用户已激活');
ok(!$user->is_banned, '用户未被封禁');

# 深度比较
is_deeply(
    $got,
    { name => 'Alice', roles => ['admin'] },
    '返回预期的结构'
);

# 模式匹配
like($error, qr/not found/i, '错误消息包含 not found');
unlike($output, qr/password/, '输出隐藏了密码');

# 类型检查
isa_ok($obj, 'MyApp::User');
can_ok($obj, 'save', 'delete');

done_testing;
```

### SKIP 和 TODO

```perl
use v5.36;
use Test::More;

# 有条件地跳过测试
SKIP: {
    skip '未配置数据库', 2 unless $ENV{TEST_DB};

    my $db = connect_db();
    ok($db->ping, '数据库可达');
    is($db->version, '15', '正确的 PostgreSQL 版本');
}

# 标记预期失败
TODO: {
    local $TODO = '缓存尚未实现';
    is($cache->get('key'), 'value', '缓存返回值');
}

done_testing;
```

## Test2::V0 现代框架

Test2::V0 是 Test::More 的现代替代品 —— 更丰富的断言、更好的诊断和可扩展。

### 为什么选择 Test2？

- 通过哈希/数组构建器实现卓越的深度比较
- 失败时更好的诊断输出
- 更清晰作用域的子测试
- 通过 Test2::Tools::* 插件可扩展
- 与 Test::More 测试向后兼容

### 使用构建器的深度比较

```perl
use v5.36;
use Test2::V0;

# 哈希构建器 —— 检查部分结构
is(
    $user->to_hash,
    hash {
        field name  => 'Alice';
        field email => match(qr/\@example\.com$/);
        field age   => validator(sub { $_ >= 18 });
        # 忽略其他字段
        etc();
    },
    '用户包含预期字段'
);

# 数组构建器
is(
    $result,
    array {
        item 'first';
        item match(qr/^second/);
        item DNE();  # 不存在 —— 验证没有额外项
    },
    '结果匹配预期列表'
);

# Bag —— 与顺序无关的比较
is(
    $tags,
    bag {
        item 'perl';
        item 'testing';
        item 'tdd';
    },
    '包含所有必需标签，不区分顺序'
);
```

### 子测试

```perl
use v5.36;
use Test2::V0;

subtest '用户创建' => sub {
    my $user = User->new(name => 'Alice', email => 'alice@example.com');
    ok($user, '用户对象已创建');
    is($user->name, 'Alice', '名称已设置');
    is($user->email, 'alice@example.com', '邮箱已设置');
};

subtest '用户验证' => sub {
    my $warnings = warns {
        User->new(name => '', email => 'bad');
    };
    ok($warnings, '无效数据时发出警告');
};

done_testing;
```

### 使用 Test2 的异常测试

```perl
use v5.36;
use Test2::V0;

# 测试代码抛出异常
like(
    dies { divide(10, 0) },
    qr/Division by zero/,
    '除以零时抛出异常'
);

# 测试代码正常运行
ok(lives { divide(10, 2) }, '除法成功') or note($@);

# 组合模式
subtest '错误处理' => sub {
    ok(lives { parse_config('valid.json') }, '有效配置解析成功');
    like(
        dies { parse_config('missing.json') },
        qr/Cannot open/,
        '缺失文件时抛出带消息的异常'
    );
};

done_testing;
```

## 测试组织和 prove

### 目录结构

```text
t/
├── 00-load.t              # 验证模块编译
├── 01-basic.t             # 核心功能
├── unit/
│   ├── config.t           # 按模块的单元测试
│   ├── user.t
│   └── util.t
├── integration/
│   ├── database.t
│   └── api.t
├── lib/
│   └── TestHelper.pm      # 共享测试工具
└── fixtures/
    ├── config.json        # 测试数据文件
    └── users.csv
```

### prove 命令

```bash
# 运行所有测试
prove -l t/

# 详细输出
prove -lv t/

# 运行特定测试
prove -lv t/unit/user.t

# 递归搜索
prove -lr t/

# 并行执行（8 个作业）
prove -lr -j8 t/

# 只运行上次失败的测试
prove -l --state=failed t/

# 带计时器的彩色输出
prove -l --color --timer t/

# CI 的 TAP 输出
prove -l --formatter TAP::Formatter::JUnit t/ > results.xml
```

### .proverc 配置

```text
-l
--color
--timer
-r
-j4
--state=save
```

## 固件和设置/清理

### 子测试隔离

```perl
use v5.36;
use Test2::V0;
use File::Temp qw(tempdir);
use Path::Tiny;

subtest '文件处理' => sub {
    # 设置
    my $dir = tempdir(CLEANUP => 1);
    my $file = path($dir, 'input.txt');
    $file->spew_utf8("line1\nline2\nline3\n");

    # 测试
    my $result = process_file("$file");
    is($result->{line_count}, 3, '计算行数');

    # 清理自动发生（CLEANUP => 1）
};
```

### 共享测试辅助工具

将可重用的辅助工具放在 `t/lib/TestHelper.pm` 中，使用 `use lib 't/lib'` 加载。通过 `Exporter` 导出工厂函数，如 `create_test_db()`、`create_temp_dir()` 和 `fixture_path()`。

## Mocking

### Test::MockModule

```perl
use v5.36;
use Test2::V0;
use Test::MockModule;

subtest '模拟外部 API' => sub {
    my $mock = Test::MockModule->new('MyApp::API');

    # 好的做法：Mock 返回受控数据
    $mock->mock(fetch_user => sub ($self, $id) {
        return { id => $id, name => 'Mock User', email => 'mock@test.com' };
    });

    my $api = MyApp::API->new;
    my $user = $api->fetch_user(42);
    is($user->{name}, 'Mock User', '返回模拟用户');

    # 验证调用次数
    my $call_count = 0;
    $mock->mock(fetch_user => sub { $call_count++; return {} });
    $api->fetch_user(1);
    $api->fetch_user(2);
    is($call_count, 2, 'fetch_user 被调用了两次');

    # Mock 在 $mock 超出作用域时自动恢复
};

# 不好的做法：不恢复的猴子补丁
# *MyApp::API::fetch_user = sub { ... };  # 永远不要这样做 —— 在测试间泄漏
```

对于轻量级模拟对象，使用 `Test::MockObject` 创建可注入的测试替身，用 `->mock()` 并用 `->called_ok()` 验证调用。

## 使用 Devel::Cover 的覆盖率

### 运行覆盖率

```bash
# 基本覆盖率报告
cover -test

# 或分步执行
perl -MDevel::Cover -Ilib t/unit/user.t
cover

# HTML 报告
cover -report html
open cover_db/coverage.html

# 特定阈值
cover -test -report text | grep 'Total'

# CI 友好：低于阈值则失败
cover -test && cover -report text -select '^lib/' \
  | perl -ne 'if (/Total.*?(\d+\.\d+)/) { exit 1 if $1 < 80 }'
```

### 集成测试

数据库测试使用内存 SQLite，API 测试使用 mock HTTP::Tiny。

```perl
use v5.36;
use Test2::V0;
use DBI;

subtest '数据库集成' => sub {
    my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '', {
        RaiseError => 1,
    });
    $dbh->do('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)');

    $dbh->prepare('INSERT INTO users (name) VALUES (?)')->execute('Alice');
    my $row = $dbh->selectrow_hashref('SELECT * FROM users WHERE name = ?', undef, 'Alice');
    is($row->{name}, 'Alice', '插入并检索用户');
};

done_testing;
```

## 最佳实践

### 应该做的

- **遵循 TDD**：在实现之前编写测试（红-绿-重构）
- **使用 Test2::V0**：现代断言、更好的诊断
- **使用子测试**：分组相关断言、隔离状态
- **Mock 外部依赖**：网络、数据库、文件系统
- **使用 `prove -l`**：始终将 lib/ 包含在 `@INC` 中
- **清晰命名测试**：`'使用无效密码登录用户失败'`
- **测试边界情况**：空字符串、undef、零、边界值
- **目标 80%+ 覆盖率**：聚焦业务逻辑路径
- **保持测试快速**：Mock I/O，使用内存数据库

### 不应该做的

- **不要测试实现细节**：测试行为和输出，而非内部机制
- **不要在子测试之间共享状态**：每个子测试应该独立
- **不要跳过 `done_testing`**：确保所有计划的测试都已运行
- **不要过度 Mock**：只 Mock 边界，不 Mock 被测代码
- **不要在新项目中使用 `Test::More`**：优先使用 Test2::V0
- **不要忽略测试失败**：所有测试必须在合并前通过
- **不要测试 CPAN 模块**：信任库的正确性
- **不要编写脆弱的测试**：避免过度具体的字符串匹配

## 快速参考

| 任务 | 命令 / 模式 |
|---|---|
| 运行所有测试 | `prove -lr t/` |
| 详细运行一个测试 | `prove -lv t/unit/user.t` |
| 并行测试运行 | `prove -lr -j8 t/` |
| 覆盖率报告 | `cover -test && cover -report html` |
| 测试相等性 | `is($got, $expected, '标签')` |
| 深度比较 | `is($got, hash { field k => 'v'; etc() }, '标签')` |
| 测试异常 | `like(dies { ... }, qr/msg/, '标签')` |
| 测试无异常 | `ok(lives { ... }, '标签')` |
| Mock 方法 | `Test::MockModule->new('Pkg')->mock(m => sub { ... })` |
| 跳过测试 | `SKIP: { skip '原因', $count unless $cond; ... }` |
| TODO 测试 | `TODO: { local $TODO = '原因'; ... }` |

## 常见陷阱

### 忘记 `done_testing`

```perl
# 不好的做法：测试文件运行但未验证所有测试是否执行
use Test2::V0;
is(1, 1, '有效');
# 缺少 done_testing —— 如果测试代码被跳过则静默存在 bug

# 好的做法：始终以 done_testing 结束
use Test2::V0;
is(1, 1, '有效');
done_testing;
```

### 缺少 `-l` 标志

```bash
# 不好的做法：lib/ 中的模块找不到
prove t/unit/user.t
# Can't locate MyApp/User.pm in @INC

# 好的做法：将 lib/ 包含在 @INC 中
prove -l t/unit/user.t
```

### 过度 Mock

Mock *依赖*，而不是被测代码。如果你的测试只验证 mock 返回了你告诉它返回的内容，那它什么也没测试。

### 测试污染

在子测试内使用 `my` 变量 —— 永远不要使用 `our` —— 以防止状态在测试间泄漏。

**记住**：测试是你的安全网。保持它们快速、聚焦和独立。新项目使用 Test2::V0，运行使用 prove，覆盖率使用 Devel::Cover。
