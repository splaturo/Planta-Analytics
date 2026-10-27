# Diccionario de datos — `planta_analytics`

Base de datos de una planta manufacturera ficticia (datos sintéticos) con cinco líneas de producción y un área de soporte de TI.
Periodo de producción: **2025-10-01 a 2026-09-30**. Moneda: **USD**. Tiempos de producción en **minutos**; tiempos de tickets en **horas**.

## 1. Resumen del modelo

| Tabla                       | Tipo       | Qué representa                        | Grano (una fila =)                                   |
| --------------------------- | ---------- | -------------------------------------- | ---------------------------------------------------- |
| `dim_producto`            | Dimensión | Catálogo de productos que se fabrican | un producto                                          |
| `dim_linea`               | Dimensión | Líneas de producción de la planta    | una línea                                           |
| `dim_turno`               | Dimensión | Turnos de trabajo                      | un turno                                             |
| `dim_proveedor`           | Dimensión | Proveedores de materiales              | un proveedor                                         |
| `dim_fecha`               | Dimensión | Calendario                             | un día                                              |
| `fact_produccion`         | Hecho      | Resultado de producción               | un turno de una línea en un día                    |
| `fact_defectos`           | Hecho      | Defectos detectados                    | un tipo de defecto dentro de un turno de producción |
| `fact_paros`              | Hecho      | Paros de línea                        | un evento de paro dentro de un turno de producción  |
| `fact_entregas_proveedor` | Hecho      | Órdenes de compra y su entrega        | una orden de compra                                  |
| `fact_tickets_ti`         | Hecho      | Tickets de soporte de TI               | un ticket                                            |

### Relaciones

| Tabla (muchos)              | Columna                                                                    | → Tabla (uno)      | Columna           | Dónde se define |
| --------------------------- | -------------------------------------------------------------------------- | ------------------- | ----------------- | ---------------- |
| `dim_linea`               | `id_producto`                                                            | `dim_producto`    | `id_producto`   | MySQL            |
| `fact_produccion`         | `id_linea`                                                               | `dim_linea`       | `id_linea`      | MySQL            |
| `fact_produccion`         | `id_turno`                                                               | `dim_turno`       | `id_turno`      | MySQL            |
| `fact_produccion`         | `id_producto`                                                            | `dim_producto`    | `id_producto`   | MySQL            |
| `fact_defectos`           | `id_produccion`                                                          | `fact_produccion` | `id_produccion` | MySQL            |
| `fact_paros`              | `id_produccion`                                                          | `fact_produccion` | `id_produccion` | MySQL            |
| `fact_paros`              | `id_linea`                                                               | `dim_linea`       | `id_linea`      | MySQL            |
| `fact_paros`              | `id_turno`                                                               | `dim_turno`       | `id_turno`      | MySQL            |
| `fact_entregas_proveedor` | `id_proveedor`                                                           | `dim_proveedor`   | `id_proveedor`  | MySQL            |
| `fact_produccion`         | `fecha`                                                                  | `dim_fecha`       | `fecha`         | Power BI         |
| `fact_paros`              | `fecha`                                                                  | `dim_fecha`       | `fecha`         | Power BI         |
| `fact_entregas_proveedor` | `fecha_prometida` (activa), `fecha_oc` y `fecha_entrega` (inactivas) | `dim_fecha`       | `fecha`         | Power BI         |
| `fact_tickets_ti`         | `fecha_creacion`                                                         | `dim_fecha`       | `fecha`         | Power BI         |

`fact_tickets_ti` no se relaciona con ninguna otra dimensión: sus atributos (categoría, prioridad, área, canal, técnico) son texto dentro de la propia tabla.

## 2. Dimensiones

### `dim_producto` — productos fabricados (5 filas)

| Columna                    | Tipo     | Descripción                                                                                                               | Ejemplo / valores                  |
| -------------------------- | -------- | -------------------------------------------------------------------------------------------------------------------------- | ---------------------------------- |
| `id_producto`            | INT (PK) | Identificador del producto                                                                                                 | 1                                  |
| `producto`               | VARCHAR  | Nombre comercial del producto                                                                                              | Pantalla 32", Refrigerador 14 pies |
| `familia`                | VARCHAR  | Familia de producto                                                                                                        | Electrónica, Línea blanca        |
| `tiempo_ciclo_ideal_seg` | INT      | Segundos que toma fabricar **una** unidad a velocidad ideal (sin paros ni lentitud). Base del cálculo de desempeño | 45                                 |
| `precio_unitario_usd`    | DECIMAL  | Precio de venta por unidad en USD                                                                                          | 140.00                             |

Productos: Pantalla 32" (45 s, $140), Pantalla 55" (70 s, $380), Refrigerador 14 pies (110 s, $520), Aire acondicionado mini split (95 s, $430), Lavadora 19 kg (100 s, $450).

### `dim_linea` — líneas de producción (5 filas)

| Columna         | Tipo     | Descripción                                                         | Ejemplo / valores    |
| --------------- | -------- | -------------------------------------------------------------------- | -------------------- |
| `id_linea`    | INT (PK) | Identificador de la línea                                           | 1                    |
| `linea`       | VARCHAR  | Nombre de la línea                                                  | Línea 1 … Línea 5 |
| `id_producto` | INT (FK) | Producto que fabrica la línea. Cada línea fabrica un solo producto | 1                    |

### `dim_turno` — turnos (3 filas)

| Columna              | Tipo     | Descripción                              | Ejemplo / valores              |
| -------------------- | -------- | ----------------------------------------- | ------------------------------ |
| `id_turno`         | INT (PK) | Identificador del turno                   | 1                              |
| `turno`            | VARCHAR  | Nombre del turno                          | Matutino, Vespertino, Nocturno |
| `horario`          | VARCHAR  | Horario original en texto, `inicio-fin` | 06:00-14:00                    |
| `hora_inicio`     | TIME     | Hora de inicio extraída de `horario`   | 06:00:00                       |
| `hora_fin`        | TIME     | Hora de fin extraída de `horario`      | 14:00:00                       |
| `duracion_horas`  | DECIMAL  | Duración del turno en horas.            | 8.0                            |

### `dim_proveedor` — proveedores (12 filas)

| Columna                | Tipo     | Descripción                    | Ejemplo / valores                                  |
| ---------------------- | -------- | ------------------------------- | -------------------------------------------------- |
| `id_proveedor`       | INT (PK) | Identificador del proveedor     | 1                                                  |
| `proveedor`          | VARCHAR  | Nombre del proveedor            | Paneles Orión                                     |
| `categoria_material` | VARCHAR  | Tipo de material que suministra | Paneles LCD, Compresores, Motores, Vidrio templado |
| `pais`               | VARCHAR  | País de origen del proveedor   | México, Corea, EE.UU., Taiwán, China             |

### `dim_fecha` — calendario  (1 fila por día)

Generada por el pipeline: cubre desde el primer día del mes de la fecha más antigua hasta el último día del mes de la más reciente que aparezca en cualquier hecho. Sin huecos.

| Columna            | Tipo       | Descripción                                                              | Ejemplo / valores |
| ------------------ | ---------- | ------------------------------------------------------------------------- | ----------------- |
| `fecha`          | DATE (PK)  | Día                                                                      | 2025-10-01        |
| `anio`           | SMALLINT   | Año                                                                      | 2025              |
| `mes_num`        | TINYINT    | Número de mes (1-12)                                                     | 10                |
| `mes`            | VARCHAR    | Nombre del mes en español, en minúsculas                                | octubre           |
| `anio_mes`       | CHAR(7)    | Año y mes, ordenable                                                     | 2025-10           |
| `trimestre`      | CHAR(2)    | Trimestre calendario                                                      | T1, T2, T3, T4    |
| `semana_iso`     | TINYINT    | Semana ISO del año (1-53)                                                | 40                |
| `dia_semana_num` | TINYINT    | Día de la semana, 1 = lunes … 7 = domingo                               | 3                 |
| `dia_semana`     | VARCHAR    | Nombre del día en español                                               | miércoles        |
| `es_laboral`     | TINYINT(1) | 1 = día laboral, 0 = domingo. Solo marca domingos: no considera feriados | 1                 |

---

## 3. Hechos

### `fact_produccion` — producción por turno y línea (4,695 filas)

Una fila por combinación única de `fecha`, `id_linea` e `id_turno`. Es el hecho central: defectos y paros se cuelgan de aquí.

| Columna                    | Tipo     | Descripción                                                                                               | Ejemplo / valores |
| -------------------------- | -------- | ---------------------------------------------------------------------------------------------------------- | ----------------- |
| `id_produccion`          | INT (PK) | Identificador del turno de producción                                                                     | 1                 |
| `fecha`                  | DATE     | Día en que ocurrió la producción (inicio del turno)                                                     | 2025-10-01        |
| `id_linea`               | INT (FK) | Línea que produjo                                                                                         | 1                 |
| `id_turno`               | INT (FK) | Turno en que se produjo                                                                                    | 1                 |
| `id_producto`            | INT (FK) | Producto fabricado en ese turno                                                                            | 1                 |
| `tiempo_planificado_min` | SMALLINT | Minutos que la línea estaba programada para producir en el turno. En los datos es constante: 450          | 450               |
| `tiempo_paro_min`        | SMALLINT | Minutos totales de paro en el turno. Es igual a la suma de `duracion_min` de sus paros en `fact_paros` | 23                |
| `unidades_producidas`    | INT      | Unidades totales fabricadas, buenas y malas                                                                | 512               |
| `unidades_buenas`        | INT      | Unidades que cumplen calidad a la primera, sin retrabajo                                                   | 504               |
| `meta_unidades`          | INT      | Unidades que se esperaba producir en el turno (plan)                                                       | 510               |

Reglas verificadas:

- `unidades_buenas` ≤ `unidades_producidas`.
- `tiempo_paro_min` ≤ `tiempo_planificado_min`.
- Unidades defectuosas = `unidades_producidas` − `unidades_buenas` = suma de `cantidad` de sus defectos en `fact_defectos`.
- Tiempo de operación = `tiempo_planificado_min` − `tiempo_paro_min`.

### `fact_defectos` — defectos por tipo (19,574 filas)

| Columna           | Tipo     | Descripción                                        | Ejemplo / valores                                                                           |
| ----------------- | -------- | --------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| `id_defecto`    | INT (PK) | Identificador del registro                          | 1                                                                                           |
| `id_produccion` | INT (FK) | Turno de producción donde se detectó              | 1                                                                                           |
| `tipo_defecto`  | VARCHAR  | Tipo de defecto                                     | Soldadura, Ensamble, Cosmético, Componente de proveedor, Falla funcional / prueba, Empaque |
| `cantidad`      | INT      | Unidades con ese defecto en ese turno (siempre > 0) | 4                                                                                           |

Un turno tiene como máximo una fila por tipo de defecto. Un turno sin defectos no tiene filas aquí.

### `fact_paros` — paros de línea (7,350 filas)

| Columna            | Tipo     | Descripción                                                 | Ejemplo / valores                                                                                                      |
| ------------------ | -------- | ------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------- |
| `id_paro`        | INT (PK) | Identificador del evento de paro                             | 1                                                                                                                      |
| `id_produccion`  | INT (FK) | Turno de producción donde ocurrió                          | 1                                                                                                                      |
| `fecha`          | DATE     | Día del paro (repite la `fecha` del turno de producción) | 2025-10-01                                                                                                             |
| `id_linea`       | INT (FK) | Línea afectada (repite la del turno de producción)         | 1                                                                                                                      |
| `id_turno`       | INT (FK) | Turno afectado (repite el del turno de producción)          | 1                                                                                                                      |
| `categoria_paro` | VARCHAR  | Categoría del paro                                          | Mantenimiento planeado, Cambio de modelo, Falla de equipo, Falta de material, Falta de personal, Ajuste / calibración |
| `causa`          | VARCHAR  | Causa específica, dentro de la categoría                   | Lubricación, Falla de motor, Esperando componente                                                                     |
| `duracion_min`   | SMALLINT | Duración del paro en minutos (> 0)                          | 6                                                                                                                      |

Causas por categoría:

| Categoría             | Causas                                                                                       |
| ---------------------- | -------------------------------------------------------------------------------------------- |
| Mantenimiento planeado | Lubricación, Limpieza profunda, Mantenimiento preventivo                                    |
| Cambio de modelo       | Ajuste de línea, Cambio de herramental, Cambio de programa                                  |
| Falla de equipo        | Banda transportadora, Falla de motor, Falla eléctrica, Fuga neumática, Sensor descalibrado |
| Falta de material      | Esperando componente, Faltante en almacén, Material en inspección                          |
| Falta de personal      | Ausentismo, Capacitación, Rotación de personal                                             |
| Ajuste / calibración  | Ajuste de soldadora, Ajuste de torque, Calibración de probador                              |

### `fact_entregas_proveedor` — órdenes de compra (3,144 filas)

Cada fila es una orden de compra (OC) ya entregada. Las fechas de órdenes van de 2025-08-23 a 2026-09; es anterior al periodo de producción porque los materiales se piden con anticipación.

| Columna                | Tipo       | Descripción                                                                                            | Ejemplo / valores |
| ---------------------- | ---------- | ------------------------------------------------------------------------------------------------------- | ----------------- |
| `id_oc`              | INT (PK)   | Identificador de la orden de compra                                                                     | 1                 |
| `fecha_oc`           | DATE       | Día en que se generó la orden                                                                         | 2025-08-23        |
| `id_proveedor`       | INT (FK)   | Proveedor al que se le compró                                                                          | 10                |
| `fecha_prometida`    | DATE       | Fecha de entrega comprometida por el proveedor                                                          | 2025-10-02        |
| `fecha_entrega`      | DATE       | Fecha real en que llegó el material                                                                    | 2025-10-02        |
| `cantidad_ordenada`  | INT        | Unidades pedidas                                                                                        | 19319             |
| `cantidad_recibida`  | INT        | Unidades que llegaron                                                                                   | 19319             |
| `cantidad_rechazada` | INT        | Unidades recibidas que no pasaron la inspección de entrada. Es parte de lo recibido, no se suma a ello | 428               |
| `costo_unitario_usd` | DECIMAL    | Costo por unidad en USD                                                                                 | 11.89             |
| `a_tiempo` ⚙️      | TINYINT(1) | 1 si `fecha_entrega` ≤ `fecha_prometida`, 0 si llegó después                                     | 1                 |
| `dias_retraso` ⚙️  | SMALLINT   | Días de retraso respecto a la fecha prometida; 0 si llegó a tiempo o antes. No es negativo            | 0                 |

Regla verificada: `cantidad_rechazada` ≤ `cantidad_recibida` ≤ `cantidad_ordenada`. Una recepción menor a lo ordenado es una entrega incompleta.

### `fact_tickets_ti` — tickets de soporte de TI (3,726 filas)

| Columna                   | Tipo                       | Descripción                                                                                                                                  | Ejemplo / valores                                                                                     |
| ------------------------- | -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| `id_ticket`             | CHAR(10) (PK)              | Identificador del ticket                                                                                                                      | TCK-000001                                                                                            |
| `fecha_creacion`        | DATE                       | Día en que el usuario abrió el ticket (la hora se descarta en el pipeline; las horas de resolución se calculan antes de descartarla)       | 2025-10-01                                                                                            |
| `fecha_resolucion`      | DATE, nulo permitido       | Día en que se cerró el ticket. **Nulo = ticket abierto**                                                                              | 2025-10-01                                                                                            |
| `categoria`             | VARCHAR                    | Tipo de problema. Se normaliza a minúsculas y sin espacios sobrantes; si falta, "sin categoría"                                             | software, hardware, accesos y cuentas, red y conectividad, impresoras, sistemas de producción, otros |
| `prioridad`             | VARCHAR                    | Urgencia del ticket. Define el SLA                                                                                                            | Crítica, Alta, Media, Baja                                                                           |
| `area_solicitante`      | VARCHAR                    | Área de la planta que pidió el soporte; si falta, "Sin especificar"                                                                         | Producción, Ingeniería, Calidad, Almacén, Logística, Compras, Finanzas, Recursos Humanos          |
| `tecnico`               | VARCHAR                    | Técnico de TI asignado                                                                                                                       | Ana, Sofía, Diego, Marco, Valeria, Luis                                                              |
| `canal`                 | VARCHAR                    | Medio por el que llegó la solicitud                                                                                                          | Portal, Teléfono, Correo, Presencial                                                                 |
| `satisfaccion`          | TINYINT, nulo permitido    | Calificación del usuario, de 1 (muy mala) a 5 (excelente). **Nulo = el usuario no respondió la encuesta** (o el ticket sigue abierto) | 5                                                                                                     |
| `estatus` ⚙️          | VARCHAR                    | "Abierto" si no hay `fecha_resolucion`, "Cerrado" si la hay                                                                                 | Cerrado                                                                                               |
| `horas_resolucion` ⚙️ | DECIMAL                    | Horas entre creación y resolución, con hora y minuto reales. Nulo si el ticket está abierto                                                | 1.91                                                                                                  |
| `sla_horas` ⚙️        | SMALLINT                   | Horas máximas de resolución según la prioridad (el SLA)                                                                                    | 8                                                                                                     |
| `cumple_sla` ⚙️       | TINYINT(1), nulo permitido | 1 si `horas_resolucion` ≤ `sla_horas`, 0 si no. Nulo si el ticket está abierto                                                          | 1                                                                                                     |

SLA por prioridad:

| Prioridad | Horas máximas |
| --------- | -------------- |
| Crítica  | 4              |
| Alta      | 8              |
| Media     | 24             |
| Baja      | 72             |

---

## 4. Nulos legítimos

Estos nulos son datos reales, no errores, y no se rellenan:

| Tabla               | Columna                              | Significado del nulo               |
| ------------------- | ------------------------------------ | ---------------------------------- |
| `fact_tickets_ti` | `fecha_resolucion`                 | Ticket abierto                     |
| `fact_tickets_ti` | `horas_resolucion`, `cumple_sla` | Ticket abierto (no se puede medir) |
| `fact_tickets_ti` | `satisfaccion`                     | No contestó la encuesta           |

Para medir el cumplimiento del SLA, usa solo tickets cerrados.

## 5. Calidad de datos aplicada en el pipeline

- Se eliminan filas duplicadas (en `fact_tickets_ti` se quitaron 22).
- `categoria` de tickets: se quitan espacios, se pasa a minúsculas y los vacíos pasan a "sin categoría".
- `area_solicitante` vacía pasa a "Sin especificar".
- Los resultados de cada tabla (filas antes y después, nulos, duplicados) se guardan en `outputs/transformer/report.json`.
