import pandas as pd
from collections import defaultdict
import json

MESES = {1: "enero", 2: "febrero", 3: "marzo", 4: "abril", 5: "mayo", 6: "junio",
         7: "julio", 8: "agosto", 9: "septiembre", 10: "octubre",
         11: "noviembre", 12: "diciembre"}
DIAS = {1: "lunes", 2: "martes", 3: "miércoles", 4: "jueves",
        5: "viernes", 6: "sábado", 7: "domingo"}


class Transformer:
    def __init__(self,params):
        self.params = params
        self.report = defaultdict(dict)
    
    def _perfil(self,df : pd.DataFrame,name):
        self.report[name]["raw"] = {"size" : df.shape,
                                    "nulls" : int(df.isna().sum().sum()),
                                    "duplicated" : int(df.duplicated().sum().sum())}
        
        if not name == "fact_tickets_ti":
            df = df.dropna().drop_duplicates()
            self.report[name]["processed"] = {"size" : df.shape,
                                              "nulls" : int(df.isna().sum().sum()),
                                              "duplicated" : int(df.duplicated().sum().sum())}
        else:
            df = df.drop_duplicates()
            self.report[name]["processed"] = {"size" : df.shape, 
                                              "duplicated" : int(df.duplicated().sum().sum())}
    
        
        return df
    
    def clean_dim_linea(self, df_raw,name):
        df = df_raw.copy()
        df = self._perfil(df,name)
        
        return df
        
        
    
    def clean_dim_producto(self, df_raw,name):
        df = df_raw.copy()
        df = self._perfil(df,name)
        
        return df
    
    def clean_dim_proveedor(self, df_raw,name):
        df = df_raw.copy()
        df = self._perfil(df,name)
        
        return df
    
        
    def clean_dim_turno(self, df_raw,name):
        df = df_raw.copy()
        df = self._perfil(df,name)
        
        df[["hora_inicio", "hora_fin"]] = df["horario"].str.split("-", expand=True)

        ini = pd.to_datetime(df["hora_inicio"], format="%H:%M")
        fin = pd.to_datetime(df["hora_fin"], format="%H:%M")
        df["duracion_horas"] = ((fin - ini).dt.total_seconds() / 3600) % 24
    
        return df
    
    def clean_fact_defectos(self, df_raw,name):
        df = df_raw.copy()
        df = self._perfil(df,name)
        
        return df
    
    def clean_fact_entregas_proveedor(self, df_raw,name):
        df = df_raw.copy()
        df = self._perfil(df,name)
        
      
        df["fecha_oc"] = pd.to_datetime(df["fecha_oc"])
        df["fecha_prometida"] = pd.to_datetime(df["fecha_prometida"])
        df["fecha_entrega"] = pd.to_datetime(df["fecha_entrega"])
        
        
        df["a_tiempo"] = (df["fecha_entrega"] <= df["fecha_prometida"]).astype(int)
        df["dias_retraso"] = (df["fecha_entrega"] - df["fecha_prometida"]).dt.days.clip(lower=0)
        
        return df
        
        
    def clean_fact_paros(self, df_raw,name):
        df = df_raw.copy()
        df = self._perfil(df,name)
        
        return df
        
    def clean_fact_produccion(self, df_raw,name):
        df = df_raw.copy()
        df = self._perfil(df,name)
        
        return df
    
    def clean_fact_tickets_ti(self, df_raw,name):
        df = df_raw.copy()
        df = self._perfil(df,name)
        
        df["categoria"] = df["categoria"].fillna("sin categoría")
        df["categoria"] = df["categoria"].str.strip().str.lower()
        df["area_solicitante"] = df["area_solicitante"].fillna("Sin especificar")
        df["Estatus"] = df["fecha_resolucion"].apply(lambda x: "Abierto" if pd.isna(x) else "Cerrado")
        
    
        df["fecha_creacion"] = pd.to_datetime(df["fecha_creacion"])
        df["fecha_resolucion"] = pd.to_datetime(df["fecha_resolucion"])
        
        df["horas_resolucion"] = ((df["fecha_resolucion"] - df["fecha_creacion"]).dt.total_seconds() / 3600).round(2)
        df["sla_horas"] = df["prioridad"].map({"Crítica": 4, "Alta": 8, "Media": 24, "Baja": 72})
        df["cumple_sla"] = (df["horas_resolucion"] <= df["sla_horas"]).astype("Int64").where(df["horas_resolucion"].notna())
        
        df["fecha_creacion"] = df["fecha_creacion"].dt.normalize()
        df["fecha_resolucion"] = df["fecha_resolucion"].dt.normalize()
        
        self.report[name]["processed"]["nulls"] = int(df.isna().sum().sum())
                                                
        
        return df

    def build_dim_fecha(self, tablas):
        """Genera dim_fecha con un día por fila, cubriendo todas las fechas de los hechos."""
        fechas = []
        for nombre, df in tablas.items():
            for col in df.columns:
                if col.startswith("fecha"):
                    fechas.append(pd.to_datetime(df[col]).dropna())

        todas = pd.concat(fechas)
        inicio = todas.min().to_period("M").start_time
        fin = todas.max().to_period("M").end_time.normalize()

        df = pd.DataFrame({"fecha": pd.date_range(inicio, fin, freq="D")})
        df["anio"] = df["fecha"].dt.year
        df["mes_num"] = df["fecha"].dt.month
        df["mes"] = df["mes_num"].map(MESES)
        df["anio_mes"] = df["fecha"].dt.strftime("%Y-%m")
        df["trimestre"] = "T" + df["fecha"].dt.quarter.astype(str)
        df["semana_iso"] = df["fecha"].dt.isocalendar().week.astype(int)
        df["dia_semana_num"] = df["fecha"].dt.dayofweek + 1
        df["dia_semana"] = df["dia_semana_num"].map(DIAS)
        df["es_laboral"] = (df["dia_semana_num"] != 7).astype(int)

        self.report["dim_fecha"]["processed"] = {
            "size": df.shape,
            "desde": str(df["fecha"].min().date()),
            "hasta": str(df["fecha"].max().date())}

        return df
        
    
    def clean_all(self,tablas : dict[str,pd.DataFrame]):
        
        limpias = {}                                                               
        
        for name, df in tablas.items():
            
            limpias[name] = getattr(self, f"clean_{name}")(df,name)                

        limpias["dim_fecha"] = self.build_dim_fecha(limpias)
   
                
        with open(self.params / "report.json", "w") as f:
            json.dump(self.report, f, indent=4)
        
        return limpias