OEE

```dax

DEFINE

    MEASURE 'planta_analytics fact_produccion'[tiempo real]=
        SUM('planta_analytics fact_produccion'[tiempo_planificado_min]) - SUM('planta_analytics fact_produccion'[tiempo_paro_min])

    MEASURE 'planta_analytics fact_produccion'[disponibilidad] = 
        DIVIDE(
            [tiempo real],
            SUM('planta_analytics fact_produccion'[tiempo_planificado_min]),
            0
        )

    MEASURE 'planta_analytics fact_produccion'[rendimiento] = 
        DIVIDE(
            SUM('planta_analytics fact_produccion'[unidades_producidas]),
            DIVIDE(
                SUM('planta_analytics fact_produccion'[meta_unidades]),
                SUM('planta_analytics fact_produccion'[tiempo_planificado_min]),
                0
            ) * [tiempo real],
            0
        )
  
    MEASURE 'planta_analytics fact_produccion'[calidad] = 
        DIVIDE(
            SUM('planta_analytics fact_produccion'[unidades_buenas]),
            SUM('planta_analytics fact_produccion'[unidades_producidas]),
            0
        )

    MEASURE 'planta_analytics fact_produccion'[OEE] = 
        [disponibilidad] * [rendimiento] * [calidad]

    EVALUATE
        SUMMARIZE('planta_analytics fact_produccion','planta_analytics fact_produccion'[id_linea],"OEE",[OEE])
```

cumplimiento del plan

```dax
DEFINE
	MEASURE 'planta_analytics fact_produccion'[cumplimiento de la meta]=
		DIVIDE(
			SUM('planta_analytics fact_produccion'[unidades_buenas]),
			SUM('planta_analytics fact_produccion'[meta_unidades])
		)

	EVALUATE
		SUMMARIZE('planta_analytics fact_produccion',
				  'planta_analytics fact_produccion'[id_linea],
				  "Cumplimiento de la meta",
				  'planta_analytics fact_produccion'[cumplimiento de la meta])
```

pareto de paros

```dax
DEFINE
	MEASURE 'planta_analytics fact_paros'[minutos de paro] =
		SUM('planta_analytics fact_paros'[duracion_min])

	MEASURE 'planta_analytics fact_paros'[% del total de paros] = 
		DIVIDE(
			SUM('planta_analytics fact_paros'[duracion_min]),
			CALCULATE(SUM('planta_analytics fact_paros'[duracion_min]),ALLSELECTED('planta_analytics fact_paros'))
		)

	MEASURE 'planta_analytics fact_paros'[% acumulado] =
		VAR minutosActual = [minutos de paro]
		VAR categorias = ALLSELECTED('planta_analytics fact_paros'[categoria_paro])
		VAR minutosAcumulados =
			SUMX(
				FILTER(categorias, [minutos de paro] >= minutosActual),
				[minutos de paro]
			)
		VAR total =
			CALCULATE([minutos de paro], ALLSELECTED('planta_analytics fact_paros'))
		RETURN
			DIVIDE(minutosAcumulados, total)

EVALUATE
ADDCOLUMNS(
	VALUES('planta_analytics fact_paros'[categoria_paro]),
	"minutos", [minutos de paro],
	"pct del total", [% del total de paros],
	"pct acumulado", [% acumulado]
)
ORDER BY [minutos] DESC
```

OTD

```dax
DEFINE

	MEASURE 'planta_analytics fact_entregas_proveedor'[entregas_a_tiempo] = 
    CALCULATE(
        COUNTROWS('planta_analytics fact_entregas_proveedor'),
        'planta_analytics fact_entregas_proveedor'[a_tiempo] = TRUE
	)

    MEASURE 'planta_analytics fact_entregas_proveedor'[OTD] = 
        DIVIDE(
            [entregas_a_tiempo],
            COUNTROWS('planta_analytics fact_entregas_proveedor')
        )

	  
EVALUATE
    SUMMARIZECOLUMNS(
        'planta_analytics fact_entregas_proveedor'[id_proveedor],
        "OTD", [OTD]
    )
```

SLA

```dax
DEFINE

	MEASURE 'planta_analytics fact_tickets_ti'[total SLA cumplido] = 
    CALCULATE(
        COUNTROWS('planta_analytics fact_tickets_ti'),
        'planta_analytics fact_tickets_ti'[cumple_sla] = TRUE
	)

	MEASURE 'planta_analytics fact_tickets_ti'[tickets cerrados] = 
    CALCULATE(
        COUNTROWS('planta_analytics fact_tickets_ti'),
        'planta_analytics fact_tickets_ti'[estatus] = "Cerrado"
	)

	MEASURE 'planta_analytics fact_tickets_ti'[cumplimiento de SLA] = 
		DIVIDE(
			[total SLA cumplido],
			[tickets cerrados]
		)

	EVALUATE
		SUMMARIZE(
			'planta_analytics fact_tickets_ti',
			'planta_analytics fact_tickets_ti'[categoria],
			"Cumplimiento SLA por categoria",
			[cumplimiento de SLA]
		)
```

Satisfaccion

```dax
DEFINE
	MEASURE 'planta_analytics fact_tickets_ti'[satisfaccion promedio] = 
			AVERAGE('planta_analytics fact_tickets_ti'[satisfaccion])

	
	MEASURE 'planta_analytics fact_tickets_ti'[tasa de respuesta] =
		DIVIDE(  
			CALCULATE(
				COUNTROWS('planta_analytics fact_tickets_ti'),
				'planta_analytics fact_tickets_ti'[satisfaccion] >=1),
			CALCULATE(
				COUNTROWS('planta_analytics fact_tickets_ti'),
				'planta_analytics fact_tickets_ti'[estatus] = "Cerrado")
		)
	
	EVALUATE
		SUMMARIZE(
			'planta_analytics fact_tickets_ti',
			'planta_analytics fact_tickets_ti'[categoria],
			"satisfaccion promedio por categoria",[satisfaccion promedio],
			"tasa de respuesta", [tasa de respuesta]
		)
```
