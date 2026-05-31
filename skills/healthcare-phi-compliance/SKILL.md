---
name: healthcare-phi-compliance
description: 医疗应用程序的受保护健康信息（PHI）和个人身份信息（PII）合规模式。涵盖数据分类、访问控制、审计跟踪、加密和常见泄露向量。
origin: Health1 Super Speciality Hospitals — 贡献者：Dr. Keyur Patel
version: "1.0.0"
---

# 医疗 PHI/PII 合规模式

用于保护医疗应用程序中患者数据、临床医生数据和财务数据的模式。适用于 HIPAA（美国）、DISHA（印度）、GDPR（欧盟）和通用医疗数据保护。

## 何时使用

- 构建任何接触患者记录的功能
- 为临床系统实现访问控制或身份验证
- 设计医疗数据的数据库架构
- 构建返回患者或临床医生数据的 API
- 实现审计跟踪或日志记录
- 审查代码的数据暴露漏洞
- 为多租户医疗系统设置行级安全性（RLS）

## 工作原理

医疗数据保护在三个层面运作：**分类**（什么是敏感的）、**访问控制**（谁可以看到它）和**审计**（谁确实看到了它）。

### 数据分类

**PHI（受保护健康信息）** — 可以识别患者且与其健康相关的任何数据：患者姓名、出生日期、地址、电话、电子邮件、国家 ID 号码（SSN、Aadhaar、NHS 号码）、医疗记录号码、诊断、药物、实验室结果、影像、保险单和索赔详情、预约和入院记录，或上述任何组合。

**PII（非患者敏感数据）** 在医疗系统中：临床医生/员工个人详细信息、医生费用结构和支付金额、员工薪资和银行详细信息、供应商支付信息。

### 访问控制：行级安全性

```sql
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;

-- 按机构限制访问
CREATE POLICY "staff_read_own_facility"
  ON patients FOR SELECT TO authenticated
  USING (facility_id IN (
    SELECT facility_id FROM staff_assignments
    WHERE user_id = auth.uid() AND role IN ('doctor','nurse','lab_tech','admin')
  ));

-- 审计日志：仅插入（防篡改）
CREATE POLICY "audit_insert_only" ON audit_log FOR INSERT
  TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "audit_no_modify" ON audit_log FOR UPDATE USING (false);
CREATE POLICY "audit_no_delete" ON audit_log FOR DELETE USING (false);
```

### 审计跟踪

每次 PHI 访问或修改必须记录：

```typescript
interface AuditEntry {
  timestamp: string;
  user_id: string;
  patient_id: string;
  action: 'create' | 'read' | 'update' | 'delete' | 'print' | 'export';
  resource_type: string;
  resource_id: string;
  changes?: { before: object; after: object };
  ip_address: string;
  session_id: string;
}
```

### 常见泄露向量

**错误消息：** 永远不要在抛给客户端的错误消息中包含患者识别数据。仅在服务器端记录详细信息。

**控制台输出：** 永远不要记录完整的患者对象。使用不透明的内部记录 ID（UUID）——而非医疗记录号码、国家 ID 或姓名。

**URL 参数：** 永远不要将患者识别数据放在可能出现在日志或浏览器历史记录中的查询字符串或路径段中。仅使用不透明的 UUID。

**浏览器存储：** 永远不要在 localStorage 或 sessionStorage 中存储 PHI。仅将 PHI 保存在内存中，按需获取。

**服务角色密钥：** 永远不要在客户端代码中使用 service_role 密钥。始终使用 anon/publishable 密钥，让 RLS 强制执行访问。

**日志和监控：** 永远不要记录完整的患者记录。仅使用不透明的记录 ID（而非医疗记录号码）。在发送到错误跟踪服务之前清理堆栈跟踪。

### 数据库架构标记

在架构级别标记 PHI/PII 列：

```sql
COMMENT ON COLUMN patients.name IS 'PHI: patient_name';
COMMENT ON COLUMN patients.dob IS 'PHI: date_of_birth';
COMMENT ON COLUMN patients.aadhaar IS 'PHI: national_id';
COMMENT ON COLUMN doctor_payouts.amount IS 'PII: financial';
```

### 部署检查清单

每次部署前：
- 错误消息或堆栈跟踪中无 PHI
- console.log/console.error 中无 PHI
- URL 参数中无 PHI
- 浏览器存储中无 PHI
- 客户端代码中无 service_role 密钥
- 所有 PHI/PII 表上启用 RLS
- 所有数据修改的审计跟踪
- 配置会话超时
- 所有 PHI 端点上的 API 身验证
- 验证跨机构数据隔离

## 示例

### 示例 1：安全与不安全的错误处理

```typescript
// 错误 — 在错误中泄露 PHI
throw new Error(`在 ${patient.facility} 中未找到患者 ${patient.name}`);

// 正确 — 通用错误，仅在服务器端记录带有不透明 ID 的详细信息
logger.error('患者查找失败', { recordId: patient.id, facilityId });
throw new Error('未找到记录');
```

### 示例 2：多机构隔离的 RLS 策略

```sql
-- 机构 A 的医生无法看到机构 B 的患者
CREATE POLICY "facility_isolation"
  ON patients FOR SELECT TO authenticated
  USING (facility_id IN (
    SELECT facility_id FROM staff_assignments WHERE user_id = auth.uid()
  ));

-- 测试：以 doctor-facility-a 身份登录，查询 facility-b 患者
-- 预期：返回 0 行
```

### 示例 3：安全日志记录

```typescript
// 错误 — 记录可识别的患者数据
console.log('正在处理患者：', patient);

// 正确 — 仅记录不透明的内部记录 ID
console.log('正在处理记录：', patient.id);
// 注意：即使是 patient.id 也应该是不透明的 UUID，而非医疗记录号码
```
