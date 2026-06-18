"""
Génération d'une base de données e-commerce synthétique mais réaliste.
Objectif : avoir un terrain de jeu SQL crédible pour des analyses avancées
(RFM, cohortes, ABC analysis, window functions...) sans dépendre d'un
dataset externe.

Période simulée : Janvier 2023 -> Décembre 2025 (3 ans)
"""

import sqlite3
import random
from datetime import date, timedelta

random.seed(42)

DB_PATH = "database/ecommerce.db"

# ---------------------------------------------------------------------------
# Référentiels
# ---------------------------------------------------------------------------

CATEGORIES = [
    "Électronique", "Mode", "Maison & Jardin", "Sport & Loisirs",
    "Beauté & Santé", "Livres & Papeterie", "Informatique", "Animalerie",
]

PRODUCT_NAMES = {
    "Électronique": ["Casque Bluetooth", "Enceinte portable", "Montre connectée",
                      "Chargeur sans fil", "Caméra sport", "Barre de son",
                      "Tablette 10\"", "Power bank 20000mAh"],
    "Mode": ["Sneakers urbaines", "Veste légère", "Sac à dos cuir", "Jean coupe droite",
             "T-shirt coton bio", "Casquette brodée", "Ceinture cuir", "Pull col rond"],
    "Maison & Jardin": ["Lampe LED design", "Set de rangement", "Plaid polaire",
                         "Diffuseur d'huiles", "Coussin déco", "Plante artificielle",
                         "Tapis salon", "Kit jardinage"],
    "Sport & Loisirs": ["Tapis de yoga", "Haltères réglables", "Gourde isotherme",
                         "Sac de sport", "Corde à sauter", "Élastiques fitness",
                         "Vélo pliant", "Tente 2 places"],
    "Beauté & Santé": ["Crème hydratante", "Sérum vitamine C", "Brosse électrique",
                        "Coffret soin visage", "Huile essentielle", "Parfum 50ml",
                        "Kit manucure", "Brumisateur"],
    "Livres & Papeterie": ["Roman best-seller", "Agenda 2026", "Carnet ligné A5",
                            "Stylo plume", "BD collector", "Pack post-it",
                            "Calendrier mural", "Livre de cuisine"],
    "Informatique": ["Souris sans fil", "Clavier mécanique", "Webcam HD",
                      "Disque SSD 1To", "Hub USB-C", "Support ordinateur",
                      "Tapis de souris XXL", "Casque gaming"],
    "Animalerie": ["Croquettes premium", "Jouet interactif chat", "Laisse rétractable",
                   "Panier moelleux", "Gamelle anti-glouton", "Litière agglomérante",
                   "Friandises dentaires", "Arbre à chat"],
}

CHANNELS = ["Organique", "Publicité Meta", "Publicité Google", "Email marketing",
            "Affiliation", "Réseaux sociaux"]
CHANNEL_WEIGHTS = [0.30, 0.22, 0.18, 0.12, 0.08, 0.10]

CITIES = ["Paris", "Lyon", "Marseille", "Toulouse", "Lille", "Bordeaux",
          "Nantes", "Strasbourg", "Nice", "Rennes"]

FIRST_NAMES = ["Léa", "Hugo", "Manon", "Louis", "Camille", "Nathan", "Chloé", "Lucas",
               "Inès", "Adam", "Sarah", "Tom", "Emma", "Jules", "Anna", "Noé",
               "Jade", "Liam", "Zoé", "Gabriel", "Lina", "Raphaël", "Mia", "Théo"]
LAST_NAMES = ["Martin", "Bernard", "Dubois", "Thomas", "Robert", "Petit", "Richard",
              "Durand", "Leroy", "Moreau", "Simon", "Laurent", "Lefebvre", "Michel",
              "Garcia", "David", "Bertrand", "Roux", "Vincent", "Fournier"]

START = date(2023, 1, 1)
END = date(2025, 12, 31)
TOTAL_DAYS = (END - START).days


def random_date_weighted_growth():
    """Tire une date avec une légère croissance du volume dans le temps
    (plus de commandes en 2025 qu'en 2023), pour rendre l'analyse de
    tendance / MoM growth pertinente."""
    r = random.random() ** 1.6  # biaise vers les dates récentes
    offset = int(r * TOTAL_DAYS)
    return START + timedelta(days=offset)


def random_signup_date(max_date):
    offset = random.randint(0, (max_date - START).days)
    return START + timedelta(days=offset)


# ---------------------------------------------------------------------------
# Construction de la base
# ---------------------------------------------------------------------------

def build_database():
    import os
    os.makedirs("database", exist_ok=True)

    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    cur.executescript("""
    DROP TABLE IF EXISTS order_items;
    DROP TABLE IF EXISTS orders;
    DROP TABLE IF EXISTS products;
    DROP TABLE IF EXISTS categories;
    DROP TABLE IF EXISTS customers;

    CREATE TABLE categories (
        category_id   INTEGER PRIMARY KEY,
        category_name TEXT NOT NULL
    );

    CREATE TABLE products (
        product_id    INTEGER PRIMARY KEY,
        product_name  TEXT NOT NULL,
        category_id   INTEGER NOT NULL,
        unit_price    REAL NOT NULL,
        cost_price    REAL NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(category_id)
    );

    CREATE TABLE customers (
        customer_id    INTEGER PRIMARY KEY,
        first_name     TEXT NOT NULL,
        last_name      TEXT NOT NULL,
        city           TEXT NOT NULL,
        signup_date    TEXT NOT NULL,
        acquisition_channel TEXT NOT NULL
    );

    CREATE TABLE orders (
        order_id      INTEGER PRIMARY KEY,
        customer_id   INTEGER NOT NULL,
        order_date    TEXT NOT NULL,
        status        TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    );

    CREATE TABLE order_items (
        order_item_id INTEGER PRIMARY KEY,
        order_id      INTEGER NOT NULL,
        product_id    INTEGER NOT NULL,
        quantity      INTEGER NOT NULL,
        unit_price    REAL NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(order_id),
        FOREIGN KEY (product_id) REFERENCES products(product_id)
    );
    """)

    # Categories
    cat_ids = {}
    for i, cat in enumerate(CATEGORIES, start=1):
        cur.execute("INSERT INTO categories VALUES (?, ?)", (i, cat))
        cat_ids[cat] = i

    # Products
    product_id = 1
    product_rows = []
    for cat, names in PRODUCT_NAMES.items():
        for name in names:
            base_price = round(random.uniform(8, 250), 2)
            cost = round(base_price * random.uniform(0.35, 0.65), 2)
            product_rows.append((product_id, name, cat_ids[cat], base_price, cost))
            product_id += 1
    cur.executemany("INSERT INTO products VALUES (?, ?, ?, ?, ?)", product_rows)

    # Customers (900 clients, signup étalé avec croissance)
    n_customers = 900
    customer_rows = []
    for cid in range(1, n_customers + 1):
        fname = random.choice(FIRST_NAMES)
        lname = random.choice(LAST_NAMES)
        city = random.choice(CITIES)
        signup = random_signup_date(date(2025, 10, 1))
        channel = random.choices(CHANNELS, weights=CHANNEL_WEIGHTS, k=1)[0]
        customer_rows.append((cid, fname, lname, city, signup.isoformat(), channel))
    cur.executemany("INSERT INTO customers VALUES (?, ?, ?, ?, ?, ?)", customer_rows)

    # Segmentation comportementale cachée (pour rendre les analyses RFM/churn
    # crédibles) : chaque client a un profil d'activité.
    profiles = random.choices(
        ["champion", "loyal", "occasionnel", "un_coup", "inactif"],
        weights=[0.08, 0.17, 0.30, 0.20, 0.25],
        k=n_customers,
    )

    profile_order_count = {
        "champion": (18, 30),
        "loyal": (8, 17),
        "occasionnel": (3, 7),
        "un_coup": (1, 2),
        "inactif": (1, 1),
    }

    # Intervalle typique (en jours) entre deux commandes, propre à chaque
    # profil. Indépendant de la fenêtre restante avant END pour éviter un
    # effet de bord artificiel (sur-densité de commandes juste avant la
    # date de fin de simulation).
    profile_gap_range = {
        "champion": (12, 40),
        "loyal": (25, 70),
        "occasionnel": (45, 130),
        "un_coup": (5, 45),
        "inactif": (5, 45),
    }

    all_products = product_rows  # (id, name, cat_id, price, cost)

    order_id = 1
    order_item_id = 1
    order_rows = []
    order_item_rows = []

    for cid, signup, profile in zip(
        [r[0] for r in customer_rows],
        [r[4] for r in customer_rows],
        profiles,
    ):
        signup_d = date.fromisoformat(signup)
        lo, hi = profile_order_count[profile]
        n_orders = random.randint(lo, hi)

        # Les clients "inactifs" n'ont commandé qu'au début (churn réel)
        if profile == "inactif":
            order_window_end = min(signup_d + timedelta(days=60), END)
        else:
            order_window_end = END

        gap_lo, gap_hi = profile_gap_range[profile]
        last_order_date = signup_d
        for _ in range(n_orders):
            gap = random.randint(gap_lo, gap_hi)
            order_date = last_order_date + timedelta(days=gap)
            if order_date > order_window_end or order_date > END:
                break
            last_order_date = order_date

            status = random.choices(
                ["Livrée", "Livrée", "Livrée", "Annulée", "Remboursée"],
                weights=[0.7, 0.15, 0.05, 0.06, 0.04],
                k=1,
            )[0]

            order_rows.append((order_id, cid, order_date.isoformat(), status))

            n_items = random.randint(1, 4)
            chosen = random.sample(all_products, k=n_items)
            for p in chosen:
                qty = random.randint(1, 3)
                # petite variation de prix (promos)
                price = round(p[3] * random.uniform(0.85, 1.0), 2)
                order_item_rows.append(
                    (order_item_id, order_id, p[0], qty, price)
                )
                order_item_id += 1

            order_id += 1

    cur.executemany("INSERT INTO orders VALUES (?, ?, ?, ?)", order_rows)
    cur.executemany("INSERT INTO order_items VALUES (?, ?, ?, ?, ?)", order_item_rows)

    conn.commit()

    print(f"Catégories     : {len(CATEGORIES)}")
    print(f"Produits       : {len(product_rows)}")
    print(f"Clients        : {len(customer_rows)}")
    print(f"Commandes      : {len(order_rows)}")
    print(f"Lignes commande: {len(order_item_rows)}")

    conn.close()


if __name__ == "__main__":
    build_database()
