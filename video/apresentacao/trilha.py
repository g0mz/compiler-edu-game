"""Trilha chiptune original do vídeo (60 s, 120 BPM), sintetizada em código.

Gera midia/trilha.wav. Só usa a biblioteca padrão do Python, e o resultado é
determinístico: o ruído da bateria vem de um gerador com semente fixa.

Seções (em segundos), alinhadas com as cenas do vídeo:
  0–4,5   abertura: arpejo e chimbal
  4,5–8   mundos: entram baixo e bumbo
  8–46,4  gameplay: groove completo com melodia
  46,4–50,4 "em breve": só baixo e chimbal
  50,4–60 final: groove completo e acorde final
"""
import array
import math
import os
import random
import wave

SR = 44100
BPM = 120
BEAT = 60 / BPM
DUR = 60.0
N = int(SR * DUR)
mix = array.array("f", bytes(4 * N))
rng = random.Random(2024)


def hz(nota):
    return 440.0 * 2 ** ((nota - 69) / 12)


def nivel(t):
    """Quanto de cada camada toca em cada momento do vídeo."""
    if t < 4.5:
        return {"arp": 1, "hat": 0.6, "baixo": 0, "bumbo": 0, "caixa": 0, "melodia": 0}
    if t < 8.0:
        return {"arp": 1, "hat": 1, "baixo": 1, "bumbo": 1, "caixa": 0, "melodia": 0}
    if 46.4 <= t < 50.4:
        return {"arp": 0.5, "hat": 1, "baixo": 1, "bumbo": 0, "caixa": 0, "melodia": 0}
    if t >= 58.5:
        return {"arp": 0, "hat": 0, "baixo": 0, "bumbo": 0, "caixa": 0, "melodia": 0}
    return {"arp": 1, "hat": 1, "baixo": 1, "bumbo": 1, "caixa": 1, "melodia": 1}


def tom(t0, dur, freq, vol, forma="pulso", duty=0.25, ataque=0.004, queda=None):
    """Soma uma nota na mixagem com envelope ataque/queda exponencial."""
    i0 = int(t0 * SR)
    n = int(dur * SR)
    queda = queda or dur
    for k in range(n):
        i = i0 + k
        if i >= N:
            break
        t = k / SR
        fase = (t * freq) % 1.0
        if forma == "pulso":
            v = 1.0 if fase < duty else -1.0
        else:  # triângulo
            v = 4 * abs(fase - 0.5) - 1
        env = min(1.0, t / ataque) * math.exp(-3.0 * t / queda)
        mix[i] += v * vol * env


def ruido(t0, dur, vol, brilho=0.0):
    i0 = int(t0 * SR)
    n = int(dur * SR)
    anterior = 0.0
    for k in range(n):
        i = i0 + k
        if i >= N:
            break
        x = rng.uniform(-1, 1)
        v = x - brilho * anterior  # brilho > 0 realça agudos (chimbal)
        anterior = x
        mix[i] += v * vol * math.exp(-k / (n / 4))


def bumbo(t0, vol):
    i0 = int(t0 * SR)
    fase = 0.0
    for k in range(int(0.16 * SR)):
        i = i0 + k
        if i >= N:
            break
        t = k / SR
        f = 50 + 110 * math.exp(-t * 30)
        fase += f / SR
        mix[i] += math.sin(2 * math.pi * fase) * vol * math.exp(-t * 18)


# Am – F – C – G (um compasso de 4 tempos cada)
ACORDES = [(57, [57, 60, 64]), (53, [53, 57, 60]), (48, [48, 52, 55]), (55, [55, 59, 62])]
MELODIA = [  # (tempo dentro da frase de 16 tempos, nota MIDI, duração em tempos)
    (0, 76, .5), (.5, 79, .5), (1, 81, 1), (2, 79, .5), (2.5, 76, .5), (3, 74, 1),
    (4, 72, .5), (4.5, 74, .5), (5, 77, 1), (6, 76, .5), (6.5, 74, .5), (7, 72, 1),
    (8, 76, .5), (8.5, 79, .5), (9, 84, 1), (10, 83, .5), (10.5, 79, .5), (11, 76, 1),
    (12, 74, .5), (12.5, 76, .5), (13, 79, 1.5), (14.5, 74, .5), (15, 71, 1),
]

total_tempos = int(DUR / BEAT)
for b in range(total_tempos):
    t = b * BEAT
    compasso = b // 4
    raiz, triade = ACORDES[compasso % 4]
    nv = nivel(t)
    # baixo em colcheias: raiz grave e oitava
    if nv["baixo"]:
        for s, nota in enumerate([raiz - 12, raiz]):
            tom(t + s * BEAT / 2, BEAT / 2 * 0.9, hz(nota), 0.30 * nv["baixo"], forma="tri")
    # arpejo em semicolcheias
    if nv["arp"]:
        notas = triade + [triade[0] + 12]
        for s in range(4):
            tom(t + s * BEAT / 4, BEAT / 4 * 0.8, hz(notas[(b * 4 + s) % 4] + 12),
                0.07 * nv["arp"], duty=0.125, queda=0.12)
    # bateria
    if nv["bumbo"] and b % 2 == 0:
        bumbo(t, 0.55)
    if nv["bumbo"] and b % 4 == 3:
        bumbo(t + BEAT / 2, 0.4)
    if nv["caixa"] and b % 2 == 1:
        ruido(t, 0.14, 0.22)
    if nv["hat"]:
        for s in range(2):
            ruido(t + s * BEAT / 2, 0.035, 0.07 * nv["hat"], brilho=0.95)

# melodia: frases de 16 tempos a partir do início do gameplay
inicio_melodia = 8.0
for frase in range(10):
    base = inicio_melodia + frase * 16 * BEAT
    for (tb, nota, d) in MELODIA:
        t = base + tb * BEAT
        if nivel(t)["melodia"]:
            tom(t, d * BEAT * 0.92, hz(nota), 0.13, duty=0.25, queda=d * BEAT * 1.5)

# acorde final (Am em oitavas) a partir de 58,5 s
for nota in [57, 64, 69, 72, 76]:
    tom(58.5, 1.5, hz(nota), 0.09, duty=0.25, queda=1.2)
bumbo(58.5, 0.6)
ruido(58.5, 0.4, 0.2)

# fade-in curto e normalização para -1 dBFS
pico = max(abs(v) for v in mix) or 1.0
alvo = 10 ** (-1 / 20) / pico
saida = array.array("h", bytes(2 * N))
for i, v in enumerate(mix):
    fade = min(1.0, i / (0.3 * SR))
    saida[i] = int(max(-1.0, min(1.0, v * alvo * fade)) * 32767)

destino = os.path.join(os.path.dirname(os.path.abspath(__file__)), "midia", "trilha.wav")
os.makedirs(os.path.dirname(destino), exist_ok=True)
with wave.open(destino, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(saida.tobytes())
print("trilha:", destino)
