import psycopg2
import log
import json

try:
    conn = psycopg2.connect("dbname=storeit user=server host=localhost")
except e:
    log.logger.error('could not connect to db')

def find_user(username: str, password: str):

    cur = conn.cursor()
    cur.execute("SELECT * FROM client WHERE username = '" + username + "'")

    rows = cur.fetchall()

    cur.close()
    return None if rows == [] else rows[0][3]

def save_new_tree(username: str, tree: dict):

    strtree = json.dumps(tree)

    conn = psycopg2.connect("dbname=storeit user=server host=localhost")

    cur = conn.cursor()

    request = "UPDATE client SET file_tree = '" + strtree + "' WHERE username = '" + username + "'"

    cur.execute(request)
    conn.commit()
    cur.close()
