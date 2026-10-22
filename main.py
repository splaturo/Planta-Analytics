import json
import logging
from pathlib import Path
from dotenv import load_dotenv

from src.extractors import Extractor
from src.transformers import Transformer
from src.loaders import Loader

RAIZ = Path(__file__).resolve().parent


def cargar_config(ruta: Path = RAIZ / "config.json") -> dict:
    return json.loads(ruta.read_text(encoding="utf-8"))


def main() -> None:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)s | %(message)s")
    load_dotenv(RAIZ / ".env")                                                      
    cfg = cargar_config()

    # 1) EXTRAER
    extractor = Extractor(RAIZ / cfg["rutas"]["raw"])
    tablas = extractor.read_all(cfg["tablas"]["raw"])
    print(f"\nTablas leídas: {len(tablas)}")

    # 2) TRANSFORMAR
    transformer = Transformer(RAIZ / cfg["rutas"]["outputs"])
    tablas = transformer.clean_all(tablas)

    print(tablas["dim_turno"])
    print(tablas["fact_tickets_ti"].head(3))

    # 3) CARGAR                                                                  
    loader = Loader(RAIZ / cfg["rutas"]["processed"], cfg["mysql"])
    loader.save_csv(tablas)
    loader.load_to_db(tablas, cfg["tablas"]["orden_carga"])


if __name__ == "__main__":
    main()