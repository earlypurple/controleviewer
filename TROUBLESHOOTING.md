# Guide de Dépannage - ControleViewer

## 🚨 Problèmes Courants

### 1. L'application ne compile pas

#### Erreur: "Package.swift not found"
**Solution:** Assurez-vous d'être dans le bon répertoire
```bash
cd /chemin/vers/controleviewer
swift build
```

#### Erreur de permissions Xcode
**Solution:** Acceptez les accords de licence Xcode
```bash
sudo xcodebuild -license accept
```

### 2. La caméra ne fonctionne pas

#### Caméra non accessible
**Causes possibles:**
- Une autre application utilise la caméra
- Permissions non accordées
- Caméra déconnectée (Mac externe)

**Solutions:**
1. Fermez toutes les autres applications utilisant la caméra (Zoom, FaceTime, etc.)
2. Vérifiez les permissions dans Préférences Système > Sécurité et confidentialité > Caméra
3. Redémarrez l'application

#### Image de la caméra est noire
**Solutions:**
- Vérifiez l'éclairage de la pièce
- Nettoyez l'objectif de la caméra
- Testez avec une autre application de caméra

### 3. Les gestes ne sont pas détectés

#### Gestes non reconnus
**Solutions:**
1. **Améliorez l'éclairage** - La détection nécessite un bon éclairage
2. **Positionnement** - Placez votre main à 50-100cm de la caméra
3. **Visibilité** - Assurez-vous que votre main entière est visible
4. **Arrière-plan** - Utilisez un arrière-plan contrasté

#### Détection intermittente
**Ajustements possibles:**
- Réduisez le seuil de confiance dans `CameraManager.swift`:
```swift
guard thumbTip.confidence > 0.5, // Au lieu de 0.7
```
- Améliorez la stabilité de votre main
- Réduisez les mouvements rapides

### 4. Le contrôle ne fonctionne pas

#### Permissions d'accessibilité
**Solution obligatoire:**
1. Allez dans **Préférences Système** > **Sécurité et confidentialité**
2. Cliquez sur **Accessibilité** (dans l'onglet Confidentialité)
3. Cliquez sur le cadenas et entrez votre mot de passe
4. Ajoutez l'application ControleViewer à la liste
5. Cochez la case à côté de l'application

#### Curseur ne bouge pas
**Vérifications:**
- L'option "Contrôle par gestes" est activée
- Les permissions d'accessibilité sont accordées
- Aucun autre logiciel de contrôle n'interfère

### 5. Connexion iPhone problématique

#### iPhone non détecté
**Solutions:**
1. **Même réseau** - Assurez-vous que Mac et iPhone sont sur le même WiFi
2. **Bluetooth** - Activez Bluetooth sur les deux appareils
3. **Firewall** - Vérifiez que le firewall n'est pas bloqué
4. **Redémarrage** - Redémarrez la découverte sur les deux appareils

#### Connexion instable
**Solutions:**
- Rapprochez les appareils
- Redémarrez le WiFi
- Fermez les autres applications réseau intensives

### 6. Performance et latence

#### Application lente
**Optimisations:**
1. Fermez les autres applications gourmandes
2. Réduisez la résolution de la caméra si possible
3. Réduisez le nombre de gestes activés

#### Latence élevée
**Solutions:**
- Vérifiez l'utilisation CPU (Activity Monitor)
- Réduisez la fréquence d'images de la caméra
- Optimisez l'éclairage pour une meilleure détection

## 🔧 Diagnostics Techniques

### Vérification des logs
```bash
# Lancer avec debug
swift run controleviewer --verbose

# Vérifier les logs système
log show --predicate 'subsystem == "com.exemple.controleviewer"' --last 5m
```

### Test de la caméra
```bash
# Tester l'accès caméra avec une autre app
open /System/Applications/Photo\ Booth.app
```

### Vérification des permissions
```bash
# Vérifier les permissions d'accessibilité
sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db \
"SELECT client,auth_value FROM access WHERE service='kTCCServiceAccessibility';"
```

## 📞 Support Avancé

### Collecte d'informations pour le support
Avant de signaler un problème, collectez ces informations:

```bash
# Version macOS
sw_vers

# Informations matériel
system_profiler SPHardwareDataType SPCameraDataType

# Processes utilisant la caméra
lsof | grep -i camera

# Statut des permissions
tccutil list
```

### Réinitialisation complète
Si rien ne fonctionne:

1. **Supprimer les préférences:**
```bash
rm -rf ~/Library/Preferences/com.exemple.controleviewer.*
```

2. **Réinitialiser les permissions:**
```bash
tccutil reset Camera
tccutil reset Accessibility
```

3. **Recompiler depuis zéro:**
```bash
swift package clean
swift build
```

## 🆘 Derniers Recours

### Cas d'urgence
Si l'application plante votre système:

1. **Forcer l'arrêt:** Cmd+Option+Esc
2. **Redémarrage sécurisé:** Maintenez Shift au démarrage
3. **Réinitialiser NVRAM:** Cmd+Option+P+R au démarrage

### Rapporter un bug
Incluez dans votre rapport:
- Version macOS
- Étapes pour reproduire
- Messages d'erreur complets
- Logs de l'application
- Configuration système (processeur, mémoire, caméra)

---
**Besoin d'aide?** Consultez le README.md ou ouvrez une issue GitHub.
