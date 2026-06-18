"""
Exécute toutes les requêtes du dossier sql/, exporte chaque résultat en CSV
dans results/, et génère 3 graphiques clés dans charts/ pour illustrer le
README sur GitHub.
"""

import sqlite3
import os
import pandas as pd
import matplotlib.pyplot as plt

DB_PATH = "database/ecommerce.db"
SQL_DIR = "sql"
RESULTS_DIR = "results"
CHARTS_DIR = "charts"

plt.rcParams.update({
    "figure.facecolor": "#0f1115",
    "axes.facecolor": "#0f1115",
    "axes.edgecolor": "#444",
    "axes.labelcolor": "#e8e8e8",
    "text.color": "#e8e8e8",
    "xtick.color": "#cccccc",
    "ytick.color": "#cccccc",
    "grid.color": "#2a2d33",
    "font.size": 10,
})

GOLD = "#E8A838"
GOLD_DIM = "#9c7427"


def run_all_queries():
    os.makedirs(RESULTS_DIR, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)

    dataframes = {}
    for filename in sorted(os.listdir(SQL_DIR)):
        if not filename.endswith(".sql"):
            continue
        name = filename.replace(".sql", "")
        with open(os.path.join(SQL_DIR, filename), encoding="utf-8") as f:
            query = f.read()
        df = pd.read_sql_query(query, conn)
        dataframes[name] = df
        df.to_csv(os.path.join(RESULTS_DIR, f"{name}.csv"), index=False)
        print(f"OK  {name:45s} -> {len(df)} lignes")

    conn.close()
    return dataframes


def make_charts(dfs):
    os.makedirs(CHARTS_DIR, exist_ok=True)

    # ---- Chart 1 : revenu mensuel + croissance -----------------------------
    df1 = dfs["01_revenu_mensuel_croissance"]
    fig, ax = plt.subplots(figsize=(10, 4.5))
    ax.bar(df1["mois"], df1["revenu"], color=GOLD)
    ax.set_title("Revenu mensuel (commandes livrées)", fontsize=13, color=GOLD)
    ax.set_ylabel("Revenu (€)")
    ax.tick_params(axis="x", rotation=75, labelsize=7)
    fig.tight_layout()
    fig.savefig(os.path.join(CHARTS_DIR, "01_revenu_mensuel.png"), dpi=150)
    plt.close(fig)

    # ---- Chart 2 : répartition des segments RFM -----------------------------
    df2 = dfs["02_segmentation_rfm"]
    counts = df2["segment_rfm"].value_counts()
    fig, ax = plt.subplots(figsize=(7, 5))
    colors = [GOLD, "#c9c9c9", GOLD_DIM, "#6b6b6b", "#3d3d3d"]
    ax.pie(
        counts.values, labels=counts.index, autopct="%1.0f%%",
        colors=colors[: len(counts)], textprops={"color": "#e8e8e8", "fontsize": 9},
        wedgeprops={"edgecolor": "#0f1115", "linewidth": 1.5},
    )
    ax.set_title("Répartition des clients par segment RFM", fontsize=13, color=GOLD)
    fig.tight_layout()
    fig.savefig(os.path.join(CHARTS_DIR, "02_segments_rfm.png"), dpi=150)
    plt.close(fig)

    # ---- Chart 3 : rétention par cohorte (heatmap simplifiée) ---------------
    df3 = dfs["03_cohortes_retention"]
    pivot = df3.pivot(index="mois_cohorte", columns="mois_ecoule", values="taux_retention_pct")
    # garde un sous-échantillon de cohortes pour rester lisible
    pivot = pivot.iloc[::3]
    fig, ax = plt.subplots(figsize=(10, 5))
    im = ax.imshow(pivot.values, cmap="YlOrBr", aspect="auto", vmin=0, vmax=100)
    ax.set_xticks(range(len(pivot.columns)))
    ax.set_xticklabels(pivot.columns)
    ax.set_yticks(range(len(pivot.index)))
    ax.set_yticklabels(pivot.index, fontsize=8)
    ax.set_xlabel("Mois écoulés depuis inscription")
    ax.set_title("Taux de rétention par cohorte (%)", fontsize=13, color=GOLD)
    cbar = fig.colorbar(im, ax=ax)
    cbar.ax.yaxis.set_tick_params(color="#cccccc")
    fig.tight_layout()
    fig.savefig(os.path.join(CHARTS_DIR, "03_cohortes_retention.png"), dpi=150,
                facecolor="#0f1115")
    plt.close(fig)

    print("\nGraphiques générés dans charts/")


if __name__ == "__main__":
    dfs = run_all_queries()
    make_charts(dfs)
