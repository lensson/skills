# DMSUpgrader 概述

## 简介

`dmsupgrader_app` 是负责在系统中发生软件升级时升级数据存储（CDB）的应用程序。该应用程序不会在系统中永久运行，它在以下情况下启动：
- 在线迁移的激活操作（activate action）
- 离线迁移的配置下载操作（config-download action）

## 核心功能

DMSUpgrader 的基本过程是将数据存储转换以兼容新激活的软件。

### 主要职责

1. **数据存储转换**：将旧版本的数据格式转换为新版本格式
2. **YANG 模型兼容性**：处理 YANG 节点变更、删除、重命名
3. **配置验证**：确保迁移后的配置符合新 YANG 模型约束
4. **版本追溯**：支持多版本间的平滑升级路径

## 迁移场景

当以下情况发生时，存在迁移影响：

### 1. YANG 节点变更

- 节点名称变更（如 `vlan-id` → `vlan_id`）
- 节点层级变更（如从容器内移到根级）
- 节点类型变更

### 2. YANG 节点删除

不再需要的配置节点需要被移除。

### 3. YANG 命名空间变更

模块的 namespace URI 发生变化。

### 4. 配置更新

- 使用 must 语句限制值范围
- 替换叶子节点的值
- 添加新的默认值

## 迁移类型

### 离线迁移 (Offline Migration)

适用于光纤板（Fiber boards）。

**特点：**
- 设备重启后应用新配置
- 使用 XSLT 脚本转换配置文件
- 在设备启动时执行迁移

**配置目录：** `offlineCfg/`

**支持的板卡：**
- FGLT-B, FGLT-D, FGLT-E
- FWLT-B, FWLT-C
- FANT-F, FANT-G, FANT-H, FANT-M
- FELT-B, FELT-D
- LGLT-D, LGLT-E
- LLLT-A, LLLT-B
- LMNT-A, LMNT-B, LMNT-C, LMNT-D
- DFMB-A/B/C/D
- CFNT-B, CFNT-D
- CFXR-K
- 等

### 在线迁移 (Online Migration)

适用于铜线板（Copper boards）和 SD-DPU。

**特点：**
- 运行时升级，无需重启设备
- 动态配置转换
- 服务不中断

**配置目录：** `SD-DPU/`

## 目录结构

```
dmsupgrader_app/
├── xsl/                           # XSLT 迁移脚本
│   ├── merged/                    # 合并的迁移脚本
│   ├── default/                   # 默认迁移脚本
│   ├── nacm/                      # NACM 相关
│   ├── qos/                       # QoS 相关
│   ├── l2forwarding/              # L2 转发相关
│   ├── multicast/                 # 组播相关
│   ├── ipfix/                     # IPFIX 相关
│   └── ...                        # 其他域
├── offlineCfg/                    # 离线迁移配置
│   ├── <BOARD_NAME>/              # 按板卡组织
│   │   ├── migration.xml          # 迁移配置
│   │   └── xsl/                   # 板卡特定 XSL
│   └── ...
├── SD-DPU/                        # SD-DPU 配置
├── tools/                         # 工具脚本
│   ├── manual_execute/            # 手动执行工具
│   ├── migration_helper.py        # 迁移辅助脚本
│   └── ...
└── script_offline/                # 离线脚本
```

## 版本命名规范

### 发布版本格式

```
lsr<YY><MM>  例如: lsr2303, lsr2306, lsr2309
```

- YY: 年份后两位
- MM: 月份

### XSLT 脚本命名

```
lsr<FROM>_<TO>_<module>_<variant>.xsl
```

示例：
- `lsr2303_to_lsr2306_nacm_1.xsl`
- `lsr2306_to_lsr2309_qos_2.xsl`
- `lsr2303_to_lsr2306_migration_cfnt-b.xsl`（板卡特定）

## 配置管理

### app.json

应用配置文件，定义构建和运行参数：

```json
{
  "build": {
    "executable": "dmsupgrader_app",
    "shared_libraries": ["confd", "protobuf", "pugixml", "xml2", "xslt", "exslt"]
  },
  "run": {
    "config": {
      "ylog": {
        "modules": {
          "dmsupgrader": { "threshold": "YLOG_INFO" },
          "upgrader": { "threshold": "YLOG_INFO" }
        }
      }
    }
  }
}
```

### offlineCfg 配置文件

定义各板卡的迁移路径和脚本：

```ini
FGLT-B=y
FGLT-B_pkg_cfg=NW89AA
FGLT-B_pkg_confd=NW9AAA
FGLT-B_pkg_fxs=NW89AA
FGLT-B_pkg_migCfg=NW89AA
FGLT-B_pkg_defaultXml=NW89AA
FGLT-B_pkg_migApp=NW89AA
```

## 迁移执行流程

### 离线迁移流程

```
1. 触发 config-download action
      ↓
2. dmsupgrader_app 启动
      ↓
3. 读取 migration.xml 获取迁移脚本
      ↓
4. 读取当前 CDB 配置
      ↓
5. 按顺序执行 XSLT 转换
      ↓
6. 写入新的 CDB 配置
      ↓
7. 应用默认配置
      ↓
8. 重启服务
```

### 在线迁移流程

```
1. 触发 activate action
      ↓
2. DMSUpgrader 在线模式启动
      ↓
3. 实时配置转换
      ↓
4. 动态应用新配置
      ↓
5. 服务持续运行
```

## YANG Owner 职责

当 YANG 模块变更影响迁移时，YANG Owner 需要：

1. 实现 XSLT 脚本
2. 将脚本添加到受影响板卡的 migration.xsl
3. 在 merge 目录创建板卡特定的迁移文件
4. 验证迁移脚本的正确性

## 相关文档

- [3HH-12875-3335-DFZZA](https://fn-antwerp.int.net.nokia.com/esam/readme/sw/vobs/dsl/sw/y/build/apps/dmsupgrader_app/) - XSLT 使用指南
- [3HH-03716-3015-DFZZA](https://fn-antwerp.int.net.nokia.com/esam/readme/sw/vobs/dsl/sw/y/build/apps/dmsupgrader_app/tools/) - 迁移框架维护
