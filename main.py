import json
import logging
from pathlib import Path

from src.extractors import Extractor

RAIZ = Path(__file__).resolve().parent


def cargar_config(ruta: Path = RAIZ / "config.json") -> dict:
    return json.loads(ruta.read_text(encoding="utf-8"))


def main() -> None:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)s | %(message)s")
    cfg = cargar_config()

    extractor = Extractor(RAIZ / cfg["rutas"]["raw"])
    tablas = extractor.read_all(cfg["tablas"]["raw"])

    print(f"\nTablas leídas: {len(tablas)}")
    print(tablas["dim_linea"])


if __name__ == "__main__":
    main()