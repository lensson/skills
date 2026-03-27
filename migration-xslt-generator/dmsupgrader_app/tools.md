# 工具脚本

## 概述

`dmsupgrader_app/tools/` 目录包含用于迁移文件维护和更新的脚本。

## 工具列表

### 升级脚本

| 脚本 | 说明 |
|------|------|
| `upgrade_offline_configs.sh` | 升级光纤板迁移文件到下一版本 |
| `upgrade_online_configs.sh` | 升级铜线板迁移文件到下一版本 |
| `upgrade_cap_configs.sh` | 升级能力配置 |
| `upgrade_nacm_configs.sh` | 升级 NACM 配置 |
| `upgrade_default_migration.sh` | 升级默认迁移 |

### 维护脚本

| 脚本 | 说明 |
|------|------|
| `check_configs.sh` | 检查升级是否正确完成 |
| `check_xslt.sh` | 检查 XSLT 脚本语法 |
| `add_ipfix_caches.sh` | 添加 IPFIX 缓存 |
| `add_merged_migration.sh` | 添加合并迁移 |
| `add-nokia_aaa-rm_transformed.sh` | 添加 Nokia AAA 移除转换 |
| `add_script.py` | 添加脚本 |
| `create_offline_first_edition.sh` | 创建离线初始版本 |

### 辅助脚本

| 脚本 | 说明 |
|------|------|
| `migration_helper.py` | 迁移辅助工具 |
| `mig_times.py` | 迁移时间工具 |

## upgrade_offline_configs.sh

### 功能

升级光纤板的 XSL/XML 到下一版本。

### 使用方法

```bash
cd vobs/dsl/sw/y/build/apps/dmsupgrader_app
./tools/upgrade_offline_configs.sh
```

### 升级内容

- XSL 文件版本后缀
- XML 配置文件
- 默认迁移文件

### 版本变量

脚本内部定义的版本变量：

```bash
g_CURR_REL_STR=lsr2512      # 当前版本字符串
g_PREV_REL_STR=lsr2509       # 前一版本字符串
g_PREV_PREV_REL_STR=lsr2506  # 前前版本字符串
g_NEXT_REL_STR=lsr2603      # 下一版本字符串
```

## upgrade_online_configs.sh

### 功能

升级铜线板的 XSL/XML 到下一版本。

### 使用方法

```bash
cd vobs/dsl/sw/y/build/apps/dmsupgrader_app
./tools/upgrade_online_configs.sh
```

## check_configs.sh

### 功能

检查升级是否正确完成。

### 使用方法

```bash
cd tools
./check_configs.sh <current_version> <next_version>
```

### 示例

```bash
# 检查 25.9 到 25.12 的升级
./check_configs.sh 25.9 25.12

# 只检查成功结果
./check_configs.sh 25.9 25.12 | grep "all ok"
```

### 预期输出

如果所有检查通过，会输出 "all ok"。

## migration_helper.py

### 功能

接收 release 和 xsl 作为输入，将修改后的 xsl 添加到选定板卡。

### 依赖

- Python 3
- click 库

### 使用方法

```bash
python3 migration_helper.py
```

脚本会提供交互式界面引导输入。

### 输入参数

| 参数 | 说明 | 示例 |
|------|------|------|
| release | 目标版本 | 23.12 |
| path | XSL 路径 | default_xsl/nacm.xsl |
| name | 名称 | nacm |
| board | 目标板卡 | FGLT-B |

### 输出

```bash
Offline selected options: FGLT-B
File '/data/user/sw/vobs/dsl/sw/y/build/apps/dmsupgrader_app/tools/default_xsl/nacm.xsl' 
    copied to '/data/user/sw/y/build/apps/dmsupgrader_app/offlineCfg/FGLT-B/xsl/lsr2309_to_lsr2312_test.xsl' successfully.
Added '/data/user/sw/y/build/apps/dmsupgrader_app/offlineCfg/FGLT-B/xsl/lsr2309_to_lsr2312_test.xsl' to the Mercurial repository.
Check changes with hg diff --stat
Rollback with hg revert --all
```

## manual_execute/run.sh

### 功能

手动执行特定路径、板卡和版本的转换。

### 使用方法

```bash
./run.sh [options]
```

### 选项

| 选项 | 说明 |
|------|------|
| `-xslt_path` | XSLT 路径 |
| `-board_name` | 板卡名称 |
| `-begin_release` | 起始版本 |
| `-end_release` | 结束版本 |
| `-input_directory` | 输入目录 |
| `-output_directory` | 输出目录 |

### 示例

```bash
cd tools/manual_execute
./run.sh -board_name FGLT-B -begin_release 23.9 -end_release 23.12 -input_directory ./input -output_directory ./output
```

## check_xslt.sh

### 功能

检查 XSLT 脚本的语法和正确性。

### 使用方法

```bash
./check_xslt.sh <xsl_file>
```

### 检查内容

- XSLT 语法正确性
- 命名空间声明
- 模板匹配表达式

## add_ipfix_caches.sh

### 功能

自动添加 IPFIX 缓存相关的迁移脚本。

### 使用方法

脚本由 `upgrade_offline_configs.sh` 自动调用。

## 维护流程

### 1. 运行升级脚本

```bash
# 升级光纤板
./tools/upgrade_offline_configs.sh

# 升级铜线板
./tools/upgrade_online_configs.sh
```

### 2. 检查升级

```bash
cd tools
./check_configs.sh <current_version> <next_version> | grep "all ok"
```

### 3. 更新版本变量

编辑升级脚本，更新版本变量为下一版本。

### 4. 创建新板卡标记

```bash
touch ./offlineCfg/NEW_BOARDS_IN_${g_CURR_REL_STR}_A
```

## 版本升级示例

### 从 25.9 到 25.12

```bash
# 1. 运行升级脚本
./tools/upgrade_offline_configs.sh
./tools/upgrade_online_configs.sh

# 2. 检查
cd tools
./check_configs.sh 25.9 25.12 | grep "all ok"

# 3. 更新版本变量
# 编辑 upgrade_offline_configs.sh 和 upgrade_online_configs.sh
# 将 g_CURR_REL_STR 从 lsr2509 改为 lsr2512
```

## N+1 构建支持

为支持 N+1 迁移（开发期间），需要确保版本变量正确：

```bash
# 当前版本变量示例
g_CURR_REL_STR=lsr2512      # 25.12 (MS)
g_PREV_REL_STR=lsr2509       # 25.9 (HS)
g_PREV_PREV_REL_STR=lsr2506  # 25.6
g_NEXT_REL_STR=lsr2603      # 26.3 (开发中)
```

这确保在开发 N+1 版本时，可以测试 N 到 N+1 的迁移。
