import sqlite3
from exceptions import EntryCreationError, EntryNotFoundError, JournalEntryError
import datetime
def singleton(cls):
    instances = {}

    def getinstance():
        if cls not in instances:
            instances[cls] = cls()
        return instances[cls]

    return getinstance

class DataBaseDriver(object):
    """
    Database driver for the candid app.
    Handles with reading and writing data with the database.
    """
    def __init__(self):
        """
        secures connection with candid.db for reading / writing
        """
        self.conn = sqlite3.connect("candid.db", check_same_thread=False)
        self.conn.row_factory = sqlite3.Row
        self.create_entries_table()

    def create_entries_table(self):
        """
        using SQL, creates the entries table
        

        """
        try:
            self.conn.execute(f"""
                CREATE TABLE IF NOT EXISTS entries (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    TITLE TEXT,
                    BODY TEXT,
                    CATEGORY VARCHAR (30) NOT NULL,
                    timestamp DATETIME
                );
            """)

            self.conn.commit()
        except sqlite3.Error as e:
            print(f"Error initializing entries table in database: {e}")

    def get_all_entries(self):
        """
        SQL function to retrieve all entries from candid.db
        """
        try:
            cursor = self.conn.cursor()
            self.conn.execute(f"""
                SELECT (id, TITLE, BODY, CATEGORY,timestamp) FROM entries;
            """
            )

            rows = cursor.fetchall()

            return rows

        except sqlite3.Error as e:
            raise EntryNotFoundError(f"Failed to get all entries from database: {e}")

    def create_entry(self, title: str, body: str, category:str="misc"):
        """
        creates an entry in candid.db entries table
        
        :param title: title of the entry
        :type title: str
        :param body: contents of the entry
        :type body: str
        :param category: category of the entry
        :type category: str
        """
        try:
            time_now = str(datetime.datetime.now())
            
            cursor = self.conn.cursor()
            #Changing this to cursor.execute 
            cursor.execute("""
                INSERT INTO entries (TITLE, BODY, CATEGORY, timestamp)
                VALUES (?, ?, ?, ?)
            """, (title, body, category,time_now))

            entry_id = cursor.lastrowid

            self.conn.commit()
            
            if not entry_id:
                raise EntryCreationError("Failed to create entry: no ID returned upon commit.")

            row = cursor.fetchone() 
            return row 
        #chatGPT said returning a dict was better idk for sure tho
        
        except sqlite3.IntegrityError as e:
            raise EntryCreationError(f"Database constrain violation: {e}.")
        
        except sqlite3.Error as e:
            raise EntryCreationError(f"Database error: {e}.")
       
# Only <=1 instance of the database driver
# exists within the app at all times
DataBaseDriver = singleton(DataBaseDriver)

if __name__ == "__main__":
    db = DataBaseDriver()
    print("db venmo initialized")
        