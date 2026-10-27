-

## KPI-01 · OEE (Eficiencia General del Equipo)

* **Área:** Producción
* **Pregunta de negocio:** ¿Qué tan bien aprovechamos el tiempo y el equipo de las líneas de producción? ¿Cuánto del tiempo disponible se convierte en producto bueno, producido a la velocidad ideal?
* **Definición (fórmula en palabras):**
  El OEE es el producto de tres factores:

  1. **Disponibilidad** = tiempo de operación ÷ tiempo planificado.
     El tiempo de operación es el tiempo planificado menos el tiempo de paro.
  2. **Rendimiento** = tiempo ideal de lo producido ÷ tiempo de operación.
     El tiempo ideal de lo producido es la suma, turno por turno, de las unidades producidas por el tiempo de ciclo ideal de su producto (convertido de segundos a minutos).
  3. **Calidad** = tiempo ideal de las unidades buenas ÷ tiempo ideal de lo producido.
     Se pondera por tiempo ideal para que un producto de ciclo largo (un refrigerador) pese más que uno de ciclo corto (una pantalla) al sumar varios productos.

  **OEE = Disponibilidad × Rendimiento × Calidad.**
  Equivale a: tiempo ideal de las unidades buenas ÷ tiempo planificado.
* **Granularidad de los datos:**
  Origen: una fila de `fact_produccion` por turno, línea y día.
  Reporte: se puede ver por línea, turno, producto, o por periodo (día, mes, trimestre, año). En cualquier corte, las sumas se hacen sobre las filas de origen y después se divide; no se promedian OEE ya calculados.
* **Tablas / vista de origen:**

  * `fact_produccion`: `tiempo_planificado_min`, `tiempo_paro_min`, `unidades_producidas`, `unidades_buenas`.
  * `dim_producto`: `tiempo_ciclo_ideal_seg` (se une por `id_producto`).
  * `dim_linea`, `dim_turno`, `dim_fecha`: para los cortes.
* **Cortes disponibles:** línea, turno, producto, fecha (día, mes, trimestre, año).
* **Meta y fuente:**
  Referencia de industria: 85 % se considera clase mundial; 60 % es un valor típico. Son referencias generales, no una política de esta planta (los datos son sintéticos). Más alto es mejor.
* **Dónde se calcula:** Medidas DAX en Power BI, sobre la tabla `fact_produccion`:

  * `[tiempo de operacion]`
  * `[tiempo ideal de lo producido]`
  * `[tiempo ideal de las unidades buenas]`
  * `[disponibilidad]`
  * `[rendimiento]`
  * `[calidad]`
  * `[OEE]`

  Código en `powerbi/medidas_dax.md`.
* **Cómo se validó:**
  Pendiente de completar con los valores obtenidos:

  1. **Prueba de identidad:** disponibilidad × rendimiento × calidad frente a (tiempo ideal de las unidades buenas ÷ tiempo planificado). Resultado:  *pendiente* .
  2. **Doble cálculo con SQL:** OEE de un mes y una línea con una consulta en MySQL, comparado con la medida DAX filtrada igual. Valor SQL: *pendiente* · Valor DAX:  *pendiente* .
  3. **Comprobación de rangos:** rendimiento ≤ 100 % y calidad ≤ 100 % en todos los cortes. Resultado:  *pendiente* .

  OEE total mostrado en el dashboard: 78 %.
* **Supuestos y limitaciones:**

  * El tiempo planificado es constante (450 min por turno) en los datos.
  * Todos los paros, incluido el mantenimiento planeado, restan disponibilidad. Algunas definiciones excluyen el mantenimiento planeado del tiempo planificado; aquí no se excluye.
  * El tiempo de ciclo ideal es el de catálogo (`dim_producto`) y es único por producto, no varía por línea.
  * Calidad usa `unidades_buenas` como unidades que cumplen a la primera, sin retrabajo.
  * `meta_unidades` (el plan de producción) no interviene en el OEE: es la base de otro KPI, el cumplimiento del plan.
  * Datos sintéticos; la meta es una referencia, no un compromiso real.
* **Historial de cambios:**

  * 2026-10-23 · v1.0 · Primera versión con rendimiento calculado contra `meta_unidades`. El rendimiento pasaba de 100 % en más de la mitad de los turnos, porque la meta es un plan y no la velocidad ideal. OEE mostrado: 92 %.
  * 2026-10-23 · v1.1 · Rendimiento recalculado con el tiempo de ciclo ideal de `dim_producto`; calidad ponderada por tiempo ideal.
  * 2026-10-23 · v1.2 · Se corrigió la unidad: el tiempo ideal se convierte de segundos a minutos para coincidir con el tiempo de operación. OEE: 78 %.
