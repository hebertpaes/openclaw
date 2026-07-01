# Publicador automático → Ghost (odiapolitico.com.br)

Automação que lê **releases de assessorias públicas** (SECOM-MT, prefeituras de
Mato Grosso) e cria posts no site **Ghost** de odiapolitico.com.br, **sempre
citando a fonte** (link + `canonical_url` + bloco de crédito).

Zero dependências — Node ≥ 18 puro (`fetch` + `crypto` nativos). Nada de `npm install`.

## Como funciona

```
sources.json ──► fetchReleases (RSS ou HTML) ──► dedupe (state) ──► transform (+atribuição) ──► Ghost Admin API
```

- **Fontes** em `sources.json` (RSS preferido; HTML/OpenGraph como fallback).
- **Dedupe** em `state/published.json` — nunca republica o mesmo URL.
- **Atribuição obrigatória**: cada post recebe `canonical_url` = link original,
  uma tag da fonte e um rodapé “Fonte: …”.
- **Rascunho por padrão** (`POST_STATUS=draft`) para revisão editorial; troque
  para `published` para publicação 100% automática.

## Pré-requisitos

1. No Ghost: **Settings → Integrations → Add custom integration** e copie a
   **Admin API Key** (formato `id:secret`) e a URL do site.
2. Node ≥ 18 (para rodar localmente) — o GitHub Actions usa Node 20.

## Rodando localmente

```bash
cp .env.example .env         # preencha GHOST_ADMIN_API_KEY (nunca commite)
set -a; . ./.env; set +a

npm run dry-run              # ou: DRY_RUN=1 node src/index.mjs  (não posta nada)
npm start                    # cria os posts (draft por padrão)
npm test                     # testes locais (JWT, RSS, atribuição, dedupe)
```

## Configurando as fontes (`sources.json`)

```jsonc
{
  "name": "SECOM-MT — Governo de Mato Grosso",
  "attribution": "Governo de Mato Grosso / SECOM-MT",
  "tag": "Governo de MT",
  "type": "rss",                 // "rss" (recomendado) ou "html"
  "url": "https://www.secom.mt.gov.br/rss/noticias",
  "enabled": true
}
```

Para fontes **sem RSS**, use `type: "html"` e ajuste:
- `linkPattern`: regex que identifica os links de matéria na listagem;
- `bodySelector`: ex. `article` ou `div.conteudo` para capturar o corpo;
- `maxArticles`: quantas matérias visitar por execução.

> ⚠️ **Confirme as URLs de feed / seletores.** Não consegui inspecionar os sites
> ao vivo deste ambiente (rede restrita). A URL do feed da SECOM em
> `sources.json` é um palpite marcado com `_note` — valide antes de publicar.

## Automação (GitHub Actions)

`.github/workflows/publish.yml` roda **de hora em hora** (e sob demanda). Configure:

**Secrets** (Settings → Secrets and variables → Actions → *Secrets*):
| Secret | Valor |
| --- | --- |
| `GHOST_ADMIN_API_URL` | `https://odiapolitico.com.br` |
| `GHOST_ADMIN_API_KEY` | a Admin API Key `id:secret` |

**Variable** (aba *Variables*, opcional):
| Variable | Efeito |
| --- | --- |
| `POST_STATUS` | `draft` (padrão) ou `published` (full-auto) |

O workflow commita o `state/published.json` de volta para não repostar entre execuções.

## Atribuição, direitos e boas práticas

- Use apenas fontes cujo **reuso editorial/imagens seja permitido** (comunicação
  oficial das assessorias, como você indicou). Cada post credita e **linka a
  fonte** e usa `canonical_url` (evita penalização de conteúdo duplicado).
- Comece com `POST_STATUS=draft` e revise antes de liberar. Só migre para
  `published` quando confiar na fonte + no mapeamento.
- Respeite `robots.txt` e os termos de cada site; ajuste a cadência do cron se
  necessário.
