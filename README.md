# openclaw

Automação para implantar e executar o motor de jogo
[OpenClaw](https://github.com/pjasicek/OpenClaw) — uma reimplementação de
*Captain Claw* (1997) — na VM **`openclaw-vm`** do Azure **ou localmente no
MacBook**.

## Estrutura

- **`deploy/`** — scripts para a **VM Azure** (Ubuntu/Debian), build headless
  com display virtual (Xvfb/VNC). Guia: [`deploy/README.md`](deploy/README.md)
  - `setup.sh`: orquestra dependências → build → organização de assets
  - `install-deps.sh`: instala SDL2, áudio MIDI e display virtual (Xvfb/VNC)
  - `build.sh`: clona e compila o OpenClaw
  - `organize-assets.sh`: **organiza a pasta de download** (coloca o `CLAW.REZ`
    no lugar e gera o `ASSETS.ZIP`)
  - `clean-downloads.sh`: remove arquivos `.dmg` inúteis (imagens macOS) da
    pasta de download
  - `run.sh`: **ativa o OpenClaw** (display virtual + VNC para acesso remoto)
  - `install-service.sh`: registra como serviço `systemd`
- **`mac/`** — scripts para rodar **localmente no macOS** (Homebrew + SDL2,
  janela nativa). Guia: [`mac/README.md`](mac/README.md)
  - `setup.sh`: orquestra dependências → build → organização de assets
  - `install-deps.sh`: instala SDL2 via Homebrew
  - `build.sh`: clona e compila (detecta prefixo do brew + arquitetura)
  - `organize-assets.sh`: coloca o `CLAW.REZ` no lugar e gera o `ASSETS.ZIP`
  - `run.sh`: **ativa o OpenClaw** numa janela nativa
- `.gitignore`: arquivos/pastas ignorados pelo Git

## Início rápido — VM `openclaw-vm` (Azure)

```bash
cd ~/openclaw
./deploy/setup.sh     # dependências + build + organiza assets
./deploy/run.sh       # ativa o jogo (acesse via túnel SSH + VNC)
```

Os scripts rodam **dentro da VM** via SSH; eles não controlam o plano de
gerenciamento do Azure. Ligue/desligue a VM pelo
[Portal Azure](https://portal.azure.com/#@abacs.org.br/resource/subscriptions/de047b31-2275-439a-a162-5596f80161cb/resourceGroups/openclaw-vm_group/providers/Microsoft.Compute/virtualMachines/openclaw-vm/overview).

## Início rápido — MacBook (macOS)

```bash
# Clone com o URL correto e entre na branch dos scripts (até o merge na main)
git clone https://github.com/hebertpaes/openclaw.git
cd openclaw && git checkout claude/vigilant-hamilton-ig74tu

cp /caminho/CLAW.REZ ~/Downloads/
./mac/setup.sh --run  # dependências (Homebrew) + build + organiza assets + roda
```

## Observação

Você precisa fornecer o arquivo `CLAW.REZ` do jogo original (protegido por
direitos autorais, **não incluído**) tanto na VM quanto no Mac.
