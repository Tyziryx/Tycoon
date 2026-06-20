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
| **Pollution du run** | Cumul de pollution depuis le dernier rebirth. **Pilote les zones / paliers.** Remis à zéro au rebirth. |
| **Pollution Totale** | Cumul **à vie** (tous les runs), ne redescend jamais. C'est le **score** du classement (et pilote le smog). |
| **Cendres** *(prestige)* | Monnaie de prestige gagnée au rebirth, **permanente**. Sert à la boutique d'améliorations persistantes. |

## Boucle de jeu

1. Le joueur achète des machines (feux de camp) qui génèrent de la pollution/sec.
2. Il peut aussi **cliquer** une machine (burner manuel) pour polluer activement.
3. Il va voir la **Mafia** (ProximityPrompt) pour vendre sa pollution → argent.
4. Il réinvestit pour acheter/améliorer plus de machines.
5. Sa **Pollution Totale** grimpe → il monte au classement et le monde devient plus enfumé.

## Machines — Zone 1

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

> Ces valeurs sont la **source de vérité** et sont reproduites telles quelles dans
> `src/shared/Config/MachineConfig.luau`.

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

## Zones & paliers — évolution du terrain

Les **zones ne sont pas des espaces séparés à acheter** : ce sont les **stades
d'évolution du même terrain**, qui se transforme à mesure que la **Pollution Totale**
franchit des **paliers**. Plus on pollue, plus le décor devient apocalyptique.
Chaque franchissement de palier déclenche une **animation de transition** qui signale
le passage au stade suivant.

5 zones, **2 niveaux de machines chacune** (10 niveaux au total) :

| Zone | Niv. | Machines (thème)                                   | Décor                                                                 | Ambiance                                              | Palette                          |
|------|------|----------------------------------------------------|-----------------------------------------------------------------------|-------------------------------------------------------|----------------------------------|
| 1    | 1–2  | Feu de camp industriel / Baril incinérateur        | Terre sèche craquelée, sacs plastiques, palettes, pneus brûlés, carcasses de voitures, fumée noire | Feu, corbeaux, vents secs, musique lente grinçante    | Brun/gris, fumée noire           |
| 2    | 3–4  | Fosse à combustion / Micro-usine de destruction    | Béton brut, piliers cassés, câbles, grues & convoyeurs rouillés, conteneurs toxiques, panneaux « DANGER » | Bruits mécaniques répétitifs, alarmes basses          | Béton gris, rouge alarme clignotant |
| 3    | 5–6  | Compacteur brûleur / Locomotive à charbon          | Sol noirci, rails de train, tuyaux, chaudières, réservoirs sous pression, fumées vertes, vapeur, égouts | Vibrations, vapeur, coups de marteau                  | Jaune-orange, effet « chaleur »  |
| 4    | 7–8  | Raffinerie primitive / Station thermo-polluante    | Sol fissuré, flaques de pétrole, nuages de gaz, camions-citernes, bras robotiques, fuites chimiques, éclairs, gouttes acides | Grésillement chimique, bips toxiques, aspiration      | Vert / violet / orange néon saturés |
| 5    | 9–10 | Réacteur de combustion / Trou noir industriel      | Sol déformé & éclaté, fissures fumantes, vortex noir, cendres tombant du ciel, fumée rougeoyante | Sons graves vibrants, distorsions audio, tremblements | Rouge sombre / noir              |

> Note de conception (auteur) : *« y'a des choses qu'on ne peut pas faire, on prend les
> idées qui sont possibles / on les adapte. »* → privilégier un **décor modulaire
> pré-construit** que l'on anime (apparition/disparition), plutôt que de la déformation
> procédurale de terrain (trop coûteuse).

### Système de paliers

- Le passage de zone est piloté par la **Pollution du run**, **pas par l'argent**.
- Chaque zone définit un `PollutionThreshold`. Un service serveur surveille la Pollution
  du run et émet un événement `ZoneReached(zoneId)` au franchissement.
- Progression suggérée (courbe géométrique, à équilibrer) :

  | Zone | Seuil Pollution du run (suggéré) |
  |------|----------------------------------|
  | 1    | 0                                |
  | 2    | 1 000                            |
  | 3    | 10 000                           |
  | 4    | 100 000                          |
  | 5    | 1 000 000                        |

### Animation de transition (à implémenter)

Au franchissement d'un palier :
1. **Décor** : faire apparaître le nouveau set (tween d'échelle/position, surgissement du
   sol) et disparaître l'ancien (fondu / enfoncement).
2. **Sol & matériaux** : tween de `Color`/`Material` du terrain vers la palette de la zone.
3. **Atmosphère & lumière** : transition de `Atmosphere` (Color/Density/Haze), `ClockTime`,
   `Ambient`, brouillard — prolonge le smog progressif déjà en place.
4. **Effets** : particules (fumée, cendres en zone 5, gouttes acides en zone 4, vapeur en
   zone 3), `ScreenShake` côté client en zone 5.
5. **Audio** : crossfade de l'ambiance sonore vers la piste de la zone.
6. **Feedback joueur** : flash + bannière « ZONE 2 DÉBLOQUÉE » + son, courte vue caméra
   sur le nouveau décor.

### Machines intermédiaires

Chaque zone introduit ses propres machines (cf. colonne « Machines »). Pour lisser la
courbe, prévoir **2–3 machines par zone** à coût/pollution croissants (chacune améliorable
en tiers ×1.5 / ×2 comme en Zone 1), afin que le joueur ait toujours un prochain achat
abordable entre deux paliers. Le rendement (pollution/sec) des machines d'une zone doit
être nettement supérieur (~×5 à ×10) à celui de la zone précédente, pour tirer la
Pollution Totale vers le palier suivant.

## Rebirth (prestige)

La courbe de prix des machines est **volontairement très raide** : le coût d'une machine
dépasse largement ce qu'on peut accumuler au palier précédent. On finit par « buter » sur
un mur → c'est le signal pour **rebirth** plutôt que de grinder à l'infini.

**Le rebirth :**
- **Remet à zéro** : argent, machines possédées, pollution courante, et la **Pollution du
  run** (progression de zones) → on repart en Zone 1.
- **Conserve** : les **Cendres**, les améliorations persistantes de la boutique, et la
  **Pollution Totale** (score à vie, jamais remis à zéro).
- **Récompense** : un gain de **Cendres** à courbe **géométrique** selon la progression
  atteinte. Grâce aux multiplicateurs de la boutique, chaque cycle est plus rapide que le
  précédent.

**Formule suggérée** (à équilibrer) :

```
-- par zone atteinte (géométrique pur)
Cendres = floor( BASE * GROWTH ^ (zoneAtteinte - 1) )
-- ex. BASE=1, GROWTH=4  →  Z1:1  Z2:4  Z3:16  Z4:64  Z5:256

-- ou en continu sur la pollution du run
Cendres = floor( (PollutionDuRun / SEUIL_BASE) ^ 0.5 )
```

### Courbe de prix (mur de progression)

Les coûts des machines croissent **plus vite** que les seuils de pollution : le prix d'une
machine de zone N dépasse de loin l'argent accumulable en zone N−1. Ce mur est **intentionnel**.
Suggestion : coût de base ×8–12 par zone (les seuils de pollution, eux, ×10 par zone).

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

- [ ] **Bug multijoueur** : les instances `Machine` sont des singletons partagés
      (`PurchasableService.init`) → `isUnlocked`/`currentLevel` sont communs à tous les
      joueurs. À rendre par-joueur avant tout test à +1 joueur.
- [ ] **Persistance** (`DataStore`) + **gains hors-ligne**.
- [ ] **Classement global** via `OrderedDataStore`.
- [ ] **Rééquilibrage** : `STARTING_MONEY = 250000` est une valeur de debug.
- [ ] **Zones & paliers** : `ZoneService` qui surveille la Pollution Totale et émet
      `ZoneReached`, déclenchant l'animation de transition (décor + atmosphère + audio).
- [ ] **Machines des zones 2–5** : spécifier coûts/rendements + créer modèles & boutons.
- [ ] **Sets de décor par zone** : pré-construire en Studio les modèles animables.
- [ ] **Rebirth / Cendres** : `RebirthService` (reset + calcul du gain géométrique).
- [x] **Boutique de prestige** : socle code UI + `ShopService` + application des
      multiplicateurs. À tester en Studio et équilibrer.
- [ ] **Courbe de prix** : recalibrer `MachineConfig` (×8–12 par zone) pour créer le mur.
- [ ] Versionner le contenu 3D (modèles en `.rbxmx`/`.model.json`) pour le sortir de Studio.
