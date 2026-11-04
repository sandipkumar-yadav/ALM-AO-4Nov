# Codebase Performance Analysis Baseline

**Work Item:** WI-000006  
**Project:** ALM-AO-4Nov  
**Date:** 2026-11-04  
**Analyst:** Salesforce Builder Agent  
**Branch:** WI-000006  

---

## 1. Executive Summary

This document establishes the **performance analysis baseline** for the `ALM-AO-4Nov` Salesforce DX project. At the time of this scan, the codebase is in a **scaffold-only state**; the feature branches contain minimal source files, and no runtime performance bottlenecks have been identified.

**Key findings:**

| Area | Status | Action Required |
|---|---|---|
| Apex Classes | 1 class on `main` (`ASimpleCtrlObjectApexForActionTest`) | P1 – missing `with sharing`, no CRUD/FLS checks (see WI-000002) |
| LWC / Aura | No components present | None at this time |
| Flows | 1 flow present (`Get_Account_by_Name`) | Review for loop-based queries |
| Static Analysis | Scanner not yet integrated | P1 – integrate into CI pipeline |
| SOQL | 1 unoptimised query identified | P1 – add filter on indexed field, add `LIMIT` |
| Platform Cache | Not enabled | P2 – enable when repeated reads warrant it |

**Conclusion:** No critical runtime performance blockers exist for a scaffold-stage project. This document acts as the performance checklist and governance baseline to be re-evaluated as code is developed.

---

## 2. Scanned Files

The following files were present in the repository at the time of analysis (WI-000006 branch):

```
./README.md
./force-app/main/default/flows/Get_Account_by_Name.flow-meta.xml
```

Files present on `main` branch (also subject to this baseline):

```
.forceignore
.project-meta.json
config/project-scratch-def.json
force-app/main/default/classes/ASimpleCtrlObjectApexForActionTest.cls
force-app/main/default/classes/ASimpleCtrlObjectApexForActionTest.cls-meta.xml
sfdx-project.json
```

---

## 3. Configuration Analysis

### 3.1 `sfdx-project.json`

```json
{
  "packageDirectories": [{ "path": "force-app", "default": true }],
  "namespace": "",
  "sfdcLoginUrl": "https://login.salesforce.com",
  "sourceApiVersion": "68.0"
}
```

| Setting | Value | Performance Impact |
|---|---|---|
| `sourceApiVersion` | `68.0` (current) | No impact; up-to-date API version |
| Package dependencies | None declared | No third-party namespace overhead |
| Namespace | Empty (no namespace) | No namespace-scoped query overhead |

### 3.2 `config/project-scratch-def.json`

```json
{
  "orgName": "Demo company",
  "edition": "Developer",
  "features": []
}
```

| Setting | Value | Performance Impact |
|---|---|---|
| `features` | `[]` (empty) | Platform Cache not enabled; add `"PlatformCache"` when needed |
| `edition` | `Developer` | Governor limits are the same across editions |

---

## 4. Static Analysis Results

### 4.1 Salesforce Code Analyzer (sf scanner)

Salesforce Code Analyzer (`@salesforce/sfdx-scanner`) was **not installed** in this environment at the time of this analysis.

**Install command:**
```bash
sf plugins install @salesforce/sfdx-scanner
```

**Recommended scan command (run after installation):**
```bash
sf scanner run --target "force-app/" --format json --outfile reports/scan-results.json
```

Expected baseline result: **zero findings** (scaffold-only codebase).

> **Action required (P1):** Install the scanner and integrate it into the CI/CD pipeline as a required quality gate before merge. See Section 6.

### 4.2 Manual Code Review — Apex

**File:** `force-app/main/default/classes/ASimpleCtrlObjectApexForActionTest.cls`

```apex
public without sharing class ASimpleCtrlObjectApexForActionTest {
    @InvocableMethod
    public static List<Account> getPropertyBasedOnCity(List<Integer> Amount) {
        return [SELECT Id, Name FROM Account LIMIT 1];
    }
}
```

| Issue | Severity | Category | Recommendation |
|---|---|---|---|
| `without sharing` | HIGH | Security / Sharing | Change to `with sharing` or `inherited sharing`. Addressed by WI-000002. |
| No CRUD/FLS check | HIGH | Security | Add `Account.SObjectType.getDescribe().isAccessible()` before query. Addressed by WI-000002. |
| `LIMIT 1` without filter | MEDIUM | Performance | SOQL without a `WHERE` clause on an indexed field causes a full-table scan. Add a selective filter. |
| No bulk-safe input handling | MEDIUM | Performance | `@InvocableMethod` receives a `List<Integer>` but executes a single SOQL. Verify this is intentional for bulk invocations. |

### 4.3 Manual Review — Flows

**File:** `force-app/main/default/flows/Get_Account_by_Name.flow-meta.xml`

Checklist for the `Get_Account_by_Name` flow:

- [ ] No SOQL Get Records elements inside loop elements
- [ ] No DML elements inside loop elements
- [ ] Flow uses fault paths on each callout/DML
- [ ] Bulk-safe: flow entry type and `processType` set appropriately

> **Action required (P2):** Review the flow in Developer Console Flow Builder to confirm no loop-based SOQL or DML.

---

## 5. Prioritised Performance Recommendations

### P1 — Critical (address before first deployment)

| # | Recommendation | Rationale |
|---|---|---|
| 1 | Enforce `with sharing` on all Apex classes | Prevents unintended cross-user data leakage and avoids full-table SOQL scans |
| 2 | Add CRUD/FLS checks before every SOQL/DML | Required for security review; also prevents unnecessary DB round-trips when the user lacks access |
| 3 | Bulkify SOQL — no queries inside loops | Each SOQL in a loop consumes one of the 100 SOQL governor limit slots per transaction |
| 4 | Use selective SOQL on indexed fields | Queries without a `WHERE` on an indexed field (`Id`, `Name`, `OwnerId`, custom external ID) trigger full table scans |
| 5 | Integrate `sf scanner` into CI pipeline | Automated static analysis catches performance and security issues on every push |

### P2 — Important (address within first sprint after scaffold)

| # | Recommendation | Rationale |
|---|---|---|
| 6 | Enable Platform Cache for read-only reference data | Eliminates repeated SOQL queries for configuration data that rarely changes |
| 7 | Use `@wire` service adapters in LWC when components are added | `@wire` caches data client-side and prevents redundant server calls |
| 8 | Lazy-load heavy LWC components with dynamic `import()` | Reduces initial page load time |
| 9 | Review and optimise Flows for loop-based DML/SOQL | `getRecords` inside a loop still causes N×SOQL performance degradation |
| 10 | Add `OFFSET`-free pagination using cursor-based patterns (`lastId > :prevId`) | `OFFSET` causes the DB to skip rows, which is O(offset) expensive |

### P3 — Good practice (address during ongoing development)

| # | Recommendation | Rationale |
|---|---|---|
| 11 | Minimise LWC re-renders — use `@track` sparingly | Excessive change detection degrades UI responsiveness |
| 12 | Use `SOSL` for cross-object text search instead of multiple `SOQL LIKE` queries | A single `FIND` statement is more efficient than N SOQL queries with `LIKE` |
| 13 | Profile `@future` and Queueable Apex — avoid chaining more than 50 jobs | Each queued job adds latency; batch Apex is preferred for large data volumes |
| 14 | Avoid `SELECT *` patterns — only retrieve fields you need | Reduces heap consumption toward the 10 MB heap limit |
| 15 | Cache `Schema.getGlobalDescribe()` in a static variable | `getGlobalDescribe()` is expensive; calling it repeatedly in a transaction wastes CPU ms |

---

## 6. Recommended Tooling

| Tool | Purpose | How to Use |
|---|---|---|
| Salesforce Code Analyzer (`sf scanner`) | PMD-based static analysis for Apex, LWC, and metadata | `sf plugins install @salesforce/sfdx-scanner` then `sf scanner run --target force-app/` |
| Query Plan Tool (Developer Console) | Explains SOQL execution plans; identifies missing indexes | Developer Console > Query Editor > check "Query Plan" checkbox |
| Apex Debug Logs with `APEX_PROFILING,INFO` | Captures CPU time, heap usage, and SOQL counts | Setup > Debug Logs > add trace flag with `APEX_CODE=DEBUG; APEX_PROFILING=INFO` |
| Checkmarx / Gearset Scanner | Enterprise CI/CD code analysis integrations | Configure in pipeline YAML as a pre-merge gate |
| SOQL EXPLAIN via REST API | Programmatic query plan retrieval | `GET /services/data/v68.0/query/?explain=SELECT...` |

---

## 7. Governor Limit Reference

Salesforce governor limits most relevant to performance:

| Governor | Synchronous Limit | Asynchronous Limit |
|---|---|---|
| SOQL queries | 100 | 200 |
| SOQL query rows | 50,000 | 50,000 |
| DML statements | 150 | 150 |
| DML rows | 10,000 | 10,000 |
| CPU time | 10,000 ms | 60,000 ms |
| Heap size | 6 MB | 12 MB |
| Callouts | 100 | 100 |
| `@future` calls | 50 | — |
| Queueable jobs | 50 | — |

> Source: [Salesforce Governor Limits](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_gov_limits.htm)

---

## 8. Next Steps

1. **Re-run this analysis** after each feature branch is merged to `main`. Update Sections 2–4 with findings from the new code.
2. **Install `sf scanner`** and run a baseline scan, capturing the JSON output to `reports/scan-results.json`.
3. **Integrate `sf scanner` into the GitHub Actions or DevOps pipeline** as a required pre-merge check:
   ```yaml
   - name: Run Salesforce Code Analyzer
     run: |
       sf plugins install @salesforce/sfdx-scanner
       sf scanner run --target "force-app/" --format sarif --outfile reports/scan-results.sarif
   ```
4. **Review the `Get_Account_by_Name` Flow** in the Developer Console to confirm it is loop-safe.
5. **Address P1 items** (sharing enforcement, CRUD/FLS) as part of WI-000002.
6. **Set a performance review milestone** for when LWC components are first added to the project.

---

*This document was generated as part of work item WI-000006 and is intended as a living baseline. Update it whenever significant code changes are introduced.*
