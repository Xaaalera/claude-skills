# SF Side: Canvas Bridge Stack

All files are under `force-app/main/default/` in the **AccountingCloud** repo.

---

## Frame Hierarchy

```
┌─────────────────────────────────────────────────────────────────┐
│  Aura frame  (AccountingSeedLocal.cmp renders here)             │
│                                                                 │
│  ┌─────────────────────────┐   ┌────────────────────────────┐  │
│  │  <c:asServiceRouter>    │   │  <iframe src="/apex/...">  │  │
│  │  (LWC, renders nothing) │   │                            │  │
│  │                         │   │  ┌──────────────────────┐  │  │
│  │  window.addEventListener│   │  │  VF page             │  │  │
│  │  ('message', ...)       │   │  │  AccountingSeedLocal  │  │  │
│  │  ← catches messages     │   │  │  .page               │  │  │
│  │    from VF via          │   │  │                      │  │  │
│  │    parent.postMessage   │   │  │  ┌────────────────┐  │  │  │
│  │                         │   │  │  │ <apex:canvasApp>│  │  │  │
│  │  @wire LDS adapters     │   │  │  │ Canvas iframe  │  │  │  │
│  │  @AuraEnabled Apex      │   │  │  │ = React SPA    │  │  │  │
│  │                         │   │  │  └────────────────┘  │  │  │
│  │  dispatches             │   │  └──────────────────────┘  │  │
│  │  CustomEvent            │   └────────────────────────────┘  │
│  └─────────────────────────┘                                    │
└─────────────────────────────────────────────────────────────────┘
```

Three frames total: Aura → VF → Canvas (React). The Aura frame has two sibling children:
- `<c:asServiceRouter>` — the LWC, listens via `window.addEventListener`
- `<iframe src="/apex/AccountingSeedLocal">` — the VF page hosting the Canvas app

---

## Request Path — React to Salesforce (Steps 1–3)

**Step 1 — React publishes via Canvas SDK**

```ts
Sfdc.canvas.client.publish(client, { name: 'AS_Service.request', payload })
```
Canvas SDK translates this into a `postMessage` to the **VF frame** (which hosts the `<apex:canvasApp>`).

**Step 2 — VF page relays to Aura frame**

`AccountingSeedLocal.page` (runs after `onCanvasReady`):
```js
Sfdc.canvas.controller.subscribe({
    name: 'AS_Service.request',
    onData: function(event) {
        window.parent.postMessage(event, '*');
    }
});
```
Receives Canvas SDK message → `window.parent.postMessage` → **Aura frame**.

**Step 3 — LWC in Aura frame catches and processes it**

`asServiceRouter.js` in `connectedCallback()`:
```js
window.addEventListener('message', (event) => {
    const messageData = event.data;
    if (!messageData || messageData.name !== 'AS_Service.request' || !messageData.payload) return;
    this.handleRequest(messageData);
});
```
`handleRequest()` dispatches to LDS wire adapters or @AuraEnabled Apex.

---

## Response Path — Salesforce back to React (Steps 4–7)

**Step 4 — LWC fires CustomEvent**

```js
this.dispatchEvent(new CustomEvent('serviceresponse', { detail: { response } }));
```

**Step 5 — Aura controller catches event, posts to VF iframe**

`AccountingSeedLocalController.js`:
```js
onServiceResponse: function(cmp, evt) {
    var response = evt.getParam('response');
    var iframe = cmp.find('vfFrame').getElement();
    iframe.contentWindow.postMessage(response, '*');
}
```

**Step 6 — VF page republishes via Canvas SDK**

`AccountingSeedLocal.page`:
```js
window.addEventListener('message', function(event) {
    var data = event.data;
    if (data && typeof data.requestId === 'string') {
        Sfdc.canvas.controller.publish({
            name: 'AS_Service.response',
            payload: data,
            target: { canvas: 'accountingSeedCanvasLocal' }
        });
    }
});
```

**Step 7 — React receives response**

`ServiceBridge.ts`:
```ts
Sfdc.canvas.client.subscribe(client, {
    name: 'AS_Service.response',
    onData: (msg) => {
        const entry = this.pending.get(msg.requestId);
        entry.resolve(msg.data);
    }
});
```
Promise resolves → TanStack Query → component re-renders.

---

## LWC Dispatch Table — `asServiceRouter.js`

| Operation | SF mechanism | Notes |
|---|---|---|
| `getRecord` | `@wire getRecord` (LDS) | FIFO queue + input coalescing |
| `getRecords` | `@wire getRecords` (LDS) | FIFO queue |
| `getListInfo` | `@wire getListInfoByName` (LDS) | FIFO queue |
| `getObjectInfo` | `@wire getObjectInfo` (LDS) | FIFO queue |
| `getPicklistValues` | `@wire getPicklistValues` (LDS) | FIFO queue |
| `getPicklistValuesByRecordType` | `@wire getPicklistValuesByRecordType` (LDS) | FIFO queue |
| `createRecord` | imperative LDS `createRecord()` | Immediate |
| `updateRecord` | imperative LDS `updateRecord()` | Immediate |
| `deleteRecord` | imperative LDS `deleteRecord()` | Immediate |
| `query` | `@AuraEnabled AS_ServiceRouterController.executeQuery` | Injects WITH USER_MODE |
| `apex` | `@AuraEnabled AS_ServiceRouterController.invokeApex` | **Implemented** — generic dynamic dispatch (see "Dynamic Apex dispatch" below). UI-config reads/writes ride this; the dedicated `getUiConfig` case is removed |

**Wire-adapter FIFO queue**: LDS read adapters have no imperative form. Each adapter has its own
queue. `_enqueue()` activates a job by writing to reactive wire inputs. `_settle()` (the `@wire`
callback) resolves all requestIds on the active job, then activates the next. Identical inputs
→ coalesced (both receive the same wire result).

---

## Apex Controller — `classes/AS_ServiceRouterController.cls`

All methods `@AuraEnabled`. All DML uses `with sharing` + `as user` / `WITH USER_MODE`.

| Method | What it does |
|---|---|
| `getRecord(recordId, fields)` | Dynamic SOQL + `WITH USER_MODE` |
| `createRecord(apiName, fields)` | `insert as user` |
| `updateRecord(fields)` | `update as user` |
| `deleteRecord(recordId)` | `delete as user` |
| `executeQuery(soql)` | Injects `WITH USER_MODE` at the right SOQL position |
| `describeObject(objectApiName)` | Schema describe — fields, labels, types, updateable flags |
| `getPicklistValues(objectApiName, fieldApiName)` | Active picklist entries |
| `invokeApex(methodName, paramsJson)` | **Implemented** — generic `Type.forName` + `Callable` dispatch, `ALLOWED_CLASSES` allow-list |

## Apex Bridge Class — `classes/AS_ServiceRouterBridge.cls`

Has `@AuraEnabled routeAura(requestJson)` and `@RemoteAction route(requestJson)` — alternative
dispatchers to `AS_ServiceRouterController`. **Neither is active** — RemoteAction call in VF page
is commented out. Kept as fallback/backup only.

---

## Dynamic Apex Dispatch — `invokeApex(methodName, paramsJson)`

The generic `apex` bridge op resolves to `AS_ServiceRouterController.invokeApex`, the house
pattern (`FinancialSuiteService implements Callable`):

- `methodName` is `'ClassName.action'`. `className` must be in `invokeApex`'s `ALLOWED_CLASSES`
  set (currently just `UIConfigController`); the class is resolved at runtime via
  `Type.forName(className)` and invoked through `((Callable) instance).call(action, args)`.
- `paramsJson` deserializes (untyped) to the `Map<String, Object>` passed as `args`.
- The target class implements `Callable` with a `switch on action` (Apex has no method-name
  reflection). `UIConfigController.call` routes `'getConfig'` / `'saveConfig'`.
- **Security:** the dispatcher does NO DML — it only instantiates an allow-listed `Callable`.
  Real DML still runs `as user` / `WITH USER_MODE` inside the handler, so FLS holds.
- To expose a new class over the bridge: implement `Callable` on it and add it to
  `ALLOWED_CLASSES` — no new bridge `case` needed.

---

## What's NOT Yet Wired on the SF Side

| Gap | Location | Status |
|---|---|---|
| `invokeApex` for named dispatch | `AS_ServiceRouterController.invokeApex` | **Implemented** — generic `Type.forName` + `Callable`, `ALLOWED_CLASSES` allow-list |
| `UIConfigController` reads + writes via bridge | `asServiceRouter.js` generic `apex` case | **Wired** — both `getConfig` and `saveConfig` ride `invokeApex`; the dedicated `getUiConfig` case is removed |
| `getRecordUi` / Layout API | `asServiceRouter.js` switch | Missing case — falls to BFF |
| `composite` / `compositeGraph` | No LDS equivalent | Always BFF |

**To add a new bridge operation end-to-end:**
1. Add `@AuraEnabled` method in `AS_ServiceRouterController.cls` (or call existing)
2. Add case in `asServiceRouter.js` `handleRequest()` switch → call the method
3. Deploy Apex + LWC to org: `sf project deploy start -o <alias> -m "LightningComponentBundle:asServiceRouter,ApexClass:AS_ServiceRouterController"`
4. Add to `ServiceOperation` union in `src/lib/salesforce/router/serviceProtocol.ts`
5. Implement in `CanvasBridgeRouter` via `this.bridge.request('newOp', payload)`
6. Add to `DataRouter` interface + `BFFRouter` (fallback for standalone mode)

---

## Full Canvas Request Lifecycle (condensed)

```
React (Canvas iframe, inside VF iframe)
  ServiceBridge.request('getRecord', { recordId, fields })
  → Sfdc.canvas.client.publish({ name: 'AS_Service.request', payload })
  ↓ Canvas SDK → postMessage to VF frame

VF page (AccountingSeedLocal.page)
  Sfdc.canvas.controller.subscribe('AS_Service.request', onData)
  → window.parent.postMessage(event, '*')
  ↓ postMessage to Aura frame (one level up)

asServiceRouter.js (LWC, sibling to the VF iframe, lives in Aura frame)
  window.addEventListener('message') catches it
  → handleRequest({ requestId, operation, payload })
      'getRecord'    → _enqueue → @wire getRecord (LDS) → _settle → _dispatch()
      'createRecord' → imperative createRecord() → _dispatch()
      'query'        → AS_ServiceRouterController.executeQuery() → _dispatch()
  → dispatchEvent(new CustomEvent('serviceresponse', { detail: { response } }))
  ↓ Aura CustomEvent

AccountingSeedLocal.cmp (Aura controller)
  onserviceresponse handler
  → iframe.contentWindow.postMessage(response, '*')
  ↓ postMessage to VF frame

VF page (AccountingSeedLocal.page)
  window.addEventListener('message'): data.requestId exists
  → Sfdc.canvas.controller.publish({ name: 'AS_Service.response', payload, target: canvasId })
  ↓ Canvas SDK → postMessage to Canvas frame (React)

React (Canvas iframe)
  ServiceBridge: Sfdc.canvas.client.subscribe('AS_Service.response')
  → pending.get(requestId).resolve(data)
  → TanStack Query receives result → component re-renders
```
