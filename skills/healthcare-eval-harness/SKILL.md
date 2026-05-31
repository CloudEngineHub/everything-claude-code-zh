---
name: healthcare-eval-harness
description: 医疗应用程序部署的患者安全评估工具。CDSS 准确性、PHI 暴露、临床工作流完整性和集成合规性的自动化测试套件。在安全失败时阻止部署。
origin: Health1 Super Speciality Hospitals — 贡献者：Dr. Keyur Patel
version: "1.0.0"
---

# 医疗评估工具 — 患者安全验证

医疗应用程序部署的自动化验证系统。单次危急失败即可阻止部署。患者安全不容妥协。

> **注意：** 示例使用 Jest 作为参考测试运行器。请根据您的框架（Vitest、pytest、PHPUnit 等）调整命令——测试类别和通过标准是框架无关的。

## 何时使用

- 在 EMR/EHR 应用程序的任何部署之前
- 修改 CDSS 逻辑后（药物相互作用、剂量验证、评分）
- 修改接触患者数据的数据库架构后
- 修改身份验证或访问控制后
- 在医疗应用程序的 CI/CD 管道配置期间
- 解决临床模块中的合并冲突后

## 工作原理

评估工具按顺序运行五个测试类别。前三个（CDSS 准确性、PHI 暴露、数据完整性）是危急关卡，需要 100% 的通过率——单次失败即可阻止部署。其余两个（临床工作流、集成）是高级关卡，需要 95%+ 的通过率。

每个类别映射到一个 Jest 测试路径模式。CI 管道使用 `--bail`（首次失败时停止）运行危急关卡，并使用 `--coverage --coverageThreshold` 强制覆盖阈值。

### 评估类别

**1. CDSS 准确性（危急 — 100% 必需）**

测试所有临床决策支持逻辑：药物相互作用对（双向）、剂量验证规则、临床评分与已发布规范的对比、无假阴性、无静默失败。

```bash
npx jest --testPathPattern='tests/cdss' --bail --ci --coverage
```

**2. PHI 暴露（危急 — 100% 必需）**

测试受保护健康信息泄露：API 错误响应、控制台输出、URL 参数、浏览器存储、跨机构隔离、未授权访问、服务角色密钥缺失。

```bash
npx jest --testPathPattern='tests/security/phi' --bail --ci
```

**3. 数据完整性（危急 — 100% 必需）**

测试临床数据安全：锁定的就诊、审计跟踪条目、级联删除保护、并发编辑处理、无孤立记录。

```bash
npx jest --testPathPattern='tests/data-integrity' --bail --ci
```

**4. 临床工作流（高级 — 95%+ 必需）**

测试端到端流程：就诊生命周期、模板渲染、药物集、药物/诊断搜索、处方 PDF、危险信号警报。

```bash
tmp_json=$(mktemp)
npx jest --testPathPattern='tests/clinical' --ci --json --outputFile="$tmp_json" || true
total=$(jq '.numTotalTests // 0' "$tmp_json")
passed=$(jq '.numPassedTests // 0' "$tmp_json")
if [ "$total" -eq 0 ]; then
  echo "未找到临床测试" >&2
  exit 1
fi
rate=$(echo "scale=2; $passed * 100 / $total" | bc)
echo "临床通过率：${rate}% ($passed/$total)"
```

**5. 集成合规性（高级 — 95%+ 必需）**

测试外部系统：HL7 消息解析（v2.x）、FHIR 验证、实验室结果映射、格式错误消息处理。

```bash
tmp_json=$(mktemp)
npx jest --testPathPattern='tests/integration' --ci --json --outputFile="$tmp_json" || true
total=$(jq '.numTotalTests // 0' "$tmp_json")
passed=$(jq '.numPassedTests // 0' "$tmp_json")
if [ "$total" -eq 0 ]; then
  echo "未找到集成测试" >&2
  exit 1
fi
rate=$(echo "scale=2; $passed * 100 / $total" | bc)
echo "集成通过率：${rate}% ($passed/$total)"
```

### 通过/失败矩阵

| 类别 | 阈值 | 失败时操作 |
|----------|-----------|------------|
| CDSS 准确性 | 100% | **阻止部署** |
| PHI 暴露 | 100% | **阻止部署** |
| 数据完整性 | 100% | **阻止部署** |
| 临床工作流 | 95%+ | 警告，审查后允许 |
| 集成 | 95%+ | 警告，审查后允许 |

### CI/CD 集成

```yaml
name: 医疗安全关卡
on: [push, pull_request]

jobs:
  safety-gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci

      # 危急关卡 — 100% 必需，首次失败时中止
      - name: CDSS 准确性
        run: npx jest --testPathPattern='tests/cdss' --bail --ci --coverage --coverageThreshold='{"global":{"branches":80,"functions":80,"lines":80}}'

      - name: PHI 暴露检查
        run: npx jest --testPathPattern='tests/security/phi' --bail --ci

      - name: 数据完整性
        run: npx jest --testPathPattern='tests/data-integrity' --bail --ci

      # 高级关卡 — 95%+ 必需，自定义阈值检查
      # 高级关卡 — 95%+ 必需
      - name: 临床工作流
        run: |
          TMP_JSON=$(mktemp)
          npx jest --testPathPattern='tests/clinical' --ci --json --outputFile="$TMP_JSON" || true
          TOTAL=$(jq '.numTotalTests // 0' "$TMP_JSON")
          PASSED=$(jq '.numPassedTests // 0' "$TMP_JSON")
          if [ "$TOTAL" -eq 0 ]; then
            echo "::error::未找到临床测试"; exit 1
          fi
          RATE=$(echo "scale=2; $PASSED * 100 / $TOTAL" | bc)
          echo "通过率：${RATE}% ($PASSED/$TOTAL)"
          if (( $(echo "$RATE < 95" | bc -l) )); then
            echo "::warning::临床通过率 ${RATE}% 低于 95%"
          fi

      - name: 集成合规性
        run: |
          TMP_JSON=$(mktemp)
          npx jest --testPathPattern='tests/integration' --ci --json --outputFile="$TMP_JSON" || true
          TOTAL=$(jq '.numTotalTests // 0' "$TMP_JSON")
          PASSED=$(jq '.numPassedTests // 0' "$TMP_JSON")
          if [ "$TOTAL" -eq 0 ]; then
            echo "::error::未找到集成测试"; exit 1
          fi
          RATE=$(echo "scale=2; $PASSED * 100 / $TOTAL" | bc)
          echo "通过率：${RATE}% ($PASSED/$TOTAL)"
          if (( $(echo "$RATE < 95" | bc -l) )); then
            echo "::warning::集成通过率 ${RATE}% 低于 95%"
          fi
```

### 反模式

- 跳过 CDSS 测试"因为上次通过了"
- 将危急阈值设置为低于 100%
- 在危急测试套件上使用 `--no-bail`
- 在集成测试中模拟 CDSS 引擎（必须测试真实逻辑）
- 当安全关卡为红色时允许部署
- 在 CDSS 套件上运行不带 `--coverage` 的测试

## 示例

### 示例 1：本地运行所有危急关卡

```bash
npx jest --testPathPattern='tests/cdss' --bail --ci --coverage && \
npx jest --testPathPattern='tests/security/phi' --bail --ci && \
npx jest --testPathPattern='tests/data-integrity' --bail --ci
```

### 示例 2：检查高级关卡通过率

```bash
tmp_json=$(mktemp)
npx jest --testPathPattern='tests/clinical' --ci --json --outputFile="$tmp_json" || true
jq '{
  passed: (.numPassedTests // 0),
  total: (.numTotalTests // 0),
  rate: (if (.numTotalTests // 0) == 0 then 0 else ((.numPassedTests // 0) / (.numTotalTests // 1) * 100) end)
}' "$tmp_json"
# 预期：{ "passed": 21, "total": 22, "rate": 95.45 }
```

### 示例 3：评估报告

```
## 医疗评估：2026-03-27 [提交 abc1234]

### 患者安全：通过

| 类别 | 测试 | 通过 | 失败 | 状态 |
|----------|-------|------|------|--------|
| CDSS 准确性 | 39 | 39 | 0 | 通过 |
| PHI 暴露 | 8 | 8 | 0 | 通过 |
| 数据完整性 | 12 | 12 | 0 | 通过 |
| 临床工作流 | 22 | 21 | 1 | 95.5% 通过 |
| 集成 | 6 | 6 | 0 | 通过 |

### 覆盖率：84%（目标：80%+）
### 结论：可安全部署
```
