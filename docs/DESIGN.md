# Tycoon Pollution — Document de design

> Migré depuis l'export Notion (juin 2026).

## Vision

Un **tycoon de la pollution** : le but du joueur est de **polluer le plus possible**.
La pollution est le cœur du jeu — c'est à la fois la *production* et le *score*.
On **vend** sa pollution à la **Mafia** pour obtenir de l'**argent**, qu'on réinvestit
dans davantage de machines… pour polluer encore plus.

```
Machines ──(pollution/sec)──► Pollution accumulée ──(vente Mafia)──► Argent ──(achat/upgrade)──► plus de machines
                                      │
                                      └──► Pollution TOTALE (à vie) = score "plus gros pollueur"
```

## Ressources

| Ressource          | Rôle                                                                 |
|--------------------|----------------------------------------------------------------------|
| **Pollution**      | Stock courant. Généré par les machines + le burner manuel. Se vide à la vente. |
| **Argent**         | Monnaie. Obtenu en vendant la pollution. Sert à acheter/améliorer les machines. |
| **Pollution du run** | Cumul de pollution depuis le dernier rebirth. **Pilote les paliers.** Remis à zéro au rebirth. |
| **Pollution Totale** | Cumul **à vie** (tous les runs), ne redescend jamais. C'est le **score** du classement (et pilote le smog). |
| **Cendres** *(prestige)* | Monnaie de prestige gagnée au rebirth, **permanente**. Sert à la boutique d'améliorations persistantes. |

## Boucle de jeu

1. Le joueur achète des machines (feux de camp) qui génèrent de la pollution/sec.
2. Il peut aussi **cliquer** une machine (burner manuel) pour polluer activement.
3. Il va voir la **Mafia** (ProximityPrompt) pour vendre sa pollution → argent.
4. Il réinvestit pour acheter/améliorer plus de machines.
5. Sa **Pollution Totale** grimpe → il monte au classement et le monde devient plus enfumé.

## Machines — Palier 1 actuel

Prototype actuellement versionné dans `MachineConfig`. Cette première chaîne est utile
pour tester achat/upgrade/rebirth, mais elle doit évoluer vers la matrice de machines par
palier proposée plus bas.

Chaque machine se débloque puis s'améliore sur **3 tiers**.
« Rendement » = pollution générée par seconde et par machine.

| Étape                       | Coût | Rendement/machine | Total Pollution/sec (cumulé) |
|-----------------------------|------|-------------------|------------------------------|
| 🔥 Machine 1                | 0    | 1                 | 1                            |
| 🔥 Machine 2                | 30   | 1                 | 2                            |
| 🔥 Machine 3                | 60   | 1                 | 3                            |
| 🔓 Tier 2 — Machine 1 (×1.5) | 100  | 1.5               | 3.5                          |
| 🔓 Tier 3 — Machine 1 (×2)   | 200  | 2                 | 5                            |
| 🔓 Tier 2 — Machine 2 (×1.5) | 150  | 1.5               | 4                            |
| 🔓 Tier 2 — Machine 3 (×1.5) | 300  | 1.5               | 4.5                          |
| 🔓 Tier 3 — Machine 2 (×2)   | 300  | 2                 | 5.5                          |
| 🔓 Tier 3 — Machine 3 (×2)   | 600  | 2                 | 6                            |

> Ces valeurs sont la **source de vérité du prototype actuel** et sont reproduites telles
> quelles dans `src/shared/Config/MachineConfig.luau`.

## Mafia (vente)

- Déclenchée par le `ProximityPrompt` du bloc Mafia.
- Convertit **toute** la pollution courante en argent : `argent = floor(pollution / 10)`
  (minimum 1 si la pollution est > 0).
- La pollution courante repasse à 0 ; la **Pollution Totale** n'est pas affectée.

## Burner manuel

- Cliquer un feu de camp ajoute de la pollution (cooldown 0,8 s).
- Pollution par clic = `BASE_POLLUTION × (LEVEL_MULTIPLIER ^ (niveau - 1))`.

## Mécaniques « polluer plus »

- **Pollution Totale + classement** : leaderstat à vie, affiché dans la liste des joueurs.
  Sert de base au classement du plus gros pollueur. *(Un classement global inter-serveurs
  nécessitera un `OrderedDataStore` — voir TODO.)*
- **Smog progressif** : plus la Pollution Totale est élevée, plus l'atmosphère devient
  dense et jaunâtre (récompense visuelle qui valorise la pollution).
  Géré côté client dans `src/client/UI/SmogDisplay.client.luau`.

## Paliers — évolution du terrain

Les **paliers ne sont pas des espaces séparés à acheter** : ce sont les **stades
d'évolution du même terrain**, qui se transforme à mesure que la **Pollution du run**
franchit des seuils. Plus on pollue pendant le run, plus le décor devient
apocalyptique. Chaque franchissement de palier déclenche une **animation de transition**
qui signale le passage au stade suivant.

> Vocabulaire : on parle désormais de **paliers**, pas de zones. Les noms techniques
> `ZoneService`, `ZoneConfig` et `ZoneReached` peuvent rester temporairement en code pour
> éviter une migration inutile, mais l'UI et le design doivent afficher « Palier ».

5 paliers, environ **10 machines par palier** (50 machines au total). Chaque machine
reste améliorable en 3 tiers comme au Palier 1 actuel : niveau 1, tier ×1.5, tier ×2.

| Palier | Thème machines | Décor | Ambiance | Palette |
|--------|----------------|-------|----------|---------|
| 1 | Brûlage artisanal sale | Terre sèche craquelée, sacs plastiques, palettes, pneus brûlés, carcasses de voitures, fumée noire | Feu, vents secs, musique lente grinçante | Brun/gris, fumée noire |
| 2 | Chantier industriel destructeur | Béton brut, piliers cassés, câbles, grues & convoyeurs rouillés, conteneurs toxiques, panneaux « DANGER » | Bruits mécaniques répétitifs, alarmes basses | Béton gris, rouge alarme |
| 3 | Charbon, vapeur et chaleur | Sol noirci, rails, tuyaux, chaudières, réservoirs sous pression, fumées vertes, vapeur, égouts | Vibrations, vapeur, coups de marteau | Jaune-orange, effet chaleur |
| 4 | Raffinerie toxique | Sol fissuré, flaques de pétrole, nuages de gaz, camions-citernes, bras robotiques, fuites chimiques, éclairs, gouttes acides | Grésillement chimique, bips toxiques, aspiration | Vert / violet / orange néon saturés |
| 5 | Apocalypse industrielle | Sol déformé & éclaté, fissures fumantes, vortex noir, cendres tombant du ciel, fumée rougeoyante | Sons graves vibrants, distorsions audio, tremblements | Rouge sombre / noir |

> Note de conception (auteur) : *« y'a des choses qu'on ne peut pas faire, on prend les
> idées qui sont possibles / on les adapte. »* → privilégier un **décor modulaire
> pré-construit** que l'on anime (apparition/disparition), plutôt que de la déformation
> procédurale de terrain (trop coûteuse).

### Système de paliers

- Le passage de palier est piloté par la **Pollution du run**, **pas par l'argent**.
- Chaque palier définit un `PollutionThreshold`. Un service serveur surveille la Pollution
  du run et émet un événement au franchissement.
- Progression suggérée (courbe géométrique, à équilibrer) :

  | Palier | Seuil Pollution du run (suggéré) |
  |--------|----------------------------------|
  | 1      | 0                                |
  | 2      | 1 000                            |
  | 3      | 10 000                           |
  | 4      | 100 000                          |
  | 5      | 1 000 000                        |

### Animation de transition (à implémenter)

Au franchissement d'un palier :
1. **Décor** : faire apparaître le nouveau set (tween d'échelle/position, surgissement du
   sol) et disparaître l'ancien (fondu / enfoncement).
2. **Sol & matériaux** : tween de `Color`/`Material` du terrain vers la palette du palier.
3. **Atmosphère & lumière** : transition de `Atmosphere` (Color/Density/Haze), `ClockTime`,
   `Ambient`, brouillard — prolonge le smog progressif déjà en place.
4. **Effets** : particules (fumée, cendres au palier 5, gouttes acides au palier 4,
   vapeur au palier 3), `ScreenShake` côté client au palier 5.
5. **Audio** : crossfade de l'ambiance sonore vers la piste du palier.
6. **Feedback joueur** : flash + bannière « PALIER 2 DÉBLOQUÉ » + son, courte vue caméra
   sur le nouveau décor.

### Machines intermédiaires

Chaque palier introduit environ **10 machines** à coût/pollution croissants, afin que le
joueur ait toujours un prochain achat visible entre deux transitions. Les valeurs ci-dessous
sont des **propositions d'équilibrage** pour `MachineConfig` ; elles devront être testées
en Studio avec la vente Mafia, le rebirth et la boutique prestige.

#### Palier 1 — brûlage artisanal sale

| Ordre | Machine | Coût niv. 1 | Pollution/sec niv. 1 |
|-------|---------|-------------|----------------------|
| 1 | Feu de camp industriel | 0 | 1 |
| 2 | Baril incinérateur | 30 | 2 |
| 3 | Tas de pneus brûlés | 80 | 3 |
| 4 | Brasero de déchets | 180 | 5 |
| 5 | Fosse de brûlage | 400 | 8 |
| 6 | Générateur diesel fuyant | 900 | 12 |
| 7 | Four de chantier | 1 800 | 18 |
| 8 | Broyeur plastique manuel | 3 500 | 26 |
| 9 | Compacteur de ferraille sale | 7 000 | 38 |
| 10 | Mini-incinérateur | 14 000 | 55 |

#### Palier 2 — chantier industriel destructeur

| Ordre | Machine | Coût niv. 1 | Pollution/sec niv. 1 |
|-------|---------|-------------|----------------------|
| 1 | Fosse à combustion | 30 000 | 90 |
| 2 | Convoyeur à déchets | 55 000 | 130 |
| 3 | Compacteur rouillé | 95 000 | 190 |
| 4 | Broyeur de palettes | 160 000 | 280 |
| 5 | Station d'huile usée | 260 000 | 420 |
| 6 | Four à pneus | 420 000 | 620 |
| 7 | Micro-usine de destruction | 680 000 | 900 |
| 8 | Pompe à goudron | 1 100 000 | 1 300 |
| 9 | Presse à ferraille | 1 800 000 | 1 900 |
| 10 | Crémateur industriel | 3 000 000 | 2 800 |

#### Palier 3 — charbon, vapeur et chaleur

| Ordre | Machine | Coût niv. 1 | Pollution/sec niv. 1 |
|-------|---------|-------------|----------------------|
| 1 | Compacteur brûleur | 5 000 000 | 4 500 |
| 2 | Chaudière à charbon | 8 000 000 | 6 500 |
| 3 | Locomotive à charbon statique | 13 000 000 | 9 500 |
| 4 | Four à coke | 21 000 000 | 14 000 |
| 5 | Broyeur de charbon | 34 000 000 | 20 000 |
| 6 | Soufflerie à cendres | 55 000 000 | 29 000 |
| 7 | Générateur vapeur sale | 90 000 000 | 42 000 |
| 8 | Réseau de tuyaux brûlants | 145 000 000 | 60 000 |
| 9 | Incinérateur de wagons | 230 000 000 | 86 000 |
| 10 | Centrale charbon miniature | 370 000 000 | 125 000 |

#### Palier 4 — raffinerie toxique

| Ordre | Machine | Coût niv. 1 | Pollution/sec niv. 1 |
|-------|---------|-------------|----------------------|
| 1 | Raffinerie primitive | 600 000 000 | 190 000 |
| 2 | Bassin d'acide | 950 000 000 | 280 000 |
| 3 | Station thermo-polluante | 1 500 000 000 | 420 000 |
| 4 | Craqueur pétrolier | 2 400 000 000 | 620 000 |
| 5 | Torchère de gaz | 3 800 000 000 | 900 000 |
| 6 | Réacteur chimique instable | 6 000 000 000 | 1 300 000 |
| 7 | Bras robot à rejets toxiques | 9 500 000 000 | 1 900 000 |
| 8 | Camion-citerne en fuite | 15 000 000 000 | 2 800 000 |
| 9 | Pompe à pétrole lourd | 24 000 000 000 | 4 100 000 |
| 10 | Tour de distillation sale | 38 000 000 000 | 6 000 000 |

#### Palier 5 — apocalypse industrielle

| Ordre | Machine | Coût niv. 1 | Pollution/sec niv. 1 |
|-------|---------|-------------|----------------------|
| 1 | Réacteur de combustion | 60 000 000 000 | 9 000 000 |
| 2 | Four plasma sale | 95 000 000 000 | 13 000 000 |
| 3 | Vortex de cendres | 150 000 000 000 | 19 000 000 |
| 4 | Trou noir industriel | 240 000 000 000 | 28 000 000 |
| 5 | Évent géothermique polluant | 380 000 000 000 | 41 000 000 |
| 6 | Méga-incinérateur | 600 000 000 000 | 60 000 000 |
| 7 | Centrale à smog rouge | 950 000 000 000 | 88 000 000 |
| 8 | Broyeur dimensionnel | 1 500 000 000 000 | 130 000 000 |
| 9 | Noyau de fusion instable | 2 400 000 000 000 | 190 000 000 |
| 10 | Extracteur de vide toxique | 3 800 000 000 000 | 280 000 000 |

## Rebirth (prestige)

La courbe de prix des machines est **volontairement très raide** : le coût d'une machine
dépasse largement ce qu'on peut accumuler au palier précédent. On finit par « buter » sur
un mur → c'est le signal pour **rebirth** plutôt que de grinder à l'infini.

**Le rebirth :**
- **Remet à zéro** : argent, machines possédées, pollution courante, et la **Pollution du
  run** (progression de paliers) → on repart au Palier 1.
- **Conserve** : les **Cendres**, les améliorations persistantes de la boutique, et la
  **Pollution Totale** (score à vie, jamais remis à zéro).
- **Récompense** : un gain de **Cendres** à courbe **géométrique** selon la progression
  atteinte. Grâce aux multiplicateurs de la boutique, chaque cycle est plus rapide que le
  précédent.

**Formule suggérée** (à équilibrer) :

```
-- par palier atteint (géométrique pur)
Cendres = floor( BASE * GROWTH ^ (palierAtteint - 1) )
-- ex. BASE=1, GROWTH=4  →  P1:1  P2:4  P3:16  P4:64  P5:256

-- ou en continu sur la pollution du run
Cendres = floor( (PollutionDuRun / SEUIL_BASE) ^ 0.5 )
```

### Courbe de prix (mur de progression)

Les coûts des machines croissent **plus vite** que les seuils de pollution : le prix d'une
machine de palier N dépasse de loin l'argent accumulable au palier N−1. Ce mur est **intentionnel**.
Suggestion : coût de base ×8–12 par palier (les seuils de pollution, eux, ×10 par palier).

## Boutique de prestige (améliorations persistantes)

Payées en **Cendres**, **conservées à travers les rebirths**. Chaque amélioration a des
niveaux à coût **géométrique** (ex. ×1.5 par niveau).

| Amélioration                       | Effet                                                  |
|------------------------------------|--------------------------------------------------------|
| Multiplicateur de revenu           | × pollution/sec de toutes les machines                 |
| Multiplicateur de vente (Mafia)    | × argent obtenu par pollution vendue                   |
| Réduction des coûts                | × coût d'achat/upgrade des machines (< 1)              |
| Boost du burner manuel             | × pollution générée par clic                           |
| Pactole de départ                  | argent de départ offert après chaque rebirth           |
| Gain de prestige                   | × Cendres gagnées au prochain rebirth (méta)           |

> Implémentation : ces multiplicateurs s'appliquent dans `Machine:generateIncome` (revenu),
> dans la conversion Mafia (`TycoonService`), dans `ManualBurnerService` (clic) et dans le
> calcul des coûts (`Purchasable`/`Machine`). Stockés par joueur, persistés via DataStore.

## Aléatoire, collection et placement libre

Le jeu peut évoluer vers un tycoon plus personnalisable : machines placées librement sur
une grille de plot, variantes aléatoires, raretés, doublons utiles, vente et recyclage.
La progression principale doit rester déterministe ; l'aléatoire sert surtout à créer de
la collection, du flex visuel et des optimisations.

UX cible : le roll doit se présenter comme une **caisse animée** type CS:GO, puis la
machine obtenue se place directement **à la souris** sur le plot avec preview, rotation et
validation serveur. Pas de placement final par champs X/Z visibles au joueur.

Voir la note dédiée : [`docs/RANDOMNESS_PLACEMENT.md`](RANDOMNESS_PLACEMENT.md).

## Notes techniques

### Ajouter une nouvelle machine

1. Ajouter une entrée dans `src/shared/Config/MachineConfig.luau` (voir le modèle commenté).
2. Dans **Roblox Studio**, placer :
   - le **modèle** de la machine dans `ReplicatedStorage.Tycoon.Machines`, avec un
     attribut `Id` = l'identifiant de la config ;
   - un **bouton** (Part) taggé `TycoonButton` avec un attribut `machineId` = ce même Id,
     possédant un sous-objet `Cost` (SurfaceGui/BillboardGui avec un TextLabel).
3. Chaîner l'affichage via `NextButton` dans la config (le bouton de la machine
   précédente révèle le suivant à l'achat).

> ⚠️ Le contenu 3D (modèles, boutons, GUI, Tycoons) vit **uniquement dans le place
> Studio** et n'est pas dans ce dépôt Git. Seuls les scripts/config le sont.

## TODO / idées futures

- [x] **Bug multijoueur** : les instances `Machine` sont des singletons partagés
      (`PurchasableService.init`) → `isUnlocked`/`currentLevel` sont communs à tous les
      joueurs. Corrigé via les données joueur `OwnedMachines/<machineId>/Level`.
- [ ] **Persistance** (`DataStore`) + **gains hors-ligne**.
- [ ] **Classement global** via `OrderedDataStore`.
- [ ] **Rééquilibrage** : `STARTING_MONEY = 250000` est une valeur de debug.
- [ ] **Paliers** : `ZoneService` qui surveille la Pollution du run et émet
      `ZoneReached`, déclenchant l'animation de transition (décor + atmosphère + audio).
- [x] **Machines des paliers 1–5** : coûts/rendements ajoutés dans `MachineConfig`,
      avec modèles et boutons placeholders remplaçables par les assets Studio.
- [ ] **Sets de décor par palier** : pré-construire en Studio les modèles animables.
- [ ] **Rebirth / Cendres** : `RebirthService` (reset + calcul du gain géométrique).
- [x] **Boutique de prestige** : socle code UI + `ShopService` + application des
      multiplicateurs. À tester en Studio et équilibrer.
- [x] **Aléatoire & placement libre** : socle d'instances uniques, placement grille,
      doublons, vente, recyclage et fusion implémenté. Reste à produire l'UI finale,
      les vrais visuels de variantes et la persistance (voir `docs/RANDOMNESS_PLACEMENT.md`).
- [ ] **Courbe de prix** : recalibrer `MachineConfig` (×8–12 par palier) pour créer le mur.
- [ ] Versionner le contenu 3D (modèles en `.rbxmx`/`.model.json`) pour le sortir de Studio.
