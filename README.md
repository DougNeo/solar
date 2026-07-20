# Dashboard da usina solar

Dashboard Rails privada para acompanhar usinas, inversores, geração e alertas da Solarman. A aplicação usa SQLite, Solid Cache e Solid Queue e continua exibindo o último estado persistido quando a API externa fica indisponível.

## Retomada rápida

Quando voltar ao projeto, siga esta ordem:

```sh
git pull --ff-only
docker compose config
docker compose up --build -d
docker compose ps
docker compose logs --tail=100 solar
```

Abra `https://HOST_CONFIGURADO`. Se a instalação ainda não tiver usuário ou dados, execute:

```sh
docker compose exec solar bin/rails admin:password
docker compose exec solar bin/rails solar:sync
```

O endpoint `GET /up` deve responder com HTTP 200. Os dois arquivos PDF da documentação Solarman que podem existir no diretório de trabalho são artefatos locais e não fazem parte do Git nem da imagem.

## Estado e arquitetura

- Runtime: Ruby 4.0.6 e Rails 8.1.3.
- Banco principal: `storage/production.sqlite3` no volume nomeado `solar_storage`.
- Cache e fila: SQLite separados no mesmo volume, gerenciados por Solid Cache e Solid Queue.
- Front-end: Turbo, Stimulus, Tailwind e Chart.js empacotado localmente, sem CDN.
- Autenticação: um administrador, sem cadastro público; somente o e-mail fica nas Rails Credentials.
- Dados atuais: cache de dois minutos e fallback para os últimos valores locais.
- Escopo Solarman: somente leitura; não há controle remoto, criação ou exclusão de equipamentos.
- Deploy: Docker Compose para um único servidor CasaOS; Kamal não é usado.

Os pontos principais do código são:

- `app/services/atores/solarman/`: cliente HTTP, token e chamadas da API;
- `app/services/solarman_sync.rb`: persistência e normalização;
- `app/jobs/`: sincronizações e backup;
- `config/recurring.yml`: agenda do Solid Queue;
- `app/controllers/dashboard_controller.rb`: dashboard e fallback local;
- `compose.yml`: serviço, volumes e healthcheck.

## Segredos e Rails Credentials

Nunca envie chaves de Credentials nem valores descriptografados ao Git. O repositório guarda o arquivo criptografado `config/credentials/production.yml.enc`; a chave correspondente fica somente no host.

Crie ou edite as Credentials de produção:

```sh
EDITOR=nano bin/rails credentials:edit --environment production
```

Conteúdo obrigatório:

```yaml
secret_key_base: "cole-a-saida-de-bin-rails-secret"

solarman:
  app_id: "..."
  app_secret: "..."
  email: "..."
  password: "senha-sem-hash"
application:
  allowed_host: "solar.exemplo.com"
admin:
  email: "admin@exemplo.com"
```

Gere `secret_key_base` com `bin/rails secret`. Use apenas o hostname em `allowed_host`, sem `https://` e sem caminho. A senha da Solarman é transformada em SHA-256 durante a autenticação; não grave o hash nas Credentials.

A inicialização falha com uma lista clara se algum valor estiver ausente. O comando cria `config/credentials/production.yml.enc` e `config/credentials/production.key`; versione apenas o arquivo `.yml.enc`. Perder a chave torna as Credentials indecifráveis; mantenha uma cópia segura dela fora do servidor.

Depois de preencher as Credentials, inclua o arquivo criptografado no próximo commit:

```sh
git add config/credentials/production.yml.enc
```

## Primeira instalação no CasaOS

Pré-requisitos: Git, Docker com Compose, hostname do Cloudflare Tunnel apontando para a porta publicada e uma cópia válida de `config/credentials/production.key`.

```sh
git clone git@github.com:DougNeo/solar.git
cd solar
install -d -m 755 backups
# Copie a chave por um canal seguro para config/credentials/production.key
chmod 600 config/credentials/production.key
docker compose up --build -d
```

O Compose monta:

- `solar_storage` em `/rails/storage`, preservando bancos entre recriações;
- `./backups` em `/rails/backups`;
- `./config/credentials/production.key` em `/rails/config/credentials/production.key`, somente leitura.

O container roda como UID/GID 1000. Se o backup apresentar erro de permissão, ajuste no host:

```sh
sudo chown -R 1000:1000 backups
```

Crie a senha local do administrador, com pelo menos 12 caracteres, e faça a primeira sincronização:

```sh
docker compose exec solar bin/rails admin:password
docker compose exec solar bin/rails solar:sync
```

Em desenvolvimento, a importação cobre somente os últimos 30 dias. Em produção, a primeira execução percorre desde o início de operação até ontem; as seguintes continuam a partir do último dia salvo. As janelas têm no máximo 30 dias e repetir a tarefa não duplica registros.

No Cloudflare, use HTTPS externamente. A aplicação força SSL, permite o hostname configurado e exclui apenas `/up` do redirecionamento para que o healthcheck interno funcione.

## Rotina automática

Solid Queue é executado no processo do Puma por `SOLID_QUEUE_IN_PUMA=1` e usa o fuso `America/Sao_Paulo`:

| Rotina | Frequência |
| --- | --- |
| Alertas | A cada 15 minutos |
| Histórico | Diariamente às 01:00 |
| Usinas e dispositivos | Diariamente às 02:00 |
| Backup | Diariamente às 03:00 |
| Limpeza de jobs concluídos | A cada hora |

Para disparar tarefas manualmente:

```sh
docker compose exec solar bin/rails solar:sync
docker compose exec solar bin/rails runner 'SyncAlertsJob.perform_now'
docker compose exec solar bin/rails runner 'BackupDatabaseJob.perform_now'
```

## Operação e diagnóstico

Comandos úteis:

```sh
docker compose ps
docker compose logs -f solar
docker compose exec solar bin/rails about
docker compose exec solar bin/rails db:migrate:status
docker compose exec solar bin/rails runner 'puts SolidQueue::FailedExecution.count'
docker compose exec solar bin/rails runner 'puts Plant.count'
curl -i http://localhost:3000/up
```

Problemas comuns:

- `Missing encryption key`: `config/credentials/production.key` está ausente, é um diretório ou não corresponde a `config/credentials/production.yml.enc`.
- `Credenciais obrigatórias ausentes`: edite as Credentials e preencha todos os campos documentados.
- `Blocked host`: confira se `application.allowed_host` contém exatamente o hostname usado no navegador.
- Dashboard desatualizada: verifique os logs, o acesso de saída a `globalapi.solarmanpv.com` e jobs com falha.
- Container não saudável: confira `/up`, permissões do volume e o resultado de `db:prepare` nos logs de inicialização.
- Login bloqueado: aguarde 15 minutos; são permitidas cinco tentativas por endereço IP nessa janela.

Para trocar a senha administrativa:

```sh
docker compose exec solar bin/rails admin:password
```

## Atualização e rollback

Antes de atualizar, gere um backup manual. Depois atualize somente por avanço de histórico:

```sh
docker compose exec solar bin/rails runner 'BackupDatabaseJob.perform_now'
git pull --ff-only
docker compose build --pull
docker compose up -d
docker compose ps
docker compose logs --tail=100 solar
```

O entrypoint executa `db:prepare` antes de iniciar o servidor. Não apague o volume ao recriar o container. Em particular, não use `docker compose down -v`, pois `-v` remove os bancos persistentes.

Se uma atualização falhar, preserve o banco, consulte `git log --oneline`, retorne ao commit conhecido em uma branch de recuperação e reconstrua a imagem. Só restaure o SQLite quando houver corrupção ou migração de dados incompatível.

## Backup e restauração

`BackupDatabaseJob` usa `VACUUM INTO` para criar um snapshot SQLite consistente e mantém as 14 cópias mais recentes em `./backups`.

Liste e teste os arquivos:

```sh
ls -lh backups/
sqlite3 backups/solar-AAAAmmdd-HHMMSS.sqlite3 'PRAGMA integrity_check;'
```

Para restaurar, substitua `ARQUIVO.sqlite3` pelo nome escolhido:

```sh
docker compose stop solar
docker compose run --rm --no-deps --entrypoint sh solar -c \
  'cp storage/production.sqlite3 backups/pre-restore.sqlite3'
docker compose run --rm --no-deps --entrypoint sh solar -c \
  'cp backups/ARQUIVO.sqlite3 storage/production.sqlite3'
docker compose up -d
docker compose exec solar bin/rails runner \
  'puts ActiveRecord::Base.connection.execute("PRAGMA integrity_check").first'
```

Nunca restaure por cima de um banco aberto. O banco principal contém usuários, usinas, dispositivos, leituras e alertas. Os bancos de cache e fila podem ser recriados; não os use no lugar do snapshot principal.

## Desenvolvimento local

Requer Ruby 4.0.6. Após instalar a Ruby indicada por `.ruby-version`:

```sh
bundle install
bin/rails db:prepare
bin/dev
```

As Credentials de desenvolvimento podem usar `config/credentials/development.yml.enc`; nunca versione `config/credentials/development.key`.

Antes de enviar mudanças:

```sh
RAILS_ENV=test bin/rails test
bin/rubocop
bin/brakeman --no-pager
RAILS_ENV=test bin/rails zeitwerk:check
docker compose config
docker build -t solar-dashboard:verify .
```

O baseline atual é 14 testes e 38 asserções, com RuboCop e Brakeman sem alertas.
