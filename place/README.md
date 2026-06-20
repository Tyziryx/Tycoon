# place/ — snapshot versionné de la scène

Ce dossier contient un **snapshot de la place Roblox** (`Tycoon.rbxlx`) : la 3D
(Workspace, Lighting, assets non-scriptés…) qui n'est pas gérée par Rojo.

## Pourquoi un snapshot et pas du « vrai » versioning collaboratif ?

Un fichier place Roblox **ne se merge pas** dans git (les `referent` sont
réécrits à chaque save). On le traite donc comme un **artefact** :

- **Collaboration 3D en temps réel → Team Create** sur le place cloud partagé.
- **Ici, dans git → une sauvegarde / base d'onboarding**, mise à jour par
  **une seule personne à la fois**. Ce n'est pas un fichier qu'on édite en
  parallèle.

## Mettre à jour le snapshot (depuis Roblox Studio)

1. Ouvre la place à jour dans Studio.
2. `File → Save to File As…`
3. Enregistre dans ce dossier sous le nom **`Tycoon.rbxlx`** (format XML, lisible
   par git). Depuis Windows, le repo WSL est accessible via
   `\\wsl.localhost\<distro>\home\tidic\Tycoon\place\`.
4. `git add place/Tycoon.rbxlx && git commit`.

## Pour un nouveau contributeur

1. Clone le repo, installe les outils : `rokit install`.
2. Ouvre `place/Tycoon.rbxlx` dans Studio (tu obtiens la 3D).
3. `rojo serve` puis connecte le plugin Rojo → les scripts arrivent de `src/`.

> Le `Tycoon.rbxlx` à la racine est l'artefact de `rojo build` (scripts seuls)
> et reste **gitignoré**. Ne pas confondre avec le snapshot de ce dossier.
