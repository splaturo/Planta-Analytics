import logging
import os
from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

logger = logging.getLogger(__name__)


class Loader:
    def __init__(self, processed_dir: Path, db_config: dict):
    
        self.processed_dir = Path(processed_dir)
        self.db_config = db_config


    def save_csv(self, tablas: dict[str, pd.DataFrame]) -> None:
        self.processed_dir.mkdir(parents=True, exist_ok=True)
        for name, df in tablas.items():
            df.to_csv(self.processed_dir / f"{name}.csv", index=False, encoding="utf-8-sig")
            logger.info("CSV guardado: %s (%d filas)", name, len(df))

    def _engine(self):
        """Crea la conexión. El usuario y la contraseña salen de variables de entorno (.env)."""
        url = URL.create(
            "mysql+pymysql",
            username=os.environ["DB_USER"],
            password=os.environ["DB_PASSWORD"],
            host=self.db_config["host"],
            port=self.db_config["port"],
            database=self.db_config["nombre"],
            query={"charset": "utf8mb4"},
        )
        return create_engine(url)

    def load_to_db(self, tablas: dict[str, pd.DataFrame], orden: list[str]) -> None:
        
        engine = self._engine()
        nombres = [n for n in orden if n in tablas]
        for n in orden:
            if n not in tablas:
                logger.warning("La tabla %s está en el orden de carga pero no se generó; se omite", n)

        with engine.begin() as conn:
  
            for name in reversed(nombres):
                conn.execute(text(f"DELETE FROM `{name}`"))
            
            for name in nombres:
                tablas[name].to_sql(name, conn, if_exists="append", index=False,
                                    chunksize=1000, method="multi")
                logger.info("Cargada %s: %d filas", name, len(tablas[name]))

        self._verify(engine, tablas, nombres)

    def _verify(self, engine, tablas: dict[str, pd.DataFrame], nombres: list[str]) -> None:
        """Comprueba que cada tabla en la base tenga las mismas filas que el DataFrame."""
        with engine.connect() as conn:
            for name in nombres:
                en_db = conn.execute(text(f"SELECT COUNT(*) FROM `{name}`")).scalar()
                if en_db != len(tablas[name]):
                    raise ValueError(f"{name}: la base tiene {en_db} filas y el DataFrame {len(tablas[name])}")
        logger.info("Verificación: el número de filas coincide en %d tablas", len(nombres))