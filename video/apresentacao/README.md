# Vídeo de apresentação

Vídeo vertical (1080×1920, 60 fps, 64 s) que apresenta o Compiler Edu Game, seus seis mundos e o objetivo de cada fase. Ele é feito com [HyperFrames](https://hyperframes.heygen.com): `index.html` é uma página animada com GSAP, e o HyperFrames captura cada quadro no Chrome e monta o MP4 com FFmpeg.

## Como gerar

Requisitos: Node.js 22+ e FFmpeg.

```bash
cd video/apresentacao
npm install
npm run render            # renders/apresentacao.mp4 (60 fps, qualidade alta, ~4 min)
npm run render:rascunho   # renders/rascunho.mp4 (30 fps, rápido, para conferir)
npm run check             # lint, layout, contraste
```

Cada comando roda antes `npm run assets`, que copia as imagens e sons usados de `../../assets` para `midia/`, recortando e reduzindo os sprites. As pastas `midia/`, `renders/` e `node_modules/` são geradas e ficam fora do git. A pasta `video/` tem um `.gdignore` para o Godot não importar nada daqui.

## Identidade visual

- **Estilo:** "Pop Bold", com cores chapadas, contorno preto de 6 px, sombra dura e animações com overshoot.
- **Cores:** as do menu do jogo (`scripts/menu/menu.gd`) e as dos tipos de token do Vale do Scanner (`scripts/fase2_scanner/scanner_data.gd`).
- **Fontes pixeladas** (OFL, instaladas via npm):
  - Press Start 2P no logo;
  - Silkscreen em títulos e rótulos;
  - Jersey 10 no texto corrido;
  - VT323 no código.

  A Press Start 2P fica só no logo porque desenha o acento agudo com um único pixel, que some com o contorno.
- **Sons:** os efeitos do próprio jogo (`assets/audio`), apenas nos momentos que importam. A trilha da fase 4 toca como ambiente na cena da Floresta da AST.

## Roteiro

| Tempo | Cena |
|---|---|
| 0–5 s | Logo e "Aprenda compiladores jogando!" |
| 5–10 s | "Você foi parar dentro de um compilador!" |
| 10–16,5 s | Os 6 mundos |
| 16,5–24,5 s | Fase 1, Reino dos Tokens: coletar só as palavras-chave |
| 24,5–32,5 s | Fase 2, Vale do Scanner: `int x = 10;` vira tokens na ordem certa |
| 32,5–36,5 s | Fase 3, Caverna do Parser (em breve) |
| 36,5–44,5 s | Fase 4, Floresta da AST: a árvore de `a + b * c` |
| 44,5–52,5 s | Fase 5, Castelo dos Erros Léxicos: o `@` vira monstro e é derrotado |
| 52,5–56,5 s | Fase 6, Fortaleza Sintática (em breve) |
| 56,5–64 s | Público, logo e créditos (AEX, Ciência da Computação, UENP) |

## Editando

- Os tempos de cada cena estão no `data-start`/`data-duration` das `<section>`.
- As animações estão na linha do tempo no fim de `index.html`, em segundos absolutos.
- Os sons são os `<audio>` antes do script.

Quando as fases 3 e 6 ficarem prontas, troque o cadeado e o selo "EM BREVE" pelo card da fase, como nas outras.
