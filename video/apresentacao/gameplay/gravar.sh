#!/usr/bin/env bash
# Grava a gameplay real usada no vídeo, com o piloto automático (diretor.gd).
#
# Uso:  GODOT=/caminho/para/godot ./gameplay/gravar.sh
# Requer: Godot 4.7.x, FFmpeg e, em servidor sem tela, xvfb-run.
#
# O jogo é copiado para uma pasta temporária e só a cópia recebe o piloto como
# autoload; o projeto do repositório não é alterado. Os clipes saem em
# midia/gameplay/*.mp4 (1920x1080, 60 fps, com o áudio do jogo).
set -euo pipefail

AQUI="$(cd "$(dirname "$0")" && pwd)"
VIDEO="$(cd "$AQUI/.." && pwd)"
RAIZ="$(cd "$VIDEO/../.." && pwd)"
GODOT="${GODOT:?defina GODOT com o caminho do executável do Godot 4.7}"
SAIDA="$VIDEO/midia/gameplay"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$SAIDA"
echo "Copiando o jogo para $TMP/jogo"
mkdir -p "$TMP/jogo"
tar -C "$RAIZ" --exclude=./.git --exclude=./video -cf - . | tar -C "$TMP/jogo" -xf -
cp "$AQUI/diretor.gd" "$TMP/jogo/diretor.gd"

# autoload do piloto, janela em 1920x1080 e MJPEG de alta qualidade (só na cópia)
python3 - "$TMP/jogo/project.godot" <<'EOF'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s = s.replace('[autoload]\n', '[autoload]\n\nDiretor="*res://diretor.gd"\n', 1)
s = s.replace('window/stretch/mode="canvas_items"',
              'window/stretch/mode="canvas_items"\nwindow/size/window_width_override=1920\nwindow/size/window_height_override=1080')
s += '\n[editor]\n\nmovie_writer/mjpeg_quality=0.95\n'
open(p, "w", encoding="utf-8").write(s)
EOF

echo "Importando recursos"
"$GODOT" --headless --path "$TMP/jogo" --import >/dev/null 2>&1 || true

RODAR=("$GODOT")
if [ -z "${DISPLAY:-}" ]; then
  RODAR=(xvfb-run -a -s "-screen 0 1920x1080x24" "$GODOT")
fi

# nome | cena | roteiro | segundos gravados | início do corte | fim do corte
CLIPES=(
  "menu|res://scenes/menu/menu.tscn||5|0|5"
  "fase1|res://scenes/fase1_tokens/Main.tscn|fase1.json|7.6|0.5|7.6"
  "fase2|res://scenes/fase2_scanner/main.tscn|fase2.json|9.5|1.3|9.3"
  "fase4|res://scenes/fase4_ast/Main.tscn|fase4.json|14.5|1.2|13.9"
  "fase5|res://scenes/fase5_erroLexico/niveis/nivel1.tscn|fase5.json|7.5|0.5|7.4"
)

for linha in "${CLIPES[@]}"; do
  IFS='|' read -r nome cena roteiro segundos ini fim <<<"$linha"
  echo "Gravando $nome"
  plano=""
  [ -n "$roteiro" ] && plano="$AQUI/roteiros/$roteiro"
  quadros=$(python3 -c "print(int($segundos * 60))")
  DIRETOR_PLANO="$plano" "${RODAR[@]}" --path "$TMP/jogo" --rendering-driver opengl3 \
    --fixed-fps 60 --write-movie "$TMP/$nome.avi" --quit-after "$quadros" "$cena" >"$TMP/$nome.log" 2>&1
  ffmpeg -v error -y -ss "$ini" -to "$fim" -i "$TMP/$nome.avi" \
    -c:v libx264 -preset slow -crf 17 -pix_fmt yuv420p -r 60 -g 30 -keyint_min 30 \
    -c:a aac -b:a 192k -ar 48000 -movflags +faststart "$SAIDA/$nome.mp4"
done

echo "Clipes prontos em $SAIDA"
