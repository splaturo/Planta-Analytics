

CREATE DATABASE IF NOT EXISTS planta_analytics
    DEFAULT CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE planta_analytics;


DROP TABLE IF EXISTS fact_tickets_ti;
DROP TABLE IF EXISTS fact_entregas_proveedor;
DROP TABLE IF EXISTS fact_paros;
DROP TABLE IF EXISTS fact_defectos;
DROP TABLE IF EXISTS fact_produccion;
DROP TABLE IF EXISTS dim_fecha;
DROP TABLE IF EXISTS dim_proveedor;
DROP TABLE IF EXISTS dim_turno;
DROP TABLE IF EXISTS dim_linea;
DROP TABLE IF EXISTS dim_producto;



CREATE TABLE dim_producto (
    id_producto             INT           NOT NULL,
    producto                VARCHAR(50)   NOT NULL,
    familia                 VARCHAR(30)   NOT NULL,
    tiempo_ciclo_ideal_seg  INT           NOT NULL,
    precio_unitario_usd     DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id_producto),
    CONSTRAINT chk_producto_ciclo  CHECK (tiempo_ciclo_ideal_seg > 0),
    CONSTRAINT chk_producto_precio CHECK (precio_unitario_usd > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE dim_linea (
    id_linea     INT         NOT NULL,
    linea        VARCHAR(20) NOT NULL,
    id_producto  INT         NOT NULL,          -- producto que fabrica la línea
    PRIMARY KEY (id_linea),
    CONSTRAINT fk_linea_producto FOREIGN KEY (id_producto) REFERENCES dim_producto (id_producto)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE dim_turno (
    id_turno        INT          NOT NULL,
    turno           VARCHAR(20)  NOT NULL,
    horario         VARCHAR(11)  NOT NULL,      -- texto original, p. ej. 06:00-14:00
    hora_inicio     TIME         NOT NULL,      -- derivada en transformers
    hora_fin        TIME         NOT NULL,      -- derivada en transformers
    duracion_horas  DECIMAL(4,1) NOT NULL,      -- derivada en transformers (con módulo 24)
    PRIMARY KEY (id_turno)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE dim_proveedor (
    id_proveedor        INT          NOT NULL,
    proveedor           VARCHAR(60)  NOT NULL,
    categoria_material  VARCHAR(60)  NOT NULL,
    pais                VARCHAR(30)  NOT NULL,
    PRIMARY KEY (id_proveedor)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Calendario: una fila por día. Sin llaves foráneas desde los hechos:
-- la relación con las fechas se define en Power BI (tabla de fechas).
CREATE TABLE dim_fecha (
    fecha           DATE         NOT NULL,
    anio            SMALLINT     NOT NULL,
    mes_num         TINYINT      NOT NULL,
    mes             VARCHAR(12)  NOT NULL,
    anio_mes        CHAR(7)      NOT NULL,      -- 2026-03
    trimestre       CHAR(2)      NOT NULL,      -- T1..T4
    semana_iso      TINYINT      NOT NULL,
    dia_semana_num  TINYINT      NOT NULL,      -- 1 = lunes
    dia_semana      VARCHAR(12)  NOT NULL,
    es_laboral      TINYINT(1)   NOT NULL,      -- 0 = domingo
    PRIMARY KEY (fecha)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- HECHOS
-- ============================================================

-- Grano: un turno de una línea en un día.
CREATE TABLE fact_produccion (
    id_produccion           INT       NOT NULL,
    fecha                   DATE      NOT NULL,
    id_linea                INT       NOT NULL,
    id_turno                INT       NOT NULL,
    id_producto             INT       NOT NULL,
    tiempo_planificado_min  SMALLINT  NOT NULL,
    tiempo_paro_min         SMALLINT  NOT NULL,
    unidades_producidas     INT       NOT NULL,
    unidades_buenas         INT       NOT NULL,
    meta_unidades           INT       NOT NULL,
    PRIMARY KEY (id_produccion),
    UNIQUE KEY uq_produccion_grano (fecha, id_linea, id_turno),
    CONSTRAINT fk_prod_linea    FOREIGN KEY (id_linea)    REFERENCES dim_linea (id_linea),
    CONSTRAINT fk_prod_turno    FOREIGN KEY (id_turno)    REFERENCES dim_turno (id_turno),
    CONSTRAINT fk_prod_producto FOREIGN KEY (id_producto) REFERENCES dim_producto (id_producto),
    CONSTRAINT chk_prod_no_negativos
        CHECK (unidades_producidas >= 0 AND unidades_buenas >= 0 AND tiempo_paro_min >= 0),
    CONSTRAINT chk_prod_buenas  CHECK (unidades_buenas <= unidades_producidas),
    CONSTRAINT chk_prod_paro    CHECK (tiempo_paro_min <= tiempo_planificado_min)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Grano: un tipo de defecto dentro de un turno de producción.
CREATE TABLE fact_defectos (
    id_defecto     INT         NOT NULL,
    id_produccion  INT         NOT NULL,
    tipo_defecto   VARCHAR(40) NOT NULL,
    cantidad       INT         NOT NULL,
    PRIMARY KEY (id_defecto),
    UNIQUE KEY uq_defecto_grano (id_produccion, tipo_defecto),
    CONSTRAINT fk_def_produccion FOREIGN KEY (id_produccion) REFERENCES fact_produccion (id_produccion),
    CONSTRAINT chk_def_cantidad  CHECK (cantidad > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Grano: un evento de paro dentro de un turno de producción.
-- fecha, id_linea e id_turno repiten datos de fact_produccion (vienen así en la fuente).
CREATE TABLE fact_paros (
    id_paro         INT         NOT NULL,
    id_produccion   INT         NOT NULL,
    fecha           DATE        NOT NULL,
    id_linea        INT         NOT NULL,
    id_turno        INT         NOT NULL,
    categoria_paro  VARCHAR(40) NOT NULL,
    causa           VARCHAR(60) NOT NULL,
    duracion_min    SMALLINT    NOT NULL,
    PRIMARY KEY (id_paro),
    KEY ix_paros_categoria (categoria_paro),
    KEY ix_paros_fecha (fecha),
    CONSTRAINT fk_paros_produccion FOREIGN KEY (id_produccion) REFERENCES fact_produccion (id_produccion),
    CONSTRAINT fk_paros_linea      FOREIGN KEY (id_linea)      REFERENCES dim_linea (id_linea),
    CONSTRAINT fk_paros_turno      FOREIGN KEY (id_turno)      REFERENCES dim_turno (id_turno),
    CONSTRAINT chk_paros_duracion  CHECK (duracion_min > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Grano: una orden de compra con su entrega.
-- a_tiempo y dias_retraso son derivadas: quedan vacías hasta que el transformer las calcule.
CREATE TABLE fact_entregas_proveedor (
    id_oc               INT           NOT NULL,
    fecha_oc            DATE          NOT NULL,
    id_proveedor        INT           NOT NULL,
    fecha_prometida     DATE          NOT NULL,
    fecha_entrega       DATE          NOT NULL,
    cantidad_ordenada   INT           NOT NULL,
    cantidad_recibida   INT           NOT NULL,
    cantidad_rechazada  INT           NOT NULL,
    costo_unitario_usd  DECIMAL(10,2) NOT NULL,
    a_tiempo            TINYINT(1)    NULL,
    dias_retraso        SMALLINT      NULL,
    PRIMARY KEY (id_oc),
    KEY ix_entregas_prometida (fecha_prometida),
    CONSTRAINT fk_entregas_proveedor FOREIGN KEY (id_proveedor) REFERENCES dim_proveedor (id_proveedor),
    CONSTRAINT chk_entregas_cantidades
        CHECK (cantidad_rechazada <= cantidad_recibida AND cantidad_recibida <= cantidad_ordenada)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Grano: un ticket de soporte de TI.
-- fecha_resolucion vacía = ticket abierto. satisfaccion vacía = el usuario no respondió.
-- horas_resolucion, sla_horas y cumple_sla son derivadas (vacías hasta que el transformer las calcule).
CREATE TABLE fact_tickets_ti (
    id_ticket         CHAR(10)     NOT NULL,
    fecha_creacion    DATE    NOT NULL,
    fecha_resolucion  DATE     NULL,
    categoria         VARCHAR(40)  NOT NULL,
    prioridad         VARCHAR(10)  NOT NULL,
    area_solicitante  VARCHAR(40)  NOT NULL,
    tecnico           VARCHAR(30)  NOT NULL,
    canal             VARCHAR(20)  NOT NULL,
    satisfaccion      TINYINT      NULL,
    estatus           VARCHAR(10)  NULL,
    horas_resolucion  DECIMAL(8,2) NULL,
    sla_horas         SMALLINT     NULL,
    cumple_sla        TINYINT(1)   NULL,
    PRIMARY KEY (id_ticket),
    KEY ix_tickets_creacion (fecha_creacion),
    KEY ix_tickets_categoria (categoria),
    CONSTRAINT chk_tickets_satisfaccion CHECK (satisfaccion BETWEEN 1 AND 5),
    CONSTRAINT chk_tickets_fechas CHECK (fecha_resolucion IS NULL OR fecha_resolucion >= fecha_creacion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;