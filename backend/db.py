import sqlite3
from exceptions import EntryCreationError, EntryNotFoundError, JournalEntryError

def singleton(cls):
    instances = {}

    def getinstance():
        if cls not in instances:
            instances[cls] = cls()
        return instances[cls]

    return getinstance

class DataBaseDriver:
    def __init__(self):
        self.conn = sqlite3.connect("candid.db", check_same_thread=False)
        self.conn.row_factory = sqlite3.Row
        self.create_entries_table()

    def create_entries_table(self):
        try:
            self.conn.execute(f"""
                CREATE TABLE IF NOT EXISTS entries (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    TITLE TEXT,
                    BODY TEXT,
                    CATEGORY VARCHAR (30) NOT NULL
                );
            """)

            self.conn.commit()
        except sqlite3.Error as e:
            print(f"Error initializing users table in database: {e}")

    def get_all_entries(self):
        try:
            cursor = self.conn.cursor()
            self.conn.execute(f"""
                SELECT (id, TITLE, BODY, CATEGORY) FROM entries;
            """
            )

            rows = cursor.fetchall()

            return rows

        except sqlite3.Error as e:
            raise EntryNotFoundError(f"Failed to get all entries from database: {e}")

    def create_entry(self, title: str, body: str, category: str):
        try:
            cursor = self.conn.cursor()

            self.conn.execute("""
                INSERT INTO entries (TITLE, BODY, CATEGORY)
                VALUES (?, ?)
            """, (title, body, category))

            entry_id = cursor.lastrowid

            self.conn.commit()
            
            if not entry_id:
                raise EntryCreationError("Failed to create entry: no ID returned upon commit.")

            row = cursor.fetchone() 
            return row
        
        except sqlite3.IntegrityError as e:
            raise EntryCreationError(f"Database constrain violation: {e}.")
        
        except sqlite3.Error as e:
            raise EntryCreationError(f"Database error: {e}.")