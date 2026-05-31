---
name: gget
description: gget CLI 和 Python 工作流，用于快速基因组数据库查询、序列查找、BLAST 风格搜索、富集检查和可重复的生物信息学证据日志。
origin: community
---

# gget

当任务需要通过 `gget` CLI 或 Python 包跨基因组参考数据库进行快速生物信息学查询时，使用此技能。

## 何时使用

- 查找 Ensembl ID、基因元数据、转录本详情或序列。
- 无需构建完整的本地流水线即可运行快速 BLAST 或 BLAT 查询。
- 从 Ensembl 获取参考基因组链接和注释。
- 通过单一界面查询蛋白质结构、通路、癌症、表达或疾病关联模块。
- 在使用更重型工具（如 Biopython、Snakemake、Nextflow、BLAST+ 或特定数据库客户端）之前，创建可重复的初步证据日志。

当任务需要受监管的临床解释、高通量生产流水线或对数据库版本和本地索引的精细控制时，请使用专用工作流而非 `gget`。

## 安装

使用干净的 Python 环境。

```bash
python -m venv .venv
. .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install --upgrade gget
gget --help
```

如果 `uv` 可用：

```bash
uv venv
. .venv/bin/activate
uv pip install gget
```

在依赖旧环境之前，升级 `gget` 并重新检查模块文档。`gget` 查询的上游数据库会随时间变化。

## 基本模式

CLI 用法：

```bash
gget <module> [arguments] [options]
```

Python 用法：

```python
import gget

result = gget.search(["BRCA1"], species="human")
print(result)
```

常用工作流：

1. 确定所需的物种、组装、基因 ID 类型和数据库。
2. 检查当前模块文档以确认参数。
3. 先运行一个小查询。
4. 使用显式文件名和日期保存输出。
5. 记录模块名称、版本、参数和数据库假设。

## 常用模块

使用当前上游文档确认确切参数。这些模块是常用的首选：

- `gget search`：从搜索词查找 Ensembl ID。
- `gget info`：检索 Ensembl、UniProt 或相关 ID 的元数据。
- `gget seq`：获取核苷酸或氨基酸序列。
- `gget ref`：检索参考基因组下载链接。
- `gget blast`：运行快速 BLAST 查询。
- `gget blat`：在支持的基因组组装上定位序列。
- `gget muscle`：运行多序列比对。
- `gget diamond`：对参考序列运行本地序列比对。
- `gget alphafold` 和 `gget pdb`：检查蛋白质结构参考。
- `gget enrichr`、`gget opentargets`、`gget archs4`、`gget bgee`、`gget cbio`、`gget cosmic`：探索富集、靶点、表达、癌症和疾病关联数据。

不要假设每个模块都支持每个 Python 版本或依赖集。某些可选的科学依赖比核心包有更窄的版本支持。

## 快速示例

查找基因：

```bash
gget search -s human brca1 dna repair -o brca1-search.json
```

获取基因元数据：

```bash
gget info ENSG00000012048 -o brca1-info.json
```

获取序列：

```bash
gget seq ENSG00000012048 -o brca1-seq.fa
```

运行小型 BLAST 查询：

```bash
gget blast "MEEPQSDPSVEPPLSQETFSDLWKLLPEN" -l 10 -o blast-results.json
```

Python 示例：

```python
import gget

genes = gget.search(["BRCA1", "DNA repair"], species="human")
info = gget.info(["ENSG00000012048"])
sequence = gget.seq("ENSG00000012048")
```

## 可重复性日志

对于科学输出，包含足够的元数据以重放查询。

```markdown
| 日期 | gget 版本 | 模块 | 查询 | 物种/组装 | 输出 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-05-11 | `gget --version` | search | `BRCA1 DNA repair` | human | `brca1-search.json` | 运行前检查了文档 |
```

还需记录：

- Python 版本和环境管理器。
- 通过 `gget setup` 安装的任何可选依赖。
- 查询返回的特定数据库标识符。
- 输出是 JSON、CSV、FASTA 还是 DataFrame 导出。
- 通过升级 `gget` 解决的任何失败。

## 审查清单

- 是否升级或验证了已安装的 `gget` 版本？
- 是否在使用参数之前检查了当前上游模块文档？
- 物种或组装是否明确？
- 标识符是否精确保留，包括 Ensembl/UniProt 前缀？
- 结果是否标记为数据库输出而非临床解释？
- 从保存的命令或 Python 代码片段是否可以重现查询？
- 可选依赖是否安装在隔离环境中？

## 参考文献

- [gget 文档](https://pachterlab.github.io/gget/)
- [gget 更新](https://pachterlab.github.io/gget/en/updates.html)
- [gget GitHub 仓库](https://github.com/pachterlab/gget)
- [gget 生物信息学论文](https://doi.org/10.1093/bioinformatics/btac836)
