import { Flamework } from "@flamework/core";

// Preload all controllers and components
Flamework.addPaths("src/client/controllers");
Flamework.addPaths("src/client/components");

// Ignite Flamework
Flamework.ignite();

print("[Client] Tycoon client started with Flamework");
