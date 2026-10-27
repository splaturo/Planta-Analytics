use planta_analytics;
show tables;

select * from dim_fecha;

select * from dim_linea;

select * from dim_producto;

select * from dim_proveedor;

select * from dim_turno;

select * from fact_defectos;

select * from fact_entregas_proveedor;

select * from fact_paros;

select * from fact_produccion;

select 
	id_linea,
    round(avg(disponibilidad) * avg(rendimiento) * avg(calidad),2) as OEE
from OEE
group by 1;

select 
	id_turno,
    round(avg(disponibilidad) * avg(rendimiento) * avg(calidad),2) as OEE
from OEE
group by 1;

select 
	id_linea,
    round(sum(unidades_buenas) / sum(meta_unidades),2) as cumplimiento_de_la_meta
from fact_produccion
group by 1;


select
	categoria,
	count(case when estatus = 'Cerrado' then 1 end) as tickets_cerrados,
    count(case when cumple_sla = 1 then 1 end) as tickets_sla,
    round(count(case when cumple_sla = 1 then 1 end)/count(case when estatus = 'Cerrado' then 1 end),2) as pct_sla
    
from fact_tickets_ti
group by 1;



select
	categoria,
	round(avg(satisfaccion),2) as satisfaccion_promedio,
    round(COUNT(case when satisfaccion >= 1 then satisfaccion end) / 
    count(case when estatus = 'Cerrado' then estatus end),2) as tasa_respuesta
from fact_tickets_ti
group by 1;


SELECT 
    ROUND(
        (SELECT SUM(cantidad) FROM fact_defectos) / 
        (SELECT SUM(unidades_producidas) FROM fact_produccion)
    , 2) AS tasa_de_defectos
from fact_produccion;

SELECT
    fp.id_turno,
    ROUND(SUM(COALESCE(d.defectos, 0)) / SUM(fp.unidades_producidas), 4) AS tasa_defectos
FROM fact_produccion fp
LEFT JOIN (
    SELECT id_produccion, SUM(cantidad) AS defectos
    FROM fact_defectos
    GROUP BY id_produccion
) d ON d.id_produccion = fp.id_produccion
GROUP BY fp.id_turno;


SELECT
    DATE_FORMAT(fecha_entrega, '%Y-%m') AS anio_mes,
    ROUND(SUM(cantidad_rechazada) / SUM(cantidad_recibida), 4) AS tasa_rechazo,
    SUM(cantidad_rechazada * costo_unitario_usd) AS costo_material_rechazado
FROM fact_entregas_proveedor
GROUP BY 1
ORDER BY 1;









