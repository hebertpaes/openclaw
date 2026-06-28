# openclaw-publisher

Automação de **publicação e sindicalização de conteúdo**. O hub é o **Ghost**
(`odiapolitico.com.br`): você cria/publica um post lá e ele é distribuído
automaticamente para **X, Facebook, Instagram e WhatsApp**.

Sem dependências externas — roda em **Node.js ≥ 18** (usa `fetch` e `crypto`
nativos). Cada plataforma é um adaptador isolado em `lib/platforms/`.

```
publisher/
├── publish.js            # cria post no Ghost + sindicaliza
├── syndicate.js          # pega um post do Ghost e sindicaliza
├── config.example.env    # template de credenciais (copie p/ config.env)
└── lib/
    ├── ghost.js          # Ghost Admin API (criar) + Content API (ler)
    ├── format.js         # monta o texto por plataforma a partir do post
    ├── syndicator.js     # orquestra o fan-out
    └── platforms/        # x.js · facebook.js · instagram.js · whatsapp.js
```

## Configuração

```bash
cp publisher/config.example.env publisher/config.env
# edite publisher/config.env com suas chaves (o arquivo é gitignored)
```

### Ghost (obrigatório)

No Ghost Admin → **Settings → Integrations → Add custom integration**. Copie:

- **Admin API Key** → `GHOST_ADMIN_API_KEY` (formato `id:secret`)
- **Content API Key** → `GHOST_CONTENT_API_KEY` (leitura)

> A *Admin API Key* **não** é a senha de login do admin. É uma chave gerada
> pela integração. Use sempre a chave da integração — nunca a senha de login.

### Redes sociais

| Plataforma | Variáveis | Como obter |
|---|---|---|
| **X** | `X_API_KEY`, `X_API_SECRET`, `X_ACCESS_TOKEN`, `X_ACCESS_SECRET` | App no [developer.x.com](https://developer.x.com) com permissão de escrita (OAuth 1.0a) |
| **Facebook** | `FB_PAGE_ID`, `FB_PAGE_ACCESS_TOKEN` | Page token longo com `pages_manage_posts` |
| **Instagram** | `IG_USER_ID`, `IG_ACCESS_TOKEN` | Conta Business ligada à Page (requer imagem no post) |
| **WhatsApp** | `WHATSAPP_PHONE_ID`, `WHATSAPP_TOKEN`, `WHATSAPP_RECIPIENTS` | [WhatsApp Cloud API](https://developers.facebook.com/docs/whatsapp/cloud-api) |

Desligue uma plataforma com `PLATFORM_X=0` (etc.) mesmo com as chaves presentes.
Plataformas sem credenciais são **puladas** automaticamente.

## Uso

```bash
# Criar um post no Ghost e já distribuir nas redes:
node publisher/publish.js --title "Manchete" --file materia.html \
     --tags politica,brasil --image https://.../capa.jpg

# Só simular a distribuição (não envia nada):
node publisher/syndicate.js --dry-run

# Distribuir o último post publicado:
node publisher/syndicate.js

# Distribuir um post específico, só em algumas redes:
node publisher/syndicate.js --slug minha-materia --only x,facebook

# Criar rascunho no Ghost sem distribuir:
node publisher/publish.js --title "Rascunho" --html "<p>...</p>" --status draft
```

`--dry-run` mostra exatamente o que seria enviado a cada rede sem chamar as APIs
— use sempre antes do primeiro envio real.

## Notas de conformidade (importante)

- **WhatsApp**: a Cloud API só entrega para quem deu **opt-in**. Fora da janela
  de 24h é obrigatório um **template aprovado** (`WHATSAPP_TEMPLATE`). Esta
  automação **não** coleta membros de grupos nem envia para quem não consentiu —
  ela faz *broadcast* para uma lista própria de inscritos. Disparo em massa não
  solicitado viola a política do WhatsApp Business e pode **banir o número**.
- **Instagram**: posts de feed não têm link clicável; a legenda direciona para o
  "link na bio". É necessário uma imagem pública (a *feature image* do post).
- **X / Facebook**: respeite os limites de taxa das APIs. Reposte com moderação.

## Próximos passos sugeridos

- Webhook do Ghost (`post.published`) → dispara `syndicate.js` automaticamente.
- Agendamento (cron/GitHub Actions) para o "último post".
- Telegram, Bluesky, LinkedIn como novos adaptadores em `lib/platforms/`.
