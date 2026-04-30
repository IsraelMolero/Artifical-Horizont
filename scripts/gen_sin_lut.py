import math

# Generacion de los valores de la lut usada en
# sin_cos_lut.vhd

def generate_sin_lut():
    lut = []
    # de o a 90 grados
    for i in range(65):
        angle_rad = math.radians(i * (360 / 256))
        value = round(math.sin(angle_rad) * 256)
        lut.append(value)
        print(i, i * (360 / 256), value)
    return lut

sin_values = generate_sin_lut()

for i, val in enumerate(sin_values):
    print(f'x"{val:04x}"', end=", " if (i + 1) % 8 != 0 else ",\n")
