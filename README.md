# Nostr HLS Demo

## Live demo

https://1l0.github.io/video_testbed/

## What this demo does

1. Fetches a nostr event containing Blossom hashes as `.ts` segments.
2. Builds an `.m3u8` playlist from the event. 
3. Converts the `.m3u8` into a data URI. 
4. Plays the HLS stream from the data URI in a video player.

## Backends used in this demo

- Relay: https://relay.damus.io
- Blossom server: https://blossom.sector01.com

## Tested platforms

- Web
- macOS
- Android