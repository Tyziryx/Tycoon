# Tycoon - Flamework Edition

Roblox Tycoon réécrit en TypeScript avec Flamework.

## Prérequis

- Node.js (v18+)
- npm
- Rojo

## Installation

```bash
cd ts-src
npm install
```

## Développement

### Build une fois
```bash
npm run build
```

### Watch mode (rebuild automatique)
```bash
npm run watch
```

### Synchroniser avec Roblox Studio
```bash
rojo serve
```

## Structure du projet

```
ts-src/
├── src/
│   ├── server/
│   │   ├── services/        # Services Flamework (logique métier)
│   │   │   ├── DataService.ts      # Sauvegarde avec ProfileService
│   │   │   ├── TycoonService.ts    # Gestion des tycoons/plots
│   │   │   ├── StatService.ts      # Argent, pollution, génération
│   │   │   └── PurchaseService.ts  # Achats et upgrades
│   │   ├── components/      # Composants Flamework
│   │   │   └── ButtonComponent.ts  # Boutons d'achat
│   │   └── runtime.server.ts
│   ├── client/
│   │   ├── controllers/     # Controllers Flamework (UI, input)
│   │   │   ├── UIController.ts
│   │   │   └── InputController.ts
│   │   └── runtime.client.ts
│   └── shared/
│       ├── config/          # Configuration du jeu
│       │   ├── machines.ts
│       │   ├── decorations.ts
│       │   └── zones.ts
│       ├── network/         # Events réseau Flamework
│       ├── types.ts         # Types TypeScript
│       └── constants.ts     # Constantes du jeu
├── package.json
├── tsconfig.json
└── default.project.json
```

## Architecture Flamework

### Services (Server)
- `@Service()` decorator pour les singletons serveur
- Injection de dépendances automatique via `Dependency<T>()`
- Lifecycle: `onInit()` puis `onStart()`

### Controllers (Client)
- `@Controller()` decorator pour les singletons client
- Même pattern que les services

### Components
- `@Component({ tag: "..." })` pour attacher de la logique aux instances
- S'active automatiquement sur les objets avec le tag CollectionService

### Networking
- `GlobalEvents` pour les événements fire-and-forget
- `GlobalFunctions` pour les appels avec retour

## Améliorations par rapport à l'ancien code

1. **Typage fort** - Plus de bugs de typo ou de type
2. **Sauvegarde** - ProfileService intégré avec auto-save
3. **Données par joueur** - Niveaux de machines stockés individuellement
4. **Configuration centralisée** - Plus de magic numbers
5. **Architecture propre** - Séparation des responsabilités claire
6. **Networking typé** - Events client-serveur type-safe

## Configuration des machines

Éditer `src/shared/config/machines.ts` pour ajouter/modifier des machines :

```typescript
[5, {
    name: "FourSolaire",
    baseCost: 500,
    baseIncome: 50,
    zoneRequired: 2,
    maxLevel: 5,
    upgradeMultipliers: [1, 1.5, 2, 2.5, 3],
    pollutionPerCycle: 0, // Écologique !
}]
```

## Ajout d'une nouvelle zone

1. Ajouter dans `src/shared/config/zones.ts`
2. Créer le modèle dans Roblox Studio
3. Les prérequis sont vérifiés automatiquement

## Commandes en jeu

- **E** : Convertir la pollution en argent
- **Clic sur bouton** : Acheter machine/décoration

## TODO

- [ ] Ajouter des effets visuels pour les machines
- [ ] Système de prestige
- [ ] Leaderboard
- [ ] Quêtes/Achievements
