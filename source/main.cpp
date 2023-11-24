#include <stdio.h>
#include <nds.h>
#include <filesystem.h>
#include <nf_lib.h>

volatile int frame = 0;

void Vblank() {
	frame++;
}

int main(int argc, char **argv) {
	consoleDemoInit();
	// Turn on MODE 0 on the Top Screen
	NF_Set2D(0, 0);
    swiWaitForVBlank();

	// Set the Root Folder
	nitroFSInit(NULL);
	NF_SetRootFolder("NITROFS");

	// Initialize the Tiled Backgrounds System on the Top Screen
	NF_InitTiledBgBuffers();
	NF_InitTiledBgSys(0);

	// Initialize the Tiled Sprites System on the Bottom Screen
	NF_InitSpriteBuffers();
	NF_InitSpriteSys(0);

	// Load our Tiled Sprite
	NF_LoadSpriteGfx("skiddo", 0, 16, 16);
	NF_LoadSpritePal("skiddo", 0);

	// Transfer our sprite to VRAM
	NF_VramSpriteGfx(0, 0, 0, false);
	NF_VramSpritePal(0, 0, 0);

	// Create the Sprite!
	NF_CreateSprite(0, 0, 0, 0, 0, 0);
	iprintf("Testing :)\n");
	while(true) {
		NF_SpriteOamSet(0);
		swiWaitForVBlank();
		oamUpdate(&oamMain);
		swiWaitForVBlank();
		/*scanKeys();
		int keys = keysDown();
		if (keys & KEY_A) {
			iprintf("penis\n");
		}
		if (keys & KEY_B) {
			iprintf("balls\n");
		}*/
	}
	return 0;
}
