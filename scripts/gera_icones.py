"""Gera os ícones do app sem depender de PIL ou ImageMagick.

Desenha em memória com supersampling 4x e grava PNG com zlib puro. O motivo de
ser à mão é chato mas simples: este ambiente não tem nenhuma biblioteca de
imagem, e sem ícone o "adicionar à tela de início" põe um quadrado em branco.

O desenho é o cofre: um disco com o mostrador e quatro raios, sobre o azul do
app. Mesma ideia da tela inicial, legível a 48 px.
"""
import math, struct, zlib, pathlib

AZUL = (0x2E, 0x90, 0xFA)
BRANCO = (0xFF, 0xFF, 0xFF)
SS = 4  # supersampling


def mistura(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def desenhar(lado, margem, cantos):
    """margem: fração livre em volta do desenho. cantos: raio, em fração."""
    n = lado * SS
    acc = [[(0.0, 0.0, 0.0, 0.0)] * lado for _ in range(lado)]
    r_canto = cantos * n
    cx = cy = n / 2
    raio_disco = n * (0.5 - margem) * 0.78
    grossura = raio_disco * 0.20

    soma = [[[0.0, 0.0, 0.0, 0.0] for _ in range(lado)] for _ in range(lado)]
    for sy in range(n):
        for sx in range(n):
            # fundo: quadrado de cantos arredondados
            dx = max(r_canto - sx, sx - (n - r_canto), 0)
            dy = max(r_canto - sy, sy - (n - r_canto), 0)
            dentro = math.hypot(dx, dy) <= r_canto
            if not dentro:
                continue
            cor, alfa = AZUL, 1.0

            d = math.hypot(sx - cx, sy - cy)
            # anel externo do cofre
            if abs(d - raio_disco) <= grossura / 2:
                cor = BRANCO
            # miolo
            elif d <= raio_disco * 0.30:
                cor = BRANCO
            else:
                # quatro raios do mostrador, nas diagonais
                ang = math.atan2(sy - cy, sx - cx)
                for k in range(4):
                    alvo = -math.pi * 3 / 4 + k * math.pi / 2
                    dif = abs((ang - alvo + math.pi) % (2 * math.pi) - math.pi)
                    if dif < 0.13 and raio_disco * 0.42 <= d <= raio_disco * 1.16:
                        cor = BRANCO
                        break

            px, py = sx // SS, sy // SS
            cel = soma[py][px]
            cel[0] += cor[0]; cel[1] += cor[1]; cel[2] += cor[2]; cel[3] += alfa * 255

    for y in range(lado):
        for x in range(lado):
            r, g, b, a = soma[y][x]
            q = SS * SS
            acc[y][x] = (round(r / q), round(g / q), round(b / q), round(a / q))
    return acc


def gravar_png(caminho, pix):
    lado = len(pix)
    cru = b''.join(
        b'\x00' + b''.join(struct.pack('4B', *pix[y][x]) for x in range(lado))
        for y in range(lado))

    def bloco(tipo, dados):
        c = struct.pack('>I', len(dados)) + tipo + dados
        return c + struct.pack('>I', zlib.crc32(tipo + dados) & 0xffffffff)

    png = (b'\x89PNG\r\n\x1a\n'
           + bloco(b'IHDR', struct.pack('>IIBBBBB', lado, lado, 8, 6, 0, 0, 0))
           + bloco(b'IDAT', zlib.compress(cru, 9))
           + bloco(b'IEND', b''))
    pathlib.Path(caminho).write_bytes(png)
    return len(png)


# Normal: desenho cheio. Maskable: o Android recorta em círculo, então o
# desenho encolhe para caber na zona segura (80% central) e o azul sangra até
# a borda — por isso cantos=0.5 (sem canto) na versão maskable.
alvos = [
    ('web/icons/Icon-192.png', 192, 0.06, 0.22),
    ('web/icons/Icon-512.png', 512, 0.06, 0.22),
    ('web/icons/Icon-maskable-192.png', 192, 0.20, 0.5),
    ('web/icons/Icon-maskable-512.png', 512, 0.20, 0.5),
    ('web/icons/apple-touch-icon.png', 180, 0.04, 0.001),
    ('web/favicon.png', 64, 0.04, 0.22),
]
for caminho, lado, margem, canto in alvos:
    n = gravar_png(caminho, desenhar(lado, margem, canto))
    print(f'  {caminho}  {lado}x{lado}  {n/1024:.1f} KB')
