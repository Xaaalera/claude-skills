# Canvas Bridge Protocol

## Message Types — `src/lib/salesforce/router/serviceProtocol.ts`

```ts
export type ServiceOperation =
  | 'getRecord' | 'getRecords' | 'getListInfo'
  | 'createRecord' | 'updateRecord' | 'deleteRecord'
  | 'getObjectInfo' | 'getPicklistValues' | 'getPicklistValuesByRecordType'
  | 'query'    // @AuraEnabled Apex SOQL
  | 'apex'     // named @AuraEnabled method dispatch (not yet wired)
  | 'getUiConfig'; // UIConfigController.getConfig — per-user UI config reads

export interface ServiceRequest {
  requestId: string;   // UUID — correlates async responses
  version: '1.0';
  operation: ServiceOperation;
  payload: unknown;
  name: string;
}

export interface ServiceResponse<T = unknown> {
  requestId: string;
  success: boolean;
  data?: T;
  error?: { code: string; message: string; statusCode?: number };
}

export const SERVICE_EVENTS = {
  REQUEST: 'AS_Service.request',
  RESPONSE: 'AS_Service.response',
} as const;
```

## ServiceBridge Internals — `src/lib/salesforce/router/serviceBridge.ts`

```
bridge.request('getRecord', payload)
  → assigns UUID requestId
  → stores { resolve, reject, timer } in pending Map
  → Sfdc.canvas.client.publish(client, { name: 'AS_Service.request', payload: message })
  → waits (default 10s timeout) for matching AS_Service.response
  → response received → pending.get(requestId).resolve(data)
```

All bridge traffic (publish + response) is logged to `useBridgeLogStore`.

## Adding a New Operation to ServiceOperation

When wiring a new operation end-to-end:

1. Add the string literal to the `ServiceOperation` union here
2. Wire the LWC `handleRequest()` switch case in `asServiceRouter.js`
3. Add `@AuraEnabled` method in `AS_ServiceRouterController.cls`
4. Implement in `CanvasBridgeRouter.ts` via `this.bridge.request('newOp', payload)`
5. Add to `DataRouter` interface + `BFFRouter` fallback

See the "What's NOT Yet Wired" section in the main SKILL.md for current gaps.
