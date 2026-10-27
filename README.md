# Planta Analytics

Pipeline de datos de una planta manufacturera ficticia: limpieza en Python, modelo en estrella
en MySQL y un tablero en Power BI con 8 KPIs de producción, calidad, proveedores y soporte de TI.

## Problema de negocio

Una planta manufacturera ficticia fabrica pantallas, refrigeradores, aires acondicionados y lavadoras en cinco líneas y tres turnos, con un área interna de soporte de TI. Su información está dispersa en varias tablas (producción, defectos, paros, entregas de proveedores y tickets), y la gerencia no tiene una vista única para responder cuatro preguntas:

1. **Producción:** ¿qué tan bien aprovechamos las líneas, cumplimos el plan y qué causas de paro nos quitan más tiempo?
2. **Calidad:** ¿qué proporción de lo que producimos sale con defecto, y de qué tipo?
3. **Proveedores:** ¿nos entregan a tiempo y con la calidad esperada, y cuánto cuesta lo que rechazamos?
4. **Soporte de TI:** ¿resolvemos los tickets dentro del tiempo comprometido y quedan satisfechos los usuarios?

## Datos

Datos sintéticos (no provienen de ninguna empresa real) del periodo oct 2025 – sep 2026:
4,695 turnos de producción, 19,574 registros de defectos, 7,350 paros, 3,144 órdenes de compra
y 3,726 tickets de soporte. Diccionario completo en [docs/diccionario_de_datos.md](docs/diccionario_de_datos.md).

## Arquitectura

```
CSV crudos  →  Python (extraer, limpiar, cargar)  →  MySQL (modelo en estrella)  →  Power BI
data/raw       src/                                  sql/                            powerbi/
```

## KPIs

| KPI                     | Resultado   | Meta     |
| ----------------------- | ----------- | -------- |
| OEE                     | 77.57 %     | ≥ 85 %  |
| Cumplimiento del plan   | 92.16 %     | 100 %    |
| Entregas a tiempo (OTD) | 87.66 %     | ≥ 95 %  |
| Cumplimiento del SLA    | 92.27 %     | ≥ 95 %  |
| Satisfacción promedio  | 4.19 de 5   | ≥ 4.0   |
| Tasa de defectos        | 2.97 %      | ≤ 3 %   |
| Rechazo de material     | 1.17 %      | ≤ 1 %   |
| Pareto de paros         | 159 mil min | Sin meta |

Definiciones, fórmulas y metas en [docs/catalogo_kpis.md](docs/catalogo_kpis.md).

## Hallazgos

## Estructura del repositorio

```
├── data/raw/           CSV de origen
├── src/                extractors.py, transformers.py, loaders.py
├── sql/                esquema, vistas, validaciones y análisis
├── powerbi/            tablero (.pbix) y medidas DAX
├── docs/               diccionario de datos, catálogo de KPIs, imágenes
├── notebooks/          exploración inicial
├── outputs/            reporte de calidad del transformer
├── main.py             ejecuta el flujo completo
└── config.json
```

## Cómo ejecutarlo

1. Crea el entorno e instala las dependencias:
   `python -m venv .venv` → activa → `pip install -r requirements.txt`
2. Crea la base de datos ejecutando `sql/01_schema_mysql.sql` en MySQL 8.0.16 o superior.
3. Copia `.env.example` a `.env` y escribe tus credenciales de MySQL.
4. Ejecuta `python main.py`.
5. Abre el `.pbix` y conéctalo a tu MySQL (necesita MySQL Connector/NET).

## Decisiones de diseño

- Columnas derivadas por fila en el ETL; KPIs que dependen de filtros en DAX.
- El pipeline es repetible y carga todo en una transacción (si algo falla, se revierte).
- Los nulos legítimos (ticket abierto, encuesta sin responder) se conservan.
- Cada KPI se validó calculándolo dos veces: en SQL y en DAX.

## Limitaciones

Datos sintéticos; las metas son referencias de industria o supuestos del proyecto.

## Autor

Arturo Ramirez Morales  · arturo.ramirez60@uabc.edu.mx
