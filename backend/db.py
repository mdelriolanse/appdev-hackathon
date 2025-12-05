import os
import psycopg2
from psycopg2 import extras
from exceptions import EntryCreationError, EntryNotFoundError, JournalEntryError
import datetime
from dotenv import load_dotenv
from typing import List, Optional

load_dotenv()

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
        Secures connection with PostgreSQL database for reading / writing.
        Uses environment variables for connection parameters.
        """
        self.conn = psycopg2.connect(
            host=os.getenv("DB_HOST", "localhost"),
            port=os.getenv("DB_PORT", "5432"),
            database=os.getenv("DB_NAME", "postgres"),
            user=os.getenv("DB_USER", "postgres"),
            password=os.getenv("DB_PASSWORD", "")
        )
        self.conn.autocommit = False
        self.create_tables()

    def create_tables(self):
        """
        Creates all required tables: entries, categories, entry_categories, and evidence.
        """
        try:
            cursor = self.conn.cursor()
            
            # Entries table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS entries (
                    id SERIAL PRIMARY KEY,
                    title TEXT,
                    body TEXT,
                    timestamp TIMESTAMP
                );
            """)
            
            # Categories table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS categories (
                    id SERIAL PRIMARY KEY,
                    name VARCHAR(30) UNIQUE NOT NULL
                );
            """)
            
            # Entry-Categories linking table (many-to-many)
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS entry_categories (
                    entry_id INTEGER REFERENCES entries(id) ON DELETE CASCADE,
                    category_id INTEGER REFERENCES categories(id) ON DELETE CASCADE,
                    PRIMARY KEY (entry_id, category_id)
                );
            """)
            
            # Evidence table (one-to-many with entries)
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS evidence (
                    id SERIAL PRIMARY KEY,
                    entry_id INTEGER REFERENCES entries(id) ON DELETE CASCADE NOT NULL,
                    claim_text TEXT NOT NULL,
                    source_title TEXT,
                    source_url TEXT
                );
            """)
            
            self.conn.commit()
        except psycopg2.Error as e:
            self.conn.rollback()
            print(f"Error initializing tables in database: {e}")

    # ==================== ENTRIES ====================

    def get_all_entries(self):
        """
        Retrieves all entries with their categories.
        """
        try:
            cursor = self.conn.cursor(cursor_factory=extras.RealDictCursor)
            cursor.execute("""
                SELECT e.id, e.title, e.body, e.timestamp,
                       COALESCE(array_agg(c.name) FILTER (WHERE c.name IS NOT NULL), '{}') as categories
                FROM entries e
                LEFT JOIN entry_categories ec ON e.id = ec.entry_id
                LEFT JOIN categories c ON ec.category_id = c.id
                GROUP BY e.id
                ORDER BY e.timestamp DESC;
            """)
            rows = cursor.fetchall()
            return rows

        except psycopg2.Error as e:
            raise EntryNotFoundError(f"Failed to get all entries from database: {e}")

    def get_entry_by_id(self, entry_id: int):
        """
        Retrieves a single entry by ID with its categories.
        """
        try:
            cursor = self.conn.cursor(cursor_factory=extras.RealDictCursor)
            cursor.execute("""
                SELECT e.id, e.title, e.body, e.timestamp,
                       COALESCE(array_agg(c.name) FILTER (WHERE c.name IS NOT NULL), '{}') as categories
                FROM entries e
                LEFT JOIN entry_categories ec ON e.id = ec.entry_id
                LEFT JOIN categories c ON ec.category_id = c.id
                WHERE e.id = %s
                GROUP BY e.id;
            """, (entry_id,))
            row = cursor.fetchone()
            if not row:
                raise EntryNotFoundError(f"Entry with id {entry_id} not found")
            return row

        except psycopg2.Error as e:
            raise EntryNotFoundError(f"Failed to get entry from database: {e}")

    def create_entry(self, title: str, body: str, category_names: List[str] = None):
        """
        Creates an entry and associates it with categories.
        
        :param title: title of the entry
        :param body: contents of the entry
        :param category_names: list of category names to associate
        """
        try:
            time_now = datetime.datetime.now()
            cursor = self.conn.cursor(cursor_factory=extras.RealDictCursor)
            
            # Insert entry
            cursor.execute("""
                INSERT INTO entries (title, body, timestamp)
                VALUES (%s, %s, %s)
                RETURNING id, title, body, timestamp
            """, (title, body, time_now))
            entry = cursor.fetchone()
            
            if not entry:
                raise EntryCreationError("Failed to create entry: no row returned.")
            
            # Associate categories
            categories = []
            if category_names:
                for cat_name in category_names:
                    cat_id = self._get_or_create_category(cursor, cat_name)
                    cursor.execute("""
                        INSERT INTO entry_categories (entry_id, category_id)
                        VALUES (%s, %s)
                        ON CONFLICT DO NOTHING
                    """, (entry['id'], cat_id))
                    categories.append(cat_name)
            
            self.conn.commit()
            entry['categories'] = categories
            return entry
        
        except psycopg2.IntegrityError as e:
            self.conn.rollback()
            raise EntryCreationError(f"Database constraint violation: {e}.")
        
        except psycopg2.Error as e:
            self.conn.rollback()
            raise EntryCreationError(f"Database error: {e}.")

    def _get_or_create_category(self, cursor, name: str) -> int:
        """
        Gets existing category ID or creates new one.
        """
        cursor.execute("""
            INSERT INTO categories (name)
            VALUES (%s)
            ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
            RETURNING id
        """, (name.lower(),))
        return cursor.fetchone()['id']

    # ==================== CATEGORIES ====================

    def get_all_categories(self):
        """
        Retrieves all categories.
        """
        try:
            cursor = self.conn.cursor(cursor_factory=extras.RealDictCursor)
            cursor.execute("SELECT id, name FROM categories ORDER BY name;")
            return cursor.fetchall()
        except psycopg2.Error as e:
            raise JournalEntryError(f"Failed to get categories: {e}")

    def create_category(self, name: str):
        """
        Creates a new category.
        """
        try:
            cursor = self.conn.cursor(cursor_factory=extras.RealDictCursor)
            cursor.execute("""
                INSERT INTO categories (name)
                VALUES (%s)
                RETURNING id, name
            """, (name.lower(),))
            row = cursor.fetchone()
            self.conn.commit()
            return row
        except psycopg2.IntegrityError:
            self.conn.rollback()
            raise JournalEntryError(f"Category '{name}' already exists.")
        except psycopg2.Error as e:
            self.conn.rollback()
            raise JournalEntryError(f"Failed to create category: {e}")

    # ==================== EVIDENCE ====================

    def get_evidence_for_entry(self, entry_id: int):
        """
        Retrieves all evidence records for a given entry.
        """
        try:
            cursor = self.conn.cursor(cursor_factory=extras.RealDictCursor)
            cursor.execute("""
                SELECT id, entry_id, claim_text, source_title, source_url
                FROM evidence
                WHERE entry_id = %s;
            """, (entry_id,))
            return cursor.fetchall()
        except psycopg2.Error as e:
            raise JournalEntryError(f"Failed to get evidence: {e}")

    def create_evidence(self, entry_id: int, claim_text: str, source_title: str = None, source_url: str = None):
        """
        Creates an evidence record for an entry.
        
        :param entry_id: ID of the entry this evidence belongs to
        :param claim_text: the claim being fact-checked
        :param source_title: title of the corroborating source
        :param source_url: URL of the corroborating source
        """
        try:
            cursor = self.conn.cursor(cursor_factory=extras.RealDictCursor)
            cursor.execute("""
                INSERT INTO evidence (entry_id, claim_text, source_title, source_url)
                VALUES (%s, %s, %s, %s)
                RETURNING id, entry_id, claim_text, source_title, source_url
            """, (entry_id, claim_text, source_title, source_url))
            row = cursor.fetchone()
            self.conn.commit()
            return row
        except psycopg2.IntegrityError as e:
            self.conn.rollback()
            raise JournalEntryError(f"Invalid entry_id or constraint violation: {e}")
        except psycopg2.Error as e:
            self.conn.rollback()
            raise JournalEntryError(f"Failed to create evidence: {e}")

    def create_evidence_batch(self, entry_id: int, evidence_list: List[dict]):
        """
        Creates multiple evidence records for an entry.
        
        :param entry_id: ID of the entry
        :param evidence_list: list of dicts with claim_text, source_title, source_url
        """
        try:
            cursor = self.conn.cursor(cursor_factory=extras.RealDictCursor)
            results = []
            for ev in evidence_list:
                cursor.execute("""
                    INSERT INTO evidence (entry_id, claim_text, source_title, source_url)
                    VALUES (%s, %s, %s, %s)
                    RETURNING id, entry_id, claim_text, source_title, source_url
                """, (entry_id, ev.get('claim_text'), ev.get('source_title'), ev.get('source_url')))
                results.append(cursor.fetchone())
            self.conn.commit()
            return results
        except psycopg2.Error as e:
            self.conn.rollback()
            raise JournalEntryError(f"Failed to create evidence batch: {e}")


# Only <=1 instance of the database driver
# exists within the app at all times
DataBaseDriver = singleton(DataBaseDriver)

if __name__ == "__main__":
    db = DataBaseDriver()
    print("db candid initialized")
