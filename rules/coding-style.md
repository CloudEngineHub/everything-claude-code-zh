# 编码风格 (Coding Style)

## 不可变性 (Immutability) (关键)

永远创建新对象，永远不要突变 (NEVER mutate):

```javascript
// WRONG: Mutation
function updateUser(user, name) {
  user.name = name  // MUTATION!
  return user
}

// CORRECT: Immutability
function updateUser(user, name) {
  return {
    ...user,
    name
  }
}
```

## 文件组织

许多小文件 > 少数大文件:
- 高内聚，低耦合
- 200-400 行典型，最大 800 行
- 从大组件中提取实用程序
- 按特性/领域组织，而不是按类型

## 错误处理

始终全面处理错误：

```typescript
try {
  const result = await riskyOperation()
  return result
} catch (error) {
  console.error('Operation failed:', error)
  throw new Error('Detailed user-friendly message')
}
```

## 输入验证

始终验证用户输入：

```typescript
import { z } from 'zod'

const schema = z.object({
  email: z.string().email(),
  age: z.number().int().min(0).max(150)
})

const validated = schema.parse(input)
```

## 代码质量检查清单

在标记工作完成之前：
- [ ] 代码可读且命名良好
- [ ] 函数很小 (<50 行)
- [ ] 文件是专注的 (<800 行)
- [ ] 没有深度嵌套 (>4 层)
- [ ] 适当的错误处理
- [ ] 没有 console.log 语句
- [ ] 没有硬编码值
- [ ] 没有突变 (使用不可变模式)
