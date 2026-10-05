# Vídeo de apresentação

Vídeo vertical (1080×1920, 60 fps, 60 s) que apresenta o Compiler Edu Game com **gameplay real** das quatro fases jogáveis. Ele é feito com [HyperFrames](https://hyperframes.heygen.com): `index.html` é uma página animada com GSAP, e o HyperFrames captura cada quadro no Chrome e monta o MP4 com FFmpeg.

## Como gerar

Requisitos: Node.js 22+, FFmpeg, Python 3 e, para gravar a gameplay, Godot 4.7.x (em servidor sem tela, também `xvfb-run`).

```bash
cd video/apresentacao
npm install
GODOT=/caminho/do/godot npm run gameplay   # grava midia/gameplay/*.mp4 (~5 min)
npm run render                             # renders/apresentacao.mp4 (60 fps, ~10 min)
npm run render:rascunho                    # 30 fps, rápido, para conferir
npm run check                              # lint, layout, contraste
```

Antes do check e do render, `npm run assets` roda dois passos:
- copia imagens e sons de `../../assets` para `midia/`;
- sintetiza a trilha em `midia/trilha.wav`.

As pastas `midia/`, `renders/` e `node_modules/` são geradas e ficam fora do git. A pasta `video/` tem um `.gdignore`, para o Godot não importar nada daqui.

## Gameplay real

Os clipes são gravados pelo próprio Godot no modo Movie Maker, com um piloto automático que joga cada fase. O piloto é o `gameplay/diretor.gd`, e cada fase segue um roteiro em `gameplay/roteiros/*.json`, com passos como "segurar direita até x ≥ 400", "pular", "apertar E" e "clicar em COMEÇAR".

`gameplay/gravar.sh` faz o processo inteiro:
1. copia o jogo para uma pasta temporária;
2. registra o piloto como autoload só nessa cópia;
3. grava cada fase em 1920×1080 a 60 fps, com o áudio do jogo;
4. recorta e converte os clipes para `midia/gameplay/`.

O projeto do repositório não é alterado.

Na gravação, o piloto faz dois ajustes que valem registrar:
- A fase 4 sorteia a expressão e a ordem dos tokens. O roteiro fixa `a + b * c` e a ordem `a`, `+`, `*`, `b`, `c`.
- A fase 5 começa direto no nível 1, sem a tela de introdução.

Todo o resto é a fase rodando normalmente: física, pontuação, combos, sons e telas de conclusão.

**Se uma fase mudar** (plataformas, posições, velocidade), o roteiro dela pode precisar de ajuste. Depois de regravar, confira a câmera: o `PAN` em `index.html` foi calculado a partir da posição do jogador em cada clipe.

## Identidade visual

- **Estilo:** "Pop Bold", com cores chapadas, contorno preto, sombra dura e animações com overshoot.
- **Cores:** as do menu do jogo (`scripts/menu/menu.gd`) e as dos tipos de token (`scripts/fase2_scanner/scanner_data.gd`).
- **Fontes pixeladas** (OFL, instaladas via npm):
  - Press Start 2P no logo;
  - Silkscreen em títulos e rótulos;
  - Jersey 10 no texto corrido;
  - VT323 nos tokens de código.

  A Press Start 2P fica só no logo porque desenha o acento agudo com um único pixel, que some com o contorno.
- **Som:**
  - o áudio original das fases;
  - uma trilha chiptune original (`trilha.py`, 120 BPM, Am–F–C–G), mais baixa por baixo da gameplay;
  - na fase 5, que não tem efeitos sonoros no jogo, os sons de pulo e acerto de `assets/audio`, sincronizados com a gravação.

## Roteiro

| Tempo | Cena |
|---|---|
| 0–4,5 s | Logo sobre o menu do jogo e "Aprenda compiladores jogando!" |
| 4,5–8 s | Os 6 mundos: 4 jogáveis, 2 em breve |
| 8–16 s | Fase 1, Reino dos Tokens: gameplay coletando `int` e `=` (combo) |
| 16–25 s | Fase 2, Vale do Scanner: pega o bloco `int` e encaixa na ponte |
| 25–38,6 s | Fase 4, Floresta da AST: monta a árvore de `a + b * c` até a conclusão |
| 38,6–46,4 s | Fase 5, Castelo Léxico: elimina `#` e `@`, pula `idade` e vai ao nível 2 |
| 46,4–50,4 s | Em breve: Caverna do Parser e Fortaleza Sintática |
| 50,4–60 s | Público, logo, mosaico de gameplay e créditos (AEX, Ciência da Computação, UENP) |

Os tempos das cenas estão no `data-start`/`data-duration` das `<section>`. As animações e os destaques ficam na linha do tempo no fim de `index.html`, em segundos absolutos.
