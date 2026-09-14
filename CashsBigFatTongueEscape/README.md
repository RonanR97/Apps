# Cash's Big Fat Tongue Escape

A complete playable Roblox starter game built in Luau.

## Included

1. Secure server controlled clicking and tongue growth
2. Pink tongue beam and validated grapple pull
3. Thirty six platform escape tower
4. Six checkpoints and a finish reward
5. Click power upgrades
6. Rebirth progression
7. Clicks, tongue length, wins, and rebirth leaderstats
8. DataStore saving
9. Desktop, mobile, and controller input
10. Responsive generated interface
11. One paste Roblox Studio installer
12. Rojo compatible source layout

## Fastest installation

1. Open Roblox Studio and choose Baseplate.
2. Open the View tab and enable Command Bar.
3. Open StudioInstaller.lua from this folder on GitHub.
4. Select Raw, then copy the entire file.
5. Paste it into the Studio Command Bar and press Enter.
6. Wait for the Output window to say the game installed successfully.
7. Press Play. The course, interface, saving system, and controls are generated automatically.
8. Stop the test before publishing.

## Test controls

Desktop uses left click or E.

Controller uses the right trigger.

Mobile uses the LICK + GRAPPLE button.

Aim the middle crosshair at a platform. Every valid activation adds clicks and tongue length. If the target is within tongue range, the tongue pulls the character toward it.

## Make it live

1. In Studio, choose File, then Publish to Roblox As.
2. Choose Create New Experience.
3. Enter Cash's Big Fat Tongue Escape as the name.
4. Add a description, select suitable devices, then create the experience.
5. Open Game Settings, then Security.
6. Turn on Enable Studio Access to API Services only while testing DataStore saving in Studio. The published game can use DataStores without this Studio testing switch.
7. Save the settings and publish again.
8. Open Creator Dashboard in a browser.
9. Select the experience.
10. Complete the experience questionnaire, content maturity details, privacy details, icon, and thumbnails.
11. Open Audience or Access settings and change the experience from private to public.
12. Confirm the required public experience checks shown by Roblox.
13. Copy the public experience link and test it on both a computer and a phone before sharing it.

## Recommended public description

Cash has one massive problem: his tongue will not stop growing. Click to grow it, grapple across a wild obstacle tower, hit every checkpoint, escape the slime, earn wins, upgrade your power, and rebirth for an even bigger boost. Can you reach the top?

## Important release test

Use Start Server with two players in Studio. Confirm that both players have separate stats, one player cannot trigger another player's checkpoint, mobile buttons fit the screen, death returns the player to their latest checkpoint, finishing awards one win, and leaving then rejoining restores saved progress.

## Rojo use

Open this folder in a terminal and run rojo serve after installing Rojo. Connect the Rojo Studio plugin to the local server. The mapping is already defined in default.project.json.

## Balancing

Main balance values are at the top of GameServer.server.lua. You can change starting tongue range, click cooldown, pull speed, maximum tongue size, finish rewards, rebirth cost, and upgrade cost there.
