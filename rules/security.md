# 安全指南 (Security Guidelines)

## 强制性安全检查

在任何提交之前：
- [ ] 没有硬编码 secrets (API keys, 密码, 令牌)
- [ ] 所有用户输入已验证
- [ ] SQL 注入预防 (参数化查询)
- [ ] XSS 预防 (清理 HTML)
- [ ] 启用了 CSRF 保护
- [ ] 验证了认证/授权
- [ ] 所有端点上的速率限制
- [ ] 错误消息不泄露敏感数据

## Secret 管理

```typescript
// NEVER: Hardcoded secrets
const apiKey = "sk-proj-xxxxx"

// ALWAYS: Environment variables
const apiKey = process.env.OPENAI_API_KEY

if (!apiKey) {
  throw new Error('OPENAI_API_KEY not configured')
}
```

## 安全响应协议

如果发现安全问题：
1. 立即停止
2. 使用 **security-reviewer** agent
3. 在继续之前修复 CRITICAL 问题
4. 轮换任何暴露的 secrets
5. 审查整个代码库中的类似问题
