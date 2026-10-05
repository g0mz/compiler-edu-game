// Copia para ./midia as imagens e sons do jogo usados no vídeo.
// Sprites com muita margem transparente são recortados, e imagens grandes são
// reduzidas para o tamanho em que aparecem no vídeo (render mais leve).
// A pasta ./midia é gerada e fica fora do git: a fonte da verdade é ../../assets.
import { mkdir, copyFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import sharp from "sharp";

const aqui = dirname(fileURLToPath(import.meta.url));
const raiz = join(aqui, "..", "..");
const saida = join(aqui, "midia");

// [origem relativa à raiz do repo, destino em ./midia, largura máxima, recortar margem transparente]
const imagens = [
  ["assets/fase1_tokens/reino_tokens_background.png", "card-fase1.png", 760, false],
  ["assets/fase2_scanner/vale_scanner_background.png", "card-fase2.png", 760, false],
  ["assets/menu/fase4_ast_card.png", "card-fase4.png", 760, false],
  ["assets/menu/fase5_erroLexico.png", "card-fase5.png", 760, true],
  ["assets/fase1_tokens/Background.png", "fundo-reino.png", 1100, false],
  ["assets/fase2_scanner/fundocenario.png", "fundo-vale.png", 1100, false],
  ["assets/fase4_ast/forest_ast_background.png", "fundo-floresta.png", 1100, false],
  ["assets/fase5_erroLexico/Nivel1.png", "fundo-castelo.png", 1100, false],
  ["assets/fase1_tokens/Player1.png", "jogador-parado.png", 520, true],
  ["assets/fase1_tokens/Player2.png", "jogador-andando.png", 520, true],
  ["assets/fase1_tokens/Player3.png", "jogador-pulando.png", 520, true],
  ["assets/fase1_tokens/PlayerCarry.png", "jogador-carregando.png", 520, true],
  ["assets/fase5_erroLexico/MonstroInvalido.png", "monstro-invalido.png", 420, true],
  ["assets/fase5_erroLexico/MonstroInvalidoDerrotado.png", "monstro-derrotado.png", 420, true],
  ["assets/fase5_erroLexico/MonstroValido.png", "monstro-valido.png", 420, true],
  ["assets/fase5_erroLexico/Coracao.png", "coracao.png", 160, true],
];

const sons = [
  ["assets/audio/confirmation_002.ogg", "acerto.ogg"],
  ["assets/audio/error_003.ogg", "erro.ogg"],
  ["assets/audio/jump_0.wav", "pulo.wav"],
  ["assets/audio/lift.wav", "pop.wav"],
  ["assets/audio/portal_beep.mp3", "portal.mp3"],
  ["assets/audio/phase4_forest_at_night.wav", "floresta.wav"],
];

await mkdir(saida, { recursive: true });

for (const [origem, destino, largura, recortar] of imagens) {
  let img = sharp(join(raiz, origem)).ensureAlpha();
  if (recortar) {
    // threshold alto: alguns PNGs têm pixels quase transparentes espalhados pela borda
    img = sharp(await img.trim({ threshold: 40 }).toBuffer());
  }
  await img
    .resize({ width: largura, withoutEnlargement: true })
    .png()
    .toFile(join(saida, destino));
}

for (const [origem, destino] of sons) {
  await copyFile(join(raiz, origem), join(saida, destino));
}

console.log(`midia/: ${imagens.length} imagens e ${sons.length} sons prontos`);
