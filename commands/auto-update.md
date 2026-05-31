---
description: 拉取最新的 ECC 仓库变更并重新安装当前管理的目标。
disable-model-invocation: true
---

# 自动更新

从上游仓库更新 ECC，并使用原始安装状态请求重新生成当前上下文的管理安装。

## 用法

```bash
# 预览更新而不修改任何内容
ECC_ROOT="${CLAUDE_PLUGIN_ROOT:-$(node -e "var r=(()=>{var e=process.env.CLAUDE_PLUGIN_ROOT;if(e&&e.trim())return e.trim();var p=require('path'),f=require('fs'),h=require('os').homedir(),d=p.join(h,'.claude'),q=p.join('scripts','lib','utils.js');if(f.existsSync(p.join(d,q)))return d;for(var s of [['ecc'],['ecc@ecc'],['marketplace','ecc'],['everything-claude-code'],['everything-claude-code@everything-claude-code'],['marketplace','everything-claude-code']]){var l=p.join(d,'plugins',...s);if(f.existsSync(p.join(l,q)))return l}try{for(var g of ['ecc','everything-claude-code']){var b=p.join(d,'plugins','cache',g);for(var o of f.readdirSync(b,{withFileTypes:true})){if(!o.isDirectory())continue;for(var v of f.readdirSync(p.join(b,o.name),{withFileTypes:true})){if(!v.isDirectory())continue;var c=p.join(b,o.name,v.name);if(f.existsSync(p.join(c,q)))return c}}}}catch(x){}return d})();console.log(r)")}"
node "$ECC_ROOT/scripts/auto-update.js" --dry-run

# 仅更新当前项目中的 Cursor 管理文件
node "$ECC_ROOT/scripts/auto-update.js" --target cursor

# 显式覆盖 ECC 仓库根目录
node "$ECC_ROOT/scripts/auto-update.js" --repo-root /path/to/everything-claude-code
```

## 注意事项

- 此命令使用记录的安装状态请求，在拉取最新仓库变更后重新运行 `install-apply.js`。
- 重新安装是有意为之的：它处理 `repair.js` 无法仅从过时操作安全重建的上游重命名和删除。
- 如果你想在修改任何内容之前查看重建的重新安装计划，请先使用 `--dry-run`。
