"""Injecte le catalogue des fiches dans Firestore.

Écrit `assets/data/treatments.json` dans le document `catalogue/current`,
celui que l'application relit pour corriger ses fiches embarquées.

Pourquoi ce script et pas l'application : les règles Firestore refusent toute
écriture depuis un client. L'écriture passe ici par l'API REST avec un jeton
`gcloud`, c'est-à-dire avec les droits d'administration du projet — lesquels
contournent les règles par conception. Corriger une fiche reste donc un geste
d'administration, jamais une action d'utilisateur : une fiche conseille des
produits phytosanitaires.

Aucune clé de service n'est stockée sur le disque : le jeton vient de
`gcloud auth print-access-token`, valable une heure.

Usage :
    gcloud auth login              # une seule fois
    python tools/seed_catalogue.py            # version locale + 1
    python tools/seed_catalogue.py --version 5
    python tools/seed_catalogue.py --dry-run  # montre sans écrire
"""

from __future__ import annotations

import argparse
import io
import json
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
FICHES = RACINE / "assets" / "data" / "treatments.json"
COLLECTION = "catalogue"
DOCUMENT = "current"


def projet() -> str:
    """Identifiant du projet, lu dans .firebaserc."""
    chemin = RACINE / ".firebaserc"
    if not chemin.exists():
        sys.exit("Fichier .firebaserc introuvable.")
    config = json.loads(chemin.read_text(encoding="utf-8"))
    identifiant = config.get("projects", {}).get("default")
    if not identifiant:
        sys.exit("Aucun projet par défaut dans .firebaserc.")
    return identifiant


def jeton() -> str:
    """Jeton d'accès, obtenu de gcloud."""
    try:
        resultat = subprocess.run(
            ["gcloud", "auth", "print-access-token"],
            capture_output=True,
            text=True,
            check=True,
            shell=sys.platform == "win32",
        )
    except FileNotFoundError:
        sys.exit("gcloud est introuvable. Installez le Google Cloud SDK.")
    except subprocess.CalledProcessError as erreur:
        sys.exit(f"gcloud a refusé : {erreur.stderr.strip()}\nEssayez : gcloud auth login")
    return resultat.stdout.strip()


def valeur(donnee: object) -> dict:
    """Convertit une valeur JSON au format typé de Firestore."""
    if donnee is None:
        return {"nullValue": None}
    if isinstance(donnee, bool):
        return {"booleanValue": donnee}
    if isinstance(donnee, int):
        # Firestore attend les entiers en chaîne de caractères.
        return {"integerValue": str(donnee)}
    if isinstance(donnee, float):
        return {"doubleValue": donnee}
    if isinstance(donnee, str):
        return {"stringValue": donnee}
    if isinstance(donnee, list):
        return {"arrayValue": {"values": [valeur(x) for x in donnee]}}
    if isinstance(donnee, dict):
        return {"mapValue": {"fields": {c: valeur(v) for c, v in donnee.items()}}}
    raise TypeError(f"Type non pris en charge : {type(donnee)}")


def envoyer(identifiant: str, corps: dict, acces: str) -> None:
    url = (
        f"https://firestore.googleapis.com/v1/projects/{identifiant}"
        f"/databases/(default)/documents/{COLLECTION}/{DOCUMENT}"
    )
    requete = urllib.request.Request(
        url,
        data=json.dumps(corps).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {acces}",
            "Content-Type": "application/json",
        },
        method="PATCH",
    )
    try:
        with urllib.request.urlopen(requete, timeout=60) as reponse:
            reponse.read()
    except urllib.error.HTTPError as erreur:
        detail = erreur.read().decode("utf-8", "replace")[:600]
        sys.exit(f"HTTP {erreur.code} : {detail}")
    except urllib.error.URLError as erreur:
        sys.exit(f"Connexion impossible : {erreur.reason}")


def main() -> None:
    analyseur = argparse.ArgumentParser(description=__doc__)
    analyseur.add_argument(
        "--version",
        type=int,
        help="version à publier ; par défaut, celle du fichier local + 1",
    )
    analyseur.add_argument(
        "--dry-run",
        action="store_true",
        help="affiche ce qui serait envoyé, sans rien écrire",
    )
    arguments = analyseur.parse_args()

    catalogue = json.loads(FICHES.read_text(encoding="utf-8"))
    locale = catalogue.get("version", 0)
    version = arguments.version if arguments.version is not None else locale + 1

    if version <= locale:
        sys.exit(
            f"La version {version} ne dépasse pas celle du fichier embarqué "
            f"({locale}) : l'application l'ignorerait."
        )

    fiches = catalogue["treatments"]
    corps = {
        "fields": {
            "version": valeur(version),
            "avertissement": valeur(catalogue.get("avertissement")),
            "treatments": valeur(fiches),
        }
    }

    identifiant = projet()
    taille = len(json.dumps(corps).encode("utf-8"))

    print(f"Projet    : {identifiant}")
    print(f"Document  : {COLLECTION}/{DOCUMENT}")
    print(f"Fiches    : {len(fiches)}")
    print(f"Version   : {locale} (embarquée) -> {version} (publiée)")
    print(f"Taille    : {taille / 1024:.0f} Ko sur 1024 Ko autorisés")

    if arguments.dry_run:
        print("\nEssai à blanc : rien n'a été écrit.")
        return

    envoyer(identifiant, corps, jeton())
    print("\nCatalogue publié.")


if __name__ == "__main__":
    main()
