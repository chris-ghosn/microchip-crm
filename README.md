# UST Secure

Salesforce managed package for enterprise security monitoring, threat detection, and compliance auditing.

## Package Components

- **SecurityEventTrigger** — Processes security events (login anomalies, permission changes, bulk data exports) and routes to threat detection engine
- **SecurityEventHandler** — Handler class for trigger logic (refactor in progress)
- **ThreatDetectionService** — Threat scoring and alert generation engine
- **ComplianceAuditController** — Compliance report generation and scheduled audit scans

## Installation

Deploy via SFDX:
```bash
sf project deploy start --source-dir force-app
```

## Development

This repo uses the standard Salesforce DX project structure. All managed package components live under `force-app/main/default/`.
