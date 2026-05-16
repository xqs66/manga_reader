# Manga Reader — 面试技术文档

## 项目概述

一款 Flutter 跨平台本地漫画阅读器，支持文件夹/ZIP/CBZ/EPUB 格式，具备书架管理、分组归类、多种阅读模式、阅读进度追踪等功能。当前支持 Android 和 Windows 桌面端。

- **代码规模**：约 8000+ 行 Dart 代码，60+ 个文件
- **架构模式**：Page-Controller-State 三层架构 + Repository 模式
- **状态管理**：GetX（GetBuilder + Obx 混合策略）
- **数据库**：Drift（SQLite），含自定义迁移策略

---

## 一、架构设计亮点

### 1.1 Page-Controller-State 三层分离

```
lib/pages/<feature>/
├── <feature>_page.dart          # 纯 UI，只负责 build
├── <feature>_page_controller.dart  # 业务逻辑、状态变更
└── <feature>_page_state.dart    # 纯状态数据（无逻辑）
```

**设计理念**：
- Page 层**禁止任何业务逻辑**，只做声明式 UI 渲染
- Controller 持有 State，处理用户交互，通过 `GetBuilder` + `update(id)` 精确控制重绘范围
- State 是纯数据类，不含任何逻辑

**面试可讲**：这套模式本质上是对 MVVM 的 Flutter 化实践——State 对应 Model，Controller 对应 ViewModel，Page 对应 View。和 BLoC 相比更轻量，适合中小型项目。

### 1.2 GetX 状态管理的分层使用策略

| 方式 | 适用场景 | 原理 |
|------|---------|------|
| `GetBuilder` + `update(id)` | 页面内局部状态 | 通过 ID 精确控制重绘范围，避免不必要的 Widget rebuild |
| `Obx` / `.obs` | 全局跨页面状态 | Rx 响应式，自动追踪依赖，跨页面自动同步 |

**关键决策**：为什么不用统一的 Obx？
- Obx 会在每个 `build` 中建立订阅关系，大量 Obx 嵌套会导致订阅管理复杂
- 页面内部的状态变化（如选择模式、滚动状态）用 Obx 会导致细粒度重绘失控
- `GetBuilder` + `update(id)` 让开发者显式控制何时重建哪个区域，性能可控

### 1.3 Repository 模式 + Result 类型

```dart
abstract class MangaRepository {
  Future<Result<List<Manga>>> loadMangasInDir(Directory dir);
}

// 实现
class MangaRepositoryImpl with ServiceBeanMixin implements MangaRepository {
  Future<Result<T>> _guard<T>(Future<T> Function() fn, String errorMsg) async {
    try { return Ok(await fn()); }
    catch (e) { return Err(errorMsg, e); }
  }
}
```

**设计理念**：
- Controller 只依赖 `MangaRepository` 接口，不依赖具体实现
- 返回值统一使用 `Result<T>`（`Ok<T>` / `Err<T>`），强制调用方处理错误
- `_guard()` 消除 try-catch 模板，所有异常走统一路径

### 1.4 ServiceLifeCircleBean 生命周期管理

```dart
class SomeService with ServiceBeanMixin implements ServiceLifeCircleBean {
  @override
  List<ServiceLifeCircleBean> get initDependencies => [storageService];

  @override
  Future<void> doInit() async { /* 在 runApp() 前执行 */ }

  @override
  Future<void> doAfterReady() async { /* 在 GetMaterialApp.onReady 中执行 */ }
}
```

- `initDependencies` 声明依赖关系，`main()` 中拓扑排序后**串行**初始化
- 避免了隐式的初始化顺序依赖，依赖关系一目了然

---

## 二、性能优化（核心亮点）

### 2.1 启动速度优化——ZIP/EPUB 加载从 4s+ 到 <2s

**问题背景**：用户有 825 部漫画（59GB），其中 34 部 ZIP 格式（3GB）。有 ZIP 漫画时启动 4 秒以上，去掉 ZIP 仅 2 秒以内。

**根因分析**：

```
之前 _loadZipManga 的流程：
1. await zipFile.readAsBytes()       → 读取整个 90MB 文件到内存
2. ZipDecoder().decodeBytes(bytes)   → 在 UI 线程同步解压全部 200MB+ 数据
3. 只取第一张图做封面，其余全部丢弃   → 99% 的工作是浪费的
```

**ZIP 文件结构**：ZIP 的文件目录（Central Directory）在文件末尾，约几十 KB，包含所有文件的名称、在文件中的偏移量、压缩/解压大小。获取封面只需读 CD + 封面 entry，无需读整个文件。

**优化方案——自实现轻量级 ZIP 读取器**：

```dart
// 核心思路：只读 Central Directory + 按需解压单个 entry
class ZipReader {
  // 1. 读文件末尾 ~64KB，定位 EOCD 签名 (0x06054b50)
  // 2. 解析 Central Directory，获取所有 entry 的偏移量/大小
  // 3. readEntryContent(entry) → 跳到文件对应偏移，只读+解压单个 entry
  // 4. 使用 dart:io ZLibDecoder(raw: true) 解压 deflate 数据
}
```

**效果**：对一部 90MB 的 ZIP 漫画：

| | 优化前 | 优化后 |
|---|---|---|
| 单部读取量 | 90MB（整个文件） | ~500KB（CD + 封面） |
| 单部解压量 | 200MB+（全部图片） | ~3MB（一张封面） |
| 34 部总 I/O | ~3GB | ~17MB |
| 34 部总解压 | ~7GB | ~100MB |
| 预计耗时 | 2-3 秒 | ~200-400ms |

**面试可讲**：
1. 理解了 ZIP 二进制格式（EOCD、Central Directory、Local File Header 结构）
2. 没有引入新依赖，用 `dart:io` 的 `RandomAccessFile` + `ZLibDecoder(raw: true)` 实现
3. 体现了"理解底层格式→找到优化空间→自研轻量方案"的工程能力

### 2.2 异步并发控制——解决 UI 卡顿

**问题**：刷新操作虽然都是 async，但 `Future.wait` 把所有漫画的加载同时触发，事件队列被几千个并发的 I/O 回调塞满，UI 渲染帧被饿死。

**分析过程**：

```
一层并发：20 部漫画 × 150 张图 = 3000 个并发的 f.length() future
虽然每个单独操作不阻塞 UI 线程，但 3000 个 I/O 完成的回调
在事件队列里竞争，Flutter 的渲染帧排到队尾，UI 卡死。
```

**解决方案——分批并发 + 事件循环让步**：

```dart
// 参数化并发控制
Future<List<Manga>> loadMangasInDir(Directory dir, {int concurrency = 0}) async {
  final poolSize = concurrency > 0 ? concurrency : entities.length;
  for (var i = 0; i < entities.length; i += poolSize) {
    final batch = entities.skip(i).take(poolSize);
    final results = await Future.wait(batch.map((e) => loadManga(...)));
    // 批间让步给 UI 帧
    if (concurrency > 0 && i + poolSize < entities.length) {
      await Future(() {}); // 把后续执行推到事件队列末尾
    }
  }
}

// 启动时：concurrency=0，全并发（无 UI，不需要让步）
// 刷新时：concurrency=3，3 部一批 + 批间让步（有 UI，需要响应）
```

**面试可讲**：
- 深刻理解 Dart 事件循环模型（microtask queue vs event queue）
- `await Future(() {})` 的技巧：把当前 continuation 推到 event queue 末尾，让后面的渲染回调优先执行
- 并发不是越高越好——在单线程事件循环模型中，并发 I/O 回调过多反而伤害 UI 响应

### 2.3 阅读页延迟加载

**问题**：点击 ZIP 漫画后要等数秒图片全部解压完才能进入阅读页，无任何反馈。

**优化方案**：

```
之前: 点漫画 → 同步/异步等解压全图(2-5s) → 导航到阅读页
之后: 点漫画 → 立刻导航到阅读页 → 异步加载图片 → 完成后重建 UI
```

**实现要点**：
1. `ReadInfo.images` 改为可空，导航时传空列表
2. `ReaderPageController.onReady` 中检测 `images` 为空时触发异步加载
3. 利用 `GetBuilder` + `update([imageListId, pageListId])` 在加载完成后精确重建渲染区域
4. 每个 `_buildImageItem` 有越界保护（`index >= images.length` → `SizedBox.shrink()`）

### 2.4 阅读页点击延迟——四天排查实录

**问题**：点击屏幕切换菜单总有明显延迟，操作不跟手。连续快速点击时菜单完全无反应，像被加了防抖。

> 以下为真实排查过程的完整记录，包括走弯路的全过程。

**第 1-2 轮：手势竞技场 + HitTestBehavior（错误方向）**

最初怀疑是 Flutter 手势竞技场竞争导致延迟——`GestureDetector` 嵌套在 `PhotoView` 内部，与 PhotoView 的缩放/拖拽识别器竞争。提取到独立层后，tap 修复了但翻页失效——原因是默认 `RenderStack` 的命中测试短路：上层命中后下层永不检测。

创建了 `HitAccumulateStack`（用 `|=` 替代 `||` 消除短路），尝试了 `onTap`、`onTapDown`、`Listener.onPointerDown`、手动 postFrameCallback 区分 tap/drag……全部无法同时满足"点击瞬发 + 拖拽不误触 + 快速连点不丢"。

**花了两天，试遍所有手势层面方案，全部失败。**

**第 3 天：关键突破——最小化实验**

注释掉整个 `PhotoView` widget，tap 立刻完美响应——确定 root cause 在 PhotoView 里，不在我写的任何代码里。

**第 3 天：发现真凶**

JHenTai 作者的 `pubspec.yaml` 中有一行关键线索：
```yaml
photo_view:
  git:
    url: https://github.com/jiangtian616/photo_view
    ref: separate  # rewrite double tap & tap drag gesture
```

对比两个版本的 `PhotoViewGestureDetector.build()`，差异一目了然：

| | 官方 photo_view 0.15.0 | JHenTai fork |
|---|---|---|
| `DoubleTapGestureRecognizer` | **无条件注册**，永远在竞技场 | 只在有回调时才注册 |
| 对每次 tap 的影响 | arena hold 300ms | 不注册，不 hold，零延迟 |

**根因——Flutter 双击识别器的 300ms arena hold**

```dart
// 官方 photo_view — 无条件注册（== 每个 tap 都被 hold 300ms）：
gestures[DoubleTapGestureRecognizer] =          // ← 永远注册！
    GestureRecognizerFactoryWithHandlers<DoubleTapGestureRecognizer>(
  () => DoubleTapGestureRecognizer(debugOwner: this),
  ...
);

// JHenTai fork — 条件注册（不需要双击时不注册）：
if (onDoubleTapDown != null || onDoubleTap != null || ...) {
  gestures[DoubleTapAndTagDragZoomGestureRecognizer] = ...;
}
```

`DoubleTapGestureRecognizer` 的工作原理：第一次点击后立即调用 `GestureBinding.instance.gestureArena.hold(pointer)`，启动 300ms 超时（`kDoubleTapTimeout`），等待可能的第二次点击。300ms 内无第二次点击则超时释放。**即使你没用到双击功能，这个 hold 机制也照常运行**。外层的 `TapGestureRecognizer` 必须等 300ms 超时，arena 释放后才能接管 tap。

这解释了所有现象：
- "像被加了防抖" → **300ms 的 `kDoubleTapTimeout`**
- "跟 JHenTai 比慢半拍" → **官方版的永久性 arena hold**
- "注释掉 PhotoView 就正常了" → **DoubleTapGestureRecognizer 随 PhotoView 从 widget tree 消失**

**最终方案**

1. 本地 fork photo_view，改一行：`DoubleTapGestureRecognizer` 从无条件注册改为仅在需要时注册
2. Reader page 结构保持简洁——JHenTai 风格的两层 Stack：

```dart
Stack(  // 外层：常规 Stack，菜单在上，可见时短路防止误触
  children: [
    HitAccumulateStack(  // 内层：`|=` 不短路，图片 + 手势层都收到事件
      children: [
        KeyedSubtree(PhotoView(...)),                         // 下层：缩放/翻页
        Positioned.fill(GestureDetector(onTap: toggleMenu)),  // 上层：tap
      ],
    ),
    menus...  // 菜单层，在外层 Stack 中短路屏蔽手势层
  ],
)
```

**复盘——为什么花了四天**

每个错误假设单独看都成立：手势竞技场竞争真实存在、Stack 短路真实存在、`OneSequenceGestureRecognizer` 序列限制真实存在、`postFrameCallback` 竞态真实存在。**但问题不在这里**。真正的瓶颈是第三方包 `.build()` 方法里一行看似无害的**无条件注册**。不走读源码根本不可能发现——而大多数工程师在"试了两天没效果"之后会放弃，改用一个 hacky workaround 了事。

**教训**：排查第三方包引入的性能问题时，**最小化实验（砍组件）比理论分析快 10 倍**。注释掉 PhotoView 只需要 30 秒，如果第一天就做，能省两天。

**知识点**：
- `DoubleTapGestureRecognizer` 机制：pointerDown → `gestureArena.hold(pointer)` → 300ms 超时
- `GestureArena` API：`hold()` vs `acceptGesture()` vs `rejectGesture()`
- 第三方包源码走读：从 pub cache 找源码，逐文件 diff 对比
- `|` vs `||` 在 RenderObject 命中测试中的语义差异
- 最小化实验方法论：砍掉最大嫌疑组件，快速确认/排除 root cause

### 2.5 批量 DB 查询 + 同步 I/O 消除

- **批量 DB**：`loadMangasInDir` 先收集全部 manga ID，一次 `SELECT ... WHERE id IN (...)` 拿到所有记录，从 N 次查询→1 次
- **listSync → await list().toList()**：消除 `await for` 的每实体异步调度开销，同时保留 async 让步点
- **fire-and-forget DB 调用补 await**：防止未捕获异常丢失，同时提供额外的 event loop 让步点

---

## 三、技术难点及解决方案

### 3.1 ZIP 漫画封面渐进式提取

**难点**：`archive` 包的 `ZipDecoder.decodeBytes()` 是 eager 的——一次性解压所有数据。只想要封面也必须解压全部。

**方案**：自研 `ZipReader`，利用 ZIP 格式的 Central Directory 结构，实现随机访问解压：
- 只读文件末尾的 Central Directory（~4KB）
- 定位封面 entry 在文件中的偏移
- 只读 + 只解压封面 entry 的压缩数据

### 3.2 EPUB 格式支持

**难点**：EPUB 本质是 ZIP，但图片顺序需要解析 `container.xml` → OPF → spine → manifest 的引用链。

**方案**：
- 轻量级读取：从 ZipReader 读取 `META-INF/container.xml` 和 OPF 两个小 XML 文件
- 解析 spine 顺序确定图片排列
- 非图片文件（HTML/CSS）直接忽略
- 解析失败回退到自然排序

### 3.3 多种阅读模式的统一渲染架构

支持 4 种阅读模式：条漫（Strip）、单页竖滑、单页左翻、单页右翻。

**设计**：
- Strip 模式使用 `ScrollablePositionedList` + `PhotoView` 实现无限滚动 + 手势缩放
- 单页模式使用 `PhotoViewGallery` + `PageController` 实现翻页
- 通过 `readSetting.readingMode` 的 Rx 值切换，`AnimatedSwitcher` 做过渡动画
- 共用的图片渲染逻辑（封面缓存、黑白模式、删除等）抽到 `_buildImageItem`

### 3.4 阅读进度的可靠持久化

**难点**：翻页、跳转、缩略图跳转、滑动条跳转，多个入口都要保存进度。而且要在退出前最后一刻落盘（`didPopNext` 时机在 `onClose` 前，缓存可能已过期）。

**方案**：
- `PopScope` 拦截返回，先 `persistToDb()` 再 `Get.back()`
- 翻页时立即更新内存缓存（`_updateCachesSync`），DB 防抖 500ms 写入
- 三种跳转（thumbnail/slider/pageChanged）统一调 `handlePageChanged` → `_debouncedSaveProgress`

### 3.5 网格布局的精确适配

**难点**：`GridView` 的 `childAspectRatio` 与卡片实际内容高度不匹配导致溢出；`Wrap` 无法保证行内元素填满宽度。

**方案**：
- 放弃 `GridView` 和 `Wrap`
- 使用 `LayoutBuilder` + `ListView.builder` + 手动 `Row` 构造
- 通过 `constraints.maxWidth` 精确计算列数和卡片宽度：`cardWidth = (availableWidth - (cols-1)*spacing) / cols`
- 封面高度按固定宽高比计算

### 3.6 跨平台文件访问抽象

**难点**：Android `MANAGE_EXTERNAL_STORAGE` 权限在桌面端不存在，`getExternalStorageDirectory()` 在桌面端返回 null。

**方案**：`PermissionUtil.checkAndRequestStoragePermission()` 和 `path_service.doInit()` 中 `Platform.isAndroid` 守卫，桌面端直接跳过权限申请和外部存储API。

### 3.7 多平台输入适配——阅读页交互

**难点**：阅读器的核心操作"翻页"在不同平台有完全不同的输入方式——Android 靠触摸手势、音量键，Windows 靠鼠标滚轮、方向键。需要统一适配而不写出平台特定的 `if/else` 面条代码。

**方案**：

**手势区域分割**：
- 将屏幕手势区域分为左/中/右三区（`Row` + 三个 `Expanded` + `GestureDetector`）
- 左 1/3 点击 → 上一页，中间点击 → 菜单显隐，右 1/3 点击 → 下一页
- 从右到左模式（RTL）下，左右翻页方向自动反转：
  ```dart
  void _onZoneTapLeft() {
    final isRTL = readSetting.readingMode.value == ReadingMode.singleRTL;
    isRTL ? goToNextPage() : goToPreviousPage();
  }
  ```

**音量键翻页**：
- 通过 `HardwareKeyboard.instance.addHandler()` 全局拦截按键事件
- `KeyDownEvent` + `LogicalKeyboardKey.audioVolumeUp/Down` 映射到翻页
- 返回 `true` 阻止系统默认行为（音量调节），返回 `false` 放行其他按键
- 在 `onClose` 中 `removeHandler` 移除监听，防止内存泄漏

**桌面端滚轮/键盘适配**：
- 鼠标滚轮：`Listener(onPointerSignal:)` 捕获 `PointerScrollEvent`，150ms 节流防抖
- 方向键：复用键盘拦截器，`arrowLeft/Up` → 上一页，`arrowRight/Down` → 下一页
- 所有输入路径最终调用统一的 `_jumpTo(index)` 方法，处理菜单关闭、缓存同步、DB 防抖保存

**设计要点**：
- 所有硬件输入统一收敛到 Controller 的 `goToNextPage()` / `goToPreviousPage()` 两个入口
- Strip 模式和 Page 模式的翻页实现不同但接口一致——调用方无需关心当前模式
- 节流控制防止滚轮和方向键的连续触发（滚轮一"格"可能产生多个事件）

### 3.8 GPU 图像实时后处理——对比度 / 饱和度调节

**难点**：用户希望像游戏中一样实时调节画面的对比度、饱和度，且不能有性能开销。传统的方案是 CPU 逐像素处理（Dart 中太慢）或 fragment shader（依赖 Impeller 引擎，Skia 不支持）。

**方案演进**：

*第一阶段：Fragment Shader 方案（失败）*
- 编写 GLSL shader，一次 pass 完成对比度+饱和度+锐化
- 用 Flutter 3.22+ 的 `FragmentProgram` + `ImageFilter.shader` 加载
- 结果：Android (Impeller) 画面异常（颠倒、X光效果），Windows (Skia) 直接抛异常 `ImageFilter.shader only supported with Impeller`
- 排查后认定：`ImageFilter.shader` API 在跨引擎场景下不稳定，坐标/纹理绑定行为不一致

*第二阶段：ColorFilter.matrix 方案（最终）*
- 放弃 shader，改用 `ColorFilter.matrix` — Flutter 原生 GPU 滤镜 API，Skia/Impeller 均支持
- 对比度 + 饱和度组合为一个 5×4 矩阵，单次 GPU pass
- 矩阵推导：
  ```
  // Saturation: lerp between grayscale (L) and original color
  // Contrast: scale around 0.5 midpoint
  // Combined matrix row for R:
  R' = c * [s * R + (1-s) * L] + (1-c)/2
     = c*(s + (1-s)*0.3086)*R + c*((1-s)*0.6094)*G + c*((1-s)*0.0820)*B + (1-c)/2
  ```
- 默认值（contrast=1.0, saturation=1.0）时 `_isIdentity` 检测跳过 `ColorFiltered`，零开销
- 设置页 Slider 拖拽时 `.obs` 触发 `Obx` 重建，图像即时响应

**经验教训**：
- 优先使用 Flutter 原生 API（`ColorFiltered`），而非依赖渲染引擎特定的扩展
- 跨引擎兼容性在移动端不是问题（统一 Impeller），但桌面端仍在过渡期（Windows 默认 Skia）
- Shader 调试困难——编译成功不代表运行时正确，坐标系统差异可能导致结果完全错误

---

## 四、核心技术知识点

详见 [knowledge_map.md](knowledge_map.md)——包含 Dart/Flutter 知识点运用表、技术栈清单、ColorFilter.matrix 数学推导。

---

## 五、面试官可能的提问及答案要点

### Q1: 为什么用 GetX 而不是 Provider/BLoC/Riverpod？

**答**：
- 项目启动时我评估了团队规模和项目复杂度，GetX 的优势在于**开箱即用**——路由管理、状态管理、依赖注入三合一，不需要多层 Provider 嵌套
- 但我没有滥用 Obx——我制定了混合策略：跨页面的全局状态用 `.obs` + `Obx`，页面内部的局部状态用 `GetBuilder` + `update(id)` 精确控制重绘
- 这种做法结合了两者优点：全局状态自动同步，局部状态性能可控
- 如果项目进一步扩大，可以考虑迁移到 Riverpod——它的编译时安全性和 Provider 独立性是 GetX 不具备的

### Q2: 如何做到 ZIP 漫画启动只读几百 KB 而不是整个文件？

**答**：
- ZIP 格式的结构是 [文件数据...][Central Directory][EOCD]
- Central Directory 记录了所有文件的名称、压缩方法、压缩前后大小、在文件中的偏移量
- 我实现了 `ZipReader`：先读文件末尾 ~64KB 定位 EOCD（签名 `0x06054b50`），解析 CD 拿到封面 entry 的偏移和大小，用 `RandomAccessFile` 跳到对应位置只读那一个 entry，最后用 `dart:io` 的 `ZLibDecoder(raw: true)` 解压（ZIP 用的是 raw deflate 而非 zlib 包裹格式）
- 读取量从整个文件（~90MB）降到 ~500KB，约 180 倍

### Q3: 阅读页点击延迟问题是怎么排查和解决的？

**答**：
- 一开始以为是手势竞技场竞争导致延迟，尝试了提取独立 tap 层、自定义 RenderStack 消除 hit test 短路、`onTapDown`/`Listener.onPointerDown` 绕过竞技场……两个方向试了两天，全部失败
- 转折点是最小化实验——把整个 `PhotoView` widget 注释掉，tap 立刻完美。确定了 root cause 在 PhotoView 里
- 对比 JHenTai 项目发现他们 fork 了 photo_view，把 `DoubleTapGestureRecognizer` 从无条件注册改成了条件注册
- 真正根因：`DoubleTapGestureRecognizer` 在第一次点击后调用 `gestureArena.hold(pointer)`，启动 300ms 超时等待第二次点击。即使你没用到双击，这个 hold 也在激活。外层的 `TapGestureRecognizer` 必须等 300ms 超时才能接管
- 修复：本地 fork photo_view，将 `DoubleTapGestureRecognizer` 改为只在有回调时才注册
- 教训：第三方包引起的性能问题，最小化实验比理论分析快 10 倍

### Q4: 你说用了分批并发控制，能解释一下吗？

**答**：
- 问题的本质是：Dart 是单线程事件循环模型，`Future.wait` 把所有 async 操作同时触发，每个 I/O 完成后的回调都会排进事件队列
- 20 部漫画 × 每部 150 张图 = 3000 个并发的 `f.length()` future——每个单独都不阻塞，但 3000 个回调塞满事件队列，Flutter 的渲染帧排到队尾
- 我的方案：参数化并发度（`concurrency`），启动时 0 表示全并发（无 UI 无需让步），刷新时设为 3
- 每批 3 个 `Future.wait` 完成后插入 `await Future(() {})`——这把后续执行推到 event queue 末尾，让 Flutter 的渲染回调优先执行
- 效果：刷新时 UI 保持 60fps 响应，LaodingIndicator 动画流畅

### Q5: 为什么不用 GridView 而手动实现网格布局？

**答**：
- `GridView` 需要预设 `childAspectRatio`，但我的卡片内容高度由封面和文字动态决定
- 比例不匹配时要么溢出要么留白，而 `Wrap` 又无法保证行内元素填满宽度
- 我用 `LayoutBuilder` 获取可用宽度，按公式 `cardWidth = (availableWidth - (cols-1)*spacing) / cols` 精确计算，用 `ListView.builder` + `Row` 手动构造每行
- 这样做的好处是：列数自适应（`clamp(2, 5)`），卡片宽度精确填充不浪费 1px

### Q6: 阅读进度保存怎么做到可靠的？

**答**：
- 翻页时**立即更新内存缓存**（两个地方：`state.readInfo.mangaInfo` 和 `localMangaService.settingPath2Mangas`），确保跨页面读取时是最新的
- DB 防抖 500ms 写入，避免翻页连发大量 SQL UPDATE
- 最关键的：用 `PopScope(canPop: false)` 拦截返回手势，先 `persistToDb()` 落盘再 `Get.back()`
- 这是因为之前踩过坑：`didPopNext`（路由 A 的监听）在 `onClose`（路由 B）之前触发，如果不拦截，A 会读到旧的缓存

### Q7: 你提到了 Platform Channel 理解，能具体说说吗？

**答**：
- 虽然项目中没直接写 Platform Channel 代码，但我在做跨平台适配时需要理解其原理
- 例如 `getExternalStorageDirectory()` 只在 Android 上返回有效值，桌面端返回 null——这是因为底层通过 MethodChannel 调用原生 API，不同平台的实现不同
- 我的处理：用 `Platform.isAndroid` 做守卫，桌面端跳过 Android 专属的存储权限和路径逻辑
- 更深的理解：像 `file_picker`、`permission_handler` 这些插件本质上都是对 Platform Channel 的封装，知道这点有助于调试平台特定 bug

### Q8: 项目里怎么处理内存管理？

**答**：
- `ExtendedImage` 的 `cacheWidth` 参数控制解码时缩放图片到指定宽度，避免全尺寸解码到内存
- `clearMemoryCacheWhenDispose: true` 确保离开阅读页时释放图片内存
- `maxBytes` 参数限制缩略图加载的最大字节数
- 重要的是理解原理：Flutter 的图片缓存以 `ImageProvider` 为 key，同一张图片不同 `cacheWidth` 会被视为不同的缓存条目，所以需要在一致性和内存间取舍

### Q9: 项目中有用到设计模式吗？

**答**：
- **Repository 模式**：Controller 只依赖接口，具体实现可替换，方便测试
- **Factory + Singleton**：`LazyDatabase` 延迟创建 DB 连接，`AppDatabase` 用工厂构造函数实现单例
- **Strategy 模式**：不同的漫画格式（文件夹/ZIP/EPUB）用不同的 `_load*Manga` 策略，结果通过统一的 `_createAndPersistManga` 处理
- **Observer 模式**：`ever(readSetting.bookshelfLayout, ...)` 监听设置变化自动更新 UI
- **Template Method 模式**：`ListPage`、`GridLayout`、`ListLayout` 作为抽象基类，子类重写差异点

### Q10: 如果项目要上生产环境，还有哪些要做？

**答**：
- **测试**：目前缺少单元测试和 Widget 测试——核心逻辑如 `ZipReader`、`_createAndPersistManga` 应该被测覆盖
- **错误边界**：增加全局错误捕获和上报（如 Sentry）
- **CI/CD**：接入 GitHub Actions 自动构建和 lint
- **性能监控**：接入 Firebase Performance 或自研帧率监控
- **ZIP64 支持**：当单个漫画超过 4GB 时需要使用 ZIP64 格式解析
- **iOS 适配**：iOS 的沙盒机制需要 security-scoped bookmarks 才能持续访问用户选择的目录

### Q11: 如果用 Riverpod 重写，你会怎么设计？

**答**：
- `ReadSetting`、`PathSetting` 这类全局配置 → `Notifier`，跨页面共享
- `MangaRepository` → `Provider<MangaRepository>`，通过 `overrideWith` 在测试中替换为 mock
- 页面级状态 → `AsyncNotifier` 或 `StateNotifier`，利用 `.autoDispose` 在页面退出时自动释放
- 读取进度这类需要精确控制 rebuild 范围的操作，利用 Riverpod 的 `select` 只监听特定字段
- GetX 的路由管理换回 `go_router` 或 Flutter 自带的 `Navigator 2.0`

### Q12: 阅读页如何适配多种输入方式（触摸、音量键、鼠标、键盘）？

**答**：

这是一个"多平台输入收敛"问题——同一个翻页操作有 4 种触发路径，但目标行为完全一致。

**架构设计**：
- 所有输入路径收敛到 Controller 的两个入口：`goToNextPage()` 和 `goToPreviousPage()`
- 内部统一调用 `_navigateTo(index)`，处理菜单关闭、缓存同步、DB 防抖保存
- Strip 模式和 Page 模式的跳转实现不同（`ScrollablePositionedList.scrollTo` vs `PageController.animateToPage`），但调用方无感知

**四条输入路径**：
1. **触摸手势分区**——屏幕左/右 1/3 点击翻页，中间点击控制菜单；RTL 模式下左右方向自动反转
2. **音量键**——`HardwareKeyboard.instance.addHandler()` 全局拦截 `KeyDownEvent`，匹配 `audioVolumeUp/Down` 返回 `true` 吞掉事件
3. **鼠标滚轮**——`Listener(onPointerSignal:)` 捕获 `PointerScrollEvent`，150ms Timer 节流防止连续触发
4. **方向键**——复用键盘拦截器，上下左右箭头键映射到翻页

**为什么不用 `Shortcuts` / `Actions` 系统**：
- Flutter 的 `Shortcuts` + `Actions` + `Intent` 体系适合"命令式"快捷键（如 Ctrl+C），但对于阅读页这种需要拦截系统按键（音量键）的场景，`HardwareKeyboard` 的全局 handler 优先级更高，且可以精确控制是否消费事件

**节流处理的关键**：
- 鼠标滚轮一个"格"可能产生多个 `PointerScrollEvent`，150ms cooldown 避免一滚翻多页
- 方向键的 `KeyDownEvent` 天然一次一页（长按由系统控制重复速率）
- 触摸手势每次 tap 只触发一次 `onTap`，无需节流

### Q13: 图像对比度/饱和度调节是怎么实现的？

**答**：

这是 GPU 图像后处理的一个例子。我尝试了两种方案：

**方案一：Fragment Shader（失败）**
- 编写 GLSL 着色器，在 GPU 上一次 pass 完成对比度+饱和度+锐化的 3×3 卷积
- 使用 Flutter 3.22 的 `FragmentProgram` + `ImageFilter.shader` 加载
- 结果：Android (Impeller) 画面异常（颠倒、X光效果），Windows (Skia) 直接抛异常不支持
- 根本原因：`ImageFilter.shader` 要求 Impeller 渲染引擎，Windows 默认用 Skia；且 shader 的坐标/纹理绑定行为在不同引擎下不一致

**方案二：ColorFilter.matrix（最终采用）**
- 回到 Flutter 原生 `ColorFiltered` + `ColorFilter.matrix` — 这是 Skia/Impeller 都支持的成熟 API
- 对比度和饱和度推导为一个 5×4 颜色矩阵，一次 GPU pass 完成
- 矩阵数学：饱和度是原色与灰度的 lerp，对比度是围绕 0.5 的缩放，两者组合成一个矩阵
- 默认值（c=1.0, s=1.0）时矩阵为单位阵，检测后直接返回 child，跳过 `ColorFiltered`，零性能开销
- `ColorFilter.matrix` 本身也是 GPU 运算，和 shader 一样快，但没有兼容性问题

**经验**：
- 跨平台项目优先用框架原生 API，而非渲染引擎特定扩展
- 渲染引擎差异在移动端不明显（统一 Impeller），但桌面端仍在过渡期
- Shader 调试困难——编译通过不代表运行时正确，坐标系统差异会导致完全错误的结果
