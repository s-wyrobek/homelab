# Cloud-Floci

Open-source (MIT) emulator AWS, zastępuje LocalStack Pro. Działa na **LXC 107
`Cloud-Floci`** (`192.168.1.107:4566`, SSH alias `cloud-floci`), katalog `~/floci`.

| Dostęp | Adres |
|--------|-------|
| Bezpośrednio | `http://192.168.1.107:4566` |
| Przez Nginx | `https://floci.home`, `https://localstack.home` (alias dla starych skryptów) |

Floci mówi API LocalStacka (łącznie z `/_localstack/health`), więc `aws --endpoint-url`
i `AWS_ENDPOINT_URL` działają bez zmian. Dane: zewnętrzny wolumen Docker `floci-data`.

## Zasoby startowe

```bash
./services/floci/init-floci.sh
```

Idempotentny — tworzy tylko to, czego brakuje: S3 `app-logs`, `app-backups`,
IAM `szymon-cloud-engineer`, SQS `app-events`, DynamoDB `app-table`.
Endpoint można nadpisać przez `AWS_ENDPOINT_URL`.
