# Models TODO

This file is the handoff between code and Roblox Studio. Code should not invent ugly
props for machines. Studio models should provide the real visual details, and scripts
only reveal/tween them.

## Required Studio Structure

All machine models live in:

```text
ReplicatedStorage
  Tycoon
    Machines
```

Each machine model must have:

```text
Model
  Attribute Id = <MachineConfig id>
  PrimaryPart set
```

For campfires, use this structure:

```text
CampFire
  FireAnchor        -- invisible BasePart at flame center
  SmokeAnchor       -- optional invisible BasePart slightly above fire
  TierVisuals       -- optional, additive visuals per upgrade tier
    Level1
    Level2
    Level3
```

Notes:
- `FireAnchor` and `SmokeAnchor` should be anchored, transparent, non-collidable parts.
- If `SmokeAnchor` is missing, code falls back to `FireAnchor`.
- `TierVisuals` folders are additive:
  - `Level1` is visible from level 1.
  - `Level2` becomes visible at level 2.
  - `Level3` becomes visible at level 3.
- Put only visual parts/meshes/particles/lights in `TierVisuals`, not gameplay hitboxes.

## Placeholder Replacement Contract

The code can now generate temporary gameplay placeholders when Studio content is missing.
These placeholders are only scaffolding: replace them by adding real Studio content with the
same IDs.

To replace a placeholder machine:
- add a model under `ReplicatedStorage.Tycoon.Machines`;
- set `Attribute Id = <MachineConfig id>`;
- set `PrimaryPart`;
- keep optional `FireAnchor`, `SmokeAnchor`, and `TierVisuals` if that machine needs effects.

To replace a placeholder button:
- add a part inside the matching tycoon;
- tag it `TycoonButton`;
- set `Attribute machineId = <MachineConfig id>`;
- add a `Cost` BillboardGui/SurfaceGui with a TextLabel.

If a real model/button with the right ID exists before server startup, the placeholder is not
created for that ID.

## Palier 1 Campfires

### CampFire Level 1

Goal: simple campfire, still readable as the player's first pollution source.

Suggested model pieces:
- stone ring
- 3-5 wood logs
- small flame core
- light smoke from `SmokeAnchor`

Required:
- `FireAnchor`
- optional `SmokeAnchor`
- optional `TierVisuals/Level1` for extra base pieces

### CampFire Level 2

Goal: it starts becoming industrial and dirty, but not absurd yet.

Create under:

```text
TierVisuals
  Level2
```

Suggested additions:
- slightly blackened stones/logs
- small burnt trash pieces close to the fire
- one or two metal scraps
- darker smoke particle near `SmokeAnchor`
- maybe a small cracked tile/ground decal if built by hand in Studio

Avoid:
- giant black square plates
- random cylinder barrels clipping into the fire
- neon colors except tiny accents

### CampFire Level 3

Goal: no longer a camping fire; it should feel like a dirty mini-incinerator.

Create under:

```text
TierVisuals
  Level3
```

Suggested additions:
- larger/charred logs
- stronger black smoke
- more metal scraps integrated into the ring
- small broken pipe or exhaust piece, placed intentionally
- burnt plastic/trash pile, but shaped by hand
- ember/cinder particles

Avoid:
- loose props that look spawned randomly
- bright toxic barrel unless it is modeled cleanly and fits the silhouette

## Naming Contract Used By Code

The current code recognizes:

```text
FireAnchor
SmokeAnchor
TierVisuals/Level1
TierVisuals/Level2
TierVisuals/Level3
```

It also cleans old generated prototype folders if they exist:

```text
ScorchMark
ScorchMarks
AshFlecks
CampfirePollutionProps
```

## Next Model Tasks

- [ ] Add `FireAnchor` and `SmokeAnchor` to all existing CampFire machine models.
- [ ] Create `TierVisuals/Level1`, `Level2`, `Level3` inside each CampFire model.
- [ ] Move real visual upgrade details into those tier folders.
- [ ] Test purchase construction animation after adding tier folders.
- [ ] Test upgrade reveal animation from Level1 to Level2 to Level3.
- [ ] Replace temporary/internal button sounds with approved `rbxassetid://...` sounds.

## Future Palier 1 Models

After CampFire is clean:

- [ ] Barrel Incinerator
- [ ] Burn Pile
- [ ] Scrap Furnace

Each should follow the same contract:

```text
MachineModel
  FireAnchor or EffectAnchor
  SmokeAnchor
  TierVisuals
    Level1
    Level2
    Level3
```
