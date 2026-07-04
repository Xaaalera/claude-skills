# BFF Server Details

## Route Registration — `server/index.ts`

```ts
app.route('/auth', auth);
app.route('/api', proxy);           // UI API, Composite, Query, Apex REST proxy
app.route('/api/agent', agent);
app.route('/api/line-manager', lineManager);
```

## BFF Route Constants — `server/config/routes.ts`

```ts
export const BFF_ROUTES = {
  AUTH: '/auth',
  API: '/api',
  API_AGENT: '/api/agent',
  API_LINE_MANAGER: '/api/line-manager',
  HEALTH: '/health',
} as const;
```

## Generic Proxy — `server/routes/proxy.ts`

| BFF path | SF path | Handler |
|---|---|---|
| `GET /api/ui-api/*` | `GET /services/data/v62.0/ui-api/*` | `sf.uiApiRequest()` |
| `POST/PATCH/DELETE /api/ui-api/*` | same | `sf.uiApiMutate()` |
| `POST /api/composite` | `/services/data/v62.0/composite` | `sf.composite()` |
| `POST /api/composite/graph` | `/services/data/v62.0/composite/graph` | `sf.compositeGraph()` |
| `GET /api/query?q=` | `/services/data/v62.0/query` | `sf.query()` (or `sf.queryMore()` when `nextRecordsUrl` param present) |
| `ALL /api/apex/*` | `/services/apexrest/*` | `sf.apex()` |

## SalesforceApi — `server/lib/transports/salesforceApi.ts`

Stateless per-request transport class (`Requester` subclass — the shared base for every BFF
outbound API; see `docs/backend/api-transports.md` in the repo). Initialized with
`SessionData` (accessToken + instanceUrl):

```ts
const sf = new SalesforceApi(c.get('session'));
await sf.apex('GET', '/AcctSeed/ui/config/KPI_Cards');
// → fetch(`${instanceUrl}/services/apexrest/AcctSeed/ui/config/KPI_Cards`, {
//     headers: { Authorization: `Bearer ${accessToken}` }
//   })
```

**Namespace:** AccountingCloud is a managed package, so Apex REST resources live under
`/services/apexrest/AcctSeed/...`. The `path` you pass to `apex()` must start with `/AcctSeed`
(see `line-manager` and `APEX_REST` in `src/lib/routes.ts`). Without it Salesforce returns
`Could not find a match for URL`. Also: Apex REST forbids an `Object` return type, so a resource
with a generic handler should be `void` and write `RestContext.response.responseBody` directly
(returning `String` via `JSON.serialize` double-encodes the body). Full write-up in
`adding-endpoints.md` → "Apex REST gotchas".

Methods:
- `uiApiRequest(path)` — GET to UI API
- `uiApiMutate(method, path, body?)` — POST/PATCH/DELETE to UI API
- `composite(body)` — Composite API
- `compositeGraph(body)` — Composite Graph API
- `query(soql)` — SOQL
- `queryMore(nextRecordsUrl)` — paginated SOQL
- `apex(method, path, body?)` — Apex REST (`/services/apexrest{path}`)
- `describeObject(objectApiName)` — sobject describe
- `deleteRecord(objectApiName, id)` — sobject delete

## Auth Middleware — `server/middleware/session.ts`

`requireAuth` reads the `as_session` cookie, looks up the session in Redis/in-memory store,
attaches `SessionData` to Hono context. All `/api/*` routes are behind this.

```ts
interface SessionData {
  accessToken: string;
  refreshToken?: string;
  instanceUrl: string;
  userId: string;
  orgId: string;
  issuedAt: number;
  canvasClient?: CanvasClientData;
  user?: CanvasUser;
  profile?: UserProfile;
}
```

## Session Setup by Mode

### Canvas mode
1. Salesforce POSTs signed_request (form body) to the Canvas App URL (the BFF root `/`)
2. BFF validates HMAC with `CANVAS_CONSUMER_SECRET`, extracts `oauthToken` + user context
3. BFF creates session → stores in Redis/in-memory → sets `as_session` cookie (httpOnly, SameSite=None)
4. SPA loads at `/?canvas=true` — `isCanvasEnvironment()` returns true
5. `checkSession()` returns `{ canvasClient }` — router becomes `CanvasBridgeRouter`

### Standalone mode (OAuth)
1. User hits `/auth/login` → redirect to SF OAuth authorize
2. SF calls back `/auth/callback` with `code`
3. BFF exchanges code for access_token/refresh_token
4. Session created, cookie set
5. Redirect to SPA — `checkSession()` returns `{ authenticated: true }` — router becomes `BFFRouter`

## API Path Constants — `src/lib/routes.ts`

```ts
export const API = {
  RECORDS: '/api/ui-api/records',
  RECORD: (id: string) => `/api/ui-api/records/${id}`,
  RECORD_UI: (id: string) => `/api/ui-api/record-ui/${id}`,
  PICKLIST_VALUES: (objectApiName: string, recordTypeId: string) =>
    `/api/ui-api/object-info/${objectApiName}/picklist-values/${recordTypeId}`,
  LIST_UI: (objectApiName: string) => `/api/ui-api/list-ui/${objectApiName}`,
  LIST_UI_VIEW: (objectApiName: string, listViewApiName: string) =>
    `/api/ui-api/list-ui/${objectApiName}/${listViewApiName}`,
  QUERY: '/api/query',
  COMPOSITE: '/api/composite',
  COMPOSITE_GRAPH: '/api/composite/graph',
  APEX: (path: string) => `/api/apex${path}`,
  LINE_MANAGER_DESCRIBE: '/api/line-manager/describe',
  LINE_MANAGER_SAVE: '/api/line-manager/save',
  AGENT: '/api/agent',
} as const;
```
