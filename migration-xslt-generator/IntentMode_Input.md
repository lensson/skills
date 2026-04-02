# Intent Mode: Input Specification

## Step 1: Collect Migration Intent

Welcome to **Mode 1: Intent-Based Generation**. This mode helps you generate XSLT when you know exactly what changes you want to make.

---

### Example Intents

Here are some common examples to guide you:

| Type | Example Intent |
|------|----------------|
| **Delete node** | Delete the leaf node "vendor-id" under /devices/device/interfaces/interface |
| **Rename node** | Rename leaf "olt-id" to "ont-id" under /services/vlan |
| **Value constraint** | If leaf "max-queue-size" value is greater than 9600, set it to 9600 |
| **Add default** | Add leaf "pbit-mode" with default value "all" if it doesn't exist under /qos/interface-config |
| **Change type** | Change leaf "rate-limit" from uint32 to uint16 under /qos/policy |
| **Merge/Split** | Merge children of /config/bridge into /bridge, removing the redundant /config/bridge container |
| **Conditional update** | For all interface nodes where "admin-status" equals "down", set "operational-mode" to "disabled" |

---

### Your Intent

Please describe your migration intent (version, path, transformation):

```
Intent:
```

---

## Step 2: Provide Sample XML (Optional)

Do you have sample XML files to demonstrate the transformation?

### Option A: Paste XML

**Input XML** (before migration):
```xml
```

**Output XML** (after migration - optional):
```xml
```

### Option B: Skip
If you don't have sample XML, the XSLT will be generated based on your intent description alone.

---

## Next Step

After providing your intent (and optional sample XML), the workflow will proceed to:
- **Generate XSLT** (Step 5 in Generator.md)
- **User Feedback Loop** (Step 6 in Generator.md)
- **Save XSLT to File** (Step 7 in Generator.md)

Reference [Generator.md](Generator.md) for the complete workflow.
