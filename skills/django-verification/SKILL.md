---
name: django-verification
description: "Django 项目的验证循环：迁移、代码检查、带覆盖率的测试、安全扫描，以及发布或 PR 前的部署就绪检查。"
origin: ECC
---

# Django 验证循环

在 PR、重大变更后和部署前运行，确保 Django 应用质量和安全。

## 何时激活

- 在为 Django 项目提交 pull request 之前
- 在重大模型变更、迁移更新或依赖升级之后
- 预发或生产环境的预部署验证
- 运行完整的环境 → 代码检查 → 测试 → 安全 → 部署就绪管道
- 验证迁移安全性和测试覆盖率

## 阶段 1：环境检查

```bash
# 验证 Python 版本
python --version  # 应与项目要求匹配

# 检查虚拟环境
which python
pip list --outdated

# 验证环境变量
python -c "import os; import environ; print('DJANGO_SECRET_KEY 已设置' if os.environ.get('DJANGO_SECRET_KEY') else '缺失：DJANGO_SECRET_KEY')"
```

如果环境配置不正确，停止并修复。

## 阶段 2：代码质量与格式化

```bash
# 类型检查
mypy . --config-file pyproject.toml

# 使用 ruff 进行代码检查
ruff check . --fix

# 使用 black 格式化
black . --check
black .  # 自动修复

# 导入排序
isort . --check-only
isort .  # 自动修复

# Django 特定检查
python manage.py check --deploy
```

常见问题：
- 公共函数缺少类型提示
- PEP 8 格式化违规
- 未排序的导入
- 生产配置中遗留的调试设置

## 阶段 3：迁移

```bash
# 检查未应用的迁移
python manage.py showmigrations

# 创建缺失的迁移
python manage.py makemigrations --check

# 试运行迁移应用
python manage.py migrate --plan

# 应用迁移（测试环境）
python manage.py migrate

# 检查迁移冲突
python manage.py makemigrations --merge  # 仅在存在冲突时
```

报告：
- 待处理迁移数量
- 任何迁移冲突
- 没有迁移的模型变更

## 阶段 4：测试 + 覆盖率

```bash
# 使用 pytest 运行所有测试
pytest --cov=apps --cov-report=html --cov-report=term-missing --reuse-db

# 运行特定应用测试
pytest apps/users/tests/

# 使用标记运行
pytest -m "not slow"  # 跳过慢速测试
pytest -m integration  # 仅集成测试

# 覆盖率报告
open htmlcov/index.html
```

报告：
- 总测试数：X 通过，Y 失败，Z 跳过
- 总体覆盖率：XX%
- 每个应用的覆盖率明细

覆盖率目标：

| 组件 | 目标 |
|-----------|--------|
| 模型 | 90%+ |
| 序列化器 | 85%+ |
| 视图 | 80%+ |
| 服务 | 90%+ |
| 总体 | 80%+ |

## 阶段 5：安全扫描

```bash
# 依赖漏洞
pip-audit
safety check --full-report

# Django 安全检查
python manage.py check --deploy

# Bandit 安全检查器
bandit -r . -f json -o bandit-report.json

# 密钥扫描（如果已安装 gitleaks）
gitleaks detect --source . --verbose

# 环境变量检查
python -c "from django.core.exceptions import ImproperlyConfigured; from django.conf import settings; settings.DEBUG"
```

报告：
- 发现的依赖漏洞
- 安全配置问题
- 检测到的硬编码密钥
- DEBUG 模式状态（生产应为 False）

## 阶段 6：Django 管理命令

```bash
# 检查模型问题
python manage.py check

# 收集静态文件
python manage.py collectstatic --noinput --clear

# 创建超级用户（如测试需要）
echo "from apps.users.models import User; User.objects.create_superuser('admin@example.com', 'admin')" | python manage.py shell

# 数据库完整性
python manage.py check --database default

# 缓存验证（如果使用 Redis）
python -c "from django.core.cache import cache; cache.set('test', 'value', 10); print(cache.get('test'))"
```

## 阶段 7：性能检查

```bash
# Django Debug Toolbar 输出（检查 N+1 查询）
# 在 DEBUG=True 的开发模式下运行并访问页面
# 在 SQL 面板中查找重复查询

# 查询计数分析
django-admin debugsqlshell  # 如果安装了 django-debug-sqlshell

# 检查缺失的索引
python manage.py shell << EOF
from django.db import connection
with connection.cursor() as cursor:
    cursor.execute("SELECT table_name, index_name FROM information_schema.statistics WHERE table_schema = 'public'")
    print(cursor.fetchall())
EOF
```

报告：
- 每页查询数（典型页面应 < 50）
- 缺失的数据库索引
- 检测到的重复查询

## 阶段 8：静态资源

```bash
# 检查 npm 依赖（如果使用 npm）
npm audit
npm audit fix

# 构建静态文件（如果使用 webpack/vite）
npm run build

# 验证静态文件
ls -la staticfiles/
python manage.py findstatic css/style.css
```

## 阶段 9：配置审查

```python
# 在 Python shell 中运行以验证设置
python manage.py shell << EOF
from django.conf import settings
import os

# 关键检查
checks = {
    'DEBUG 为 False': not settings.DEBUG,
    'SECRET_KEY 已设置': bool(settings.SECRET_KEY and len(settings.SECRET_KEY) > 30),
    'ALLOWED_HOSTS 已设置': len(settings.ALLOWED_HOSTS) > 0,
    'HTTPS 已启用': getattr(settings, 'SECURE_SSL_REDIRECT', False),
    'HSTS 已启用': getattr(settings, 'SECURE_HSTS_SECONDS', 0) > 0,
    '数据库已配置': settings.DATABASES['default']['ENGINE'] != 'django.db.backends.sqlite3',
}

for check, result in checks.items():
    status = '✓' if result else '✗'
    print(f"{status} {check}")
EOF
```

## 阶段 10：日志配置

```bash
# 测试日志输出
python manage.py shell << EOF
import logging
logger = logging.getLogger('django')
logger.warning('测试警告消息')
logger.error('测试错误消息')
EOF

# 检查日志文件（如果已配置）
tail -f /var/log/django/django.log
```

## 阶段 11：API 文档（如果使用 DRF）

```bash
# 生成 schema
python manage.py generateschema --format openapi-json > schema.json

# 验证 schema
# 检查 schema.json 是否为有效 JSON
python -c "import json; json.load(open('schema.json'))"

# 访问 Swagger UI（如果使用 drf-yasg）
# 在浏览器中访问 http://localhost:8000/swagger/
```

## 阶段 12：Diff 审查

```bash
# 显示 diff 统计
git diff --stat

# 显示实际变更
git diff

# 显示变更文件
git diff --name-only

# 检查常见问题
git diff | grep -i "todo\|fixme\|hack\|xxx"
git diff | grep "print("  # 调试语句
git diff | grep "DEBUG = True"  # 调试模式
git diff | grep "import pdb"  # 调试器
```

检查清单：
- 没有调试语句（print、pdb、breakpoint()）
- 关键代码中没有 TODO/FIXME 注释
- 没有硬编码的密钥或凭据
- 模型变更包含数据库迁移
- 配置变更已记录
- 外部调用有错误处理
- 需要的地方有事务管理

## 输出模板

```
DJANGO 验证报告
==========================

阶段 1：环境检查
  ✓ Python 3.11.5
  ✓ 虚拟环境已激活
  ✓ 所有环境变量已设置

阶段 2：代码质量
  ✓ mypy：无类型错误
  ✗ ruff：发现 3 个问题（已自动修复）
  ✓ black：无格式问题
  ✓ isort：导入已正确排序
  ✓ manage.py check：无问题

阶段 3：迁移
  ✓ 无未应用的迁移
  ✓ 无迁移冲突
  ✓ 所有模型都有迁移

阶段 4：测试 + 覆盖率
  测试：247 通过，0 失败，5 跳过
  覆盖率：
    总体：87%
    users：92%
    products：89%
    orders：85%
    payments：91%

阶段 5：安全扫描
  ✗ pip-audit：发现 2 个漏洞（需要修复）
  ✓ safety check：无问题
  ✓ bandit：无安全问题
  ✓ 未检测到密钥
  ✓ DEBUG = False

阶段 6：Django 命令
  ✓ collectstatic 已完成
  ✓ 数据库完整性正常
  ✓ 缓存后端可达

阶段 7：性能
  ✓ 未检测到 N+1 查询
  ✓ 数据库索引已配置
  ✓ 查询计数可接受

阶段 8：静态资源
  ✓ npm audit：无漏洞
  ✓ 资源构建成功
  ✓ 静态文件已收集

阶段 9：配置
  ✓ DEBUG = False
  ✓ SECRET_KEY 已配置
  ✓ ALLOWED_HOSTS 已设置
  ✓ HTTPS 已启用
  ✓ HSTS 已启用
  ✓ 数据库已配置

阶段 10：日志
  ✓ 日志已配置
  ✓ 日志文件可写

阶段 11：API 文档
  ✓ Schema 已生成
  ✓ Swagger UI 可访问

阶段 12：Diff 审查
  变更文件：12
  +450, -120 行
  ✓ 无调试语句
  ✓ 无硬编码密钥
  ✓ 迁移已包含

建议：警告：部署前修复 pip-audit 漏洞

后续步骤：
1. 更新有漏洞的依赖
2. 重新运行安全扫描
3. 部署到预发环境进行最终测试
```

## 预部署检查清单

- [ ] 所有测试通过
- [ ] 覆盖率 ≥ 80%
- [ ] 无安全漏洞
- [ ] 无未应用的迁移
- [ ] 生产设置中 DEBUG = False
- [ ] SECRET_KEY 已正确配置
- [ ] ALLOWED_HOSTS 设置正确
- [ ] 数据库备份已启用
- [ ] 静态文件已收集并提供服务
- [ ] 日志已配置并正常工作
- [ ] 错误监控（Sentry 等）已配置
- [ ] CDN 已配置（如适用）
- [ ] Redis/缓存后端已配置
- [ ] Celery worker 已运行（如适用）
- [ ] HTTPS/SSL 已配置
- [ ] 环境变量已记录

## 持续集成

### GitHub Actions 示例

```yaml
# .github/workflows/django-verification.yml
name: Django 验证

on: [push, pull_request]

jobs:
  verify:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v3

      - name: 设置 Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: 缓存 pip
        uses: actions/cache@v3
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}

      - name: 安装依赖
        run: |
          pip install -r requirements.txt
          pip install ruff black mypy pytest pytest-django pytest-cov bandit safety pip-audit

      - name: 代码质量检查
        run: |
          ruff check .
          black . --check
          isort . --check-only
          mypy .

      - name: 安全扫描
        run: |
          bandit -r . -f json -o bandit-report.json
          safety check --full-report
          pip-audit

      - name: 运行测试
        env:
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
          DJANGO_SECRET_KEY: test-secret-key
        run: |
          pytest --cov=apps --cov-report=xml --cov-report=term-missing

      - name: 上传覆盖率
        uses: codecov/codecov-action@v3
```

## 快速参考

| 检查 | 命令 |
|-------|---------|
| 环境 | `python --version` |
| 类型检查 | `mypy .` |
| 代码检查 | `ruff check .` |
| 格式化 | `black . --check` |
| 迁移 | `python manage.py makemigrations --check` |
| 测试 | `pytest --cov=apps` |
| 安全 | `pip-audit && bandit -r .` |
| Django 检查 | `python manage.py check --deploy` |
| 收集静态文件 | `python manage.py collectstatic --noinput` |
| Diff 统计 | `git diff --stat` |

记住：自动化验证能捕获常见问题，但不能替代手动代码审查和在预发环境中的测试。
