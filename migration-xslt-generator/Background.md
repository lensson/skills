# Background: XSLT Framework Reference

This document contains key reference information for XSLT migration script generation.

---

## XSLT 文件组织原则

### 关键原则

1. **不重复**：相同文件应只有一份
2. **不符号链接**：避免使用符号链接

### 目录结构

XSLT 文件按域组织在 `xsl/<domain>/` 目录下。

### 域分类

| 域目录 | 说明 |
|--------|------|
| `nacm/` | NACM (NETCONF Access Control) |
| `qos/` | QoS 策略和调度 |
| `l2forwarding/` | 二层转发 |
| `multicast/` | 组播配置 |
| `ipfix/` | IPFIX 流量监控 |
| `cfm/` | CFM (Connectivity Fault Management) |
| `erps/` | ERPS 环网保护 |
| `bbf/` | BBF 标准模块 |
| `merged/` | 合并的迁移脚本 |
| `default/` | 默认迁移脚本 |
| `remove/` | 移除不支持节点 |
| `...` | 其他功能域 |

---

## XSLT 命名规范

### 通用 XSL

可跨板卡复用的 XSL 必须以 `_1` 结尾：

```
lsr2009_to_lsr2012_nacm_1.xsl
```

### 变体 XSL

与通用 XSL 有轻微偏差的 XSL 使用 `_2`、`_3` 等后缀：

```
lsr2009_to_lsr2012_nacm_2.xsl
```

### 板卡特定 XSL

迁移 XSL 和 IPFIX 自动生成的文件始终是板卡特定的，使用 `_<board>` 后缀：

```
lsr2303_to_lsr2306_migration_cfnt-b.xsl
```

---

## XSLT 文件位置

XSLT 文件应保存到：
```
vobs/dsl/sw/y/build/apps/dmsupgrader_app/xsl/{domain}/
```

### 完整路径示例

```
vobs/dsl/sw/y/build/apps/dmsupgrader_app/xsl/qos/
vobs/dsl/sw/y/build/apps/dmsupgrader_app/xsl/nacm/
vobs/dsl/sw/y/build/apps/dmsupgrader_app/xsl/merged/
```

---

## XSLT 标准模板结构

### 基础模板

```xml
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:confd="http://www.tail-f.com/ns/confd/1.0">

    <xsl:strip-space elements="*"/>
    <xsl:output method="xml" indent="yes"/>

    <!-- Description -->
    <xsl:comment>
        YANG Migration: filename.yang
        Change: description of change
        Date: YYYY-MM-DD
    </xsl:comment>

    <!-- Identity transform -->
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- Templates for specific transformations -->

</xsl:stylesheet>
```

### 带命名空间的模板

```xml
<?xml version='1.0' encoding='UTF-8'?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:bbf-qos-cls="urn:bbf:yang:bbf-qos-classifiers"
                xmlns:bbf-qos-pol="urn:bbf:yang:bbf-qos-policies"
                version="1.0">

    <xsl:strip-space elements="*"/>
    <xsl:output method="xml" indent="yes"/>

    <!-- Default identity transform -->
    <xsl:template match="*">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>

    <!-- Templates for specific transformations -->

</xsl:stylesheet>
```

---

## 常见迁移操作

### 1. 删除节点

**方式一：空模板（最常用）**
```xml
<!-- 删除特定节点 -->
<xsl:template match="path/to/node-to-delete"/>
```

**方式二：带注释的删除**
```xml
<!-- Remove /bbf-l2-fwd:forwarding -->
<xsl:template match="bbf-l2-fwd:forwarding"/>
```

### 2. 重命名节点

```xml
<!-- 重命名节点：复制后删除原节点 -->
<xsl:template match="old-name">
    <new-name>
        <xsl:apply-templates select="@* | node()"/>
    </new-name>
</xsl:template>
```

### 3. 修改属性值

```xml
<!-- 修改属性值 -->
<xsl:template match="node/@attr">
    <xsl:attribute name="attr">
        <xsl:value-of select="."/>
    </xsl:attribute>
</xsl:template>
```

### 4. 条件删除

```xml
<!-- 根据条件删除节点 -->
<xsl:template match="node[condition]/child-to-remove"/>
```

### 5. 移动节点位置

```xml
<!-- 将节点从一个位置移动到另一个位置 -->
<xsl:template match="old-path/node">
    <new-path>
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </new-path>
</xsl:template>
```

### 6. 添加默认值

```xml
<!-- Add default value to leaf if missing -->
<xsl:template match="namespace:container">
    <xsl:copy>
        <xsl:apply-templates select="@* | node()"/>
        <xsl:if test="not(namespace:leaf)">
            <namespace:leaf>default-value</namespace:leaf>
        </xsl:if>
    </xsl:copy>
</xsl:template>
```

### 7. 类型转换

```xml
<!-- Convert value from old type to new type -->
<xsl:template match="namespace:leaf[@type='old']">
    <xsl:element name="{local-name()}">
        <xsl:attribute name="type">new</xsl:attribute>
        <xsl:value-of select="number(.) * conversion-factor"/>
    </xsl:element>
</xsl:template>
```

---

## XSLT 优化建议

### 1. 使用 xsl:include 而非默认规则

```xml
<!-- 推荐 -->
<xsl:include href="your_xsl.xsl"/>

<!-- 避免 -->
<xsl:template match="/">
```

### 2. 在 match 表达式中描述条件

```xml
<!-- 推荐：在 match 中描述条件 -->
<xsl:template match="onu:onus/onu:onu/ifNs:interfaces/ifNs:interface[ifNs:type='ianaift-mounted:ethernetCsmacd']/ptp:ptp-port"/>

<!-- 避免：使用 xsl:when -->
<xsl:template match="ptp:ptp-port">
    <xsl:when test="ancestor::interface/type='ethernetCsmacd'">
        ...
    </xsl:when>
</xsl:template>
```

### 3. 避免使用 //

```xml
<!-- 推荐：匹配精确路径 -->
<xsl:template match="onu:onus/onu:onu/ifNs:interfaces"/>

<!-- 避免：使用通配符 -->
<xsl:template match="onu:onus//ifNs:interfaces"/>
```

### 4. 避免通配符匹配

```xml
<!-- 推荐：明确指定 -->
<xsl:template match="fwding:forwarding/fwding:forwarders/fwding:forwarder/fwding:port-groups"/>

<!-- 避免：使用 * -->
<xsl:template match="*/*[local-name()='forwarding']/*[local-name()='forwarders']"/>
```

### 5. 使用 OR 表达式匹配同 XPath 树中的节点

```xml
<!-- 推荐：使用 | 匹配多个节点 -->
<xsl:template match="tcont:additional-bw-eligibility-indicator |
                     tcont:weight |
                     tcont:priority"/>

<!-- 避免：复杂的 local-name 检查 -->
<xsl:template match="*[local-name()='additional-bw-eligibility-indicator' or local-name()='weight' or local-name()='priority']"/>
```

### 6. 使用 xsl:apply-templates 而非 xsl:for-each

```xml
<!-- 推荐：递归处理 -->
<xsl:template match="container">
    <xsl:apply-templates select="child"/>
</xsl:template>

<!-- 避免：显式迭代 -->
<xsl:for-each select="child">
    ...
</xsl:for-each>
```

### 7. 移除未使用的命名空间

```xml
<!-- 移除 XSL 中任何 match 条件都未使用的命名空间 -->
<xsl:stylesheet ...>
    <xsl:namespace-alias stylesheet-prefix="xsl" result-prefix="xslt"/>
    <!-- 只声明需要的命名空间 -->
</xsl:stylesheet>
```

---

## 迁移脚本执行顺序

XSLT 脚本**不按顺序执行**，因此模板规则不应相互依赖。

如果存在依赖关系：
1. 首先尝试解耦规则
2. 如果无法解耦，联系 XSLT 专家协助优化

---

## Framework 文件

框架提供的基础模板：

| 文件 | 用途 |
|------|------|
| `framework/identity-utils.xsl` | Identity and type utilities |
| `framework/node-operations.xsl` | Node manipulation templates |
| `framework/type-converters.xsl` | Type conversion functions |

---

## 相关文档

- [Overview](dmsupgrader_app/overview.md) - System architecture overview
- [Workflow](dmsupgrader_app/workflow.md) - Detailed workflow guide
- [Tools](dmsupgrader_app/tools.md) - Available tools reference
