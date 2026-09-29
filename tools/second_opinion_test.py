"""Teste le deuxième avis en ligne, hors application.

But : décider si Gemini rattrape les cas où le modèle embarqué se trompe,
*avant* d'écrire la moindre ligne de Dart. Le cas de référence est la photo
de thrips, sur laquelle PlantVillage répond « alternariose » à 97,1 % de
confiance alors qu'il s'agit d'un ravageur absent de ses 38 classes.

Usage :
    python tools/second_opinion_test.py photo.jpg --culture tomate

La clé est lue dans .env et n'est jamais affichée.
"""

from __future__ import annotations

import argparse
import base64
import io
import json
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

from PIL import Image, ImageOps

RACINE = Path(__file__).resolve().parent.parent
FICHES = RACINE / "assets" / "data" / "treatments.json"

# Côté téléphone, l'utilisateur est souvent en 2G : on envoie une image
# réduite, pas la photo de 12 Mpx. L'application devra faire pareil.
COTE_MAX = 768
QUALITE_JPEG = 80


def lire_env() -> dict[str, str]:
    """Lit .env sans dépendance externe."""
    chemin = RACINE / ".env"
    if not chemin.exists():
        sys.exit("Fichier .env introuvable. Copier .env.example en .env.")

    valeurs: dict[str, str] = {}
    for ligne in chemin.read_text(encoding="utf-8").splitlines():
        ligne = ligne.strip()
        if not ligne or ligne.startswith("#") or "=" not in ligne:
            continue
        cle, _, valeur = ligne.partition("=")
        valeurs[cle.strip()] = valeur.strip()

    manquantes = [
        c
        for c in ("RODIUM_API_KEY", "RODIUM_BASE_URL", "RODIUM_MODEL")
        if not valeurs.get(c)
    ]
    if manquantes:
        sys.exit("Valeurs absentes dans .env : " + ", ".join(manquantes))
    return valeurs


def charger_etiquettes(culture: str | None) -> list[dict[str, str]]:
    """Les étiquettes réellement présentes dans notre catalogue.

    On ne laisse pas le modèle nommer librement une maladie : il choisit
    parmi nos fiches, ou répond « aucune ». Ainsi la règle 1 est respectée
    par construction — il identifie, il ne prescrit jamais — et il n'y a
    aucun appariement approximatif à faire ensuite.
    """
    fiches = json.loads(FICHES.read_text(encoding="utf-8"))["treatments"]
    if culture:
        connues = sorted({f["crop"] for f in fiches})
        fiches = [f for f in fiches if f["crop"] == culture]
        if not fiches:
            sys.exit(f"Culture inconnue. Valeurs possibles : {connues}")
    return [
        {"etiquette": f["modelLabel"], "nom": f["name"], "culture": f["crop"]}
        for f in fiches
    ]


def construire_prompt(etiquettes: list[dict[str, str]], culture: str | None) -> str:
    liste = "\n".join(
        f"- {e['etiquette']} : {e['nom']} ({e['culture']})" for e in etiquettes
    )
    precision = (
        f"L'utilisateur a indiqué cultiver : {culture}."
        if culture
        else "L'utilisateur n'a pas précisé la culture."
    )
    return f"""Tu aides un petit producteur agricole d'Afrique de l'Ouest à identifier
ce qui affecte sa plante, à partir d'une photo de feuille.

{precision}

Choisis au plus une étiquette dans cette liste, et rien d'autre :
{liste}

Règles impératives :
1. Tu identifies seulement. Tu ne donnes JAMAIS de conseil de traitement,
   ni de produit, ni de dose. Les conseils viennent de fiches rédigées par
   des agronomes.
2. Si aucune étiquette ne convient, réponds etiquette = null et explique ce
   que tu vois. Répondre « je ne sais pas » est une bonne réponse, bien
   meilleure qu'une étiquette choisie par défaut.
3. Beaucoup de dégâts viennent de ravageurs (thrips, acariens, chenilles)
   et non de maladies. Dis-le si c'est le cas.
4. Pas de pourcentage ni de score : une certitude que tu t'attribues
   toi-même n'est pas comparable à celle d'un modèle calculé.

Réponds uniquement par un objet JSON, sans texte autour :
{{
  "etiquette": "<une étiquette de la liste, ou null>",
  "nom": "<nom français de la maladie, ou null>",
  "certitude": "haute | moyenne | faible",
  "observation": "<ce qui est visible sur la feuille, une ou deux phrases,
                   en français simple>",
  "ravageur_plutot_que_maladie": true ou false,
  "raison_si_aucune": "<pourquoi aucune étiquette ne convient, ou null>"
}}"""


def preparer_image(chemin: Path) -> tuple[str, int]:
    """Redresse, réduit et encode l'image. Renvoie (base64, octets)."""
    with Image.open(chemin) as image:
        image = ImageOps.exif_transpose(image).convert("RGB")
        image.thumbnail((COTE_MAX, COTE_MAX))
        tampon = io.BytesIO()
        image.save(tampon, format="JPEG", quality=QUALITE_JPEG)
    donnees = tampon.getvalue()
    return base64.b64encode(donnees).decode("ascii"), len(donnees)


def interroger(env: dict[str, str], prompt: str, image_b64: str) -> str:
    corps = {
        "model": env["RODIUM_MODEL"],
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    {
                        "type": "image_url",
                        "image_url": {"url": f"data:image/jpeg;base64,{image_b64}"},
                    },
                ],
            }
        ],
        "max_tokens": 600,
    }
    requete = urllib.request.Request(
        env["RODIUM_BASE_URL"].rstrip("/") + "/chat/completions",
        data=json.dumps(corps).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {env['RODIUM_API_KEY']}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(requete, timeout=60) as reponse:
            charge = json.loads(reponse.read().decode("utf-8"))
    except urllib.error.HTTPError as erreur:
        detail = erreur.read().decode("utf-8", "replace")[:500]
        sys.exit(f"HTTP {erreur.code} : {detail}")
    except urllib.error.URLError as erreur:
        sys.exit(f"Connexion impossible : {erreur.reason}")
    return charge["choices"][0]["message"]["content"]


def afficher(texte: str) -> None:
    """Affiche la réponse, en JSON lisible si c'en est."""
    nettoye = texte.strip().removeprefix("```json").removeprefix("```")
    nettoye = nettoye.removesuffix("```").strip()
    try:
        objet = json.loads(nettoye)
    except json.JSONDecodeError:
        print("Réponse non-JSON :\n" + texte)
        return
    print(json.dumps(objet, ensure_ascii=False, indent=2))


def main() -> None:
    analyseur = argparse.ArgumentParser(description=__doc__)
    analyseur.add_argument("photo", type=Path, help="chemin de la photo à tester")
    analyseur.add_argument(
        "--culture",
        choices=["manioc", "tomate", "maïs"],
        help="culture choisie par l'utilisateur, comme dans l'application",
    )
    arguments = analyseur.parse_args()

    if not arguments.photo.exists():
        sys.exit(f"Photo introuvable : {arguments.photo}")

    env = lire_env()
    etiquettes = charger_etiquettes(arguments.culture)
    image_b64, octets = preparer_image(arguments.photo)

    print(f"Modèle    : {env['RODIUM_MODEL']}")
    print(f"Étiquettes: {len(etiquettes)}")
    print(f"Image     : {octets / 1024:.0f} Ko après réduction à {COTE_MAX} px")

    debut = time.monotonic()
    reponse = interroger(env, construire_prompt(etiquettes, arguments.culture), image_b64)
    print(f"Latence   : {time.monotonic() - debut:.1f} s\n")

    afficher(reponse)


if __name__ == "__main__":
    main()
