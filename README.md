# openclaw

Automação para instalar e rodar o **gateway de IA OpenClaw**
([github.com/openclaw/openclaw](https://github.com/openclaw/openclaw) — o 🦞
assistente self-hosted, <https://openclaw.ai>) na VM **`openclaw-vm`** do Azure
**e localmente no MacBook**.

O OpenClaw é um agente de IA self-hosted que conecta seus apps de mensagem a um
agente Claude. Ele roda um processo *gateway* que escuta na porta **18789**
(painel local em `http://localhost:18789`).

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
export ANTHROPIC_API_KEY=sk-ant-...   # chave do Claude (não é commitada)
./deploy/setup.sh                     # instala + configura + sobe o daemon
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
export ANTHROPIC_API_KEY=sk-ant-...
./mac/setup.sh                        # instala + configura + sobe o daemon (launchd)
# painel: http://localhost:18789
```

## Observações

- A **chave da Anthropic** (`ANTHROPIC_API_KEY`) é fornecida por você em runtime
  e **nunca** é escrita no repositório nem no `openclaw.json`.
- O OpenClaw é um agente autônomo (executa shell, lê/escreve arquivos). Mantenha
  o gateway em `localhost` + túnel SSH em vez de expor a porta 18789.
- Os scripts rodam **dentro da VM/Mac**; não controlam o plano de gerenciamento
  do Azure.
