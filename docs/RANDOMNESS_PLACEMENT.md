# Aléatoire, placement libre et recyclage

Cette note décrit une évolution possible du tycoon après le socle paliers/rebirth :
garder une progression fiable, mais ajouter de la collection, du hasard contrôlé et un
plot personnalisable.

## Intention

Le joueur ne construit pas seulement "la meilleure usine". Il construit **son** usine :
machines rares, variantes visuelles, placement choisi, organisation du plot et petites
optimisations personnelles.

Pour que ça reste adapté à un tycoon pollution :

- la progression principale reste déterministe : paliers, rebirth, Cendres, boutique de
  prestige ;
- l'aléatoire donne des exemplaires, variantes et traits, sans bloquer l'accès au contenu
  principal ;
- les doublons sont utiles : placement multiple, fusion, vente ou recyclage ;
- le plot devient une vitrine visible des machines rares et de l'identité du joueur.

## Principe central : une machine gagnée est une instance

Aujourd'hui, une machine est surtout un `MachineId` acheté une fois dans le run. Pour un
système aléatoire, il faut distinguer :

- la **famille** de machine : `MachineId`, par exemple "Incinérateur" ;
- la **variante** : `VariantId`, par exemple `Rusted`, `Toxic`, `Mafia`, `Golden` ;
- l'**exemplaire possédé** : `InstanceId`, unique, plaçable, vendable ou recyclable.

Exemple de donnée future :

```lua
{
	InstanceId = "m_8f31a6",
	MachineId = 12,
	VariantId = "Toxic",
	Rarity = "Rare",
	Traits = { "Overclocked" },
	Level = 1,
	Locked = false,
	Placed = true,
	PlotX = 6,
	PlotZ = 14,
	Rotation = 90,
}
```

Conséquence importante : retomber sur la même machine n'est pas une erreur. C'est un
deuxième exemplaire, que le joueur peut placer, fusionner, vendre ou recycler.

## Progression et hasard

Le hasard doit entourer la progression, pas la remplacer.

### Progression déterministe

- Les paliers sont débloqués par la Pollution du run.
- Les familles de machines deviennent disponibles par palier.
- Le rebirth donne des Cendres selon une formule prévisible.
- La boutique de prestige donne des bonus persistants.

### Sources aléatoires possibles

- conteneurs achetés avec argent ;
- récompense de franchissement de palier ;
- récompense de rebirth ;
- deal Mafia limité dans le temps ;
- événement serveur ;
- quête journalière ;
- recyclage avancé ou fusion.

### Roll recommandé

1. Déterminer le pool autorisé selon le palier atteint.
2. Tirer une rareté avec poids configurés.
3. Tirer une famille de machine compatible.
4. Tirer une variante compatible avec la rareté.
5. Tirer éventuellement 0 à 2 traits bonus.
6. Créer une instance unique avec `InstanceId`.

Les poids doivent vivre en config, pas en dur dans les services.

## Raretés, variantes et traits

### Raretés

Proposition de base :

| Rareté | Rôle | Exemple de poids |
|--------|------|------------------|
| Common | Machine fiable, peu bonusée | 70% |
| Uncommon | Petit bonus ou visuel différent | 20% |
| Rare | Bonus notable, bon objet de collection | 8% |
| Epic | Forte identité visuelle ou trait fort | 1.8% |
| Legendary | Flex, très rare, pas obligatoire pour progresser | 0.2% |

### Variantes

Exemples adaptés au thème pollution :

- `Rusted` : rouillée, coût de vente faible, rendement légèrement bonusé ;
- `Toxic` : plus de pollution, plus d'effets visuels ;
- `Mafia` : meilleur taux à la vente Mafia ;
- `Unstable` : gros rendement, effet secondaire ou maintenance ;
- `Golden` : rareté visuelle, bon recyclage ou bonne valeur de vente ;
- `Prototype` : bonus puissant mais limite de placement stricte.

### Traits

Les traits peuvent être de petits modificateurs indépendants de la variante :

- `Overclocked` : plus de pollution/sec ;
- `CheapMaintenance` : coût réduit ;
- `DirtySmoke` : augmente le smog visuel ;
- `Compact` : prend moins de place sur le plot ;
- `RecyclerBonus` : donne plus de matière au recyclage.

## Doublons

Les doublons doivent être désirables, ou au moins jamais frustrants.

Usages recommandés :

- **Placement multiple** : plusieurs exemplaires d'une même famille peuvent produire en
  parallèle si le plot et les limites le permettent.
- **Fusion** : consommer des doublons pour améliorer une instance.
- **Vente** : récupérer de l'argent rapidement.
- **Recyclage** : récupérer une ressource de craft/fusion.
- **Collection** : le premier exemplaire découvert remplit l'album, même si l'instance est
  vendue ensuite.

## Placement libre sur le plot

Le placement libre est pertinent pour ce jeu, mais il doit rester contrôlé.

Recommandation : utiliser une **grille de plot**, pas des positions totalement libres.

Données minimales :

```lua
{
	InstanceId = "m_8f31a6",
	PlotX = 6,
	PlotZ = 14,
	Rotation = 90,
}
```

Règles de base :

- chaque machine a une taille de grille (`FootprintX`, `FootprintZ`) ;
- rotation par pas de 90 degrés ;
- pas de collision avec une autre machine ;
- placement uniquement dans la zone débloquée du plot ;
- une machine peut être remise en inventaire ;
- une machine placée garde son `InstanceId`, sa variante et son niveau ;
- une machine non autorisée par le palier courant peut rester en inventaire, mais ne doit
  pas produire tant que le palier requis n'est pas atteint.

Le plot devient alors une partie du gameplay :

- choix entre machines compactes ou très rentables ;
- bonus d'adjacence ;
- décor utilitaire ;
- zones du plot débloquées par paliers ;
- vitrine sociale pour montrer les variantes rares.

## Vente et recyclage

La vente et le recyclage servent à rendre les doublons utiles et à éviter que l'inventaire
devienne une poubelle.

### Deux actions différentes

**Vendre** :

- détruit l'instance ;
- donne de l'argent immédiatement ;
- utile en début/milieu de run ;
- ne donne pas de Cendres ;
- doit rapporter moins que ce qu'une bonne machine peut produire sur la durée.

**Recycler** :

- détruit l'instance ;
- donne une ressource de craft, par exemple `Ferraille`, `FragmentsToxiques` ou
  `Composants` ;
- sert à fusionner, reroll un trait, fabriquer un conteneur ou améliorer une variante ;
- peut parfois donner un bonus rare, mais ne doit pas devenir la source principale de
  Cendres.

### Formules proposées

Tout doit être configurable.

```lua
SellValue = floor(BaseCost * SellRefundRate * RaritySellMultiplier * LevelMultiplier)
RecycleYield = floor(BaseRecycleYield * RarityRecycleMultiplier * LevelMultiplier)
```

Valeurs de départ possibles :

| Paramètre | Valeur de départ |
|-----------|------------------|
| `SellRefundRate` | 0.20 à 0.35 |
| `LevelMultiplier` | `1 + ((Level - 1) * 0.25)` |
| Common recycle | 1x |
| Uncommon recycle | 2x |
| Rare recycle | 5x |
| Epic recycle | 15x |
| Legendary recycle | 50x |

Important : la vente doit être une soupape, pas une stratégie dominante. Si vendre des
machines rapporte plus que jouer la boucle pollution -> Mafia -> upgrades, l'économie se
casse.

### Garde-fous UX

- Une instance `Locked = true` ne peut pas être vendue ni recyclée.
- Les raretés `Epic` et `Legendary` demandent une confirmation.
- Les machines placées doivent être retirées du plot avant vente/recyclage, ou le système
  doit les retirer automatiquement proprement.
- Le premier exemplaire découvert reste enregistré dans la collection même si l'instance
  est détruite.
- Afficher clairement la différence entre `Vendre` et `Recycler`.
- Prévoir un bouton "verrouiller" sur les machines favorites.

### Recyclage avancé

Options futures :

- recycler 3 machines d'une même rareté pour obtenir un conteneur de rareté supérieure ;
- recycler une variante pour obtenir des fragments de cette variante ;
- utiliser les fragments pour cibler un futur roll ;
- transformer des doublons en expérience de fusion ;
- bonus de recyclage via boutique de prestige.

## Fusion

La fusion donne une utilité directe aux doublons sans créer trop de monnaie.

Proposition simple :

- fusionner 3 exemplaires de même `MachineId` et même rareté ;
- l'instance principale gagne un niveau de fusion ;
- les deux autres sont détruites ;
- le bonus augmente la pollution/sec, la valeur de vente et le rendement de recyclage.

Variante plus stricte :

- même `MachineId` ;
- même `VariantId` ;
- même rareté.

La version stricte est meilleure pour une économie longue, mais plus frustrante au début.

## Rebirth et persistance

Recommandation :

- le rebirth retire les machines placées et remet le run au Palier 1 ;
- l'inventaire de machines aléatoires peut rester permanent ;
- une machine de palier élevé conservée en inventaire ne peut pas produire avant que le
  palier requis soit à nouveau atteint ;
- la collection découverte reste permanente ;
- les ressources de recyclage doivent être classées :
  - ressources de run, reset au rebirth ;
  - ressources permanentes, conservées.

Pour éviter de casser le rebirth, il ne faut pas permettre à un joueur de placer une
machine de Palier 5 productive dès le début d'un nouveau run.

## MVP recommandé

1. [x] Ajouter un inventaire d'instances avec `InstanceId`, `MachineId`, `VariantId`,
   `Rarity`.
2. [x] Ajouter un placement grille basique avec placeholders.
3. [x] Ajouter vente simple contre argent.
4. [x] Ajouter recyclage contre une ressource unique : `Ferraille`.
5. [x] Ajouter fusion de doublons.
6. [x] Ajouter variantes rares et traits.
7. [x] Ajouter album/collection.
8. [ ] Ajouter sources événementielles.

## Implémentation actuelle

Socle code ajouté :

- `src/shared/Config/RandomMachineConfig.luau` : raretés, variantes, traits, coût de roll,
  pity, vente, recyclage, fusion et grille.
- `src/server/Services/MachineInventoryService.luau` : source de vérité des instances,
  rolls, placement, vente, recyclage, fusion et remotes.
- `src/client/UI/MachineInventory.client.luau` : UI de test avec tirage animé type caisse,
  sélection d'instance, placement au curseur avec ghost preview, rangement, vente,
  recyclage, fusion et verrouillage.
- `Machine.luau` et `PurchasableService.luau` : les achats existants créent maintenant
  des instances placées, et le revenu lit les instances placées.

Remotes serveur :

- `GetMachineInventoryRemote`
- `RollMachineRemote`
- `PlaceMachineRemote`
- `UnplaceMachineRemote`
- `SellMachineRemote`
- `RecycleMachineRemote`
- `FuseMachineRemote`
- `ToggleMachineLockRemote`
- `MachineInventoryUpdated`

Limites connues du MVP :

- le placement au curseur utilise un ghost preview grille ; l'UX finale devra remplacer
  le panneau de test par une interface plus intégrée au jeu ;
- la persistance DataStore n'est pas encore branchée ;
- les variantes utilisent surtout les placeholders et des attributs/tints, les vrais
  visuels Studio restent à produire ;
- les sources événementielles ne sont pas encore implémentées ;
- la fusion consomme des doublons même `MachineId` + même rareté, sans exiger la même
  variante pour garder le test moins frustrant.

## Points à décider avant implémentation

- Les machines aléatoires sont-elles permanentes ou liées au run ?
- Quelle ressource de recyclage utiliser : `Ferraille`, `Composants`, autre ?
- Est-ce que certaines variantes donnent des bonus visuels seulement ?
- Est-ce que la boutique prestige améliore la chance, le recyclage ou les deux ?
- Faut-il une limite stricte par famille de machine placée ?
- Faut-il autoriser la vente des machines gratuites/de départ ?
