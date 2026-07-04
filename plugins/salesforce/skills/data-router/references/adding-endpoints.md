# Adding a New Endpoint — Full Walkthroughs

Detailed steps and code for the three cases summarized in SKILL.md → "How to Add a New Endpoint".

## Case A: Generic Apex REST call (simplest)

Use the existing `apex()` on DataRouter. No new files needed:

```ts
// In a hook — note the /AcctSeed namespace segment (see gotchas below):
const result = await getDataRouter().apex<MyType>('GET', '/AcctSeed/ui/config/KPI_Cards');
const saved  = await getDataRouter().apex<MyType>('POST', '/AcctSeed/ui/config/KPI_Cards', body);
```

The generic BFF proxy at `ALL /api/apex/*` handles it. The Apex REST resource at
`/services/apexrest/AcctSeed/ui/config/*` (`UIConfigResource`) receives the call.

### Apex REST gotchas (learned the hard way — both cost a 502 debugging session)

1. **Namespace prefix is mandatory in a managed org.** AccountingCloud is a managed package
   (namespace `AcctSeed`), so its `@RestResource` endpoints live at
   `/services/apexrest/AcctSeed/<urlMapping>`, *not* `/services/apexrest/<urlMapping>`. Omit
   `/AcctSeed` and Salesforce returns `Could not find a match for URL` (which Cloudflare then
   masks as its own 502 HTML page — check the BFF response directly, not the tunnel). The
   `line-manager` route already hardcodes `/AcctSeed/...`; follow that. Keep these paths in
   `APEX_REST` in `src/lib/routes.ts`.

2. **A resource that parses path segments must tolerate the namespace.** In a managed org
   `RestContext.request.requestURI` includes the namespace (`/AcctSeed/ui/config/KPI_Cards`),
   which shifts every segment by one. Locate a known segment by name (e.g. find `'config'`,
   take the next), never a fixed index — otherwise the type comes back wrong in managed orgs.

3. **Apex REST cannot return `Object`** (`HttpGet methods do not support return type of Object`).
   When a handler is generic (returns `Object` for any configType), you can't return a concrete
   type. Returning `String` via `JSON.serialize(...)` compiles, but double-encodes the body into
   a JSON *string* — forcing the caller to parse twice. The clean fix: make the method `void` and
   write the bytes yourself, so Salesforce emits exactly what you wrote (a plain JSON array):
   ```apex
   @HttpGet global static void getConfig() {
       Object result = UIConfigHandlerFactory.getHandler(configType).getConfig();
       RestContext.response.addHeader('Content-Type', 'application/json');
       RestContext.response.responseBody = Blob.valueOf(JSON.serialize(result));
   }
   ```
   This matches the Canvas path (`@AuraEnabled UIConfigController` returns a plain `Object`), so
   both transports yield an array and the BFF needs no normalization.

## Case B: Dedicated BFF route (for feature-specific validation or response shaping)

**Step 1** — `server/routes/{feature}.ts`:
```ts
import { Hono } from 'hono';
import { requireAuth, type SessionData } from '../middleware/session';
import { SalesforceApi } from '../lib/transports/salesforceApi';

type Env = { Variables: { session: SessionData } };
const myFeature = new Hono<Env>();

myFeature.use('*', requireAuth);
myFeature.onError((err, c) => c.json({ error: err.message }, 502));

myFeature.get('/:configType', async (c) => {
  const sf = new SalesforceApi(c.get('session'));
  const result = await sf.apex('GET', `/ui/config/${c.req.param('configType')}`);
  return c.json(result);
});

export { myFeature };
```

**Step 2** — `server/config/routes.ts`: add `API_MY_FEATURE: '/api/my-feature'`

**Step 3** — `server/index.ts`: `app.route(BFF_ROUTES.API_MY_FEATURE, myFeature)`

**Step 4** — `src/lib/routes.ts`: add path constants to `API`

**Step 5** — `src/requests/salesforce/{feature}.ts`: add typed request function

**Step 6** — `src/lib/salesforce/router/types.ts`: add method to `DataRouter` interface

**Step 7** — `src/lib/salesforce/router/bffRouter.ts`: implement calling the request function

**Step 8** — `src/lib/salesforce/router/canvasBridgeRouter.ts`: implement (bridge or BFF fallback)

**Step 9** — Write the React hook using `getDataRouter().yourMethod()` + TanStack Query

## Case C: New Canvas bridge operation (when LWC side is wired)

**Step 1** — `src/lib/salesforce/router/serviceProtocol.ts`: add to `ServiceOperation` union

**Step 2** — `src/lib/salesforce/router/canvasBridgeRouter.ts`:
```ts
yourOp(args: Args): Promise<Result> {
  return this.bridge.request<Result>('yourOp', { ...args });
}
```

**Step 3** — `src/lib/salesforce/router/bffRouter.ts`: implement BFF fallback (keep for non-Canvas mode)

**Step 4** — `src/lib/salesforce/router/types.ts`: add to `DataRouter`

**Step 5** — Wire the SF-side LWC router to handle the new operation name

## React Hook Pattern

All data hooks follow this shape:

```ts
// READ — TanStack Query
export function useMyData(id: string | null) {
  return useQuery({
    queryKey: ['my-data', id],
    queryFn: () => getDataRouter().myMethod(id!),
    enabled: !!id,
    staleTime: 30_000,
  });
}

// WRITE — TanStack Mutation + cache invalidation
export function useSaveMyData() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: MyData) => getDataRouter().myMutation(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['my-data'] });
    },
  });
}
```

Import from `src/requests/*` directly in components or hooks is an antipattern — it bypasses the
router entirely and breaks Canvas mode (bridge never fires). Always go through `getDataRouter()`.
