| name | description |
|------|-------------|
| cloud-infrastructure-security | 当部署到云平台、配置基础设施、管理 IAM 策略、设置日志/监控或实施 CI/CD 管道时使用此技能。提供符合最佳实践的云安全检查清单。 |

# 云与基础设施安全技能 (Cloud & Infrastructure Security Skill)

此技能确保云基础设施、CI/CD 管道和部署配置遵循安全最佳实践并符合行业标准。

## 何时激活

- 将应用程序部署到云平台 (AWS, Vercel, Railway, Cloudflare)
- 配置 IAM 角色和权限
- 设置 CI/CD 管道
- 实施基础设施即代码 (Terraform, CloudFormation)
- 配置日志和监控
- 在云环境中管理 secrets
- 设置 CDN 和边缘安全
- 实施灾难恢复和备份策略

## 云安全检查清单

### 1. IAM & 访问控制 (IAM & Access Control)

#### 最小特权原则 (Principle of Least Privilege)

```yaml
# ✅ CORRECT: Minimal permissions
iam_role:
  permissions:
    - s3:GetObject  # Only read access
    - s3:ListBucket
  resources:
    - arn:aws:s3:::my-bucket/*  # Specific bucket only

# ❌ WRONG: Overly broad permissions
iam_role:
  permissions:
    - s3:*  # All S3 actions
  resources:
    - "*"  # All resources
```

#### 多因素认证 (MFA)

```bash
# ALWAYS enable MFA for root/admin accounts
aws iam enable-mfa-device \
  --user-name admin \
  --serial-number arn:aws:iam::123456789:mfa/admin \
  --authentication-code1 123456 \
  --authentication-code2 789012
```

#### 验证步骤

- [ ] 生产环境中不使用 root 账户
- [ ] 为所有特权账户启用了 MFA
- [ ] 服务账户使用角色，而不是长期凭证
- [ ] IAM 策略遵循最小特权
- [ ] 定期进行访问审查
- [ ] 轮换或移除未使用的凭证

### 2. Secrets 管理 (Secrets Management)

#### 云 Secrets 管理器

```typescript
// ✅ CORRECT: Use cloud secrets manager
import { SecretsManager } from '@aws-sdk/client-secrets-manager';

const client = new SecretsManager({ region: 'us-east-1' });
const secret = await client.getSecretValue({ SecretId: 'prod/api-key' });
const apiKey = JSON.parse(secret.SecretString).key;

// ❌ WRONG: Hardcoded or in environment variables only
const apiKey = process.env.API_KEY; // Not rotated, not audited
```

#### Secrets 轮换

```bash
# Set up automatic rotation for database credentials
aws secretsmanager rotate-secret \
  --secret-id prod/db-password \
  --rotation-lambda-arn arn:aws:lambda:region:account:function:rotate \
  --rotation-rules AutomaticallyAfterDays=30
```

#### 验证步骤

- [ ] 所有 secrets 存储在云 secrets 管理器 (AWS Secrets Manager, Vercel Secrets) 中
- [ ] 为数据库凭证启用了自动轮换
- [ ] API keys 至少每季度轮换一次
- [ ] 代码、日志或错误消息中没有 secrets
- [ ] 为 secret 访问启用了审计日志

### 3. 网络安全 (Network Security)

#### VPC 和防火墙配置

```terraform
# ✅ CORRECT: Restricted security group
resource "aws_security_group" "app" {
  name = "app-sg"
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Internal VPC only
  }
  
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Only HTTPS outbound
  }
}

# ❌ WRONG: Open to the internet
resource "aws_security_group" "bad" {
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # All ports, all IPs!
  }
}
```

#### 验证步骤

- [ ] 数据库不可公开访问
- [ ] SSH/RDP 端口仅限制为 VPN/bastion
- [ ] 安全组遵循最小特权
- [ ] 配置了网络 ACL
- [ ] 启用了 VPC 流日志

### 4. 日志 & 监控 (Logging & Monitoring)

#### CloudWatch/日志配置

```typescript
// ✅ CORRECT: Comprehensive logging
import { CloudWatchLogsClient, CreateLogStreamCommand } from '@aws-sdk/client-cloudwatch-logs';

const logSecurityEvent = async (event: SecurityEvent) => {
  await cloudwatch.putLogEvents({
    logGroupName: '/aws/security/events',
    logStreamName: 'authentication',
    logEvents: [{
      timestamp: Date.now(),
      message: JSON.stringify({
        type: event.type,
        userId: event.userId,
        ip: event.ip,
        result: event.result,
        // Never log sensitive data
      })
    }]
  });
};
```

#### 验证步骤

- [ ] 为所有服务启用了 CloudWatch/日志
- [ ] 记录了失败的认证尝试
- [ ] 审计了管理员操作
- [ ] 配置了日志保留 (90+ 天以符合规)
- [ ] 为可疑活动配置了警报
- [ ] 日志集中且防篡改

### 5. CI/CD 管道安全 (CI/CD Pipeline Security)

#### 安全管道配置

```yaml
# ✅ CORRECT: Secure GitHub Actions workflow
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read  # Minimal permissions
      
    steps:
      - uses: actions/checkout@v4
      
      # Scan for secrets
      - name: Secret scanning
        uses: trufflesecurity/trufflehog@main
        
      # Dependency audit
      - name: Audit dependencies
        run: npm audit --audit-level=high
        
      # Use OIDC, not long-lived tokens
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789:role/GitHubActionsRole
          aws-region: us-east-1
```

#### 供应链安全

```json
// package.json - Use lock files and integrity checks
{
  "scripts": {
    "install": "npm ci",  // Use ci for reproducible builds
    "audit": "npm audit --audit-level=moderate",
    "check": "npm outdated"
  }
}
```

#### 验证步骤

- [ ] 使用 OIDC 而不是长期凭证
- [ ] 管道中的 secrets 扫描
- [ ] 依赖项漏洞扫描
- [ ] 容器镜像扫描 (如果适用)
- [ ] 强制执行分支保护规则
- [ ] 合并前需要代码审查
- [ ] 强制执行签名提交

### 6. Cloudflare & CDN 安全

#### Cloudflare 安全配置

```typescript
// ✅ CORRECT: Cloudflare Workers with security headers
export default {
  async fetch(request: Request): Promise<Response> {
    const response = await fetch(request);
    
    // Add security headers
    const headers = new Headers(response.headers);
    headers.set('X-Frame-Options', 'DENY');
    headers.set('X-Content-Type-Options', 'nosniff');
    headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
    headers.set('Permissions-Policy', 'geolocation=(), microphone=()');
    
    return new Response(response.body, {
      status: response.status,
      headers
    });
  }
};
```

#### WAF 规则

```bash
# Enable Cloudflare WAF managed rules
# - OWASP Core Ruleset
# - Cloudflare Managed Ruleset
# - Rate limiting rules
# - Bot protection
```

#### 验证步骤

- [ ] 启用了带有 OWASP 规则的 WAF
- [ ] 配置了速率限制
- [ ] Bot 保护处于活动状态
- [ ] 启用了 DDoS 保护
- [ ] 配置了安全标头
- [ ] 启用了 SSL/TLS 严格模式

### 7. 备份 & 灾难恢复 (Backup & Disaster Recovery)

#### 自动备份

```terraform
# ✅ CORRECT: Automated RDS backups
resource "aws_db_instance" "main" {
  allocated_storage     = 20
  engine               = "postgres"
  
  backup_retention_period = 30  # 30 days retention
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"
  
  enabled_cloudwatch_logs_exports = ["postgresql"]
  
  deletion_protection = true  # Prevent accidental deletion
}
```

#### 验证步骤

- [ ] 配置了自动每日备份
- [ ] 备份保留符合合规要求
- [ ] 启用了时间点恢复
- [ ] 每季度执行备份测试
- [ ] 记录了灾难恢复计划
- [ ] 定义并测试了 RPO 和 RTO

## 部署前云安全检查清单

在任何生产云部署之前：

- [ ] **IAM**: 不使用 Root 账户，启用了 MFA，最小特权策略
- [ ] **Secrets**: 所有 secrets在云 secrets 管理器中并有轮换
- [ ] **Network**: 安全组受限，没有公共数据库
- [ ] **Logging**: 启用了 CloudWatch/日志并有保留
- [ ] **Monitoring**: 为异常配置了警报
- [ ] **CI/CD**: OIDC 认证，secrets 扫描，依赖项审计
- [ ] **CDN/WAF**: 启用了带有 OWASP 规则的 Cloudflare WAF
- [ ] **Encryption**: 静态和传输中数据已加密
- [ ] **Backups**: 具有经过测试的恢复的自动备份
- [ ] **Compliance**: 满足 GDPR/HIPAA 要求 (如果适用)
- [ ] **Documentation**: 基础设施已记录，创建了 runbooks
- [ ] **Incident Response**: 安全事件计划到位

## 常见云安全错误配置

### S3 Bucket 暴露

```bash
# ❌ WRONG: Public bucket
aws s3api put-bucket-acl --bucket my-bucket --acl public-read

# ✅ CORRECT: Private bucket with specific access
aws s3api put-bucket-acl --bucket my-bucket --acl private
aws s3api put-bucket-policy --bucket my-bucket --policy file://policy.json
```

### RDS 公共访问

```terraform
# ❌ WRONG
resource "aws_db_instance" "bad" {
  publicly_accessible = true  # NEVER do this!
}

# ✅ CORRECT
resource "aws_db_instance" "good" {
  publicly_accessible = false
  vpc_security_group_ids = [aws_security_group.db.id]
}
```

## 资源

- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)
- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)
- [Cloudflare Security Documentation](https://developers.cloudflare.com/security/)
- [OWASP Cloud Security](https://owasp.org/www-project-cloud-security/)
- [Terraform Security Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/)

**记住**：云错误配置是数据泄露的主要原因。单个暴露的 S3 bucket 或过于宽松的 IAM 策略可能会危及整个基础设施。始终遵循最小特权和深度防御原则。
