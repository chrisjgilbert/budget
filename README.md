# Budget

A personal budget tracking web app — Rails 8.1 + Hotwire + SQLite.

The original Electron desktop app lives under [`electron/`](./electron) for
reference and is no longer maintained.

## Local development

Requires Ruby 3.3.6 (see `.ruby-version`).

```bash
bundle install
bin/rails db:prepare

# Generate a bcrypt hash for the shared login password and export it:
export BUDGET_PASSWORD_HASH=$(bin/rails runner 'puts BCrypt::Password.create("your-password")' | tail -1)

bin/rails s
```

Visit <http://localhost:3000>, log in with the password you hashed.

Run tests with `bin/rails test`.

## Deploying to a Hetzner VM with Kamal

This is a Kamal-managed Docker deploy targeting
[budget.gilbert.works](https://budget.gilbert.works), with Kamal-Proxy handling
TLS via Let's Encrypt automatically.

### One-time prerequisites

1. **Hetzner VM** running Ubuntu 22.04+ with the public IP reachable on ports
   80 and 443. Hetzner Cloud images come with `root` SSH access by default.
2. **Local SSH key** authorised for `root@<vm-ip>` (e.g. `ssh-copy-id`).
3. **DNS A record**: `budget.gilbert.works` → your VM's public IP.
4. **GitHub Container Registry token** with `read:packages` and
   `write:packages`. Create at <https://github.com/settings/tokens>.
5. **`config/deploy.yml`**: replace the placeholder IP under `servers.web` with
   your VM's actual address.

### Set local environment

```bash
# Bcrypt hash of the shared password (same one you use locally)
export BUDGET_PASSWORD_HASH='$2a$12$...'

# GHCR token from prerequisite #4
export KAMAL_REGISTRY_PASSWORD='ghp_...'
```

`config/master.key` (which Kamal also needs) is read from the file directly —
make sure it's present and not committed.

### First deploy

```bash
bin/kamal setup
```

This installs Docker on the VM, pushes the first image, boots Kamal-Proxy,
provisions a TLS certificate, and starts the app. Takes ~5 minutes the first
time. When it finishes, `https://budget.gilbert.works` should respond.

### Subsequent deploys

```bash
bin/kamal deploy
```

### Useful aliases

```bash
bin/kamal logs        # tail app logs
bin/kamal console     # rails console on the running container
bin/kamal shell       # bash on the running container
bin/kamal app exec 'bin/rails db:migrate'   # one-off command
```

### Importing the old Electron data

Not yet wired — see the original plan. To DIY in the meantime:
`bin/kamal app exec --interactive 'bin/rails runner "..."'` with a script that
reads the JSON shape under `electron/renderer/app.js`'s `migrateMonth`.

## Data storage

A single SQLite database at `storage/production.sqlite3` on the VM, mounted
into the container via the `budget_storage` volume declared in `deploy.yml`.

Backup story: none yet. Add Litestream as a Kamal accessory once you've
chosen an S3-compatible target — there's a commented-out scaffold in
`config/deploy.yml`.
