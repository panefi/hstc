import os
import mysql.connector
from .logger import logger


class SQLConnection:
    def __init__(self):
        """Connects to the database"""
        self.mydb = None
        self.mycursor = None

    def __enter__(self):
        """Establish the database connection"""
        self.mydb = mysql.connector.connect(
            host=os.getenv("DB_HOST"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
            port=int(os.getenv("DB_PORT")),
            db=os.getenv("DB_NAME")
        )
        self.mycursor = self.mydb.cursor()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Close the database connection"""
        if exc_type is None:
            self.mydb.commit()
        else:
            self.mydb.rollback()
        if self.mycursor:
            self.mycursor.close()
        if self.mydb:
            self.mydb.close()

    def execute_query(self, query, params=None):
        """Executes a query and returns the result"""
        try:
            self.mycursor.execute(query, params)
            return self.mycursor.fetchall()
        except Exception as e:
            logger.error(f"Database query failed: {str(e)}")
            raise Exception(f"Database query failed: {str(e)}")
