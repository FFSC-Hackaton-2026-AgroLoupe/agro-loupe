# AgroLoupe

> Identifier les maladies des cultures à partir d'une photo de feuille — **sans connexion internet**.

AgroLoupe est une application mobile destinée aux petits producteurs. On prend une photo d'une
feuille, l'application l'analyse **directement sur le téléphone** grâce à un modèle d'intelligence
artificielle embarqué, puis affiche la maladie probable, un niveau de confiance et une fiche de
traitement.

Aucune connexion n'est nécessaire pour le diagnostic : c'est le cœur du projet. En zone rurale,
le réseau est souvent absent au moment précis où l'on a besoin de l'outil.

Projet réalisé dans le cadre du **FlutterFire Summer Camp**.

---

## Pourquoi ce projet

| Objectif de Développement Durable | Contribution |
|---|---|
| **ODD 2 — Faim zéro** (principal) | Réduire les pertes de récolte en détectant les maladies tôt, sans attendre la visite d'un technicien |
| **ODD 12 — Consommation et production responsables** (secondaire) | Traiter la bonne maladie avec le bon produit, au lieu de pulvériser « au cas où » |

**Utilisateur cible :** petit producteur, réseau faible ou absent, téléphone Android d'entrée de gamme.

---

## Ce que fait l'application

Le périmètre du MVP tient en quatre points :

1. **Prendre ou importer une photo** d'une feuille.
2. **Diagnostiquer hors-ligne** : nom de la maladie + taux de confiance.
3. **Afficher la fiche de traitement** correspondante (consultable hors-ligne grâce au cache).
4. **Conserver l'historique** des diagnostics sur l'appareil.

En dessous de **60 % de confiance**, l'application affiche « Diagnostic incertain » et invite à
reprendre la photo ou à consulter un agent agricole. Un résultat faible n'est jamais présenté
comme une certitude.

**Hors périmètre** (assumé) : comptes utilisateurs, carte, partage, paiement.

---

## Comment ça marche

```
   Photo ──► Redimensionnement ──► Modèle TFLite ──► Maladie + confiance
  (caméra      et normalisation       (embarqué,              │
  ou galerie)                        hors-ligne)              │
                                                              ▼
   Historique local  ◄───────────────────────────  Fiche de traitement
   (SQLite, sur l'appareil)                        (Firestore, mise en cache)
```

Les photos et l'historique **ne quittent jamais le téléphone**. Firestore ne sert qu'à distribuer
les fiches de traitement, en lecture seule.

---

## Stack technique

| Rôle | Choix |
|---|---|
| Framework | Flutter (canal stable), Dart 3 |
| Gestion d'état | `provider` (ChangeNotifier) |
| IA embarquée | `tflite_flutter` + `image` |
| Photo | `image_picker` |
| Stockage local | `sqflite` (historique), `shared_preferences` (réglages) |
| Backend | Firebase, **plan Spark uniquement** : `firebase_core`, `cloud_firestore` |
| Connectivité | `connectivity_plus` |
| Tests | `flutter_test`, `mocktail` |

> **Contrainte assumée :** ni Cloud Storage ni Cloud Functions (ils exigent le plan payant Blaze).
> Le dépôt étant public, les Security Rules Firestore sont verrouillées : lecture seule sur les
> fiches, aucune écriture depuis l'application.

---

## Démarrage rapide

**Prérequis**

- Flutter 3.35 ou plus récent (canal `stable`) — vérifier avec `flutter doctor`
- Un appareil Android ou un émulateur
- Les modèles de `assets/models/` — celui du manioc est versionné ; celui de la
  tomate et du maïs se produit avec [`tools/plantvillage_to_tflite.md`](tools/plantvillage_to_tflite.md)

**Installation**

```bash
git clone https://github.com/FFSC-Hackaton-2026-AgroLoupe/agro-loupe.git
cd agro-loupe
flutter pub get
flutter run
```

**Configuration Firebase**

Le fichier `lib/firebase_options.dart` n'est pas versionné tel quel : générez-le avec

```bash
flutterfire configure
```

---

## Commandes utiles

```bash
flutter pub get               # Installer les dépendances
flutter analyze               # Analyse statique (doit passer sans aucun avertissement)
dart format .                 # Formater le code
flutter test                  # Lancer les tests
flutter run                   # Lancer sur l'appareil connecté
flutter build apk --release   # Construire l'APK de démonstration
```

---

## Modèles de diagnostic

L'application couvre trois cultures au moyen de deux modèles, tous deux exécutés
sur l'appareil, sans réseau.

| Culture | Modèle | Classes | Sortie |
|---|---|---|---|
| Manioc | **CropNet** (Google) | 6 | probabilités |
| Tomate · Maïs | **PlantVillage** MobileNet V2 (Rishit Dagli) | 38, dont 10 tomate et 4 maïs | probabilités |

Les deux attendent la même entrée — 224 × 224 pixels, RGB entre 0 et 1 — et
renvoient directement des probabilités. **Ne pas leur appliquer de softmax** :
la page Kaggle du second annonce des logits, mais la mesure sur le modèle
converti donne une somme de 1,000. Un softmax de plus écraserait les scores
sous le seuil de confiance, sans provoquer la moindre erreur.

L'utilisateur choisit sa culture avant de photographier : seules les classes de
cette culture sont ensuite prises en compte, ce qui améliore nettement la
précision par rapport à un choix parmi 38 possibilités.

Attributions et licences complètes dans [`NOTICE`](NOTICE).

---

## Architecture du code

Organisation **par fonctionnalité**, avec trois couches dans chacune :

```
lib/
├── main.dart          # Initialisation puis runApp
├── app.dart           # MaterialApp, thème, MultiProvider racine
├── core/              # Transverse : thème, erreurs, services, utilitaires
├── shared/widgets/    # Widgets réutilisés par plusieurs fonctionnalités
└── features/
    ├── diagnosis/     # Photo → modèle → résultat
    ├── treatments/    # Fiches de traitement (Firestore)
    └── history/       # Historique local (SQLite)
```

Chaque fonctionnalité contient `data/` (accès aux services), `models/` (données immuables),
`state/` (providers) et `ui/` (écrans et widgets). Le sens des dépendances est toujours
**`ui → state → data → models`**, jamais l'inverse.

### Les règles à respecter

| Couche | A le droit de | N'a PAS le droit de |
|---|---|---|
| `data/` | Appeler les packages externes (TFLite, Firestore, SQLite) | Importer `material.dart`, connaître un provider |
| `models/` | Porter `fromJson`, `toJson`, `copyWith` | Accéder au réseau ou au disque |
| `state/` | Appeler les repositories, exposer un état | Construire des widgets, utiliser `BuildContext` |
| `ui/` | Lire les providers, afficher l'état | Appeler directement un service ou Firestore |

Une fonctionnalité n'importe jamais le dossier `data/` d'une autre : on passe par un repository
injecté via Provider.

Quelques conventions transverses :

- Chaque provider expose **un état unique** décrit par une `sealed class`, traité côté UI par un
  `switch` exhaustif. Pas de booléens `isLoading` / `hasError` éparpillés.
- `context.read()` pour déclencher une action, `context.watch()` ou `context.select()` pour afficher.
- Les couches `data/` lèvent des exceptions métier portant un message en français ; les providers
  les transforment en état d'erreur. Jamais de `catch` vide.
- Modèles immuables, widgets `const` dès que possible, `debugPrint` au lieu de `print`.
- Textes affichés en français, simples, pour un utilisateur non technicien.

> Le guide de développement complet de l'équipe n'est pas versionné ici ; il est partagé
> directement entre les membres.

---

## État d'avancement

- [x] Cahier des charges et règles de développement
- [x] Modèle du manioc (CropNet) embarqué
- [ ] Modèle tomate et maïs (conversion PlantVillage à faire)
- [x] Dépendances et squelette de l'architecture
- [ ] Fonctionnalité *diagnosis* (photo → résultat)
- [ ] Fonctionnalité *treatments* (Firestore + règles de sécurité)
- [ ] Fonctionnalité *history* (SQLite)
- [ ] Intégration continue (`flutter analyze` + `flutter test` sur chaque PR)

---

## Équipe

| Membre | Rôle |
|---|---|
| **Darius HOUESSOU-KODE** | Chef d'équipe (Lead) |
| **LETISSIA ALLOU** | Membre |
| **BABA Traoré Hannatou** | Membre |
| **HOUEGBE Uriel** | Membre |
| **NABOUDJA Tchapo Joseph** | Membre |

Projet encadré par le **FlutterFire Summer Camp** — édition 2026.

---

## Contribuer

- La branche `main` est protégée : on passe **toujours** par une Pull Request relue par un autre membre.
- Nommage des branches : `feat/<sujet>`, `fix/<sujet>`, `chore/<sujet>`.
- Messages de commit au format [Conventional Commits](https://www.conventionalcommits.org/fr/) :
  `feat: ajoute l'écran de résultat`, `fix: corrige le crash sans caméra`.
- Avant d'ouvrir une PR : `dart format .`, `flutter analyze` et `flutter test` doivent passer.
- Aucun secret dans le dépôt.
