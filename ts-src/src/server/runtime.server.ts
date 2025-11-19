import { Flamework } from "@flamework/core";

// Preload all services and components
Flamework.addPaths("src/server/services");
Flamework.addPaths("src/server/components");

// Ignite Flamework
Flamework.ignite();

print("[Server] Tycoon server started with Flamework");
