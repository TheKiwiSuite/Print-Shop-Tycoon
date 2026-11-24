PRINT SHOP TYCOON - ORIGINAL MUSIC AND SOUND EFFECTS (2026-11-22)

Everything here is synthesized by make_audio.py with numpy: no samples, no
recordings, nothing downloaded. The tunes were written for this game.

Music (stereo, about 70-95 seconds each)
  open-sign               bouncy ukulele, whistle and glockenspiel in C (shop)
  weeding-by-the-window   lazy swing in F, whistled tune over marimba (shop)
  rush-order              upbeat in G with a soft pulse lead and claps (shop)
  paper-and-ink           gentle music box in D (title screen, loops)

Sound effects (mono)
  click place cash door done fanfare levelup error cutter press print pack day

Rebuild (CPU only, about a minute; no rendering):
  blender -b --factory-startup --python make_audio.py -- --out <new folder>
  ffmpeg -i music-<name>.wav -c:a libvorbis -q:a 5 music-<name>.ogg

final/                 generated WAV files, the Ogg music and audio-report.json
source/assets/audio    the Ogg music and WAV effects the game loads

The mix was balanced by measurement (band levels and matched loudness), not by
ear, so the owner's listening test is the real check. Each instrument's level is
one number in make_audio.py and can be changed and rebuilt in a minute.
