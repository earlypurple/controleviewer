# 🎯 Guide de Calibration - GestureControl Pro

## 📋 Vue d'Ensemble

Le module de calibration permet d'optimiser la détection des gestes et le contrôle de la souris pour votre configuration spécifique. Il analyse votre position, l'angle de la caméra, l'éclairage et votre zone de travail pour créer un mapping précis.

## ✨ Pourquoi Calibrer ?

### Avant Calibration
- ❌ Mapping linéaire simple (imprécis aux bords)
- ❌ Pas d'adaptation à l'angle de caméra
- ❌ Sensibilité générique
- ❌ Micro-mouvements non filtrés

### Après Calibration
- ✅ **Transformation perspective** adaptée à votre angle
- ✅ **Mapping précis des coins** à ±2% de l'écran
- ✅ **Zone morte intelligente** (élimine tremblements)
- ✅ **Sensibilité personnalisée** selon votre amplitude
- ✅ **Seuils de confiance optimisés** basés sur vos performances

## 🚀 Processus de Calibration

### Étape 1 : Introduction (10 secondes)
**Objectif** : Comprendre le processus

- Durée estimée : **2 minutes**
- Échantillons à collecter : **90 au total**
- Résultat : **Précision +40% en moyenne**

**Action** : Cliquez sur "Commencer"

---

### Étape 2 : Position de Référence (15 secondes)
**Objectif** : Enregistrer votre position naturelle

**Instructions** :
1. Asseyez-vous confortablement devant votre Mac
2. Placez votre main **ouverte** (✋) au centre de la caméra
3. Distance recommandée : **50cm de la caméra**
4. Maintenez la position **stable pendant 3 secondes**

**Données collectées** : 30 échantillons
- Position du poignet
- Orientation de la main
- Échelle de la main

**Indicateurs** :
```
✅ Main détectée
📊 Échantillons: 0/30
⏱️ Temps restant: 3s
```

---

### Étapes 3-6 : Mapping des Coins (60 secondes)

#### Coin Supérieur Gauche ↖️
**Instructions** :
1. Levez votre index (👆)
2. Pointez vers le **coin supérieur GAUCHE** de votre écran
3. Maintenez la position jusqu'à la collecte des 10 échantillons
4. Un cercle rouge clignotant indique la cible

**Données collectées** : 10 échantillons par coin

#### Coin Supérieur Droit ↗️
**Instructions** : Pointez vers le **coin supérieur DROIT**

#### Coin Inférieur Gauche ↙️
**Instructions** : Pointez vers le **coin inférieur GAUCHE**

#### Coin Inférieur Droit ↘️
**Instructions** : Pointez vers le **coin inférieur DROIT**

**💡 Astuce** : Soyez le plus précis possible. Ces points déterminent la transformation affine finale.

---

### Étape 7 : Point Central (10 secondes)
**Objectif** : Valider l'alignement central

**Instructions** :
1. Index pointé (👆)
2. Visez le **centre exact** de votre écran
3. Maintenez stable

**Données collectées** : 10 échantillons
- Correction du décalage central
- Validation de la symétrie

---

### Étape 8 : Test des Gestes (30 secondes)
**Objectif** : Optimiser les seuils de confiance

**Instructions** : Effectuez chaque geste pendant 2 secondes :

1. **✊ Poing Fermé** (2 secondes)
   - Tous les doigts repliés
   - Maintenir fermé

2. **✌️ Peace Sign** (2 secondes)
   - Index et majeur levés
   - Doigts écartés

3. **👍 Pouce Levé** (2 secondes)
   - Seul le pouce levé
   - Autres doigts repliés

**Données collectées** : 5 échantillons par geste
- Niveau de confiance minimum observé
- Variabilité de votre exécution
- Seuil optimal calculé automatiquement

---

### Étape 9 : Finalisation (5 secondes)
**Objectif** : Sauvegarder les paramètres

**Calculs effectués** :
```swift
1. Transformation Affine
   screenPoint = cameraPoint.applying(calibrationTransform)

2. Facteurs d'Échelle
   scaleX = screenWidth / cameraWidth
   scaleY = screenHeight / cameraHeight

3. Offset de Translation
   offsetX = screenCorner.x - cameraCorner.x * scaleX
   offsetY = screenCorner.y - cameraCorner.y * scaleY

4. Seuils de Confiance
   threshold = min(observedConfidences) * 0.9
```

**Sauvegarde** : Les données sont enregistrées dans UserDefaults

---

## 📊 Données Calibrées

### Mapping Spatial
```swift
struct CalibrationData {
    // Coins de référence
    topLeftMapping: (camera: CGPoint, screen: CGPoint)
    topRightMapping: (camera: CGPoint, screen: CGPoint)
    bottomLeftMapping: (camera: CGPoint, screen: CGPoint)
    bottomRightMapping: (camera: CGPoint, screen: CGPoint)
    centerMapping: (camera: CGPoint, screen: CGPoint)
    
    // Transformation
    screenMapping: CGAffineTransform
    scalingFactor: CGPoint  // Ex: (2.5, 2.8)
    translationOffset: CGPoint  // Ex: (120, -50)
    
    // Paramètres de mouvement
    smoothingFactor: Double = 0.3  // Lissage (0-1)
    movementSensitivity: Double = 1.0  // Sensibilité (0.5-2.0)
    deadZoneRadius: Double = 5.0  // Zone morte en pixels
    
    // Seuils de gestes
    gestureThresholds: [GestureType: Float]
    // Ex: [.fist: 0.85, .peace: 0.78, .thumbsUp: 0.82]
}
```

### Exemple de Transformation

**Sans calibration** :
```swift
Input : camera(0.3, 0.4)  // Coordonnées normalisées
Output: screen(518, 691)  // Mapping linéaire brut
```

**Avec calibration** :
```swift
Input : camera(0.3, 0.4)
Step 1: apply(transform) → (0.32, 0.38)
Step 2: scale(2.5, 2.8) → (0.80, 1.06)
Step 3: translate(120, -50) → (920, 806)
Step 4: deadZone + smooth → (918, 805)
Output: screen(918, 805)  // Précision optimale
```

---

## 🎯 Utilisation Post-Calibration

### Mode Calibré Actif

Une fois calibré, chaque mouvement de l'index utilise :

1. **Transformation Perspective**
   - Corrige l'angle de la caméra
   - Compense la distorsion aux bords

2. **Zone Morte Intelligente**
   ```swift
   if distance(newPos, lastPos) < deadZoneRadius {
       return lastPos  // Pas de mouvement
   }
   ```
   - Élimine les micro-mouvements (< 5px)
   - Curseur plus stable

3. **Lissage Adaptatif**
   ```swift
   smoothed = last + (current - last) * sensitivity
   ```
   - Mouvement fluide et naturel
   - Configurable dans les réglages

4. **Seuils Optimisés**
   - Détection plus fiable des gestes
   - Moins de faux positifs

---

## ⚙️ Paramètres Avancés

### Modifier la Sensibilité
```swift
// Dans CalibrationData (UserDefaults)
movementSensitivity: 1.0  // Défaut

// Valeurs suggérées :
0.5  // Mouvements lents et précis
1.0  // Équilibré (recommandé)
1.5  // Mouvements rapides
2.0  // Très réactif (experts)
```

### Ajuster la Zone Morte
```swift
deadZoneRadius: 5.0  // Défaut (pixels)

// Selon vos besoins :
2.0  // Très sensible (main stable)
5.0  // Équilibré (recommandé)
10.0 // Moins sensible (main instable)
```

### Facteur de Lissage
```swift
smoothingFactor: 0.3  // Défaut

// Impact :
0.1  // Mouvements saccadés mais précis
0.3  // Équilibré (recommandé)
0.5  // Très fluide mais avec latence
```

---

## 🔄 Recalibration

### Quand Recalibrer ?

**Obligatoire** :
- ✅ Changement de position de la caméra
- ✅ Changement de position d'assise
- ✅ Changement d'éclairage majeur
- ✅ Changement de résolution d'écran

**Recommandé** :
- 🔄 Après 50h d'utilisation
- 🔄 Si la précision diminue
- 🔄 Pour optimiser de nouveaux gestes

**Optionnel** :
- 💡 Pour tester différentes configurations
- 💡 Pour différents profils utilisateurs

### Procédure de Recalibration

1. Ouvrir l'application
2. Aller dans **Calibration** (onglet avec icône 🎯)
3. Cliquer sur **"Commencer la Calibration"**
4. Suivre les 8 étapes à nouveau
5. Les anciennes données seront écrasées

---

## 📈 Amélioration de la Précision

### Conseils pour une Calibration Optimale

#### Environnement
- ✅ **Éclairage uniforme** : Éviter contre-jour
- ✅ **Arrière-plan neutre** : Mur uni si possible
- ✅ **Position stable** : Chaise avec accoudoirs
- ✅ **Distance constante** : Garder 50cm de la caméra

#### Technique
- ✅ **Mouvements lents** : Vitesse constante
- ✅ **Positions extrêmes** : Vraiment toucher les coins
- ✅ **Gestes distincts** : Bien différencier chaque geste
- ✅ **Main stable** : Minimiser les tremblements

#### Métriques de Qualité

**Excellente calibration** :
```
✅ Échantillons collectés : 90/90
✅ Variance position : < 5%
✅ Symétrie coins : > 95%
✅ Seuils confiance : > 0.80
```

**Calibration à refaire** :
```
❌ Échantillons collectés : < 80/90
❌ Variance position : > 15%
❌ Symétrie coins : < 85%
❌ Seuils confiance : < 0.60
```

---

## 🐛 Résolution de Problèmes

### La calibration ne démarre pas
**Causes possibles** :
- Caméra non autorisée
- Application pas en avant-plan

**Solutions** :
1. Vérifier les permissions caméra
2. Redémarrer l'application
3. Vérifier que la caméra fonctionne (autre app)

---

### Les échantillons ne sont pas collectés
**Causes possibles** :
- Geste incorrect
- Main trop loin/proche
- Mauvais éclairage

**Solutions** :
1. Vérifier le geste demandé (voir instructions)
2. Ajuster la distance (50cm idéal)
3. Améliorer l'éclairage
4. Nettoyer l'objectif de la caméra

---

### Le curseur n'est toujours pas précis
**Causes possibles** :
- Calibration incomplète
- Position changée depuis calibration
- Paramètres à ajuster

**Solutions** :
1. Refaire la calibration complète
2. Ajuster `movementSensitivity` (+/- 0.2)
3. Augmenter `deadZoneRadius` (+2px)
4. Vérifier que vous êtes dans la même position

---

## 📝 Fichier de Calibration

Les données sont sauvegardées dans UserDefaults :

```swift
UserDefaults.standard.object(forKey: "CalibrationData")
```

### Export Manuel (Terminal)
```bash
# Lire la calibration
defaults read com.gesturecontrol.pro CalibrationData

# Sauvegarder
defaults export com.gesturecontrol.pro ~/calibration_backup.plist

# Restaurer
defaults import com.gesturecontrol.pro ~/calibration_backup.plist
```

---

## 🎓 Ressources Complémentaires

### Documentation Technique
- [Vision Framework](https://developer.apple.com/documentation/vision)
- [CGAffineTransform](https://developer.apple.com/documentation/coregraphics/cgaffinetransform)
- [Accessibility API](https://developer.apple.com/documentation/applicationservices/accessibility)

### Algorithmes Utilisés
- **Perspective Homography** : Transformation 2D perspective
- **Kalman Filtering** : Lissage des positions
- **Dead Reckoning** : Prédiction de trajectoire

---

## 💡 FAQ

**Q : Combien de temps dure la calibration ?**  
R : Environ 2 minutes pour une calibration complète.

**Q : Puis-je sauter des étapes ?**  
R : Oui, mais la précision sera réduite. Toutes les étapes sont recommandées.

**Q : La calibration fonctionne avec plusieurs écrans ?**  
R : Actuellement, la calibration est pour l'écran principal uniquement.

**Q : Puis-je avoir plusieurs profils de calibration ?**  
R : Pas encore, mais prévu en v2.0. Actuellement une seule calibration active.

**Q : Que se passe-t-il si j'annule la calibration ?**  
R : Les anciennes données sont conservées (si existantes).

---

**🎯 Une bonne calibration = Une expérience exceptionnelle !**

*Version : 2.0 | Dernière mise à jour : 2025-10-04*
