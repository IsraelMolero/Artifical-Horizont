import math

par_p1 = 36000.0  
par_p2 = -10000.0
par_p3 = 88.0     
par_p4 = 6000.0   
par_p5 = 10.0     
par_p6 = 30.0     
par_p7 = 20.0     
par_p8 = -2000.0  
par_p9 = -50.0    
par_p10 = 30.0    

#128000.0 = 25ºC de temperatura ambiente.
t_fine = 128000.0

P0 = 101325.0
const_log = 8434.0

print("Generando ROM con la fórmula oficial de Bosch. Por favor espera...")

with open("bme680_rom_altura.txt", "w") as archivo:
    archivo.write("constant ALTURA_ROM : rom_type := (\n")
    
    for i in range(4096):
        press_adc = float(i * 256)
        
        var1 = (t_fine / 2.0) - 64000.0
        var2 = var1 * var1 * (par_p6 / 131072.0)
        var2 = var2 + (var1 * par_p5 * 2.0)
        var2 = (var2 / 4.0) + (par_p4 * 65536.0)
        var1 = (((par_p3 * var1 * var1) / 16384.0) + (par_p2 * var1)) / 524288.0
        var1 = (1.0 + (var1 / 32768.0)) * par_p1
        
        press_comp = 1048576.0 - press_adc
        
        if var1 != 0:
            press_comp = ((press_comp - (var2 / 4096.0)) * 6250.0) / var1
            var1_f = (par_p9 * press_comp * press_comp) / 2147483648.0
            var2_f = press_comp * (par_p8 / 32768.0)
            var3_f = (press_comp / 256.0) * (press_comp / 256.0) * (press_comp / 256.0) * (par_p10 / 131072.0)
            
            press_comp = press_comp + (var1_f + var2_f + var3_f + (par_p7 * 128.0)) / 16.0
        else:
            press_comp = 0.1 
            
        if press_comp > 1000 and press_comp < 120000:
            h = const_log * math.log(P0 / press_comp)
        else:
            h = 0 
            
        
        h = max(0, min(65535, int(h)))
        
       
        if i < 4095:
            archivo.write(f"    {i} => {h},\n")
        else:
            archivo.write(f"    {i} => {h}\n")
            
    archivo.write(");\n")