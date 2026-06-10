# PLAN.md — pre-commit review

> Ten plik NIE jest commitowany. Usuń go lub dodaj do `.gitignore` przed commitem.

---

## Zmienione / nowe pliki

| Plik | Status | Idzie do commita? |
|------|--------|-------------------|
| `localstack/docker-compose.yml` | Zmodyfikowany | TAK |
| `localstack/.env` | Nowy (sekret) | **NIE** — objęty `.gitignore` |
| `localstack/.env.example` | Nowy (template) | TAK |
| `.gitignore` | Zmodyfikowany | TAK |
| `README.md` | Zmodyfikowany | TAK |
| `PLAN.md` | Nowy (ten plik) | **NIE** — usunąć przed commitem |

---

## Opisy zmian

### `localstack/docker-compose.yml`

Zastąpiono hardcoded token referencją do zmiennej środowiskowej:

```diff
-      - LOCALSTACK_AUTH_TOKEN=ls-surI-...   # token usunięty
+      - LOCALSTACK_AUTH_TOKEN=${LOCALSTACK_AUTH_TOKEN}
```

Docker Compose przy starcie podczytuje wartość z `localstack/.env` (jeśli uruchomiony z `--env-file .env` lub plik `.env` jest obok `docker-compose.yml`).

---

### `localstack/.env` (nowy, nie commitowany)

Zawiera prawdziwy token. Plik ignorowany przez `.gitignore`.

```
LOCALSTACK_AUTH_TOKEN=<wartość tokena — nie pokazywana tutaj>
```

---

### `localstack/.env.example` (nowy, commitowany)

Template dokumentujący wymaganą zmienną:

```
LOCALSTACK_AUTH_TOKEN=your-token-here
```

---

### `.gitignore`

Dodano explicit wpis dla `localstack/.env` (choć wzorzec `.env` już go pokrywał — jawny wpis dla czytelności):

```diff
 # Environment variables
 .env
+localstack/.env
```

Weryfikacja: `git check-ignore localstack/.env` → zwraca `localstack/.env` ✅

---

### `README.md`

1. **Tabela Stack**: zmieniono `LocalStack (community, Docker)` → `LocalStack Pro (free tier), Docker Compose`

2. **Sekcja LocalStack** — rozbudowana:
   - Bind mount `./data:/var/lib/localstack` + brak persistence (Pro-only)
   - Zarządzanie tokenem przez `.env`
   - Tabela zasobów tworzonych przez `init-localstack.sh`
   - Opis retry loop w skrypcie health check
   - Quirk: `available` → `running` w health endpoincie

---

## Proponowany commit message (Conventional Commits)

```
security: move LocalStack auth token to .env and update README

- Replace hardcoded LOCALSTACK_AUTH_TOKEN in localstack/docker-compose.yml
  with ${LOCALSTACK_AUTH_TOKEN} env var reference
- Add localstack/.env.example documenting required variable
- Add explicit localstack/.env to .gitignore
- Update README with LocalStack setup details: bind mount, init-localstack.sh
  behavior, health check quirk, and secret management approach
```

---

## Do weryfikacji przed commitem

- [ ] `grep -r "ls-surI" localstack/` → zero wyników (token nie w żadnym commitowanym pliku)
- [ ] `git check-ignore localstack/.env` → zwraca ścieżkę ✅ (już zweryfikowane)
- [ ] `git status` → `localstack/.env` **nie** pojawia się jako untracked / staged
- [ ] `README.md` nie zawiera tokena w żadnym przykładzie
- [ ] `PLAN.md` usunięty lub dodany do `.gitignore` przed `git add`
- [ ] **Git history czysta**: `git log --all -S "ls-surI" --oneline` → puste ✅ (już zweryfikowane)
- [ ] Shell history (`~/.zsh_history`) — jeśli token był eksportowany ręcznie, to nie wpływa na repo, ale warto wiedzieć
