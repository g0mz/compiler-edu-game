// Copia para ./midia as imagens e sons do jogo usados no vídeo.
// (Os clipes de gameplay ficam em ./midia/gameplay, gerados por gameplay/gravar.sh.)
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
  ["assets/fase1_tokens/Player3.png", "jogador-pulando.png", 520, true],
];

const sons = [
  ["assets/audio/confirmation_002.ogg", "acerto.ogg"],
  ["assets/audio/jump_0.wav", "pulo.wav"],
  ["assets/audio/portal_beep.mp3", "portal.mp3"],
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
