TODO LIST:

IMU 9 grados BNO055:
- Controlador I2C, máquina de estados con todos los casos
- Extracción datos tramas y guardado en registros

Representación gráfica:
- Dibujado vídeo buffer en BRAM en base a registros
    - Algoritmo CORDIC (difícil) o LUT con senos y cosenos (fácil)
    - Uso de coma fija en lugar de floats

Controlador VGA:
- Implementación VGA, doble buffer, hsync, vsync, etc.

Altímetro:
- Seleccionar sensor de presión analógico
- ADC
- Conversión valor ADC a presión atmosférica
- Conversión presión a altura
- Representación en display de 7 segmentos



