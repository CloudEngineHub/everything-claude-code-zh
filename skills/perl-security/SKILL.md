---
name: perl-security
description: 全面的 Perl 安全指南，涵盖污染模式、输入验证、安全进程执行、DBI 参数化查询、Web 安全（XSS/SQLi/CSRF）和 perlcritic 安全策略。
origin: ECC
---

# Perl 安全模式

Perl 应用程序的全面安全指南，涵盖输入验证、注入防护和安全编码实践。

## 何时激活

- 在 Perl 应用程序中处理用户输入
- 构建 Perl Web 应用程序（CGI、Mojolicious、Dancer2、Catalyst）
- 审查 Perl 代码的安全漏洞
- 使用用户提供的路径执行文件操作
- 从 Perl 执行系统命令
- 编写 DBI 数据库查询

## 工作原理

从污染感知的输入边界开始，然后向外扩展：验证和去污染输入，保持文件系统和进程执行的约束，并在所有地方使用参数化的 DBI 查询。下面的示例展示了此技能期望你在发布触及用户输入、shell 或网络的 Perl 代码之前应用的安全默认值。

## 污染模式

Perl 的污染模式（`-T`）跟踪来自外部来源的数据，并防止其在未经显式验证的情况下用于不安全的操作。

### 启用污染模式

```perl
#!/usr/bin/perl -T
use v5.36;

# 受污染的：来自程序外部的任何内容
my $input    = $ARGV[0];        # 受污染
my $env_path = $ENV{PATH};      # 受污染
my $form     = <STDIN>;         # 受污染
my $query    = $ENV{QUERY_STRING}; # 受污染

# 尽早清理 PATH（在污染模式下必需）
$ENV{PATH} = '/usr/local/bin:/usr/bin:/bin';
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};
```

### 去污染模式

```perl
use v5.36;

# 好的做法：使用特定正则表达式验证并去污染
sub untaint_username($input) {
    if ($input =~ /^([a-zA-Z0-9_]{3,30})$/) {
        return $1;  # $1 是未受污染的
    }
    die "Invalid username: must be 3-30 alphanumeric characters\n";
}

# 好的做法：验证并去污染文件路径
sub untaint_filename($input) {
    if ($input =~ m{^([a-zA-Z0-9._-]+)$}) {
        return $1;
    }
    die "Invalid filename: contains unsafe characters\n";
}

# 不好的做法：过于宽松的去污染（违背了目的）
sub bad_untaint($input) {
    $input =~ /^(.*)$/s;
    return $1;  # 接受任何内容 —— 毫无意义
}
```

## 输入验证

### 白名单优于黑名单

```perl
use v5.36;

# 好的做法：白名单 —— 精确定义允许的内容
sub validate_sort_field($field) {
    my %allowed = map { $_ => 1 } qw(name email created_at updated_at);
    die "Invalid sort field: $field\n" unless $allowed{$field};
    return $field;
}

# 好的做法：使用特定模式验证
sub validate_email($email) {
    if ($email =~ /^([a-zA-Z0-9._%+-]+\@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})$/) {
        return $1;
    }
    die "Invalid email address\n";
}

sub validate_integer($input) {
    if ($input =~ /^(-?\d{1,10})$/) {
        return $1 + 0;  # 强制转换为数字
    }
    die "Invalid integer\n";
}

# 不好的做法：黑名单 —— 总是不完整的
sub bad_validate($input) {
    die "Invalid" if $input =~ /[<>"';&|]/;  # 遗漏了编码攻击
    return $input;
}
```

### 长度约束

```perl
use v5.36;

sub validate_comment($text) {
    die "Comment is required\n"        unless length($text) > 0;
    die "Comment exceeds 10000 chars\n" if length($text) > 10_000;
    return $text;
}
```

## 安全的正则表达式

### ReDoS 防护

在重叠模式上使用嵌套量词时会发生灾难性回溯。

```perl
use v5.36;

# 不好的做法：易受 ReDoS 攻击（指数级回溯）
my $bad_re = qr/^(a+)+$/;           # 嵌套量词
my $bad_re2 = qr/^([a-zA-Z]+)*$/;   # 字符类上的嵌套量词
my $bad_re3 = qr/^(.*?,){10,}$/;    # 重复的贪婪/懒惰组合

# 好的做法：不嵌套重写
my $good_re = qr/^a+$/;             # 单个量词
my $good_re2 = qr/^[a-zA-Z]+$/;     # 字符类上的单个量词

# 好的做法：使用占有量词或原子组防止回溯
my $safe_re = qr/^[a-zA-Z]++$/;             # 占有的（5.10+）
my $safe_re2 = qr/^(?>a+)$/;                # 原子组

# 好的做法：对不受信任的模式强制超时
use POSIX qw(alarm);
sub safe_match($string, $pattern, $timeout = 2) {
    my $matched;
    eval {
        local $SIG{ALRM} = sub { die "Regex timeout\n" };
        alarm($timeout);
        $matched = $string =~ $pattern;
        alarm(0);
    };
    alarm(0);
    die $@ if $@;
    return $matched;
}
```

## 安全的文件操作

### 三参数 open

```perl
use v5.36;

# 好的做法：三参数 open、词法文件句柄、检查返回值
sub read_file($path) {
    open my $fh, '<:encoding(UTF-8)', $path
        or die "Cannot open '$path': $!\n";
    local $/;
    my $content = <$fh>;
    close $fh;
    return $content;
}

# 不好的做法：带用户数据的两参数 open（命令注入）
sub bad_read($path) {
    open my $fh, $path;        # 如果 $path = "|rm -rf /"，会执行命令！
    open my $fh, "< $path";   # Shell 元字符注入
}
```

### TOCTOU 防护和路径遍历

```perl
use v5.36;
use Fcntl qw(:DEFAULT :flock);
use File::Spec;
use Cwd qw(realpath);

# 原子文件创建
sub create_file_safe($path) {
    sysopen(my $fh, $path, O_WRONLY | O_CREAT | O_EXCL, 0600)
        or die "Cannot create '$path': $!\n";
    return $fh;
}

# 验证路径保持在允许的目录内
sub safe_path($base_dir, $user_path) {
    my $real = realpath(File::Spec->catfile($base_dir, $user_path))
        // die "Path does not exist\n";
    my $base_real = realpath($base_dir)
        // die "Base dir does not exist\n";
    die "Path traversal blocked\n" unless $real =~ /^\Q$base_real\E(?:\/|\z)/;
    return $real;
}
```

临时文件使用 `File::Temp`（`tempfile(UNLINK => 1)`），使用 `flock(LOCK_EX)` 防止竞态条件。

## 安全的进程执行

### 列表形式的 system 和 exec

```perl
use v5.36;

# 好的做法：列表形式 —— 无 shell 插值
sub run_command(@cmd) {
    system(@cmd) == 0
        or die "Command failed: @cmd\n";
}

run_command('grep', '-r', $user_pattern, '/var/log/app/');

# 好的做法：使用 IPC::Run3 安全捕获输出
use IPC::Run3;
sub capture_output(@cmd) {
    my ($stdout, $stderr);
    run3(\@cmd, \undef, \$stdout, \$stderr);
    if ($?) {
        die "Command failed (exit $?): $stderr\n";
    }
    return $stdout;
}

# 不好的做法：字符串形式 —— shell 注入！
sub bad_search($pattern) {
    system("grep -r '$pattern' /var/log/app/");  # 如果 $pattern = "'; rm -rf / #"
}

# 不好的做法：带插值的反引号
my $output = `ls $user_dir`;   # Shell 注入风险
```

也可以使用 `Capture::Tiny` 安全地从外部命令捕获 stdout/stderr。

## SQL 注入防护

### DBI 占位符

```perl
use v5.36;
use DBI;

my $dbh = DBI->connect($dsn, $user, $pass, {
    RaiseError => 1,
    PrintError => 0,
    AutoCommit => 1,
});

# 好的做法：参数化查询 —— 始终使用占位符
sub find_user($dbh, $email) {
    my $sth = $dbh->prepare('SELECT * FROM users WHERE email = ?');
    $sth->execute($email);
    return $sth->fetchrow_hashref;
}

sub search_users($dbh, $name, $status) {
    my $sth = $dbh->prepare(
        'SELECT * FROM users WHERE name LIKE ? AND status = ? ORDER BY name'
    );
    $sth->execute("%$name%", $status);
    return $sth->fetchall_arrayref({});
}

# 不好的做法：SQL 中的字符串插值（SQLi 漏洞！）
sub bad_find($dbh, $email) {
    my $sth = $dbh->prepare("SELECT * FROM users WHERE email = '$email'");
    # 如果 $email = "' OR 1=1 --"，返回所有用户
    $sth->execute;
    return $sth->fetchrow_hashref;
}
```

### 动态列白名单

```perl
use v5.36;

# 好的做法：根据白名单验证列名
sub order_by($dbh, $column, $direction) {
    my %allowed_cols = map { $_ => 1 } qw(name email created_at);
    my %allowed_dirs = map { $_ => 1 } qw(ASC DESC);

    die "Invalid column: $column\n"    unless $allowed_cols{$column};
    die "Invalid direction: $direction\n" unless $allowed_dirs{uc $direction};

    my $sth = $dbh->prepare("SELECT * FROM users ORDER BY $column $direction");
    $sth->execute;
    return $sth->fetchall_arrayref({});
}

# 不好的做法：直接插值用户选择的列
sub bad_order($dbh, $column) {
    $dbh->prepare("SELECT * FROM users ORDER BY $column");  # SQLi!
}
```

### DBIx::Class（ORM 安全）

```perl
use v5.36;

# DBIx::Class 生成安全的参数化查询
my @users = $schema->resultset('User')->search({
    status => 'active',
    email  => { -like => '%@example.com' },
}, {
    order_by => { -asc => 'name' },
    rows     => 50,
});
```

## Web 安全

### XSS 防护

```perl
use v5.36;
use HTML::Entities qw(encode_entities);
use URI::Escape qw(uri_escape_utf8);

# 好的做法：为 HTML 上下文编码输出
sub safe_html($user_input) {
    return encode_entities($user_input);
}

# 好的做法：为 URL 上下文编码
sub safe_url_param($value) {
    return uri_escape_utf8($value);
}

# 好的做法：为 JSON 上下文编码
use JSON::MaybeXS qw(encode_json);
sub safe_json($data) {
    return encode_json($data);  # 处理转义
}

# 模板自动转义（Mojolicious）
# <%= $user_input %>   — 自动转义（安全）
# <%== $raw_html %>    — 原始输出（危险，仅用于受信任内容）

# 模板自动转义（Template Toolkit）
# [% user_input | html %]  — 显式 HTML 编码

# 不好的做法：HTML 中的原始输出
sub bad_html($input) {
    print "<div>$input</div>";  # 如果 $input 包含 <script> 则存在 XSS
}
```

### CSRF 防护

```perl
use v5.36;
use Crypt::URandom qw(urandom);
use MIME::Base64 qw(encode_base64url);

sub generate_csrf_token() {
    return encode_base64url(urandom(32));
}
```

验证 token 时使用常量时间比较。大多数 Web 框架（Mojolicious、Dancer2、Catalyst）提供内置的 CSRF 防护 —— 优先使用这些而非手工编写的解决方案。

### 会话和头部安全

```perl
use v5.36;

# Mojolicious 会话 + 头部
$app->secrets(['long-random-secret-rotated-regularly']);
$app->sessions->secure(1);          # 仅 HTTPS
$app->sessions->samesite('Lax');

$app->hook(after_dispatch => sub ($c) {
    $c->res->headers->header('X-Content-Type-Options' => 'nosniff');
    $c->res->headers->header('X-Frame-Options'        => 'DENY');
    $c->res->headers->header('Content-Security-Policy' => "default-src 'self'");
    $c->res->headers->header('Strict-Transport-Security' => 'max-age=31536000; includeSubDomains');
});
```

## 输出编码

始终根据上下文编码输出：HTML 使用 `HTML::Entities::encode_entities()`，URL 使用 `URI::Escape::uri_escape_utf8()`，JSON 使用 `JSON::MaybeXS::encode_json()`。

## CPAN 模块安全

- **固定版本**在 cpanfile 中：`requires 'DBI', '== 1.643';`
- **优先使用维护良好的模块**：查看 MetaCPAN 上的近期发布
- **最小化依赖**：每个依赖都是攻击面

## 安全工具

### perlcritic 安全策略

```ini
# .perlcriticrc — 安全聚焦配置
severity = 3
theme = security + core

# 要求三参数 open
[InputOutput::RequireThreeArgOpen]
severity = 5

# 要求检查系统调用
[InputOutput::RequireCheckedSyscalls]
functions = :builtins
severity = 4

# 禁止字符串 eval
[BuiltinFunctions::ProhibitStringyEval]
severity = 5

# 禁止反引号运算符
[InputOutput::ProhibitBacktickOperators]
severity = 4

# CGI 中要求污染检查
[Modules::RequireTaintChecking]
severity = 5

# 禁止两参数 open
[InputOutput::ProhibitTwoArgOpen]
severity = 5

# 禁止裸字文件句柄
[InputOutput::ProhibitBarewordFileHandles]
severity = 5
```

### 运行 perlcritic

```bash
# 检查文件
perlcritic --severity 3 --theme security lib/MyApp/Handler.pm

# 检查整个项目
perlcritic --severity 3 --theme security lib/

# CI 集成
perlcritic --severity 4 --theme security --quiet lib/ || exit 1
```

## 快速安全检查清单

| 检查项 | 验证内容 |
|---|---|
| 污染模式 | CGI/Web 脚本上的 `-T` 标志 |
| 输入验证 | 白名单模式、长度限制 |
| 文件操作 | 三参数 open、路径遍历检查 |
| 进程执行 | 列表形式 system、无 shell 插值 |
| SQL 查询 | DBI 占位符，绝不插值 |
| HTML 输出 | `encode_entities()`、模板自动转义 |
| CSRF token | 已生成，在状态变更请求上验证 |
| 会话配置 | Secure、HttpOnly、SameSite cookie |
| HTTP 头部 | CSP、X-Frame-Options、HSTS |
| 依赖项 | 固定版本、已审计模块 |
| 正则安全 | 无嵌套量词、锚定模式 |
| 错误消息 | 不向用户泄露堆栈跟踪或路径 |

## 反模式

```perl
# 1. 带用户数据的两参数 open（命令注入）
open my $fh, $user_input;               # 严重漏洞

# 2. 字符串形式的 system（shell 注入）
system("convert $user_file output.png"); # 严重漏洞

# 3. SQL 字符串插值
$dbh->do("DELETE FROM users WHERE id = $id");  # SQLi

# 4. 带用户输入的 eval（代码注入）
eval $user_code;                         # 远程代码执行

# 5. 信任未清理的 $ENV
my $path = $ENV{UPLOAD_DIR};             # 可能被操纵
system("ls $path");                      # 双重漏洞

# 6. 未经验证就禁用污染
($input) = $input =~ /(.*)/s;           # 懒惰的去污染 —— 违背目的

# 7. HTML 中的原始用户数据
print "<div>Welcome, $username!</div>";  # XSS

# 8. 未验证的重定向
print $cgi->redirect($user_url);         # 开放重定向
```

**记住**：Perl 的灵活性很强大但需要纪律。对面向 Web 的代码使用污染模式，用白名单验证所有输入，对每个查询使用 DBI 占位符，并根据上下文编码所有输出。深度防御 —— 永远不要依赖单一层。
