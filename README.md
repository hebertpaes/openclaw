# openclaw

Automação para implantar e executar o motor de jogo
[OpenClaw](https://github.com/pjasicek/OpenClaw) — uma reimplementação de
*Captain Claw* (1997) — na VM **`openclaw-vm`** do Azure.

## Estrutura

- `deploy/`: scripts de instalação, build e execução para a VM Azure
  - `setup.sh`: orquestra dependências → build → organização de assets
  - `install-deps.sh`: instala SDL2, áudio MIDI e display virtual (Xvfb/VNC)
  - `build.sh`: clona e compila o OpenClaw
  - `organize-assets.sh`: **organiza a pasta de download** (coloca o `CLAW.REZ`
    no lugar e gera o `ASSETS.ZIP`)
  - `clean-downloads.sh`: remove arquivos `.dmg` inúteis (imagens macOS) da
    pasta de download
  - `run.sh`: **ativa o OpenClaw** (display virtual + VNC para acesso remoto)
  - `install-service.sh`: registra como serviço `systemd`
  - `README.md`: guia completo de implantação
- `.gitignore`: arquivos/pastas ignorados pelo Git

## Início rápido (na VM `openclaw-vm`)

```bash
cd ~/openclaw
./deploy/setup.sh     # dependências + build + organiza assets
./deploy/run.sh       # ativa o jogo (acesse via túnel SSH + VNC)
```

> Você precisa fornecer o arquivo `CLAW.REZ` do jogo original (protegido por
> direitos autorais, não incluído). Veja **[`deploy/README.md`](deploy/README.md)**
> para o passo a passo completo, túnel VNC e execução como serviço.

## Observações

Os scripts rodam **dentro da VM** (Ubuntu/Debian) via SSH; eles não controlam
o plano de gerenciamento do Azure. Ligue/desligue a VM pelo
[Portal Azure](https://portal.azure.com/#@abacs.org.br/resource/subscriptions/de047b31-2275-439a-a162-5596f80161cb/resourceGroups/openclaw-vm_group/providers/Microsoft.Compute/virtualMachines/openclaw-vm/overview).
