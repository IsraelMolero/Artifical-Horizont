import math

P0 = 101325.0
const_log = 8434.0
P_min = 20000.0
P_max = P0


with open("codigo_rom.txt", "w") as archivo:
    archivo.write("constant ALTURA_ROM : rom_type := (\n")
    for i in range(4096):
        P = P_min + (i / 4095.0) * (P_max - P_min)
        h = const_log * math.log(P0 / P)
        
        if i < 4095:
            archivo.write(f"    {i} => {int(h)},\n")
        else:
            archivo.write(f"    {i} => {int(h)}\n") 
            
    archivo.write(");\n")

