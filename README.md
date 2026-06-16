# WeaveKit

The GUI kit built on top of [Weave](https://github.com/royhanantariksaaa/weave-rbx).

Provides Atoms, Molecules, and Organisms (Button, Card, Modal, Dropdown, Window,
VirtualGrid, Theme/ThemeProvider, etc.) composed from Weave's reactive primitives.

## Runtime sibling requirements

WeaveKit uses **absolute requires** to sibling modules in `ReplicatedStorage.Libraries`.
At runtime, the following must be present as a sibling of `WeaveKit`:

- `Weave` — `ReplicatedStorage.Libraries.Weave` (including its `Types` submodule,
  e.g. `ReplicatedStorage.Libraries.Weave.Types`)

Weave itself further requires its own siblings (`WeaveSignal`, `Symbol`, `Tween`);
see the [Weave README](https://github.com/royhanantariksaaa/weave-rbx) for those.

## Consume as a git submodule

From your game repo root (assuming `src/Shared` maps to `ReplicatedStorage`):

```sh
git submodule add https://github.com/royhanantariksaaa/weave-rbx.git src/Shared/Libraries/Weave
git submodule add https://github.com/royhanantariksaaa/weavekit-rbx.git src/Shared/Libraries/WeaveKit
```

This lands WeaveKit at `ReplicatedStorage.Libraries.WeaveKit`, matching what its
own requires expect.

## Standalone dev

Open the project in [Rojo](https://rojo.space):

```sh
rojo serve default.project.json
```

This serves WeaveKit at `ReplicatedStorage.Libraries.WeaveKit`. Weave (and its
siblings) still need to be present for it to run.

## License

TBD. No license file is included yet; default copyright applies in the meantime.
