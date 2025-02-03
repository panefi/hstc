from .database import SQLConnection
from .queries import GET_GATES
from .logger import logger


def get_gates():
    """
    Get all gates from the database
    """
    try:
        with SQLConnection() as db:
            gates = db.execute_query(GET_GATES)
            logger.info(f"Successfully retrieved gates: {gates}")
            return gates
    except Exception as e:
        logger.error(f"Database query failed: {str(e)}")
        raise Exception(f"Database query failed: {str(e)}")
