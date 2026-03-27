# DMSUpgrader 升级工作流详解 {#workflow}

## 概述

本文档详细描述了当希望将某个板卡从版本 A 升级到版本 B 时，整个系统如何调用 XSL 文件、如何获取输入 XML 并最终生成输出 XML 的完整流程。

---

## 完整工作流总览 {#overview}

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           阶段 1: 触发升级                                  │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           阶段 2: 准备 XSL 文件                             │
│  dms_upgrade.sh 从 Type-U 包复制 migration.xml 和 xsl/ 到迁移目录            │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           阶段 3: dmsupgrader_app 执行                      │
│  读取 migration.xml，确定迁移路径(source→target)                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           阶段 4: 获取输入 XML                               │
│  从 ConfD CDB 导出当前配置为 XML                                            │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           阶段 5: 顺序执行 XSLT                             │
│  按 migration.xml 中的脚本列表，顺序应用 XSL 转换                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           阶段 6: 生成输出 XML                              │
│  XSLT 转换后的新配置写入 new-xml/ 目录                                      │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           阶段 7: 应用新配置                                │
│  dms_upgrade.sh 将 new-xml 复制到 ConfD 初始化目录，重启设备                │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 阶段详解

## 阶段 1: 触发升级

### 触发方式

用户通过配置下载操作触发离线迁移：

```bash
# 通过 CLI 或 NETCONF 触发
config-download
```

### 调用链

```
用户触发
    │
    ▼
swm (Software Manager)
    │
    ▼
dms_upgrade.sh (入口脚本)
```

---

## 阶段 2: 准备 XSL 文件

### dms_upgrade.sh 关键操作

`dms_upgrade.sh` 从目标版本的 Type-U 包复制必要的迁移文件：

```bash
# 1. 挂载目标版本的 Type-U 包
mount -t squashfs ${source_dir}/${typeU_file} ${tmp_dir}

# 2. 复制 migration.xml 到 new_cfg/
cp -f ${var_tag_cfg_dir}/*.xml $dest_dir/new_cfg/.

# 3. 复制 xsl/ 目录到迁移目录
cp -f ${var_tag_cfg_dir}/xsl/*.xsl $dest_dir/xsl/.
```

### 目录创建

```bash
# 创建目录结构
/mnt/nand-persistent/persistent/migration/
├── xml/              # 输入 XML (从 CDB 导出)
├── new_cfg/         # 目标版本的 migration.xml
├── xsl/             # 目标版本的 XSL 文件
├── tmp-xml/         # 临时 XML (XSLT 转换中)
└── new-xml/         # 输出 XML (转换后)
```

---

## 阶段 3: dmsupgrader_app 执行

### 应用启动

```bash
# dms_upgrade.sh 调用 dmsupgrader_app
${APP_EXE} ${APP_CONFIG_PARA} $1
```

### 读取 migration.xml

`TransferAgent::readMigrationCfg()` 解析 `migration.xml`：

```cpp
// 伪代码
bool TransferAgent::readMigrationCfg(const char *cfg) {
    // 1. 解析 XML
    xml_document doc;
    doc.load_file(cfg);
    
    // 2. 遍历 <migration> 元素
    for (auto migration : doc.select_nodes("//migration")) {
        string source = migration.select_node("source").text();
        string target = migration.select_node("target").text();
        
        // 3. 提取 <scripts>
        for (auto script : migration.select_nodes("scripts/script")) {
            string subtree = script.attribute("subtree").value();
            string xsl_file = script.text().as_string();
            
            // 4. 添加到迁移映射表
            MigrationItem item;
            item.m_source = source;
            item.m_target = target;
            item.m_subtree = subtree;
            item.m_xsl = xsl_file;
            addMigrationToMap(item);
        }
    }
}
```

### 确定迁移路径

`isMigrationNeeded()` 比较版本：

```cpp
bool TransferAgent::isMigrationNeeded() {
    // 旧版本: 从 release_versions.xml 或 CDB 读取
    // 新版本: 从目标版本的 release_versions.xml 读取
    return (m_newDbVersion == m_oldDbVersion) ? false : true;
}
```

### 迁移路径选择逻辑

如果要从 **23.9 升级到 25.12**：

```
migration.xml 中可能找到：
  23.9 → 23.12
  23.12 → 24.3
  24.3 → 24.6
  24.6 → 24.9
  24.9 → 24.12
  24.12 → 25.3
  25.3 → 25.6
  25.6 → 25.9
  25.9 → 25.12

系统会按顺序执行每一段迁移
```

---

## 阶段 4: 获取输入 XML

### 从 ConfD CDB 导出

```bash
# dms_upgrade.sh 调用 dmsupgrader_app 无参数时导出 CDB
if [ $# -eq 0 ]; then
    ${APP_EXE} ${APP_CONFIG_PARA}  # 导出 CDB 为 XML
fi
```

### 输出位置

```
/mnt/nand-persistent/persistent/migration/
└── xml/
    └── all_config.xml  # 当前系统的完整配置
```

### 导出内容示例

```xml
<config xmlns="http://tail-f.com/ns/config/1.1">
    <interfaces xmlns="urn:ietf:params:xml:ns:yang:ietf-interfaces">
        <interface>
            <name>eth0</name>
            <type>ethernetCsmacd</type>
            <enabled>true</enabled>
        </interface>
    </interfaces>
    <forwarding xmlns="urn:bbf:yang:bbf-l2-forwarding">
        <!-- L2 转发配置 -->
    </forwarding>
    <qos xmlns="urn:bbf:yang:bbf-qos-policies">
        <!-- QoS 配置 -->
    </qos>
</config>
```

---

## 阶段 5: 顺序执行 XSLT

### XSLT 执行入口

```cpp
// TransferAgent.cpp
if (madeXsltCmds() != 0) {
    LOG_PRINTF(YLOG_ERROR, "Make xslt cmds failed\n");
    return ERR_MADE_CMD_FAIL;
}

// 实际执行在 XsltCmd.cpp
```

### madeXsltCmds() 逻辑

```cpp
bool TransferAgent::madeXsltCmds() {
    // 1. 获取迁移路径中的所有 XSL 文件
    list<string> xsl_files = getMigrationScripts(source_version, target_version);
    
    // 2. 生成 XSLT 命令
    for (auto xsl : xsl_files) {
        string cmd = buildXsltCommand(xsl, input_file, output_file);
        addToCommandList(cmd);
    }
    
    // 3. 执行命令
    return executeCommandList();
}
```

### XSLT 命令格式

```bash
# xsltproc 命令格式
xsltproc \
    --output output.xml \
    --path /mnt/nand-persistent/persistent/migration/xsl/merged/ \
    /mnt/nand-persistent/persistent/migration/xsl/merged/lsr2303_to_lsr2306_migration_cfnt-d.xsl \
    input.xml
```

### 执行顺序

对于 `23.3 → 23.6 → 23.9 → 23.12` 的升级路径：

```
┌──────────────────────────────────────────────────────────────┐
│ Step 1: 23.3 → 23.6                                        │
│ ┌────────────────────────────────────────────────────────┐ │
│ │ merged/lsr2303_to_lsr2306_migration_cfnt-d.xsl        │ │
│ │   ├── lsr2303_to_lsr2306_nacm_1.xsl                   │ │
│ │   ├── lsr2303_to_lsr2306_qos_1.xsl                    │ │
│ │   ├── lsr2303_to_lsr2306_l2fwd_1.xsl                  │ │
│ │   └── ...                                             │ │
│ └────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────────────────────────┐
│ Step 2: 23.6 → 23.9                                        │
│ ┌────────────────────────────────────────────────────────┐ │
│ │ merged/lsr2306_to_lsr2309_migration_cfnt-d.xsl         │ │
│ └────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────────────────────────┐
│ Step 3: 23.9 → 23.12                                       │
│ ┌────────────────────────────────────────────────────────┐ │
│ │ merged/lsr2309_to_lsr2312_migration_cfnt-d.xsl         │ │
│ └────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

### 流水线处理

```
input.xml  ──→ [XSL 1] ──→ temp1.xml ──→ [XSL 2] ──→ temp2.xml ──→ ...
                      │                            │
                      ▼                            ▼
              merged/lsr2303_...         lsr2306_...
              _to_lsr2306_...             _to_lsr2309_...
```

---

## 阶段 6: 生成输出 XML

### 最终输出位置

```bash
/mnt/nand-persistent/persistent/migration/
└── new-xml/
    └── all_config.xml  # 转换后的新配置
```

### 输出验证

```cpp
// XsltCmd.cpp 中的验证逻辑
bool XsltCmd::validateOutput(const string& output_file) {
    // 1. 检查文件是否存在
    if (!file_exists(output_file)) return false;
    
    // 2. 检查 XML 格式是否有效
    if (!isValidXml(output_file)) return false;
    
    // 3. 检查是否包含必要元素
    if (!containsRequiredElements(output_file)) return false;
    
    return true;
}
```

---

## 阶段 7: 应用新配置

### dms_upgrade.sh 的更新逻辑

```bash
# 1. 备份旧的 ConfD CDB
rm /mnt/nand-dbase/confd-cdb/*.cdb

# 2. 复制新的 XML 到 ConfD 初始化目录
cp /mnt/nand-persistent/persistent/migration/new-xml/*.xml /var/confd/init-xmls/.

# 3. 清理临时文件
rm -rf /mnt/nand-persistent/persistent/migration/new-xml
rm -rf /mnt/nand-persistent/persistent/migration/tmp-xml

# 4. 创建迁移完成标志
touch ${g_TMP_PATH}/flag_run_with_migrated_cdb
```

### 设备重启

迁移完成后，设备重启以应用新配置。

---

## 具体示例：CFNT-D 从 23.9 升级到 23.12

### 1. 触发升级

```bash
config-download
```

### 2. 准备阶段

```bash
# 挂载目标版本 Type-U 包
mount -t squashfs /isam/software/OSWP1/CFNT-D_TypeU_23.12.squashfs /mnt/nand-persistent/persistent/migration/tmp

# 复制配置
cp /tmp/dmsupgrader_cfg/migration.xml /mnt/nand-persistent/persistent/migration/new_cfg/
cp /tmp/dmsupgrader_cfg/xsl/*.xsl /mnt/nand-persistent/persistent/migration/xsl/
```

### 3. migration.xml 内容

```xml
<migrations>
    <board>CFNT-D</board>
    
    <!-- 23.9 → 23.12 迁移 -->
    <migration>
        <source>23.9</source>
        <target>23.12</target>
        <scripts>
            <script subtree="merged">lsr2309_to_lsr2312_migration_cfnt-d.xsl</script>
        </scripts>
    </migration>
</migrations>
```

### 4. 获取输入 XML

```
/mnt/nand-persistent/persistent/migration/xml/all_config.xml
```

### 5. XSLT 转换

```bash
# 执行 XSLT
xsltproc \
    --output /mnt/nand-persistent/persistent/migration/tmp-xml/all_config.xml \
    --path /mnt/nand-persistent/persistent/migration/xsl/merged/ \
    /mnt/nand-persistent/persistent/migration/xsl/merged/lsr2309_to_lsr2312_migration_cfnt-d.xsl \
    /mnt/nand-persistent/persistent/migration/xml/all_config.xml
```

### 6. 生成输出

```
/mnt/nand-persistent/persistent/migration/new-xml/all_config.xml
```

### 7. 应用配置

```bash
# 复制到 ConfD
cp /mnt/nand-persistent/persistent/migration/new-xml/*.xml /var/confd/init-xmls/.

# 重启设备
reboot
```

---

## 具体示例：LLLT-A 从 26.3 升级到 26.6 {#lllt-a-detail}

### 背景

LLLT-A 是一个 GPON OLT 板卡，需要从版本 26.3 升级到 26.6。

### 1. LLLT-A 的 migration.xml

文件位置：`offlineCfg/LLLT-A/migration.xml`

```xml
<migrations>
    <board>LLLT-A</board>

    <!-- 25.6 → 25.9 -->
    <migration>
        <source>25.6</source>
        <target>25.9</target>
        <scripts>
            <script subtree="merged">lsr2506_to_lsr2509_migration_lllt-a.xsl</script>
        </scripts>
    </migration>

    <!-- 25.9 → 25.12 -->
    <migration>
        <source>25.9</source>
        <target>25.12</target>
        <scripts>
            <script subtree="merged">lsr2509_to_lsr2512_migration_lllt-a.xsl</script>
        </scripts>
    </migration>

    <!-- 25.12 → 26.3 -->
    <migration>
        <source>25.12</source>
        <target>26.3</target>
        <scripts>
            <script subtree="merged">lsr2512_to_lsr2603_migration_lllt-a.xsl</script>
        </scripts>
    </migration>

    <!-- 26.3 → 26.6 ← 目标迁移 -->
    <migration>
        <source>26.3</source>
        <target>26.6</target>
        <scripts>
            <script subtree="merged">lsr2603_to_lsr2606_migration_lllt-a.xsl</script>
        </scripts>
    </migration>
</migrations>
```

### 2. merged 脚本内容

文件位置：`xsl/merged/lsr2603_to_lsr2606_migration_lllt-a.xsl`

```xml
<?xml version="1.0" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!-- Identity transform (必须：复制所有未匹配的节点) -->
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- 包含 IPFIX 缓存迁移 (板卡特定) -->
    <xsl:include href="lsr2603_to_lsr2606_ipfix-caches_lllt-a.xsl"/>

    <!-- 包含 NACM 迁移 (通用) -->
    <xsl:include href="lsr2603_to_lsr2606_nacm_1.xsl"/>

    <!-- 包含 eONU 时钟迁移 -->
    <xsl:include href="lsr2603_to_lsr2606_eonu_clock.xsl"/>

</xsl:stylesheet>
```

### 3. 功能域脚本示例

#### NACM 脚本

文件位置：`xsl/nacm/lsr2603_to_lsr2606_nacm_1.xsl`

```xml
<?xml version="1.0" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                              xmlns:nacm="urn:ietf:params:xml:ns:yang:ietf-netconf-acm"
                              xmlns:tacm="http://tail-f.com/yang/acm"
>

    <!-- 移除默认的 rule-list (已在 default xml 中定义) -->
    <!-- 保留 admin-rule-list, techsupport-rule-list 等 -->
    <xsl:template match="nacm:nacm/nacm:rule-list[ nacm:name = 'admin-rule-list' or
                                                 nacm:name = 'techsupport-rule-list' or
                                                 nacm:name = 'netconf-only-rule-list' or
                                                 nacm:name = 'cli-only-rule-list'
                                                 ]/nacm:rule"/>

    <!-- 移除默认的 rule-list (包含 'default', 'vcli-rule-list' 等) -->
    <xsl:template match="nacm:nacm/nacm:rule-list[ nacm:name[ text()='admin-read-only-list' or
                                                             text()='any-group' or
                                                             text()='default' or
                                                             text()='vcli-rule-list' or
                                                             text()='default-interfaces-list' or
                                                             ( (contains(text(), '-read-access-list') or
                                                               contains(text(), '-config-access-list') or
                                                               contains(text(), '-exec-access-list') ) and
                                                               ( contains(text(), 'log') or
                                                                 contains(text(), 'transport') or
                                                                 contains(text(), 'qos') or
                                                                 contains(text(), 'swm') or
                                                                 ...
                                                             ))
                                                             ]]"/>

</xsl:stylesheet>
```

### 4. 升级执行流程

#### Step 1: 触发升级

```
用户执行: config-download
    ↓
swm (Software Manager)
    ↓
dms_upgrade.sh
    ↓
dmsupgrader_app
```

#### Step 2: 读取 migration.xml

```cpp
// TransferAgent::readMigrationCfg() 解析后得到：
{
    source: "26.3",
    target: "26.6",
    scripts: [
        { subtree: "merged", xsl: "lsr2603_to_lsr2606_migration_lllt-a.xsl" }
    ]
}
```

#### Step 3: XSLT 执行命令

```bash
# 单条 XSLT 命令（merged 脚本会递归加载其包含的其他脚本）
xsltproc \
    --output /mnt/nand-persistent/persistent/migration/tmp-xml/all_config.xml \
    --path /mnt/nand-persistent/persistent/migration/xsl/ \
    /mnt/nand-persistent/persistent/migration/xsl/merged/lsr2603_to_lsr2606_migration_lllt-a.xsl \
    /mnt/nand-persistent/persistent/migration/xml/all_config.xml
```

### 5. XSLT 执行顺序

```
┌─────────────────────────────────────────────────────────────────┐
│ 输入 XML (26.3 版本配置)                                        │
│ xml/all_config.xml                                              │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│ XSLT Processor 执行 lsr2603_to_lsr2606_migration_lllt-a.xsl     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Identity transform (复制所有节点)                           │
│                                                                 │
│  2. 应用 lsr2603_to_lsr2606_ipfix-caches_lllt-a.xsl           │
│     └── 转换 IPFIX 缓存配置                                      │
│                                                                 │
│  3. 应用 lsr2603_to_lsr2606_nacm_1.xsl                         │
│     └── 清理默认 NACM rule-list                                 │
│                                                                 │
│  4. 应用 lsr2603_to_lsr2606_eonu_clock.xsl                     │
│     └── 转换 eONU 时钟配置                                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│ 输出 XML (26.6 版本配置)                                        │
│ new-xml/all_config.xml                                          │
└─────────────────────────────────────────────────────────────────┘
```

### 6. 转换前后对比示例

#### 转换前 (26.3 版本)

```xml
<config xmlns="http://tail-f.com/ns/config/1.1">
    <!-- NACM 配置 -->
    <nacm xmlns="urn:ietf:params:xml:ns:yang:ietf-netconf-acm">
        <rule-list>
            <name>default</name>     <!-- 在 26.6 中将被移除 -->
            <rule>
                <name>rule1</name>
                <access-operations>*</access-operations>
                <action>permit</action>
            </rule>
        </rule-list>
        <rule-list>
            <name>admin-rule-list</name>  <!-- 保留 -->
            <rule>
                <name>admin-rule</name>
                <access-operations>*</access-operations>
                <action>permit</action>
            </rule>
        </rule-list>
    </nacm>

    <!-- 其他配置... -->
</config>
```

#### 转换后 (26.6 版本)

```xml
<config xmlns="http://tail-f.com/ns/config/1.1">
    <!-- NACM 配置 -->
    <nacm xmlns="urn:ietf:params:xml:ns:yang:ietf-netconf-acm">
        <!-- default rule-list 已被移除 -->
        <rule-list>
            <name>admin-rule-list</name>  <!-- 保留 -->
            <rule>
                <name>admin-rule</name>
                <access-operations>*</access-operations>
                <action>permit</action>
            </rule>
        </rule-list>
    </nacm>

    <!-- 其他配置... -->
</config>
```

### 7. 目录映射

```
源目录 (build 时打包到 Type-U 包)
│
├── xsl/
│   ├── merged/
│   │   └── lsr2603_to_lsr2606_migration_lllt-a.xsl  ← merged 脚本
│   ├── nacm/
│   │   └── lsr2603_to_lsr2606_nacm_1.xsl           ← 功能域脚本
│   ├── ipfix/
│   │   └── lsr2603_to_lsr2606_ipfix-caches_lllt-a.xsl
│   └── eonu/
│       └── lsr2603_to_lsr2606_eonu_clock.xsl
│
└── offlineCfg/LLLT-A/
    └── migration.xml  ← 定义迁移路径

        ↓ 打包到 Type-U 包

运行时目录 (设备上 /mnt/nand-persistent/persistent/migration/)
│
├── new_cfg/
│   └── migration.xml  ← 目标版本的迁移配置
│
├── xsl/
│   ├── merged/
│   │   └── lsr2603_to_lsr2606_migration_lllt-a.xsl
│   ├── nacm/
│   │   └── lsr2603_to_lsr2606_nacm_1.xsl
│   └── ...
│
├── xml/
│   └── all_config.xml  ← 输入 XML (26.3 版本)
│
├── tmp-xml/
│   └── all_config.xml  ← 中间 XML
│
└── new-xml/
    └── all_config.xml  ← 输出 XML (26.6 版本)
```

### 8. 版本跨度升级

如果 LLLT-A 需要从 25.12 升级到 26.6：

```
migration.xml 中需要按顺序执行：
┌─────────────────────────────────────────────────────────────────┐
│ Step 1: 25.12 → 26.3                                            │
│ lsr2512_to_lsr2603_migration_lllt-a.xsl                        │
│ (可能包含 10+ 个功能域脚本)                                       │
└─────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────┐
│ Step 2: 26.3 → 26.6                                            │
│ lsr2603_to_lsr2606_migration_lllt-a.xsl                        │
│ (包含 3 个功能域脚本)                                            │
└─────────────────────────────────────────────────────────────────┘
```

---

## 目录对应关系图

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           源: vobs/dsl/sw/y/build/apps/dmsupgrader_app/     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │                           xsl/ 目录                                   │  │
│  │                                                                      │  │
│  │  merged/                                                             │  │
│  │  ├── lsr2309_to_lsr2312_migration_cfnt-d.xsl  ←─── merged 脚本     │  │
│  │  └── ...                                                             │  │
│  │                                                                      │  │
│  │  nacm/                                                               │  │
│  │  ├── lsr2309_to_lsr2312_nacm_1.xsl        ←─── 功能域脚本            │  │
│  │  └── ...                                                             │  │
│  │                                                                      │  │
│  │  qos/                                                                │  │
│  │  ├── lsr2309_to_lsr2312_qos_1.xsl                                   │  │
│  │  └── ...                                                             │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │                     offlineCfg/<BOARD>/ 目录                          │  │
│  │                                                                      │  │
│  │  CFNT-D/                                                             │  │
│  │  ├── migration.xml        ←─── 定义迁移路径和脚本引用                  │  │
│  │  ├── release_versions.xml ←─── 支持的版本列表                         │  │
│  │  └── internal/                                                       │  │
│  │      └── framework/     ←─── 框架配置                               │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘

                              │
                              │ 复制到运行时目录
                              ▼

┌─────────────────────────────────────────────────────────────────────────────┐
│                      运行时: /mnt/nand-persistent/persistent/migration/      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  xml/                          ← 输入 XML (从 CDB 导出)                    │
│  └── all_config.xml                                                      │
│                                                                             │
│  new_cfg/                      ← 目标版本的 migration.xml                 │
│  └── migration.xml                                                      │
│                                                                             │
│  xsl/                          ← XSLT 脚本                                 │
│  ├── merged/                                                             │
│  │   └── lsr2309_to_lsr2312_migration_cfnt-d.xsl                         │
│  ├── nacm/                                                              │
│  └── qos/                                                               │
│                                                                             │
│  tmp-xml/                        ← 中间转换文件                            │
│                                                                             │
│  new-xml/                        ← 输出 XML (转换后)                       │
│  └── all_config.xml                                                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 关键文件对应关系

| 源目录 | 运行时目录 | 说明 |
|--------|-------------|------|
| `offlineCfg/<BOARD>/migration.xml` | `migration/new_cfg/migration.xml` | 定义迁移路径 |
| `xsl/merged/` | `migration/xsl/merged/` | 合并的迁移脚本 |
| `xsl/<domain>/` | `migration/xsl/<domain>/` | 功能域 XSL |

---

## 总结

整个升级流程的核心是：

1. **migration.xml** 定义了版本间的迁移路径和对应的 XSL 文件
2. **subtree 属性** 指向 `xsl/` 下的具体子目录
3. **merged 脚本** 使用 `xsl:include` 组合多个功能域脚本
4. **流水线处理**：输入 XML 经过多个 XSL 转换，逐步生成兼容新版本的输出 XML
