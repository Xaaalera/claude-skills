# Client Router Internals

Code-level detail for the client-side routing layer (`src/lib/salesforce/router/`).

## Router Singleton — `src/lib/salesforce/router/index.ts`

```ts
let _router: DataRouter = new BFFRouter();

export function createDataRouter(canvasClient?: CanvasClient | null): DataRouter {
  return isCanvasEnvironment() && canvasClient
    ? new CanvasBridgeRouter(canvasClient)
    : new BFFRouter();
}

export function setDataRouter(router: DataRouter): void { _router = router; }
export function getDataRouter(): DataRouter { return _router; }
```

Set once in `useAuth` after `checkSession()`. Every hook reads it via `getDataRouter()`.

**Canvas detection** — `src/lib/canvas/sdk.ts`:
```ts
export function isCanvasEnvironment(): boolean {
  if (new URLSearchParams(window.location.search).get('canvas') === 'true') return true;
  try { return window.self !== window.top; } catch { return true; }
}
```

## DataRouter Interface — `src/lib/salesforce/router/types.ts`

The contract both routers satisfy:

```ts
export interface DataRouter {
  getRecord(id: string, fields: string[]): Promise<RecordRepresentation>;
  getRecordUi(id: string): Promise<RecordUiRepresentation>;
  createRecord(apiName: string, fields: Record<string, unknown>): Promise<RecordRepresentation>;
  updateRecord(id: string, fields: Record<string, unknown>): Promise<void>;
  deleteRecord(id: string): Promise<void>;

  query<T>(soql: string): Promise<QueryResult<T>>;
  queryMore<T>(nextRecordsUrl: string): Promise<QueryResult<T>>;

  composite(requests: CompositeSubrequest[]): Promise<CompositeResponse>;
  compositeGraph(graphs: CompositeGraphInput[]): Promise<CompositeGraphResponse>;

  getPicklistValuesByRecordType(objectApiName: string, recordTypeId: string): Promise<PicklistValuesCollection>;

  apex<T>(method: string, path: string, body?: unknown): Promise<T>;

  fetchListViews(objectApiName: string, pageSize?: number): Promise<ListViewsCollectionResponse>;
  fetchListUi(objectApiName: string, listViewApiName: string, pageSize?: number, pageToken?: string): Promise<ListUiRepresentation>;
}
```

## BFFRouter Delegation — `src/lib/salesforce/router/bffRouter.ts`

Every method delegates to a function from `src/requests/salesforce/*`:

```
BFFRouter.getRecord()  →  getRecord()  →  requester('/api/ui-api/records/{id}?fields=...')
BFFRouter.query()      →  query()      →  requester('/api/query?q=...')
BFFRouter.apex()       →  apex()       →  requester('/api/apex{path}', { method, body })
```

### requester — `src/requests/requester.ts`

All HTTP calls go through this function:
- Attaches `credentials: 'include'` (session cookie)
- On 401 → redirects to `/auth/login`
- Logs every request + response to `useBridgeLogStore` with a UUID correlation ID (visible in Dev Tools page)

API path constants live in `src/lib/routes.ts` (the `API` object) — full listing in
`bff-server.md` → "API Path Constants".

## CanvasBridgeRouter — Which Ops Go Where

`src/lib/salesforce/router/canvasBridgeRouter.ts` holds two transports internally:
- `this.bridge` — `ServiceBridge` (postMessage to Aura host)
- `this.bff` — `BFFRouter` (BFF fallback for ops the bridge can't serve yet)

| Operation | Transport | Reason |
|---|---|---|
| `getRecord` | Bridge → LDS | No API-limit cost |
| `createRecord` | Bridge → LDS | No API-limit cost |
| `updateRecord` | Bridge → LDS | No API-limit cost |
| `deleteRecord` | Bridge → LDS | No API-limit cost |
| `query` | Bridge → @AuraEnabled | No API-limit cost |
| `getUiConfig` | Bridge → generic `apex` op | `invokeApex` → `UIConfigController.getConfig` (Callable) — no API-limit cost |
| `setUiConfig` | Bridge → generic `apex` op | `invokeApex` → `UIConfigController.saveConfig` (Callable) — no API-limit cost |
| `computeKpiMetric` | Bridge → generic `apex` op | `invokeApex` → `UIConfigController.computeMetric` (Callable) → `KPIMetricCompiler`; standalone GETs `UIMetricResource` `/ui/metric/{key}` — no API-limit cost |
| `getRecordUi` | BFF fallback | Bridge not wired yet |
| `getPicklistValuesByRecordType` | BFF fallback | LWC wired; bridge activation pending on client |
| `queryMore` | BFF fallback | Pagination via API |
| `composite` | BFF fallback | No bridge equivalent |
| `compositeGraph` | BFF fallback | No bridge equivalent |
| `apex` | Bridge → `invokeApex` | Generic dynamic dispatch: `Type.forName` + `Callable`, class allow-list. UI config rides this; the dedicated `getUiConfig` bridge op is removed |
| `fetchListViews` | BFF fallback | List metadata |
| `fetchListUi` | BFF fallback | Paginated list data |

## The `BRIDGE_DATA_OPS` Toggle — Bridge Ops Are Gated, Not Always-On

The "Bridge → LDS / @AuraEnabled" rows above (`getRecord`, CRUD, `query`) only actually
hit the bridge when the `BRIDGE_DATA_OPS` flag is on. The flag reads the
`VITE_BRIDGE_DATA_OPS` env var (`import.meta.env.VITE_BRIDGE_DATA_OPS === 'true'`) and
**defaults to false** when unset — the safe state, since the SF-side bridge handler
("Phase 2", see "What's NOT Yet Wired" in `sf-canvas-stack.md`) isn't live in every org
yet. While false, those ops fall back to the BFF (which uses the Canvas session token, so
it still hits the org — just consuming REST API limits the bridge wouldn't).
`getUiConfig` / `setUiConfig` are the exception: they always bridge (via the generic
`apex` op), independent of this flag.

- `.env.example` ships `false` (the template others copy) — flip to `true` per-developer
  in your own `.env` only once Phase 2 is verified in your org.
- Documented in `.env.example` and `docs/setup/SETUP.md`.

**Pattern for adding a bridge-served op** (once LWC side is wired):
```ts
// In CanvasBridgeRouter:
someOp(args): Promise<Result> {
  return this.bridge.request<Result>('operationName', { ...args });
}

// In BFFRouter: stays as BFF call (or add bridge later)
```

**Pattern for BFF fallback** (start here, move to bridge later):
```ts
someOp(args) {
  return this.bff.someOp(args);
}
```

## Key File Map

| What | File | Repo |
|---|---|---|
| DataRouter interface | `src/lib/salesforce/router/types.ts` | Accounting-Seed-UI |
| Router singleton (get/set/create) | `src/lib/salesforce/router/index.ts` | Accounting-Seed-UI |
| Standalone router | `src/lib/salesforce/router/bffRouter.ts` | Accounting-Seed-UI |
| Canvas router | `src/lib/salesforce/router/canvasBridgeRouter.ts` | Accounting-Seed-UI |
| postMessage bridge (client) | `src/lib/salesforce/router/serviceBridge.ts` | Accounting-Seed-UI |
| Bridge message protocol | `src/lib/salesforce/router/serviceProtocol.ts` | Accounting-Seed-UI |
| HTTP requester (fetch wrapper) | `src/requests/requester.ts` | Accounting-Seed-UI |
| SF request functions | `src/requests/salesforce/` | Accounting-Seed-UI |
| Client API path constants | `src/lib/routes.ts` | Accounting-Seed-UI |
| Canvas env detection | `src/lib/canvas/sdk.ts` | Accounting-Seed-UI |
| Auth init + router setup | `src/hooks/useAuth.ts` | Accounting-Seed-UI |
| BFF app entrypoint | `server/index.ts` | Accounting-Seed-UI |
| BFF route constants | `server/config/routes.ts` | Accounting-Seed-UI |
| BFF generic SF proxy | `server/routes/proxy.ts` | Accounting-Seed-UI |
| BFF SF transport (all API methods) | `server/lib/transports/salesforceApi.ts` | Accounting-Seed-UI |
| BFF session middleware | `server/middleware/session.ts` | Accounting-Seed-UI |
| Example feature BFF route | `server/routes/line-manager.ts` | Accounting-Seed-UI |
| VF page (Canvas relay) | `force-app/main/default/pages/AccountingSeedLocal.page` | AccountingCloud |
| Aura host component | `force-app/main/default/aura/AccountingSeedLocal/` | AccountingCloud |
| LWC service router (SF-side bridge) | `force-app/main/default/lwc/asServiceRouter/` | AccountingCloud |
| Apex bridge dispatcher | `force-app/main/default/classes/AS_ServiceRouterController.cls` | AccountingCloud |
| Apex @AuraEnabled bridge stub | `force-app/main/default/classes/AS_ServiceRouterBridge.cls` | AccountingCloud |
