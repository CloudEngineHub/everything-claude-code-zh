---
name: windows-desktop-e2e
description: 使用 pywinauto 和 Windows UI Automation 进行 Windows 原生桌面应用（WPF、WinForms、Win32/MFC、Qt）的 E2E 测试。
origin: ECC
---

# Windows 桌面 E2E 测试

使用基于 Windows UI Automation (UIA) 的 **pywinauto** 对 Windows 原生桌面应用进行端到端测试。涵盖 WPF、WinForms、Win32/MFC 和 Qt（5.x / 6.x）— Qt 特定指导作为独立章节。

## 何时激活

- 编写或运行 Windows 原生桌面应用的 E2E 测试
- 从零搭建桌面 GUI 测试套件
- 诊断不稳定或失败的桌面自动化测试
- 为现有应用添加可测试性（AutomationId、无障碍名称）
- 将桌面 E2E 集成到 CI/CD 管道（GitHub Actions `windows-latest`）

### 何时不使用

- Web 应用 → 使用 `e2e-testing` 技能（Playwright）
- Electron / CEF / WebView2 应用 → HTML 层需要浏览器自动化，而非 UIA
- 移动应用 → 使用平台特定工具（UIAutomator、XCUITest）
- 纯单元或集成测试，不需要运行中的 GUI

## 核心概念

所有 Windows 桌面自动化都依赖 **UI Automation (UIA)**，这是 Windows 内置的无障碍 API。每个支持的框架都暴露一个 UIA 元素树，其属性 Claude 可以读取和操作：

```
你的测试 (Python)
    └── pywinauto (UIA 后端)
        └── Windows UI Automation API   ← 内置于 Windows，框架无关
            └── 应用的 UIA 提供者      ← 每个框架自带
                └── 运行中的 .exe
```

**各框架的 UIA 质量：**

| 框架 | AutomationId | 可靠性 | 备注 |
|-----------|-------------|-------------|-------|
| WPF | ★★★★★ | 优秀 | `x:Name` 直接映射为 AutomationId |
| WinForms | ★★★★☆ | 良好 | `AccessibleName` = AutomationId |
| UWP / WinUI 3 | ★★★★★ | 优秀 | 完整 Microsoft 支持 |
| Qt 6.x | ★★★★★ | 优秀 | 默认启用无障碍；类名变为 `Qt6*` |
| Qt 5.15+ | ★★★★☆ | 良好 | 改进的无障碍模块 |
| Qt 5.7-5.14 | ★★★☆☆ | 一般 | 需要 `QT_ACCESSIBILITY=1`；objectName 需手动设置 |
| Win32 / MFC | ★★★☆☆ | 一般 | 控件 ID 可访问；文本匹配常见 |

## 设置与先决条件

```bash
# Python 3.8+，仅 Windows
pip install pywinauto pytest pytest-html Pillow pytest-timeout
# 可选：屏幕录制
# 安装 ffmpeg 并添加到 PATH：https://ffmpeg.org/download.html
```

验证 UIA 是否可访问：

```python
from pywinauto import Desktop
Desktop(backend="uia").windows()  # 列出所有顶级窗口
```

安装 **Accessibility Insights for Windows**（Microsoft 免费）— 你在编写任何测试之前检查 UIA 元素树的 DevTools 等效工具。

## 可测试性设置（按框架）

你能做的最有影响力的事情就是在编写测试之前**为每个交互控件提供一个稳定的 AutomationId**。

### WPF

```xml
<!-- XAML: x:Name 自动成为 AutomationId -->
<TextBox x:Name="usernameInput" />
<PasswordBox x:Name="passwordInput" />
<Button x:Name="btnLogin" Content="Login" />
<TextBlock x:Name="lblError" />
```

### WinForms

```csharp
// 在设计器或代码中设置
usernameInput.AccessibleName = "usernameInput";
passwordInput.AccessibleName = "passwordInput";
btnLogin.AccessibleName = "btnLogin";
lblError.AccessibleName = "lblError";
```

### Win32 / MFC

```cpp
// .rc 文件中的控件资源 ID 作为 AutomationId 字符串暴露
// IDC_EDIT_USERNAME -> AutomationId "1001"
// 优先使用 SetWindowText 设置 Name；添加 IAccessible 以获得更丰富的支持
```

### Qt — 见下方独立章节

---

## 页面对象模型

```
tests/
├── conftest.py          # 应用启动 fixture，失败截图
├── pytest.ini
├── config.py
├── pages/
│   ├── __init__.py      # 导入所需
│   ├── base_page.py     # 定位器、等待、截图辅助
│   ├── login_page.py
│   └── main_page.py
├── tests/
│   ├── __init__.py
│   ├── test_login.py
│   └── test_main_flow.py
└── artifacts/           # 截图、视频、日志
```

### base_page.py

```python
import os, time
from pywinauto import Desktop
from config import ACTION_TIMEOUT, ARTIFACT_DIR

class BasePage:
    def __init__(self, window):
        self.window = window

    # --- 定位器（优先级顺序） ---

    def by_id(self, auto_id, **kw):
        """AutomationId — 最稳定。作为首选。"""
        return self.window.child_window(auto_id=auto_id, **kw)

    def by_name(self, name, **kw):
        """可见文本 / 无障碍名称。"""
        return self.window.child_window(title=name, **kw)

    def by_class(self, cls, index=0, **kw):
        """控件类 + 索引 — 脆弱，尽量避免。"""
        return self.window.child_window(class_name=cls, found_index=index, **kw)

    # --- 等待 ---

    def wait_visible(self, spec, timeout=ACTION_TIMEOUT):
        spec.wait("visible", timeout=timeout)
        return spec

    def wait_gone(self, spec, timeout=ACTION_TIMEOUT):
        spec.wait_not("visible", timeout=timeout)
        return spec

    def wait_window(self, title, timeout=ACTION_TIMEOUT):
        """等待新的顶级窗口（对话框、子窗口）。"""
        dlg = Desktop(backend="uia").window(title=title)
        dlg.wait("visible", timeout=timeout)
        return dlg

    def wait_until(self, fn, timeout=ACTION_TIMEOUT, interval=0.3):
        """轮询任意条件 — 当 UIA 事件不可靠时使用。"""
        deadline = time.time() + timeout
        while time.time() < deadline:
            try:
                if fn():
                    return True
            except Exception:
                pass
            time.sleep(interval)
        raise TimeoutError(f"条件在 {timeout}s 内未满足")

    # --- 操作 ---

    def click(self, spec):
        self.wait_visible(spec)
        spec.click_input()

    def type_text(self, spec, text):
        self.wait_visible(spec)
        ctrl = spec.wrapper_object()
        try:
            ctrl.set_edit_text(text)
        except Exception as e:
            # Qt 5.x 回退：UIA Value Pattern 可能不完整
            import sys, pywinauto.keyboard as kb
            print(f"[windows-desktop-e2e] set_edit_text 失败 ({e})，使用键盘回退", file=sys.stderr)
            ctrl.click_input()
            kb.send_keys("^a")
            kb.send_keys(text, with_spaces=True)

    def get_text(self, spec):
        ctrl = spec.wrapper_object()
        for attr in ("window_text", "get_value"):
            try:
                v = getattr(ctrl, attr)()
                if v:
                    return v
            except Exception:
                pass
        return ""

    # --- 产物 ---

    def screenshot(self, name):
        os.makedirs(ARTIFACT_DIR, exist_ok=True)
        path = os.path.join(ARTIFACT_DIR, f"{name}.png")
        self.window.capture_as_image().save(path)
        return path
```

### login_page.py

```python
from pages.base_page import BasePage

class LoginPage(BasePage):
    @property
    def username(self): return self.by_id("usernameInput")

    @property
    def password(self): return self.by_id("passwordInput")

    @property
    def btn_login(self): return self.by_id("btnLogin")

    @property
    def error_label(self): return self.by_id("lblError")

    def login(self, user, pwd):
        self.type_text(self.username, user)
        self.type_text(self.password, pwd)
        self.click(self.btn_login)

    def login_ok(self, user, pwd, main_title="Main Window"):
        self.login(user, pwd)
        return self.wait_window(main_title)

    def login_fail(self, user, pwd):
        self.login(user, pwd)
        self.wait_visible(self.error_label)
        return self.get_text(self.error_label)
```

### conftest.py

> 对于新项目，推荐使用**第 1 层沙箱 fixture**（见下文）— 它以零额外成本添加文件系统隔离。此基础 fixture 仅用于最小/遗留设置。

```python
import os, pytest
os.environ["QT_ACCESSIBILITY"] = "1"  # Qt 5.x UIA 支持所需

from pywinauto import Application
from config import APP_PATH, MAIN_WINDOW_TITLE, LAUNCH_TIMEOUT, ARTIFACT_DIR

@pytest.fixture
def app(request):
    if not APP_PATH:
        pytest.exit("APP_PATH 环境变量未设置", returncode=1)
    proc = Application(backend="uia").start(APP_PATH, timeout=LAUNCH_TIMEOUT)
    win  = proc.window(title=MAIN_WINDOW_TITLE)
    win.wait("visible", timeout=LAUNCH_TIMEOUT)
    yield win
    # 失败时截图
    if getattr(getattr(request.node, "rep_call", None), "failed", False):
        os.makedirs(ARTIFACT_DIR, exist_ok=True)
        try:
            win.capture_as_image().save(
                os.path.join(ARTIFACT_DIR, f"FAIL_{request.node.name}.png")
            )
        except Exception:
            pass
    # 先优雅退出，强制终止作为后备
    # proc 是 pywinauto Application — 使用 wait_for_process_exit()，而非 wait_for_process()
    try:
        win.close()
        proc.wait_for_process_exit(timeout=5)
    except Exception:
        proc.kill()

@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item, call):
    outcome = yield
    setattr(item, f"rep_{outcome.get_result().when}", outcome.get_result())
```

### config.py

```python
import os
APP_PATH          = os.environ.get("APP_PATH", "")           # 通过环境变量设置 — 无默认路径
MAIN_WINDOW_TITLE = os.environ.get("APP_TITLE", "")
LAUNCH_TIMEOUT    = int(os.environ.get("LAUNCH_TIMEOUT", "15"))
ACTION_TIMEOUT    = int(os.environ.get("ACTION_TIMEOUT", "10"))
ARTIFACT_DIR      = os.path.join(os.path.dirname(__file__), "artifacts")
```

### pytest.ini

```ini
[pytest]
testpaths = tests
markers =
    smoke: 关键路径的快速冒烟测试
    flaky: 已知不稳定的测试
addopts = -v --tb=short --html=artifacts/report.html --self-contained-html
```

## 定位器策略

```
AutomationId  >  Name（文本） >  ClassName + 索引  >  XPath
  （稳定）         （可读）         （脆弱）           （最后手段）
```

使用 Accessibility Insights 检查 → **属性**面板 → 先查找 `AutomationId`。

```python
# 运行时检查 — 粘贴到 REPL 中探索树
win.print_control_identifiers()
# 或缩小范围：
win.child_window(auto_id="groupBox1").print_control_identifiers()
```

## 等待模式

```python
# 等待控件出现
page.wait_visible(page.by_id("statusLabel"))

# 等待控件消失（如加载旋转器）
page.wait_gone(page.by_id("spinnerOverlay"))

# 等待对话框弹出
dlg = page.wait_window("确认删除")

# 自定义条件（如文本变化）
page.wait_until(lambda: page.get_text(page.by_id("lblStatus")) == "就绪")
```

**绝不要使用 `time.sleep()` 作为主要同步方式** — 使用 `wait()` 或 `wait_until()`。

## 产物管理

```python
# 按需截图
page.screenshot("登录后")

# 全屏捕获（当窗口在屏幕外或最小化时）
import pyautogui
pyautogui.screenshot("artifacts/fullscreen.png")

# 使用 ffmpeg 屏幕录制（测试前开始，测试后停止）
import subprocess

def start_recording(name):
    return subprocess.Popen([
        "ffmpeg", "-f", "gdigrab", "-framerate", "10",
        "-i", "desktop", "-y", f"artifacts/videos/{name}.mp4"
    ], stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def stop_recording(proc):
    proc.stdin.write(b"q"); proc.stdin.flush(); proc.wait(timeout=10)
```

## 每步跟踪（可选）

默认的失败截图对于诊断不稳定测试通常不够详细。下面的步骤级跟踪**默认关闭** — 仅在重现不稳定用例时启用。

### 启用

```bash
E2E_TRACE=1 pytest tests/test_login.py -v
# 在 JSONL 日志中包含输入的文本（不要在输入凭据/PII 的测试上使用）：
E2E_TRACE=1 E2E_TRACE_INCLUDE_TEXT=1 pytest ...
```

### 打补丁到 BasePage

```python
import os, json, time
TRACE_ENABLED      = os.environ.get("E2E_TRACE") == "1"
TRACE_INCLUDE_TEXT = os.environ.get("E2E_TRACE_INCLUDE_TEXT") == "1"

class BasePage:
    _step = 0

    def _trace(self, action, spec=None, text=None):
        if not TRACE_ENABLED:
            return
        BasePage._step += 1
        idx = f"{BasePage._step:03d}"
        os.makedirs(ARTIFACT_DIR, exist_ok=True)
        try:
            self.window.capture_as_image().save(
                os.path.join(ARTIFACT_DIR, f"step_{idx}_{action}.png"))
        except Exception:
            pass  # 捕获失败不能破坏测试
        rec = {
            "ts": time.time(), "step": BasePage._step, "action": action,
            "locator": getattr(spec, "criteria", None),
            "text": text if TRACE_INCLUDE_TEXT else ("<redacted>" if text else None),
        }
        with open(os.path.join(ARTIFACT_DIR, "trace.jsonl"), "a") as f:
            f.write(json.dumps(rec) + "\n")

    def click(self, spec):
        self.wait_visible(spec); self._trace("click_before", spec)
        spec.click_input();      self._trace("click_after",  spec)

    def type_text(self, spec, text):
        self.wait_visible(spec); self._trace("type_before", spec, text)
        # ... 现有的 set_edit_text / 键盘回退 ...
        self._trace("type_after", spec)
```

### 注意事项

- **PII / 凭据**：`type_text` 内容默认为 `<redacted>`。永远不要在登录或支付流程上设置 `E2E_TRACE_INCLUDE_TEXT=1`。
- **开销**：每个操作约 50-200ms + 每步一个 PNG 文件。不要在默认 CI 矩阵上启用 — 仅在专用的不稳定重现作业上使用。
- **产物膨胀**：长流程会产生数十 MB；相应调整 `retention-days`。
- **并行/重跑清洁**：此简单示例追加到 `trace.jsonl` 并使用类级别计数器。重跑前清除产物目录，并行测试使用按工作进程的产物目录。
- **覆盖缺口**：在 `BasePage` 外执行的操作（测试代码中的原始 `pywinauto` 调用）不会被跟踪。

## 不稳定测试处理

```python
# 隔离 — 等同于 Playwright 的 test.fixme()
@pytest.mark.skip(reason="不稳定：慢 CI 上的动画竞争。Issue #42")
def test_animated_transition(self, app): ...

# 仅在 CI 中跳过
@pytest.mark.skipif(os.environ.get("CI") == "true", reason="CI 中不稳定 #43")
def test_heavy_load(self, app): ...
```

常见原因和修复：

| 原因 | 修复 |
|-------|-----|
| 控件未就绪 | 用 `wait_visible` 替换 `time.sleep` |
| 窗口未聚焦 | 在交互前添加 `win.set_focus()` |
| 动画进行中 | `wait_until(lambda: not loading_indicator.exists())` |
| 对话框时序 | `wait_window(title, timeout=15)` |
| CI 显示器未就绪 | 设置 `DISPLAY` 或在 CI 中使用虚拟桌面 |
| `set_edit_text` 抛出 NotImplementedError | UIA ValuePattern 缺失（Qt 5.x 常见）— `BasePage.type_text` 已回退到 `keyboard.send_keys` |
| 控件存在但 `wait_visible` 超时 | 窗口最小化或在屏幕外 — 在等待前调用 `win.restore()` + `win.set_focus()` |

## 测试隔离与沙箱

三个隔离层级 — 使用能满足需求的最轻量层级。

### 第 1 层 — 文件系统隔离（默认，始终使用）

每个测试通过 `subprocess.Popen` 和 `Application.connect()` 获得自己的 `APPDATA` / `LOCALAPPDATA` / `TEMP`。pytest 的 `tmp_path` fixture 自动处理清理。

```python
# conftest.py — 用此替换基础 `app` fixture
import os, subprocess, pytest
from pywinauto import Application
from config import APP_PATH, APP_ARGS, APP_TITLE, LAUNCH_TIMEOUT, ACTION_TIMEOUT, ARTIFACT_DIR

@pytest.fixture(scope="function")
def app(request, tmp_path):
    """每个测试使用新进程 + 隔离的用户数据目录。"""
    if not APP_PATH:
        pytest.exit("APP_PATH 未设置", returncode=1)

    # 将所有每用户存储重定向到隔离的 tmp 目录
    sandbox_env = os.environ.copy()
    sandbox_env["QT_ACCESSIBILITY"]  = "1"
    sandbox_env["APPDATA"]           = str(tmp_path / "AppData" / "Roaming")
    sandbox_env["LOCALAPPDATA"]      = str(tmp_path / "AppData" / "Local")
    sandbox_env["TEMP"] = sandbox_env["TMP"] = str(tmp_path / "Temp")
    for p in (sandbox_env["APPDATA"], sandbox_env["LOCALAPPDATA"], sandbox_env["TEMP"]):
        os.makedirs(p, exist_ok=True)

    if not APP_TITLE:
        pytest.exit("APP_TITLE 环境变量未设置", returncode=1)

    # shlex.split 处理带空格的引用参数；plain split() 会破坏它们
    import shlex
    # 通过 subprocess 启动以传递 env；通过 PID 连接 pywinauto
    proc = subprocess.Popen(
        [APP_PATH] + shlex.split(APP_ARGS),
        env=sandbox_env,
    )
    pw_app = Application(backend="uia").connect(process=proc.pid, timeout=LAUNCH_TIMEOUT)
    win    = pw_app.window(title=APP_TITLE)
    win.wait("visible", timeout=LAUNCH_TIMEOUT)
    yield win

    if getattr(getattr(request.node, "rep_call", None), "failed", False):
        os.makedirs(ARTIFACT_DIR, exist_ok=True)
        try:
            win.capture_as_image().save(
                os.path.join(ARTIFACT_DIR, f"FAIL_{request.node.name}.png")
            )
        except Exception:
            pass
    try:
        win.close()
        proc.wait(timeout=5)
    except Exception:
        proc.kill()
    # tmp_path 由 pytest 自动清理

@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item, call):
    outcome = yield
    setattr(item, f"rep_{outcome.get_result().when}", outcome.get_result())
```

### 第 2 层 — Windows Job Object（可选：进程生命周期控制）

将进程附加到 Job Object，使其在测试 fixture 的 job 句柄被 GC 时**自动终止**。还防止应用生成逃逸 fixture 清理的子进程。

> **隔离范围：** Job Object 不虚拟化文件系统访问也不阻止网络流量。文件写入和网络隔离需要 AppContainer、Windows Firewall 规则或第 3 层（Windows Sandbox）。仅将第 2 层用于进程生命周期和子进程控制。

无需额外依赖。

```python
import ctypes, ctypes.wintypes as wt

def restrict_process(pid: int):
    """
    将进程附加到 Job Object，防止其：
    - 在 job 外部生成进程（LIMIT_KILL_ON_JOB_CLOSE）
    不阻止网络 — 使用 Windows Firewall 规则。
    """
    JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE = 0x00002000
    # 最小权限：SET_QUOTA (0x0100) | TERMINATE (0x0001)
    PROCESS_SET_QUOTA_AND_TERMINATE    = 0x0101

    kernel32 = ctypes.windll.kernel32
    job   = kernel32.CreateJobObjectW(None, None)
    hproc = kernel32.OpenProcess(PROCESS_SET_QUOTA_AND_TERMINATE, False, pid)

    # 正确的结构体布局 — LimitFlags 在偏移 +16，不是 +44
    class JOBOBJECT_BASIC_LIMIT_INFORMATION(ctypes.Structure):
        _fields_ = [
            ("PerProcessUserTimeLimit", wt.LARGE_INTEGER),
            ("PerJobUserTimeLimit",     wt.LARGE_INTEGER),
            ("LimitFlags",             wt.DWORD),
            ("MinimumWorkingSetSize",   ctypes.c_size_t),
            ("MaximumWorkingSetSize",   ctypes.c_size_t),
            ("ActiveProcessLimit",      wt.DWORD),
            ("Affinity",               ctypes.c_size_t),
            ("PriorityClass",          wt.DWORD),
            ("SchedulingClass",        wt.DWORD),
        ]

    info = JOBOBJECT_BASIC_LIMIT_INFORMATION()
    info.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
    ok = kernel32.SetInformationJobObject(job, 2, ctypes.byref(info), ctypes.sizeof(info))
    if not ok:
        raise ctypes.WinError()
    kernel32.AssignProcessToJobObject(job, hproc)
    kernel32.CloseHandle(hproc)
    return job  # 保持存活 — job 关闭时（被 GC）会终止进程

# 在 proc = subprocess.Popen(...) 之后：job = restrict_process(proc.pid)
```

### 第 3 层 — Windows Sandbox（CI 完整操作系统隔离）

当每次运行需要干净的 Windows 镜像（无残留注册表键、无共享 GPU 状态、真正隔离）时，在 [Windows Sandbox](https://learn.microsoft.com/windows/security/application-security/application-isolation/windows-sandbox/windows-sandbox-overview) 内运行**整个测试套件**。

**要求：** Windows 10/11 Pro 或 Enterprise，已启用虚拟化。

在项目根目录创建 `e2e-sandbox.wsb`：

```xml
<Configuration>
  <MappedFolders>
    <!-- 应用二进制（只读） -->
    <MappedFolder>
      <HostFolder>C:\path\to\your\build\Release</HostFolder>
      <SandboxFolder>C:\app</SandboxFolder>
      <ReadOnly>true</ReadOnly>
    </MappedFolder>
    <!-- 测试套件（读写，用于产物） -->
    <MappedFolder>
      <HostFolder>C:\path\to\your\e2e_test</HostFolder>
      <SandboxFolder>C:\e2e_test</SandboxFolder>
      <ReadOnly>false</ReadOnly>
    </MappedFolder>
  </MappedFolders>
  <LogonCommand>
    <!--
      Windows Sandbox 启动时没有 Python。先静默安装它，
      然后安装依赖并运行测试。产物通过上面的 MappedFolder 写回宿主机。
    -->
    <Command>powershell -Command "
      winget install --id Python.Python.3.11 --silent --accept-package-agreements;
      $env:PATH += ';' + $env:LOCALAPPDATA + '\Programs\Python\Python311\Scripts';
      cd C:\e2e_test;
      pip install -r requirements.txt;
      pytest tests\ -v
    "</Command>
  </LogonCommand>
</Configuration>
```

启动：`WindowsSandbox.exe e2e-sandbox.wsb`

> pywinauto 和应用都在沙箱**内部**运行（需要同一会话）。
> 产物通过映射文件夹写回宿主机。

### 层级对比

| 层级 | 隔离 | 设置成本 | 适用于 CI | 使用场景 |
|------|-----------|-----------|-------------|----------|
| 1 — `tmp_path` 环境重定向 | 文件系统 | 零 | 始终 | 所有测试的默认选择 |
| 2 — Job Object | 进程树 | 低 | 始终 | 防止子进程逃逸 |
| 3 — Windows Sandbox | 完整操作系统 | 中等 | 需要 Pro/Enterprise 镜像 | 每日干净环境运行 |

### 防止测试挂起

添加 `pytest-timeout` 来限制单个测试。在 `pytest.ini` 中设置 `timeout = 60` 和 `timeout_method = thread`。注意：`thread` 方法无法在 Windows 上终止 Qt 应用子进程 — 在 `conftest.py` 中添加 `atexit.register(lambda: [p.kill() for p in psutil.Process().children(recursive=True)])` 来清理孤儿进程。

## CI/CD 集成

```yaml
# .github/workflows/e2e-desktop.yml
name: Desktop E2E
on: [push, pull_request]

jobs:
  e2e:
    runs-on: windows-latest   # 真实 GUI 环境，无需 Xvfb
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with: { python-version: "3.11" }

      - name: 安装依赖
        run: pip install pywinauto pytest pytest-html Pillow

      - name: 构建应用
        run: cmake --build build --config Release  # 根据你的构建系统调整

      - name: 运行 E2E
        env:
          APP_PATH: ${{ github.workspace }}\build\Release\MyApp.exe
          APP_TITLE: "My Application"
          CI: "true"
        run: pytest tests/ --html=artifacts/report.html --self-contained-html --junitxml=artifacts/results.xml -v

      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: e2e-artifacts
          path: artifacts/
          retention-days: 14
```

## Qt 专项

### 在 Qt 5.x 中启用 UIA

Qt 5.x 无障碍在某些构建中默认禁用（特别是 5.7-5.14）。在启动**之前**设置环境变量。Qt 6.x 默认启用无障碍 — 跳过此步骤。

```python
# conftest.py — 在模块顶部添加
import os
os.environ["QT_ACCESSIBILITY"] = "1"
```

或在 CI 中导出：

```yaml
env:
  QT_ACCESSIBILITY: "1"
```

### 为 Qt 控件添加稳定标识符

```cpp
// 首选：同时设置 objectName 和 accessibleName
void setTestId(QWidget* w, const char* id) {
    w->setObjectName(id);
    w->setAccessibleName(id);  // 成为 UIA Name 属性
}

// 在你的对话框构造函数中：
setTestId(ui->usernameEdit, "usernameInput");
setTestId(ui->passwordEdit, "passwordInput");
setTestId(ui->loginButton,  "btnLogin");
setTestId(ui->errorLabel,   "lblError");
```

将所有 ID 集中到一个头文件中避免拼写错误：

```cpp
// test_ids.h
#define TID_USERNAME   "usernameInput"
#define TID_PASSWORD   "passwordInput"
#define TID_BTN_LOGIN  "btnLogin"
#define TID_LBL_ERROR  "lblError"
```

### Qt 特定怪癖

**QComboBox** — 下拉菜单是单独的顶级窗口：

```python
from pywinauto import Desktop

def select_combo_item(page, combo_spec, item_text):
    page.click(combo_spec)
    # 下拉菜单作为新的根级窗口出现
    # class_name 因 Qt 版本而异 — 用 Accessibility Insights 验证
    # Qt 5.x: "Qt5QWindowIcon"  |  Qt 6.x: "Qt6QWindowIcon" — 用 Accessibility Insights 验证
    popup = Desktop(backend="uia").window(class_name_re="Qt[56]QWindowIcon")
    popup.wait("visible", timeout=5)
    popup.child_window(title=item_text).click_input()
```

**QMessageBox / QDialog** — 也是单独的顶级窗口：

```python
dlg = page.wait_window("确认")          # 等待对话框标题
dlg.child_window(title="OK").click_input() # 点击其中的按钮
```

**QTableWidget / QTableView** — 行/单元格访问：

```python
table = page.by_id("tblUsers").wrapper_object()
cell  = table.cell(row=0, column=1)
print(cell.window_text())
```

**自绘控件**（仅 `paintEvent`、`QGraphicsView`、`QOpenGLWidget`）— UIA 无法看到其内部。使用下面的回退方案。

## 回退：截图模式

当控件无法通过 UIA 访问时（自绘、第三方、游戏引擎）：

```bash
pip install pyautogui Pillow opencv-python
```

```python
import pyautogui, cv2, numpy as np
from PIL import Image

def find_image_on_screen(template_path, confidence=0.85):
    """在屏幕上定位模板图像。返回 (x, y) 中心坐标或 None。"""
    screen   = np.array(pyautogui.screenshot())
    template = np.array(Image.open(template_path))
    result   = cv2.matchTemplate(
        cv2.cvtColor(screen, cv2.COLOR_RGB2BGR),
        cv2.cvtColor(template, cv2.COLOR_RGB2BGR),
        cv2.TM_CCOEFF_NORMED,
    )
    _, max_val, _, max_loc = cv2.minMaxLoc(result)
    if max_val >= confidence:
        h, w = template.shape[:2]
        return max_loc[0] + w // 2, max_loc[1] + h // 2
    return None

def click_image(template_path, confidence=0.85):
    pos = find_image_on_screen(template_path, confidence)
    if pos is None:
        raise RuntimeError(f"屏幕上未找到图像: {template_path}")
    pyautogui.click(*pos)
```

### DPI / 缩放规则（仅截图模式）

截图匹配对 Windows 显示缩放（100% / 125% / 150%）极其敏感。三条硬性规则：

1. **在与目标机器相同的缩放比例下捕获模板。** 不要试图用 `PIL.Image.resize` 挽救不匹配 — `cv2.matchTemplate` 对重采样伪影非常脆弱。
2. **固定 CI 显示缩放。** 在 `windows-latest` 上添加类似 `Set-DisplayResolution 1920 1080 -Force` 的步骤并禁用按显示器 DPI 缩放，使截图尺寸可重现。
3. **在每个产物旁记录缩放比例。** 捕获时，将 `GetDpiForWindow(hwnd) / 96` 写入 `artifacts/<test>/metadata.json` — 事后分析变得直观而非猜测。

> 进程级 DPI 感知（`SetProcessDpiAwarenessContext`）在被测应用是 Qt 应用时**可能与 Qt 自身的 DPI 处理冲突**。优先使用"相同缩放模板 + CI 固定"而非在 fixture 中翻转进程级 DPI 模式。

### 调试匹配置信度

调整 `confidence` 阈值时，唯一合理的工作流程是**看到**匹配落在了哪里。下面的辅助函数仅用于诊断 — 不要从测试代码中调用。

```python
def debug_match(template_path, out="artifacts/match_debug.png", confidence=0.85):
    """仅用于诊断。在当前屏幕上绘制最佳匹配矩形 + 分数。

    不用于生产测试 — 仅在校准置信度或追踪错误匹配时使用。
    """
    import os, cv2, pyautogui, numpy as np
    screen = np.array(pyautogui.screenshot())[:, :, ::-1]
    tpl    = cv2.imread(template_path)
    if tpl is None:
        raise RuntimeError(f"模板无法读取: {template_path}")
    res    = cv2.matchTemplate(screen, tpl, cv2.TM_CCOEFF_NORMED)
    _, mv, _, ml = cv2.minMaxLoc(res)
    h, w   = tpl.shape[:2]
    colour = (0, 255, 0) if mv >= confidence else (0, 0, 255)  # 绿色通过 / 红色失败
    cv2.rectangle(screen, ml, (ml[0]+w, ml[1]+h), colour, 2)
    cv2.putText(screen, f"score={mv:.3f} thr={confidence}",
                (ml[0], max(20, ml[1]-6)),
                cv2.FONT_HERSHEY_SIMPLEX, 0.7, colour, 2)
    os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
    cv2.imwrite(out, screen)
    return mv
```

**谨慎使用** — 图像匹配在 DPI 变更、主题切换和部分遮挡时会失效。
始终先尝试 UIA；仅对真正无法访问的控件回退到截图。

## 反模式

```python
# 错误：固定等待
time.sleep(3)
page.click(page.by_id("btnSubmit"))

# 正确：条件等待
page.wait_visible(page.by_id("btnSubmit"))
page.click(page.by_id("btnSubmit"))
```

```python
# 错误：脆弱的类+索引定位器作为主要策略
page.by_class("Edit", index=2).type_keys("hello")

# 正确：AutomationId
page.by_id("usernameInput").set_edit_text("hello")
```

```python
# 错误：断言像素坐标
assert btn.rectangle().left == 120

# 正确：断言内容/状态
assert page.get_text(page.by_id("lblStatus")) == "已登录"
assert page.by_id("btnLogout").is_enabled()
```

```python
# 错误：在所有测试间共享应用实例（状态泄漏）
@pytest.fixture(scope="session")
def app(): ...

# 正确：每个测试使用新进程（或最多每个类一个）
@pytest.fixture(scope="function")
def app(): ...
```

## 运行测试

```bash
# 所有测试
pytest tests/ -v

# 仅冒烟测试
pytest tests/ -m smoke -v

# 特定文件
pytest tests/test_login.py -v

# 使用自定义应用路径
APP_PATH="C:\build\Release\MyApp.exe" APP_TITLE="MyApp" pytest tests/ -v

# 检测不稳定测试（每个重复 5 次）
pip install pytest-repeat
pytest tests/test_login.py --count=5 -v
```

## 相关技能

- `e2e-testing` — Web 应用的 Playwright E2E 测试
- `cpp-testing` — 使用 GoogleTest 的 C++ 单元/集成测试
- `cpp-coding-standards` — C++ 代码风格和模式
