# openclaw

Automação para instalar e rodar o **gateway de IA OpenClaw**
([github.com/openclaw/openclaw](https://github.com/openclaw/openclaw) — o 🦞
assistente self-hosted, <https://openclaw.ai>) na VM **`openclaw-vm`** do Azure
**e localmente no MacBook**.

O OpenClaw é um agente de IA self-hosted que conecta seus apps de mensagem a um
agente de código. Ele roda um processo *gateway* que escuta na porta **18789**
(painel local em `http://localhost:18789`). Por padrão estes scripts usam o
backend **Codex** (Codex app-server da OpenAI, via plugin `@openclaw/codex`);
use `OPENCLAW_BACKEND=claude` para usar o Claude (Anthropic).

## Estrutura

- **`deploy/`** — instala e ativa o gateway na **VM Azure** (Ubuntu/Debian).
  Guia: [`deploy/README.md`](deploy/README.md)
  - `setup.sh`: instala Node + OpenClaw → gera config → onboard + daemon
  - `install.sh` · `configure.sh` · `start.sh` · `connect.sh` (túnel SSH do Mac)
- **`mac/`** — roda o gateway **localmente no macOS** (Homebrew + npm).
  Guia: [`mac/README.md`](mac/README.md)
  - `setup.sh` · `install.sh` · `configure.sh` · `start.sh`
- `.gitignore`

## Início rápido — VM `openclaw-vm` (Azure)

```bash
ssh azureuser@<ip-da-vm>
cd ~/openclaw
export OPENAI_API_KEY=sk-...          # backend Codex (ou login ChatGPT/Codex no onboard)
./deploy/setup.sh                     # instala + configura + sobe o daemon
# Para usar Claude:  OPENCLAW_BACKEND=claude ANTHROPIC_API_KEY=sk-ant-... ./deploy/setup.sh
```

Acesse o painel do seu Mac via túnel SSH:

```bash
export VM_HOST=azureuser@<ip-da-vm>
./deploy/connect.sh                   # abre o túnel; depois abra http://localhost:18789
```

Ligue/desligue a VM pelo
[Portal Azure](https://portal.azure.com/#@abacs.org.br/resource/subscriptions/de047b31-2275-439a-a162-5596f80161cb/resourceGroups/openclaw-vm_group/providers/Microsoft.Compute/virtualMachines/openclaw-vm/overview).

## Início rápido — MacBook (macOS)

```bash
git clone https://github.com/hebertpaes/openclaw.git
cd openclaw && git checkout claude/vigilant-hamilton-ig74tu   # até o merge na main
export OPENAI_API_KEY=sk-...          # backend Codex (ou login ChatGPT/Codex no onboard)
./mac/setup.sh                        # instala + configura + sobe o daemon (launchd)
# painel: http://localhost:18789
```

## Credenciais (`secrets.env`)

Em vez de exportar chaves à mão, copie o template e preencha — os scripts
carregam automaticamente e o arquivo é **gitignored**:

```bash
cp secrets.env.example secrets.env
# edite: OPENCLAW_BACKEND, OPENAI_API_KEY (ou ANTHROPIC_API_KEY), GITHUB_TOKEN, VM_HOST
```

Para **conectar ao GitHub**, deixe `OPENCLAW_GITHUB=1` e preencha o `GITHUB_TOKEN`
(PAT fine-grained, escopos `repo` + `read:org`) no `secrets.env` — o `install.sh`
adiciona o plugin do GitHub e o agente autentica pela variável de ambiente
(nunca no `openclaw.json`).

Para alterar a credencial de **login da VM** (ação no Azure, feita por você no
Cloud Shell): `az vm user update -g openclaw-vm_group -n openclaw-vm -u azureuser
--ssh-key-value "$(cat ~/.ssh/id_ed25519.pub)"` — ou a aba **Reset password** no
portal.

## Recomeçar do zero

```bash
./deploy/uninstall.sh --purge   # (ou ./mac/uninstall.sh) remove tudo: pacote, plugins, ~/.openclaw
./deploy/setup.sh               # instala de novo, já com Codex + GitHub
```

## Automação (CI)

O repositório tem um workflow do GitHub Actions (`.github/workflows/ci.yml`) que,
a cada push/PR, valida os scripts (`bash -n` + `shellcheck`) e garante que nenhum
arquivo de segredo foi commitado.

## Observações

- A **chave do provider** (`OPENAI_API_KEY` para Codex, `ANTHROPIC_API_KEY` para
  Claude) é fornecida por você em runtime e **nunca** é escrita no repositório
  nem no `openclaw.json`.
- O OpenClaw é um agente autônomo (executa shell, lê/escreve arquivos). Mantenha
  o gateway em `localhost` + túnel SSH em vez de expor a porta 18789.
- Os scripts rodam **dentro da VM/Mac**; não controlam o plano de gerenciamento
  do Azure.
