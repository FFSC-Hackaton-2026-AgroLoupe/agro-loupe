# Convertir le modèle PlantVillage en TFLite

Le modèle de Rishit Dagli (38 classes, MobileNetV2, Apache 2.0) n'est publié qu'en
SavedModel. Ce carnet le convertit en `.tflite` utilisable par l'application, et
produit son fichier d'étiquettes.

Ouvrir [colab.research.google.com](https://colab.research.google.com), créer un
carnet vide, puis coller chaque cellule dans l'ordre. Durée : environ 15 minutes,
sans GPU.

---

### Cellule 1 — Récupérer le SavedModel

```python
!curl -sSL -o plantvillage.tar.gz \
  "https://www.kaggle.com/models/rishitdagli/plant-disease/tensorFlow2/plant-disease/1/download"
!mkdir -p saved && tar -xzf plantvillage.tar.gz -C saved
!ls saved
```

Attendu : `saved_model.pb` et `variables`.

---

### Cellule 2 — Convertir en TFLite

La quantification en float16 divise le poids par deux pour une perte de précision
négligeable — ce qui compte pour un APK destiné à des téléphones d'entrée de gamme.

```python
import tensorflow as tf

converter = tf.lite.TFLiteConverter.from_saved_model("saved")
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.target_spec.supported_types = [tf.float16]
tflite_model = converter.convert()

with open("plantvillage.tflite", "wb") as f:
    f.write(tflite_model)

print(f"{len(tflite_model)/1e6:.1f} Mo")
```

**Si cette cellule échoue**, réessayer sans quantification — le fichier sera plus
lourd mais utilisable :

```python
converter = tf.lite.TFLiteConverter.from_saved_model("saved")
tflite_model = converter.convert()
open("plantvillage.tflite", "wb").write(tflite_model)
print(f"{len(tflite_model)/1e6:.1f} Mo")
```

---

### Cellule 3 — Construire le fichier d'étiquettes

L'ordre des lignes doit suivre exactement l'ordre des sorties du modèle.

```python
import json, urllib.request

URL = ("https://github.com/Rishit-dagli/Greenathon-Plant-AI"
       "/releases/download/v0.1.0/class_indices.json")
index = json.load(urllib.request.urlopen(URL))
labels = [index[str(i)] for i in range(38)]

with open("plantvillage_labels.txt", "w") as f:
    f.write("\n".join(labels) + "\n")

print("Classes qui nous intéressent :")
for i, nom in enumerate(labels):
    if nom.startswith(("Corn_", "Tomato")):
        print(f"  {i:>2}  {nom}")
```

Attendu : 4 classes de maïs (index 7 à 10), 10 de tomate (index 28 à 37).

---

### Cellule 4 — Vérifier la conversion

```python
import numpy as np

interp = tf.lite.Interpreter(model_path="plantvillage.tflite")
interp.allocate_tensors()
entree = interp.get_input_details()[0]
sortie = interp.get_output_details()[0]

print("ENTREE :", entree["shape"], entree["dtype"])
print("SORTIE :", sortie["shape"], sortie["dtype"])

# Image grise neutre : sert uniquement à voir la forme de la sortie.
interp.set_tensor(entree["index"], np.full((1, 224, 224, 3), 0.5, dtype=np.float32))
interp.invoke()
y = interp.get_tensor(sortie["index"])[0]

print(f"sortie : min {y.min():.3f}  max {y.max():.3f}  somme {y.sum():.3f}")
print("=> somme proche de 1 : probabilités | sinon : logits, softmax nécessaire")
```

Résultat constaté : entrée `[1 224 224 3] float32`, sortie `[1 38] float32`,
somme **égale à 1,000**. Le modèle renvoie donc des probabilités, contrairement
à ce qu'annonce sa page Kaggle. Aucun softmax ne doit être appliqué côté
application.

---

### Cellule 5 — Essai sur une vraie photo (recommandé)

Téléverser une photo de feuille de tomate ou de maïs.

```python
from google.colab import files

envoi = files.upload()
nom = list(envoi)[0]

img = tf.io.decode_image(tf.io.read_file(nom), channels=3, expand_animations=False)
img = tf.image.resize(tf.cast(img, tf.float32) / 255.0, (224, 224))[None, ...]

interp.set_tensor(entree["index"], img.numpy())
interp.invoke()
y = interp.get_tensor(sortie["index"])[0]
p = tf.nn.softmax(y).numpy()

for i in p.argsort()[::-1][:3]:
    print(f"{p[i]*100:5.1f}%   {labels[i]}")
```

---

### Cellule 6 — Récupérer les fichiers

```python
from google.colab import files
files.download("plantvillage.tflite")
files.download("plantvillage_labels.txt")
```

Déposer ensuite les deux fichiers dans `assets/models/` du projet.

---

## À me renvoyer

Colle-moi la sortie des **cellules 4 et 5**. Elles me donnent la forme exacte des
tenseurs et confirment si la sortie est en logits — ce qui détermine le
post-traitement côté application.
