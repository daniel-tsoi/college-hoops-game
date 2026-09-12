#!/usr/bin/env python3
"""Check shop transactions, catalog integrity, and syntax without claiming a Studio runtime test."""
import argparse
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--luau', required=True)
parser.add_argument('--compiler', required=True)
args = parser.parse_args()
subprocess.run([args.luau, str(ROOT / 'tests/shop.spec.luau')], check=True)
subprocess.run([args.luau, str(ROOT / 'tests/quests.spec.luau')], check=True)
subprocess.run([args.luau, str(ROOT / 'tests/best_team.spec.luau')], check=True)
subprocess.run([args.luau, str(ROOT / 'tests/collection.spec.luau')], check=True)
subprocess.run([args.luau, str(ROOT / 'tests/leaderboard.spec.luau')], check=True)
subprocess.run([args.luau, str(ROOT / 'tests/gold_cards.spec.luau')], check=True)
subprocess.run([args.luau, str(ROOT / 'tests/roll.spec.luau')], check=True)
subprocess.run([args.luau, str(ROOT / 'tests/rare_wheel.spec.luau')], check=True)
subprocess.run([args.luau, str(ROOT / 'tests/rare_reveal.spec.luau')], check=True)
subprocess.run([args.luau, str(ROOT / 'tests/chemistry.spec.luau')], check=True)
subprocess.run([args.luau, str(ROOT / 'tests/auto_finish.spec.luau')], check=True)
subprocess.run([args.luau, str(ROOT / 'tests/sixth_man.spec.luau')], check=True)
paths = [ROOT / p for p in [
    'src/StarterPlayer/StarterPlayerScripts/RollSounds.luau',
    'src/StarterPlayer/StarterPlayerScripts/SixthManView.luau',
    'src/StarterPlayer/StarterPlayerScripts/SquadCompletion.luau',
    'src/ServerScriptService/Roll/SixthMan.luau',
    'src/ServerScriptService/Roll/RareReveal.luau',
    'src/StarterPlayer/StarterPlayerScripts/RareRevealFX.client.luau',
    'src/ServerScriptService/Roll/RareWheel.luau',
    'src/StarterPlayer/StarterPlayerScripts/RareWheelView.luau',
    'src/shared/ShopCatalog.luau',
    'src/shared/CardPortrait.luau',
    'src/shared/CardAppearance.luau',
    'src/shared/CardArt/JerseyMetadata.luau',
    'src/StarterPlayer/StarterPlayerScripts/CardAura.client.luau',
    'src/ServerScriptService/Roll/Pool.luau',
    'src/ServerScriptService/Config/SummonConfig.luau',
    'src/StarterPlayer/StarterPlayerScripts/RollController.luau',
    'src/ServerScriptService/Leaderboard/Ranking.luau',
    'src/ServerScriptService/LeaderboardServer.server.luau',
    'src/StarterPlayer/StarterPlayerScripts/LeaderboardUI.client.luau',
    'src/StarterPlayer/StarterPlayerScripts/CollectionUI.client.luau',
    'src/ServerScriptService/EquippedCard.server.luau',
    'src/ServerScriptService/Shop/BestTeam.luau',
    'src/StarterPlayer/StarterPlayerScripts/BestTeamUI.client.luau',
    'src/ServerScriptService/Shop/Transactions.luau',
    'src/ServerScriptService/ShopServer.server.luau',
    'src/StarterPlayer/StarterPlayerScripts/ShopUI.client.luau',
    'src/StarterPlayer/StarterPlayerScripts/QuestsUI.client.luau',
    'src/ReplicatedStorage/QuestConfig.luau',
    'staged-implementation/src/StarterPlayer/StarterPlayerScripts/HoopsUI.client.luau',
]]
for path in paths:
    subprocess.run([args.compiler, str(path)], check=True, stdout=subprocess.DEVNULL)
with tempfile.TemporaryDirectory(prefix='hoops-shop-check-') as directory:
    temp = Path(directory)
    (temp / 'PlayerTypes.luau').write_text((ROOT / 'src/shared/PlayerTypes.luau').read_text())
    for name in ['GeneratedHOF001', 'GeneratedNonCollege001']:
        source = (ROOT / f'src/shared/PlayerData/{name}.luau').read_text()
        source = source.replace('require(script.Parent.Parent.PlayerTypes)', 'require("./PlayerTypes")')
        (temp / f'{name}.luau').write_text(source)
    source = (ROOT / 'src/shared/ShopCatalog.luau').read_text().replace('local data = script.Parent.PlayerData', '')
    source = 'local Color3 = { fromRGB = function(r, g, b) return {r, g, b} end }\n' + source
    for name in ['GeneratedHOF001', 'GeneratedNonCollege001']:
        source = source.replace(f'require(data.{name})', f'require("./{name}")')
    (temp / 'ShopCatalog.luau').write_text(source)
    (temp / 'check.luau').write_text('''
local catalog = require("./ShopCatalog")
assert(#catalog.Offers == 16)
local groups = { HOF = 0, ["NON-COLLEGE"] = 0 }
local seen = {}
for _, offer in ipairs(catalog.Offers) do
    assert(not seen[offer.id], "Duplicate offer")
    seen[offer.id] = true
    assert(catalog.ById[offer.id] == offer)
    assert(offer.price > 0 and offer.price % 1 == 0)
    assert(offer.player.name ~= "" and offer.player.overall > 0)
    assert(offer.number ~= "")
    for _, stat in ipairs({"shooting", "dribbling", "defense", "speed", "stamina"}) do
        assert(type(offer.player.attributes[stat]) == "number")
    end
    groups[offer.group] += 1
end
assert(groups.HOF == 8 and groups["NON-COLLEGE"] == 8)
assert(catalog.ById["hof-shaquille-oneal-1991-92"].price == 400000)
print("Shop catalog: 8 HOF + 8 non-college, unique IDs, stats, icons, prices, and Shaq anchor passed")
''')
    subprocess.run([args.luau, str(temp / 'check.luau')], check=True)
print('All shop scripts compiled. Studio rendering and live DataStore testing remain separate.')
