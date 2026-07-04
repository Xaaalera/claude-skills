# as_mcp — Tool Catalog, Parameters & Worked Examples

Companion reference for the `salesforce:as_mcp` skill. Full per-tool catalog, parameter
details, and workflow walkthroughs live here.

## Loading the deferred tools

The `mcp__claude_ai_Accounting_Seed_Salesforce__*` tools are not loaded by default. Load
what you need in ONE `ToolSearch` call before the first use:

```
ToolSearch  query: "select:mcp__claude_ai_Accounting_Seed_Salesforce__search_codebase,mcp__claude_ai_Accounting_Seed_Salesforce__get_class_summary,mcp__claude_ai_Accounting_Seed_Salesforce__get_dependencies,mcp__claude_ai_Accounting_Seed_Salesforce__describe_salesforce_object,mcp__claude_ai_Accounting_Seed_Salesforce__get_field_usage"
```

## Token hygiene on search — parameter details

`search_codebase` and `get_class_summary` default `include_source:false` (metadata only).
Keep it that way for discovery; set `include_source:true` only for the one chunk you
actually need to read. Use `chunk_types` (`method`, `class_summary`, `trigger`,
`custom_label`, `lwc_function`, …) and `top_k` to narrow results.

## `query_salesforce` here vs `dx_mcp` — parameter detail

For SOQL against **our** target org and anything you'll act on (deploy/test), use
`dx_mcp`'s `run_soql_query` with `useToolingApi:true` for metadata/`*__mdt` queries.

## Branch & namespace parameters

Code tools take an optional `branch` (defaults to the configured branch) and `repo`;
`get_class_summary` defaults `namespace:"AcctSeed"`. Pass them when you're not on the
default. Field/object API names are namespaced (`AcctSeed__...`) — use API names, never labels.

## Tool quick reference

**Codebase intelligence**
| Tool | Use for |
|---|---|
| `search_codebase` | Find code by name/method/behavior. Filters: `chunk_types`, `repo`, `branch`, `top_k`, `include_source`, `include_kb`. Also Custom Labels via `chunk_types:["custom_label"]`. |
| `get_class_summary` | One class/LWC/Aura: method signatures, annotations, SObject refs, deps. `include_source` for bodies; `namespace` (default `AcctSeed`). |
| `get_dependencies` | Call graph for a `chunk_id`. `direction:"calls"` (outgoing) or `"called_by"` (incoming callers). Works for labels too. |
| `get_field_usage` | Everywhere a field is referenced. |
| `get_sobject_references` | Everywhere an SObject is referenced. |
| `find_test_classes` | The test class(es) covering a given class. |
| `find_extension_overrides` | AS extension/override hook points. |
| `get_lambda_boundary` | Handler/lambda boundaries for a flow. |

**Schema & data**
| Tool | Use for |
|---|---|
| `describe_salesforce_object` | Full object schema — field API names, types, picklist values, parent lookups (`referenceTo`), child relationships. Use API names. |
| `query_salesforce` | SOQL for discovery. Prefer **aggregate** queries for summaries/counts; always `LIMIT` detailed queries. |
| `get_salesforce_record` | Fetch one record by Id. |

**Knowledge & domain ops**
| Tool | Use for |
|---|---|
| `search_knowledge_base` | AS Knowledge Base articles. |
| `post_accounting_seed_billing` / `unpost_accounting_seed_billing` | Post / unpost a billing (domain action). |
| `submit_for_approval` / `process_approval_request` / `find_approval_requests` | Approval workflow. |
| `analyze_feedback` / `send_meeting_summary_dm` | Internal utilities. |

## Worked example — the research this skill replaces

Building the KPI metric engine needed package internals we *reverse-engineered by hand*.
Next time, ask the MCP instead:

- "How does AcctSeed compute the current accounting period?" →
  `search_codebase("current accounting period")` → `get_class_summary("AccountingPeriodHandler")`
  for the real method names, instead of grepping for the singleton.
- "Why does inserting a Financial Cube row get blocked, and what's the override?" →
  `get_class_summary("FinancialCubeActions")` surfaces `isPreventOverride` /
  `FINANCIAL_CUBE_PERIOD` — no guessing.
- "What drives `MTD_Actual_P_L__c` / `Year_To_Date__c`, and which cube fields are writable?" →
  `describe_salesforce_object("AcctSeed__Financial_Cube__c")` returns each field's type and
  whether it's a formula (read-only) vs writable — the exact thing that took a describe loop.

One MCP call beats a grep-and-guess loop and is far less likely to be wrong.
