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
	// turn on MODE 0 on the top screen
	NF_Set2D(0, 0);
    swiWaitForVBlank();

	// init nitroFS
	if(!nitroFSInit(argv[0])) {
        if(!nitroFSInit("/title/00030004/54455354/content/%08x.app")) {
            if(!nitroFSInit("nand:/title/00030004/54455354/content/%08x.app")) {
                printf("NitroFS Init failed");
            }
        }
    }
    // set nitroFS as root
	NF_SetRootFolder("NITROFS");

	// init tiled bg system on the top screen
	NF_InitTiledBgBuffers();
	NF_InitTiledBgSys(0);

	// init tiled sprites system on the top screen
	NF_InitSpriteBuffers();
	NF_InitSpriteSys(0);

	// Load our Tiled Sprite
	NF_LoadSpriteGfx("skiddo", 0, 16, 16);
	NF_LoadSpritePal("skiddo", 0);

	// transfer sprite to VRAM
	NF_VramSpriteGfx(0, 0, 0, false);
	NF_VramSpritePal(0, 0, 0);

	// create sprite
	NF_CreateSprite(0, 0, 0, 0, 0, 0);
	// print shit

	printf("Testing :)\n");
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
