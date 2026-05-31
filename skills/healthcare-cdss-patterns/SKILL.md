---
name: healthcare-cdss-patterns
description: 临床决策支持系统（CDSS）开发模式。药物相互作用检查、剂量验证、临床评分（NEWS2、qSOFA）、警报严重程度分类，以及集成到 EMR 工作流中。
origin: Health1 Super Speciality Hospitals — 贡献者：Dr. Keyur Patel
version: "1.0.0"
---

# 医疗 CDSS 开发模式

用于构建集成到 EMR 工作流的临床决策支持系统的模式。CDSS 模块对患者安全至关重要——对假阴性零容忍。

## 何时使用

- 实现药物相互作用检查
- 构建剂量验证引擎
- 实现临床评分系统（NEWS2、qSOFA、APACHE、GCS）
- 设计异常临床值的警报系统
- 构建带有安全检查的医嘱录入
- 将实验室结果解释与临床上下文集成

## 工作原理

CDSS 引擎是一个**具有零副作用的纯函数库**。输入临床数据，输出警报。这使其完全可测试。

三个主要模块：

1. **`checkInteractions(newDrug, currentMeds, allergies)`** — 检查新药与当前药物和已知过敏的相互作用。返回按严重程度排序的 `InteractionAlert[]`。使用 `DrugInteractionPair` 数据模型。
2. **`validateDose(drug, dose, route, weight, age, renalFunction)`** — 根据基于体重、年龄调整和肾脏调整的规则验证处方剂量。返回 `DoseValidationResult`。
3. **`calculateNEWS2(vitals)`** — 根据 `NEWS2Input` 计算国家早期预警评分 2。返回包含总分、风险级别和升级指导的 `NEWS2Result`。

```
EMR UI
  ↓ (用户输入数据)
CDSS 引擎（纯函数，无副作用）
  ├── 药物相互作用检查器
  ├── 剂量验证器
  ├── 临床评分（NEWS2、qSOFA 等）
  └── 警报分类器
  ↓ (返回警报)
EMR UI（内联显示警报，严重时阻止操作）
```

### 药物相互作用检查

```typescript
interface DrugInteractionPair {
  drugA: string;           // 通用名
  drugB: string;           // 通用名
  severity: 'critical' | 'major' | 'minor';
  mechanism: string;
  clinicalEffect: string;
  recommendation: string;
}

function checkInteractions(
  newDrug: string,
  currentMedications: string[],
  allergyList: string[]
): InteractionAlert[] {
  if (!newDrug) return [];
  const alerts: InteractionAlert[] = [];
  for (const current of currentMedications) {
    const interaction = findInteraction(newDrug, current);
    if (interaction) {
      alerts.push({ severity: interaction.severity, pair: [newDrug, current],
        message: interaction.clinicalEffect, recommendation: interaction.recommendation });
    }
  }
  for (const allergy of allergyList) {
    if (isCrossReactive(newDrug, allergy)) {
      alerts.push({ severity: 'critical', pair: [newDrug, allergy],
        message: `与记录的过敏存在交叉反应：${allergy}`,
        recommendation: '未经过敏咨询请勿开药' });
    }
  }
  return alerts.sort((a, b) => severityOrder(a.severity) - severityOrder(b.severity));
}
```

相互作用对必须是**双向的**：如果药物 A 与药物 B 相互作用，则药物 B 也与药物 A 相互作用。

### 剂量验证

```typescript
interface DoseValidationResult {
  valid: boolean;
  message: string;
  suggestedRange: { min: number; max: number; unit: string } | null;
  factors: string[];
}

function validateDose(
  drug: string,
  dose: number,
  route: 'oral' | 'iv' | 'im' | 'sc' | 'topical',
  patientWeight?: number,
  patientAge?: number,
  renalFunction?: number
): DoseValidationResult {
  const rules = getDoseRules(drug, route);
  if (!rules) return { valid: true, message: '无可用验证规则', suggestedRange: null, factors: [] };
  const factors: string[] = [];

  // 安全性：如果规则需要体重但体重缺失，阻止（而非通过）
  if (rules.weightBased) {
    if (!patientWeight || patientWeight <= 0) {
      return { valid: false, message: `${drug} 需要体重（mg/kg 药物）`,
        suggestedRange: null, factors: ['weight_missing'] };
    }
    factors.push('weight');
    const maxDose = rules.maxPerKg * patientWeight;
    if (dose > maxDose) {
      return { valid: false, message: `剂量超过 ${patientWeight}kg 的最大值`,
        suggestedRange: { min: rules.minPerKg * patientWeight, max: maxDose, unit: rules.unit }, factors };
    }
  }

  // 基于年龄的调整（当规则定义年龄分段且提供年龄时）
  if (rules.ageAdjusted && patientAge !== undefined) {
    factors.push('age');
    const ageMax = rules.getAgeAdjustedMax(patientAge);
    if (dose > ageMax) {
      return { valid: false, message: `超过 ${patientAge}yr 的年龄调整最大值`,
        suggestedRange: { min: rules.typicalMin, max: ageMax, unit: rules.unit }, factors };
    }
  }

  // 肾脏调整（当规则定义 eGFR 分段且提供 eGFR 时）
  if (rules.renalAdjusted && renalFunction !== undefined) {
    factors.push('renal');
    const renalMax = rules.getRenalAdjustedMax(renalFunction);
    if (dose > renalMax) {
      return { valid: false, message: `超过 eGFR ${renalFunction} 的肾脏调整最大值`,
        suggestedRange: { min: rules.typicalMin, max: renalMax, unit: rules.unit }, factors };
    }
  }

  // 绝对最大值
  if (dose > rules.absoluteMax) {
    return { valid: false, message: `超过绝对最大值 ${rules.absoluteMax}${rules.unit}`,
      suggestedRange: { min: rules.typicalMin, max: rules.absoluteMax, unit: rules.unit },
      factors: [...factors, 'absolute_max'] };
  }
  return { valid: true, message: '在范围内',
    suggestedRange: { min: rules.typicalMin, max: rules.typicalMax, unit: rules.unit }, factors };
}
```

### 临床评分：NEWS2

```typescript
interface NEWS2Input {
  respiratoryRate: number; oxygenSaturation: number; supplementalOxygen: boolean;
  temperature: number; systolicBP: number; heartRate: number;
  consciousness: 'alert' | 'voice' | 'pain' | 'unresponsive';
}
interface NEWS2Result {
  total: number;           // 0-20
  risk: 'low' | 'low-medium' | 'medium' | 'high';
  components: Record<string, number>;
  escalation: string;
}
```

评分表必须与皇家内科医师学会规范完全匹配。

### 警报严重程度和 UI 行为

| 严重程度 | UI 行为 | 需要临床医生操作 |
|----------|---------|------------------|
| 危急 | 阻止操作。不可关闭的模态框。红色。 | 必须记录覆盖原因才能继续 |
| 重要 | 内联警告横幅。橙色。 | 继续前必须确认 |
| 次要 | 内联信息提示。黄色。 | 仅需知晓，无需操作 |

危急警报绝不能自动关闭或实现为 toast 通知。覆盖原因必须存储在审计跟踪中。

### 测试 CDSS（对假阴性零容忍）

```typescript
describe('CDSS — 患者安全', () => {
  INTERACTION_PAIRS.forEach(({ drugA, drugB, severity }) => {
    it(`检测 ${drugA} + ${drugB} (${severity})`, () => {
      const alerts = checkInteractions(drugA, [drugB], []);
      expect(alerts.length).toBeGreaterThan(0);
      expect(alerts[0].severity).toBe(severity);
    });
    it(`检测 ${drugB} + ${drugA} (反向)`, () => {
      const alerts = checkInteractions(drugB, [drugA], []);
      expect(alerts.length).toBeGreaterThan(0);
    });
  });
  it('体重缺失时阻止 mg/kg 药物', () => {
    const result = validateDose('gentamicin', 300, 'iv');
    expect(result.valid).toBe(false);
    expect(result.factors).toContain('weight_missing');
  });
  it('优雅处理格式错误的药物数据', () => {
    expect(() => checkInteractions('', [], [])).not.toThrow();
  });
});
```

通过标准：100%。单个遗漏的相互作用就是患者安全事件。

### 反模式

- 使 CDSS 检查可选或可跳过而无需记录原因
- 将相互作用检查实现为 toast 通知
- 对药物或临床数据使用 `any` 类型
- 硬编码相互作用对而非使用可维护的数据结构
- 静默捕获 CDSS 引擎中的错误（必须大声暴露失败）
- 体重不可用时跳过基于体重的验证（必须阻止，而非通过）

## 示例

### 示例 1：药物相互作用检查

```typescript
const alerts = checkInteractions('warfarin', ['aspirin', 'metformin'], ['penicillin']);
// [{ severity: 'critical', pair: ['warfarin', 'aspirin'],
//    message: '出血风险增加', recommendation: '避免联合使用' }]
```

### 示例 2：剂量验证

```typescript
const ok = validateDose('paracetamol', 1000, 'oral', 70, 45);
// { valid: true, suggestedRange: { min: 500, max: 4000, unit: 'mg' } }

const bad = validateDose('paracetamol', 5000, 'oral', 70, 45);
// { valid: false, message: '超过绝对最大值 4000mg' }

const noWeight = validateDose('gentamicin', 300, 'iv');
// { valid: false, factors: ['weight_missing'] }
```

### 示例 3：NEWS2 评分

```typescript
const result = calculateNEWS2({
  respiratoryRate: 24, oxygenSaturation: 93, supplementalOxygen: true,
  temperature: 38.5, systolicBP: 100, heartRate: 110, consciousness: 'voice'
});
// { total: 13, risk: 'high', escalation: '紧急临床复查。考虑 ICU。' }
```
