# Cash's Big Fat Tongue Escape

A complete playable Roblox starter game built in Luau.

## Version four overhaul

Version four replaces the old grapple prototype with the proper tongue escape loop.

1. Tongue length grows automatically every second.
2. Aim at a coloured platform and extend the tongue.
3. A solid tongue stretches from Cash to the platform.
4. Cash slides along the tongue and lands on the target.
5. The crosshair turns green when the target is reachable.
6. Five themed zones increase the required tongue range.
7. Each completed zone becomes a saved checkpoint.
8. Finishing awards a win and 1000 growth points.
9. Rebirths and upgrades increase passive growth.
10. VIP, Double Growth, and Super Tongue remain supported.

## Release candidate overhaul

The release candidate combines all major pretest work into one installation.

1. Five decorated zones with candy, teeth, fire, planets, coins, moving platforms, spinning hazards, lighting, atmosphere, and a finish arch
2. Rounded animated tongue extension with saliva particles, retraction, sound, and premium colours
3. Character mounting pose, visible tongue slide, landing recovery, and camera feedback
4. Responsive interface with stats moved away from chat, limited distance signs, target distance, and reachable crosshair colour
5. Built in extend, slide, landing, reward, and error sounds
6. Daily streak rewards, five minute gifts, launch codes, slide quest, playtime rewards, and milestone achievements
7. Four hatchable pets with growth multipliers
8. Five tongue skins and four character trails
9. First session tutorial and improved mobile layout

Available codes are CASH, BIGTONGUE, and LAUNCH.

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


## Premium shop setup

Publish the experience before creating paid items.

Create these permanent passes in Creator Dashboard:

1. VIP Tongue at 299 Robux
2. Double Growth at 149 Robux
3. Super Tongue at 199 Robux

Create these repeatable developer products:

1. 500 Clicks at 25 Robux
2. 5000 Clicks at 99 Robux
3. Skip Checkpoint at 39 Robux

Copy each numeric asset ID. In Studio, open ReplicatedStorage, then MonetizationConfig. Replace the matching zero with each ID. Publish the experience again.

VIP Tongue gives a gold tongue, a visible VIP crown tag, faster walking, and 50 percent bonus growth.

Double Growth permanently doubles click and tongue gains.

Super Tongue adds 30 studs of grapple range, a stronger pull, and a purple tongue.

Developer products are awarded by the server through ProcessReceipt. Do not grant developer products from a local script.

Test each item with a low price before advertising the game. Roblox controls the purchase prompt and displays the live price automatically.
