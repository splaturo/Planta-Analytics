import logging
from pathlib import Path

import pandas as pd

logger = logging.getLogger(__name__)


class Extractor:
    def __init__(self, carpeta_raw: Path):
        self.carpeta_raw = Path(carpeta_raw)

    def read_csv(self, path: Path) -> pd.DataFrame:
        path = Path(path)
        try:
            df = pd.read_csv(path, encoding="utf-8-sig")
        except FileNotFoundError:
            logger.error("El archivo no existe: %s", path)
            raise
        except pd.errors.EmptyDataError:
            logger.error("El archivo CSV está vacío: %s", path)
            raise
        except UnicodeDecodeError:
            logger.error("No se pudo decodificar como UTF-8: %s", path)
            raise
        except pd.errors.ParserError:
            logger.error("Formato CSV inválido o corrupto: %s", path)
            raise

        logger.info("Leído %s: %d filas, %d columnas", path.name, df.shape[0], df.shape[1])
        return df

    def read_all(self, nombres: list[str]) -> dict[str, pd.DataFrame]:
        return {n: self.read_csv(self.carpeta_raw / f"{n}.csv") for n in nombres}