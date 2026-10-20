# Datos de una planta ficticia de electrónica y línea blanca

Todos los datos son **sintéticos**: no pertenecen a ninguna empresa real.
Periodo: 1 de octubre de 2025 al 30 de septiembre de 2026.
Planta con 5 líneas de producción, 3 turnos, 12 proveedores y un área de soporte de TI.

Formato: CSV, UTF-8 con BOM (se abre bien en Excel y Power BI).
Fechas: `AAAA-MM-DD`. En tickets, fecha y hora: `AAAA-MM-DD HH:MM:SS`.

> Estos archivos están "crudos": revisa su calidad antes de analizarlos.

## Archivos

### Dimensiones
| Archivo | Filas | Columnas |
|---|---:|---|
| `dim_producto.csv` | 5 | `id_producto`, `producto`, `familia`, `tiempo_ciclo_ideal_seg`, `precio_unitario_usd` |
| `dim_linea.csv` | 5 | `id_linea`, `linea`, `id_producto` (producto que fabrica la línea) |
| `dim_turno.csv` | 3 | `id_turno`, `turno`, `horario` |
| `dim_proveedor.csv` | 12 | `id_proveedor`, `proveedor`, `categoria_material`, `pais` |

No incluí tabla de calendario; si la necesitas, constrúyela tú.

### Hechos
| Archivo | Filas | Una fila es... | Columnas |
|---|---:|---|---|
| `fact_produccion.csv` | 4,695 | un turno de una línea en un día | `id_produccion`, `fecha`, `id_linea`, `id_turno`, `id_producto`, `tiempo_planificado_min`, `tiempo_paro_min`, `unidades_producidas`, `unidades_buenas`, `meta_unidades` |
| `fact_defectos.csv` | 19,574 | un tipo de defecto dentro de un turno | `id_defecto`, `id_produccion`, `tipo_defecto`, `cantidad` |
| `fact_paros.csv` | 7,350 | un evento de paro dentro de un turno | `id_paro`, `id_produccion`, `fecha`, `id_linea`, `id_turno`, `categoria_paro`, `causa`, `duracion_min` |
| `fact_entregas_proveedor.csv` | 3,144 | una orden de compra con su entrega | `id_oc`, `fecha_oc`, `id_proveedor`, `fecha_prometida`, `fecha_entrega`, `cantidad_ordenada`, `cantidad_recibida`, `cantidad_rechazada`, `costo_unitario_usd` |
| `fact_tickets_ti.csv` | 3,748 | un ticket de soporte de TI | `id_ticket`, `fecha_creacion`, `fecha_resolucion`, `categoria`, `prioridad`, `area_solicitante`, `tecnico`, `canal`, `satisfaccion` |

## Relaciones

- `fact_produccion` se une con `dim_linea`, `dim_turno` y `dim_producto` por `id_linea`, `id_turno` e `id_producto`.
- `dim_linea.id_producto` también apunta a `dim_producto`.
- `fact_defectos` y `fact_paros` se unen con `fact_produccion` por `id_produccion`.
- `fact_entregas_proveedor` se une con `dim_proveedor` por `id_proveedor`.
- `fact_tickets_ti` no tiene llaves hacia otras tablas.

## Notas sobre las columnas

- `tiempo_planificado_min`: minutos planificados del turno (ya descuenta la comida).
- `tiempo_paro_min`: minutos que la línea estuvo detenida en ese turno.
- `tiempo_ciclo_ideal_seg`: segundos ideales por unidad de ese producto.
- `meta_unidades`: unidades que se esperaba producir en el turno.
- `fecha_oc`: fecha de la orden de compra; `fecha_prometida`: fecha comprometida por el proveedor; `fecha_entrega`: fecha en que llegó.
- `fecha_resolucion` vacía significa que el ticket seguía abierto.
- `satisfaccion`: calificación de 1 a 5; vacía si el usuario no respondió.

## Regla de negocio de TI (por si la necesitas)

Tiempo objetivo de resolución por prioridad, en horas corridas: Crítica 4 · Alta 8 · Media 24 · Baja 72.
