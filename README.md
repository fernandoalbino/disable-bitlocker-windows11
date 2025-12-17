# BitLocker Control (Unified) – CLI/TUI + GUI (Windows 10 / 11)

Este repositório entrega **controle explícito** do BitLocker / Device Encryption com foco em **VMs (migração)** e também em **PC físico**.

Inclui:
- **Script unificado CLI/TUI** (menu interativo no terminal)
- **GUI real (WinForms)** no estilo “painel pragmático”
- **Detecção automática do drive do sistema**
- **Logs em arquivo**
- **Confirmações de segurança**
- **Export automático da Recovery Key** ao habilitar

## Arquivos

- `bitlocker-control.ps1`  
  CLI/TUI (menu no terminal) + modo automação por parâmetro (`-Mode`).

- `bitlocker-control-gui.ps1`  
  GUI WinForms (botões Enable/Disable/Test/Status + console/log).

## Requisitos

- Windows 10 ou Windows 11
- PowerShell
- Executar como **Administrador**
- `manage-bde` disponível (Windows)

> TPM pode permanecer habilitado (Windows 11 compatível).

---

## Uso rápido (CLI/TUI)

Abra **PowerShell como Administrador** e rode:

```powershell
.\bitlocker-control.ps1
```

Isso abre o menu interativo com cores e ícones ASCII.

### Modo automação (sem menu)

```powershell
.\bitlocker-control.ps1 -Mode status
.\bitlocker-control.ps1 -Mode enable
.\bitlocker-control.ps1 -Mode disable
.\bitlocker-control.ps1 -Mode test
```

### Forçar sem confirmação

Para automação (CI/remote), você pode suprimir confirmações:

```powershell
.\bitlocker-control.ps1 -Mode disable -Force
```

---

## Uso (GUI WinForms)

Abra **PowerShell como Administrador** e execute:

```powershell
.\bitlocker-control-gui.ps1
```

A interface oferece:
- **Enable (Export Key)**
- **Disable (Prevent Auto)**
- **Test (Enable -> Disable)**
- **Status**
- **Open Logs**

A GUI executa as ações em background e escreve no console interno e no log em arquivo.

---

## Drive do sistema (detecção automática)

Os scripts detectam automaticamente o drive do sistema via:

- `Win32_OperatingSystem.SystemDrive` (preferencial)
- fallback: `$env:SystemDrive`
- fallback final: `C:`

Você não precisa informar manualmente o drive.

---

## Logs (arquivo)

Cada execução gera um log em:

```
C:\ProgramData\BitLocker-Control\logs\
```

Exemplos:
- `bitlocker-control-YYYY-MM-DD_HH-MM-SS.log`
- `bitlocker-control-gui-YYYY-MM-DD_HH-MM-SS.log`

---

## Recovery Key (chave de recuperação)

### O que acontece ao habilitar

Ao rodar **Enable**, o Windows gera uma **NOVA Recovery Key** (numérica).

### Export automático

O script exporta automaticamente a chave para:

```
C:\ProgramData\BitLocker-Recovery\recovery-key-YYYY-MM-DD_HH-MM-SS.txt
```

Esse arquivo contém:
- Informações do volume
- Key ID (GUID)
- Recovery Password (numérica)

### Boas práticas

- Trate o arquivo como **segredo sensível**
- Copie para um local seguro (vault / password manager / storage fora da VM)
- Em VMs, **não confie apenas** no disco da VM

---

## Fluxo de teste seguro (VM)

Se você quer apenas validar e não “travar” a VM:

- Use **Test (Enable -> Disable)**
- **Não reinicie** entre enable e disable

No CLI:

```powershell
.\bitlocker-control.ps1 -Mode test
```

---

## Verificação do estado

Em qualquer momento:

```powershell
manage-bde -status
```

Estados esperados:

- **Disabled**: `Protection Status: Off` e criptografia indo para `0%`
- **Enabled**: `Protection Status: On` e criptografia progredindo para `100%`

---

## Considerações de segurança

- **Enable** aumenta proteção de dados em repouso (recomendado para notebooks e produção).
- **Disable** remove proteção de dados em repouso (adequado para laboratório/VMs e ambientes onde isso atrapalha operação).

Se você precisa de compliance/segurança formal, não utilize o modo disable.

---

## Aviso

Uso por sua conta e risco. Nenhuma garantia é oferecida.

## Licença

MIT
