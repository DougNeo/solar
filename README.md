# Dashboard da usina solar

Dashboard Rails privada para consultar usinas, inversores, geração e alertas da Solarman. Usa SQLite, Solid Cache e Solid Queue; se a API ficar indisponível, a tela continua mostrando o último estado persistido.

## Configuração

Requer Ruby 4.0.6. Instale as dependências e prepare os bancos:

```sh
bundle install
bin/rails db:prepare
```

Edite `config/credentials.yml.enc` com `bin/rails credentials:edit` e preencha:

```yaml
solarman:
  app_id: "..."
  app_secret: "..."
  email: "..."
  password: "..."
application:
  allowed_host: "solar.exemplo.com"
admin:
  email: "admin@exemplo.com"
```

A aplicação interrompe a inicialização com a lista de valores ausentes. A senha da Solarman é transformada em SHA-256 apenas ao autenticar; não informe um hash. Crie a senha local (mínimo de 12 caracteres) de forma interativa:

```sh
bin/rails admin:password
```

Não há cadastro público. Para a primeira importação, execute `bin/rails solar:sync`. O histórico é importado desde o início da operação até ontem, em janelas inclusivas de no máximo 30 dias. Depois disso, Solid Queue atualiza usinas/dispositivos diariamente, histórico às 01:00 (America/Sao_Paulo), alertas a cada 15 minutos e backups às 03:00.

## CasaOS / Docker Compose

Crie `config/master.key` no host com a chave que corresponde a `credentials.yml.enc`, crie o diretório `backups` gravável pelo UID 1000 e execute:

```sh
docker compose up --build -d
docker compose exec solar bin/rails admin:password
docker compose exec solar bin/rails solar:sync
```

O banco fica no volume `solar_storage`, os backups em `./backups`, e a chave é montada somente para leitura. `.dockerignore` impede que `master.key` entre no contexto; o Dockerfile também falha caso uma chave chegue à etapa de build. Guarde outra cópia da chave fora do servidor: perdê-la torna as Credentials indecifráveis; expô-la junto com `credentials.yml.enc` revela todos os segredos.

## Backup e restauração

`BackupDatabaseJob` usa `VACUUM INTO`, que cria um snapshot SQLite consistente, e conserva as 14 cópias mais recentes. Para restaurar:

1. Pare o container (`docker compose stop solar`) para impedir escritas.
2. Copie o arquivo atual de `storage/production.sqlite3` para um local seguro.
3. Copie o snapshot escolhido de `backups/` para `storage/production.sqlite3` (via um container temporário com o volume montado, se usar volume nomeado).
4. Preserve proprietário UID/GID 1000, suba o serviço e confira `docker compose exec solar bin/rails runner 'puts ActiveRecord::Base.connection.execute("PRAGMA integrity_check").first'`.

Nunca restaure por cima de um banco aberto. Cache e fila podem ser recriados; o banco principal contém usuários, usinas, dispositivos, leituras e alertas.

## Qualidade

```sh
bin/rails test
bin/rubocop
bin/brakeman --no-pager
```
