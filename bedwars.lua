plugin = {
    name = "bedwars",
    displayName = "BedWars",
    command = "bw",
    prefix = "§cB§fW",
    version = "0.2.1",
    description = [[
Various BedWars tools and quality of life features

- Keyless tablist stats overlay
- Player respawn timer
- Auto /who
- Party counter
- Height limit indicator]],
dependencies = {
        { name = "hypixel-mod-api", minVersion = "1.0.0" },
        { name = "denicker",  optional = true },
        { name = "urchin",    optional = true },
        { name = "anticheat", optional = true }
    }
}

-- Constants

local STATS_API = "https://api.urchin.gg/v3/hypixel/player?player="
local STATS_MAX_CACHE_AGE = "90s"
local CACHE_TTL = 300
local FETCH_RETRIES = 3
local RETRY_BASE_MS = 2000
local REFRESH_MS = 500
local AUTO_WHO_DEDUPE_MS = 5000
local PARTY_GROUP_MS = 250
local RESPAWN_SECONDS = 5
local RECONNECT_RESPAWN_SECONDS = 10
local HEIGHT_BAR_MS = 250
local HEIGHT_WARN_RANGE = 10
local GAME_START_PHRASE = "powerful upgrades"
local GAME_END_PHRASE = "1st Killer "
local REJOIN_MESSAGES = {
    ["You will respawn in 10 seconds!"] = "respawn",
    ["Your bed was destroyed so you are a spectator!"] = "spectator",
}

local TEAM_COLORS = {
    Red = "§c", Blue = "§9", Green = "§a", Yellow = "§e",
    Aqua = "§b", White = "§f", Pink = "§d", Gray = "§8",
}

local HEIGHT_LIMITS = {
    acropolis = 101, aetius = 95, airshow = 101, alaric = 98, amazon = 94,
    ambush = 102, antenna = 89, apollo = 99, aqil = 91, aquarium = 110,
    arcade = 91, archway = 87, arid = 84, artemis = 97, ashfire = 106,
    ashore = 121, babylon = 108, beeeee = 102, biohazard = 96, blitzen = 111,
    blizzard_bay = 93, bloom = 100, blossom = 97, boardwalk = 98, boletum = 121,
    bucket_bay = 92, build_site = 97, bunnywars = 100, burrow = 101, capture = 121,
    carapace = 95, casita = 94, cascade = 88, catalyst = 102, cauldron = 100,
    chained = 90, chalk_cliffs = 108, cliffside = 101, coastal = 90, comet = 116,
    crimson = 106, crogorm = 124, crypt = 96, cryptic = 105, darkened = 82,
    daolong = 91, deadwood = 84, deposit = 82, dockyard = 98, dragon_light = 96,
    dragonstar = 101, dreamgrove = 116, duye = 95, eastwood = 101, easter_basket = 94,
    easter_garden = 99, egg_factory = 93, egg_hunt = 101, egg_run = 99, enchanted = 101,
    entangle = 96, extinction = 96, fang_outpost = 100, fireplace = 96, fort_doon = 91,
    foxtrots = 95, frost = 122, frosted = 91, fruitbrawl = 101, frogiton = 91,
    gardens = 102, gateway = 129, gelato = 81, ghoulish = 87, gingerbread = 107,
    gingerbread_town = 90, glacier = 106, graveship = 124, grotto = 101,
    hanging_gardens = 108, harvest = 84, harvesting = 96, hell_temple = 115,
    highland_peaks = 89, hollow = 89, hollow_hills = 103, holmgang = 98, horizon = 101,
    impere = 105, infinite = 89, invasion = 116, ironclad = 88, ivory_castle = 111,
    jurassic = 95, katsu = 97, keep = 62, kubo = 92, lectus = 90, lighthouse = 111,
    lightstone = 96, lions_temple = 104, loft = 83, lost_temple = 92, lotice = 91,
    lotus = 90, lucky_rush = 85, lunarhouse = 111, meadow = 81, meso = 96, mirage = 87,
    montipora = 98, mortuus = 91, mosdalr = 105, mystery = 93, nebuc = 106, nostalgia = 97,
    nutcracker = 99, obelisk = 114, ominosity = 124, orbit = 97, orchestra = 107,
    orchid = 87, orientwood = 101, paladin = 99, paradox = 85, pavilion = 98,
    pernicious = 91, pharaoh = 96, picnic = 121, planet_98 = 106, playground = 101,
    polygon = 94, pool_party = 87, pumpkin_bay = 86, raze = 89, relic = 91,
    rigged = 97, rise = 96, rooftop = 92, rooted = 96, salmon_bay = 91,
    sandcastle = 102, sanctuary = 92, sanctum = 92, santas_rush = 93, scareshow = 101,
    scorched_sands = 93, screamway = 91, seraph = 95, serenity = 94, shark_attack = 95,
    siege = 109, silver_birch = 115, sky_festival = 95, sky_rise = 91, slumber = 94,
    snails = 91, snowkeep = 96, snowy_square = 96, solace = 101, speedway = 91,
    springtide = 87, steampumpkin = 100, steampunk = 100, stilted = 81, stonekeep = 75,
    sunflower = 96, swashbuckle = 86, sweet_wonderland = 95, symphonic = 107, temple = 106,
    tengshe = 101, terminal = 88, terraced = 90, tigris = 107, tinselbury = 101,
    toro = 93, treenan = 96, trick_or_yeet = 95, turtle_cove = 99, tuzi = 92,
    unchained = 91, unturned = 93, urban_plaza = 84, usagi = 97, varyth = 105,
    vigilante = 88, waterfall = 101, whiskers = 88, yandi = 81, yue = 102,
    zarzul = 115, zen_plaza = 84,
}

-- Prestige schemes

local PRESTIGE_SCHEMES = {
    [0] = "7", "f", "6", "b", "2", "3", "4", "d", "9", "5",
    "c6eabd5", "7ffff77", "7eeee67", "7bbbb37", "7aaaa27",
    "7333397", "7cccc47", "7dddd57", "7999917", "7555587",
    "87ff778", "ffee666", "66ffb33", "55dd6ee", "bbff778",
    "ffaa222", "44ccdd5", "eeff888", "aa2266e", "bb33991",
    "ee66cc4", "993366e", "c4774cc", "999dcc4", "2add552",
    "cc442aa", "aaab991", "44ccb33", "11955d1", "ccaa399",
    "55cc66e", "ee6cdd5", "193bf77", "0588550", "22ae65d",
    "ffbb333", "3be66d5", "f4cc919", "55c66b3", "2afffa2",
    "4459910", "4cc6ef4", "193bfe1", "5defed5", "3a282a3",
    "2aefbd5", "4cefec4", "4623958", "5c6fb39", "7087ff7",
    "cffffcf", "6efffb3", "efe66fe", "aeeeea2", "bbcccaa",
    "33aafa3", "9ddddb9", "5ddddf5", "066eeff", "aaaa228",
    "3bbbbf3", "4c6ec6e", "2af2af8", "233bba2", "88888d8",
    "6622fff", "fff77c8", "dcccc6d", "87fffe8", "6f262f6",
    "2aaac42", "87fb391", "fffffaf", "8844cc8", "fdddaaf",
    "36666e3", "dffffed", "8666668", "444ccff", "9bbb339",
    "ddddd58", "0c66cc4", "2dddda2", "f8888ff", "e648888",
    "008877f", "eee00e0", "dddeebe", "0888880", "87fffef",
    "9bfffc4",
}

local STAR_SYMBOLS = { [0] = "✫", "✪", "⚝", "✥", "✭" }

local function statTier(value, tiers)
    for _, tier in ipairs(tiers) do
        if value >= tier[1] then return "§" .. tier[2] end
    end
    return "§7"
end

local STAT_COLORS = {
    fkdr = function(v)
        return statTier(v, {{100, "5"}, {50, "d"}, {30, "4"}, {20, "c"}, {10, "6"}, {7, "e"}, {5, "2"}, {3, "a"}, {1, "f"}})
    end,
    finals = function(v)
        return statTier(v, {{100000, "5"}, {50000, "d"}, {25000, "4"}, {15000, "c"}, {7500, "6"}, {5000, "e"}, {2500, "2"}, {1000, "a"}, {500, "f"}})
    end,
}

-- Config schema

starfish.schema.section({
    key = "tab",
    label = "Tab Stats",
    description = "Show BedWars stats in the tab list after /who.",
    defaults = {
        tab = {
            mode = "compact",
            headerLabels = true,
            showStars = true, showFkdr = true, showFinals = true,
            showRespawns = true, showFlags = true,
            keepEliminated = true,
            grayOwnTeam = false
        }
    },
    settings = {
        { key = "tab.mode", type = "cycle", description = "Tab stats display mode.", displayLabel = "Mode", values = {
            { text = "Compact", value = "compact" },
            { text = "Off", value = "off" }
        }},
        { key = "tab.headerLabels", type = "toggle", default = true, description = "Show column labels in the tab list header instead of next to each value." },
        { key = "tab.showStars", type = "toggle", default = true, description = "Show BedWars stars." },
        { key = "tab.showFkdr", type = "toggle", default = true, description = "Show final kill/death ratio." },
        { key = "tab.showFinals", type = "toggle", default = true, description = "Show final kill count." },
        { key = "tab.showRespawns", type = "toggle", default = true, description = "Show a respawn countdown in a player's tab row while they are dead." },
        { key = "tab.showFlags", type = "toggle", default = true, description = "Mark players the anticheat has flagged this game." },
        { key = "tab.keepEliminated", type = "toggle", default = true, description = "Keep permanently eliminated players in the tab list, grayed out, instead of letting them disappear." },
        { key = "tab.grayOwnTeam", type = "toggle", default = false, description = "Render your own team's stats in gray to de-emphasize them." },
    }
})

starfish.schema.section({
    key = "who",
    label = "Auto /who",
    description = "Automatically run /who when a game starts.",
    defaults = { who = { enabled = true, delay = 500 } },
    settings = {
        { key = "who.enabled", type = "toggle", default = true, description = "Send /who at game start to load everyone's stats." },
        { key = "who.delay", type = "cycle", description = "Delay before sending /who.", displayLabel = "Delay", values = {
            { text = "0ms", value = 0 },
            { text = "500ms", value = 500 },
            { text = "1000ms", value = 1000 }
        }},
    }
})

starfish.schema.section({
    key = "lobbyStats",
    label = "Lobby Stats",
    description = "Show stats for players in the pre-game lobby.",
    defaults = { lobbyStats = { enabled = true, mentions = true } },
    settings = {
        { key = "lobbyStats.enabled", type = "toggle", default = true, description = "Show a stat line for every player who chats in the pre-game lobby." },
        { key = "lobbyStats.mentions", type = "toggle", default = true, description = "Show a stat line for anyone whose message mentions your name." },
    }
})

starfish.schema.section({
    key = "requeue",
    label = "Requeue",
    description = "Requeue the last played mode with /rq.",
    defaults = { requeue = { auto = false, delay = 1000 } },
    settings = {
        { key = "requeue.auto", type = "toggle", default = false, description = "Automatically requeue when a game ends." },
        { key = "requeue.delay", type = "cycle", description = "Delay before auto-requeueing.", displayLabel = "Delay", values = {
            { text = "0ms", value = 0 },
            { text = "1000ms", value = 1000 },
            { text = "2000ms", value = 2000 },
            { text = "3000ms", value = 3000 }
        }},
    }
})

starfish.schema.section({
    key = "partyCounter",
    label = "Party Counter",
    description = "Detect groups of players joining or leaving the lobby together.",
    defaults = { partyCounter = { enabled = true } },
    settings = {
        { key = "partyCounter.enabled", type = "toggle", default = true, description = "Announce when a party of players joins or leaves your lobby." },
    }
})

starfish.schema.section({
    key = "heightLimit",
    label = "Height Limit",
    description = "Warn in the action bar as you build near the map's height limit.",
    defaults = { heightLimit = { enabled = true } },
    settings = {
        { key = "heightLimit.enabled", type = "toggle", default = true, description = "Show a live action bar warning when you are close to the build height limit." },
    }
})

-- State

local location = { inBedwars = false, inGame = false, map = nil }
local lastMode = nil
local stats = {}
local fetchCallbacks = {}
local managed = {}
local pendingJoins = {}
local lastApplied = {}
local tabActive = false
local refreshTimer = nil
local dirty = false
local game = { started = false, eliminated = {}, respawns = {} }
local lobby = { active = false, statsSeen = {}, mentionsSeen = {} }
local party = { count = 0, timer = nil, maxPlayers = 0, isJoin = false }
local heightWatch = { limit = nil, timer = nil }
local flagged = {}
local lastWhoAt = 0
local requeueTriggered = false

local NICKED_STATS = { isNicked = true }

-- Helpers

local function getConfig(key, default)
    local val = starfish.config.get(key)
    if val ~= nil then return val end
    return default
end

local function stripColors(text)
    return text:gsub("§.", "")
end

local function formatNumber(n)
    local result = tostring(math.floor(n))
    local pos = #result - 3
    while pos > 0 do
        result = result:sub(1, pos) .. "," .. result:sub(pos + 1)
        pos = pos - 3
    end
    return result
end

local function tabMode()
    return getConfig("tab.mode", "compact")
end

local function tabEnabled()
    return tabMode() ~= "off"
end

local function callPlugin(name, func, ...)
    if starfish.plugins.exists(name) then
        return starfish.plugins.call(name, func, ...)
    end
    return nil
end

local function getRealName(name)
    return callPlugin("denicker", "getRealName", name)
end

local function isNicked(name)
    return callPlugin("denicker", "isNicked", name) == true
end

local function teamColorOf(name)
    local team = starfish.players.getTeam(name)
    if not team or not team.prefix then return "§f" end
    local last = nil
    for code in team.prefix:gmatch("§([0-9a-f])") do
        last = code
    end
    return last and ("§" .. last) or "§f"
end

local function teamFormatted(name, displayText)
    local team = starfish.players.getTeam(name)
    local prefix = team and team.prefix or ""
    local suffix = team and team.suffix or ""
    return prefix .. (displayText or name) .. suffix
end

-- Stats service

local function levelFromXp(xp)
    local level = 100 * math.floor(xp / 487000)
    local rem = xp % 487000
    if rem < 500 then return level end
    if rem < 1500 then return level + 1 end
    if rem < 3500 then return level + 2 end
    if rem < 7000 then return level + 3 end
    return level + 4 + math.floor((rem - 7000) / 5000)
end

local function parseBedwarsStats(player)
    local bw = player.stats and player.stats.Bedwars or {}
    local fk = bw.final_kills_bedwars or 0
    local stars = player.achievements and player.achievements.bedwars_level
        or levelFromXp(bw.Experience or 0)

    return {
        stars = stars,
        fkdr = fk / math.max(1, bw.final_deaths_bedwars or 1),
        finals = fk,
        displayName = player.displayname,
        timestamp = os.time()
    }
end

local function notifyFetched(key)
    local callbacks = fetchCallbacks[key]
    fetchCallbacks[key] = nil
    if callbacks then
        for _, callback in ipairs(callbacks) do
            callback(stats[key])
        end
    end
    dirty = true
end

local function fetchStats(key, query, attempt)
    local cached = stats[key]
    if cached and not cached.isLoading and cached.timestamp and os.time() - cached.timestamp < CACHE_TTL then
        notifyFetched(key)
        return
    end
    if cached and cached.isLoading and (attempt or 1) == 1 then return end

    stats[key] = { isLoading = true }
    starfish.http.get(STATS_API .. query .. "&max_cache_age=" .. STATS_MAX_CACHE_AGE, {}, function(res)
        if res.success and res.data and res.data.player then
            stats[key] = parseBedwarsStats(res.data.player)
            notifyFetched(key)
        elseif res.success and res.data and res.data.player == nil then
            stats[key] = { isNicked = true }
            notifyFetched(key)
        else
            local tries = attempt or 1
            if tries < FETCH_RETRIES then
                starfish.events.delay(RETRY_BASE_MS * 2 ^ (tries - 1), function()
                    fetchStats(key, query, tries + 1)
                end)
            else
                stats[key] = { fetchError = res.error or ("HTTP " .. tostring(res.status or "?")) }
                notifyFetched(key)
            end
        end
    end)
end

local function requestStats(name, callback)
    local realName = getRealName(name)
    if not realName and isNicked(name) then
        if callback then callback(NICKED_STATS) end
        return
    end

    local query = realName or name
    local key = query:lower()
    if callback then
        fetchCallbacks[key] = fetchCallbacks[key] or {}
        table.insert(fetchCallbacks[key], callback)
    end

    fetchStats(key, query)
end

local function statsFor(name)
    local realName = getRealName(name)
    if not realName and isNicked(name) then return NICKED_STATS end
    return stats[(realName or name):lower()]
end

-- Font metrics

local SPACE_WIDTH = 3.2
local DEFAULT_CHAR_WIDTH = 4.0
local CHAR_WIDTH = {
    ["I"] = 2.667,
    ["f"] = 3.333, ["i"] = 1.333, ["k"] = 3.333, ["l"] = 2.0, ["t"] = 2.667,
    ["["] = 2.667, ["]"] = 2.667, ["."] = 1.333, [","] = 1.333, ["|"] = 1.333,
    ["!"] = 1.333,
    ["✫"] = 5.667, ["✪"] = 5.667, ["⚝"] = 5.667, ["✥"] = 6.0, ["✭"] = 5.667,
    ["✓"] = 5.667, ["✗"] = 5.667,
    [" "] = SPACE_WIDTH,
}

local function textWidth(text)
    local width = 0
    for _, code in utf8.codes(stripColors(text)) do
        width = width + (CHAR_WIDTH[utf8.char(code)] or DEFAULT_CHAR_WIDTH)
    end
    return width
end

local function spaceCount(deficit)
    if deficit <= 0 then return 0 end
    return math.floor(deficit / SPACE_WIDTH + 0.5)
end

local function padSpaces(deficit)
    local count = spaceCount(deficit)
    if count <= 0 then return "", 0 end
    return ("§r "):rep(count), count * SPACE_WIDTH
end

-- Column formatting

local function colorizeStars(stars)
    local scheme = PRESTIGE_SCHEMES[math.min(math.floor(stars / 100), 100)]
    local symbol = STAR_SYMBOLS[math.min(math.floor(stars / 1000), 4)]
    local function color(slot)
        local index = math.min(slot, #scheme)
        return "§" .. scheme:sub(index, index)
    end

    local digitsText = tostring(math.floor(stars))
    local parts = { color(1), "[" }
    for i = 1, #digitsText do
        table.insert(parts, color(2 + math.min(i - 1, 3)))
        table.insert(parts, digitsText:sub(i, i))
    end
    table.insert(parts, color(6))
    table.insert(parts, symbol)
    table.insert(parts, color(7))
    table.insert(parts, "]")
    return table.concat(parts)
end

local function statsUnavailable(st)
    return st.isNicked or st.fetchError
end

local COLUMNS = {
    {
        key = "stars",
        config = "tab.showStars",
        header = "✫",
        position = "prefix",
        value = function(st)
            if not st or st.isLoading then return "§8[---✫]" end
            if statsUnavailable(st) then return "§c[???✫]" end
            return colorizeStars(st.stars)
        end
    },
    {
        key = "fkdr",
        config = "tab.showFkdr",
        header = "FKDR",
        position = "prefix",
        value = function(st)
            if not st or st.isLoading then return "§8-.-" end
            if statsUnavailable(st) then return "§c?.?" end
            return STAT_COLORS.fkdr(st.fkdr) .. string.format("%.1f", st.fkdr)
        end
    },
    {
        key = "finals",
        config = "tab.showFinals",
        header = "Finals",
        position = "suffix",
        value = function(st)
            if not st or st.isLoading then return "§8-" end
            if statsUnavailable(st) then return "§c?" end
            return STAT_COLORS.finals(st.finals) .. formatNumber(st.finals)
        end
    },
}

local SUFFIX_PRIORITY = 100
local FLAG_BADGE = "§4[!] "

local function enabledColumns()
    local columns = {}
    for _, column in ipairs(COLUMNS) do
        if getConfig(column.config, true) then
            table.insert(columns, column)
        end
    end
    return columns
end

local function columnsByPosition(columns, position)
    local filtered = {}
    for _, column in ipairs(columns) do
        if column.position == position then
            table.insert(filtered, column)
        end
    end
    return filtered
end

-- Tab manager

local function computeColumnWidths(columns)
    local widths = {}
    for i, column in ipairs(columns) do
        widths[i] = 0
        for name in pairs(managed) do
            local width = textWidth(column.value(statsFor(name), name))
            if width > widths[i] then widths[i] = width end
        end
    end
    return widths
end

local function myTeamColor()
    local me = starfish.players.me()
    return me and teamColorOf(me.name) or nil
end

local function isGrayed(name, teamColor, ownTeamColor)
    if game.eliminated[name] then return true end
    return ownTeamColor ~= nil and getConfig("tab.grayOwnTeam", false) and teamColor == ownTeamColor
end

local function teamPrefixWidth(name)
    local team = starfish.players.getTeam(name)
    return team and team.prefix and textWidth(team.prefix) or 0
end

local function computeMaxTeamPrefixWidth()
    local maxWidth = 0
    for name in pairs(managed) do
        local width = teamPrefixWidth(name)
        if width > maxWidth then maxWidth = width end
    end
    return maxWidth
end

local function displayNameOf(name)
    local player = starfish.players.find(name)
    return (player and player.displayName) or name
end

local function flagBadge(name)
    if flagged[name] and getConfig("tab.showFlags", true) then return FLAG_BADGE end
    return ""
end

local function nameColumnWidth(name, uuid)
    return textWidth(flagBadge(name))
        + textWidth(displayNameOf(name))
        + textWidth(starfish.display.getOthersPrefix(uuid))
        + textWidth(starfish.display.getOthersSuffix(uuid))
end

local function computeMaxNameColumnWidth()
    local maxWidth = 0
    for name, entry in pairs(managed) do
        local width = nameColumnWidth(name, entry.uuid)
        if width > maxWidth then maxWidth = width end
    end
    return maxWidth
end

local SEPARATOR = " §8| §r"

local function emitColumn(parts, x, target, text, colWidth, alignRight)
    target = target + colWidth
    local textW = textWidth(text)
    local pad, padW = padSpaces(target - x - textW)

    if alignRight then
        table.insert(parts, pad)
        table.insert(parts, text)
    else
        table.insert(parts, text)
        table.insert(parts, pad)
    end

    return x + textW + padW, target
end

local function joinColumns(parts, x, target, name, columns, widths, grayed, alignRight)
    local st = statsFor(name)
    for i, column in ipairs(columns) do
        if i > 1 then
            table.insert(parts, SEPARATOR)
            local sepW = textWidth(SEPARATOR)
            x, target = x + sepW, target + sepW
        end
        local text = column.value(st, name)
        if grayed then
            text = "§8" .. stripColors(text)
        end
        x, target = emitColumn(parts, x, target, text, widths[i], alignRight)
    end
    return x, target
end

local function buildPrefix(name, prefixColumns, widths, ownTeamColor, teamPrefixPad)
    local teamColor = teamColorOf(name)
    local grayed = isGrayed(name, teamColor, ownTeamColor)

    local thisTeamPrefixWidth = teamPrefixWidth(name)
    local teamPad, teamPadW = padSpaces(teamPrefixPad - thisTeamPrefixWidth)
    local parts = { teamPad }
    local x, target = thisTeamPrefixWidth + teamPadW, teamPrefixPad

    if #prefixColumns > 0 then
        x, target = joinColumns(parts, x, target, name, prefixColumns, widths, grayed, true)
        table.insert(parts, " §8| ")
        local sepW = textWidth(" §8| ")
        x, target = x + sepW, target + sepW
    end
    table.insert(parts, flagBadge(name))
    table.insert(parts, game.eliminated[name] and "§7" or teamColor)

    return table.concat(parts), x, target
end

local function buildSuffix(name, uuid, suffixColumns, widths, ownTeamColor, maxNameWidth, x, target)
    if #suffixColumns == 0 then return "" end
    local grayed = isGrayed(name, teamColorOf(name), ownTeamColor)

    x = x + nameColumnWidth(name, uuid)
    target = target + maxNameWidth
    local namePad, namePadW = padSpaces(target - x)
    x = x + namePadW

    local parts = { namePad, " §8| " }
    local sepW = textWidth(" §8| ")
    x, target = x + sepW, target + sepW

    joinColumns(parts, x, target, name, suffixColumns, widths, grayed, false)
    return table.concat(parts)
end

local function headerLabelsLine(prefixColumns, suffixColumns, maxNameWidth)
    local labels = {}
    for _, column in ipairs(prefixColumns) do
        table.insert(labels, column.header)
    end
    local namePad = padSpaces(maxNameWidth - textWidth("Name"))
    table.insert(labels, "Name" .. namePad)
    for _, column in ipairs(suffixColumns) do
        table.insert(labels, column.header)
    end
    return "§7" .. table.concat(labels, " §8| §7")
end

local function respawnOverride(name)
    if not getConfig("tab.showRespawns", true) then return nil end
    local respawn = game.respawns[name]
    if not respawn then return nil end
    return "", " §8[§c" .. respawn.remaining .. "s§8]"
end

local function updateTabHeader(prefixColumns, suffixColumns, maxNameWidth)
    if getConfig("tab.headerLabels", true) then
        starfish.display.setTabHeaderAppend(headerLabelsLine(prefixColumns, suffixColumns, maxNameWidth))
    else
        starfish.display.clearTabHeaderAppend()
    end
end

local function clearTabDecorations()
    for _, entry in pairs(managed) do
        starfish.display.clearPrefix(entry.uuid)
        starfish.display.clearSuffix(entry.uuid)
    end
    starfish.display.clearTabHeaderAppend()
    managed = {}
    pendingJoins = {}
    lastApplied = {}
end

local function deactivateTab()
    if not tabActive then return end
    tabActive = false
    if refreshTimer then
        starfish.events.clearTimer(refreshTimer)
        refreshTimer = nil
    end
    clearTabDecorations()
end

local function refreshTab()
    if not tabActive then return end
    if not tabEnabled() then
        deactivateTab()
        return
    end
    if not dirty then return end
    dirty = false

    local columns = enabledColumns()
    local prefixColumns = columnsByPosition(columns, "prefix")
    local suffixColumns = columnsByPosition(columns, "suffix")
    local widths = computeColumnWidths(columns)
    local ownTeamColor = myTeamColor()
    local teamPrefixPad = computeMaxTeamPrefixWidth()
    local maxNameWidth = computeMaxNameColumnWidth()
    updateTabHeader(prefixColumns, suffixColumns, maxNameWidth)

    for name, entry in pairs(managed) do
        local prefix, suffix = respawnOverride(name)
        if not prefix then
            local x, target
            prefix, x, target = buildPrefix(name, prefixColumns, widths, ownTeamColor, teamPrefixPad)
            suffix = buildSuffix(name, entry.uuid, suffixColumns, widths, ownTeamColor, maxNameWidth, x, target)
        end
        local combined = prefix .. "\0" .. suffix
        if lastApplied[entry.uuid] ~= combined then
            lastApplied[entry.uuid] = combined
            starfish.display.setPrefix(entry.uuid, prefix)
            starfish.display.setSuffix(entry.uuid, suffix, SUFFIX_PRIORITY)
        end
    end
end

local function activateTab(names)
    if not tabEnabled() then return end
    if tabMode() == "overlay" then
        starfish.chat.send(starfish.chat.warning("Overlay mode is not available yet - using compact."))
    end

    for _, name in ipairs(names) do
        if not managed[name] then
            local player = starfish.players.find(name)
            if player and player.uuid then
                managed[name] = { uuid = player.uuid }
                requestStats(name)
            else
                pendingJoins[name] = true
            end
        end
    end

    if next(managed) or next(pendingJoins) then
        tabActive = true
        dirty = true
        if not refreshTimer then
            refreshTimer = starfish.events.interval(REFRESH_MS, refreshTab)
        end
    end
end

-- Tab entry protection

local function shouldProtect(name)
    if not managed[name] then return false end
    if game.eliminated[name] and not getConfig("tab.keepEliminated", true) then
        return false
    end
    return true
end

starfish.packets.intercept("inbound", starfish.protocol.PLAYER_LIST_ITEM, function(packet)
    local reader = starfish.encoding.reader(packet.data)
    reader:varint()
    if reader:varint() ~= starfish.protocol.PLAYER_LIST_ACTION_REMOVE then return end

    local protectedUuids = {}
    for name, entry in pairs(managed) do
        if shouldProtect(name) then
            protectedUuids[entry.uuid] = true
        end
    end

    local count = reader:varint()
    local kept = {}
    for _ = 1, count do
        local uuid = reader:uuid()
        if not protectedUuids[uuid] then
            table.insert(kept, uuid)
        end
    end
    if #kept == count then return end
    if #kept == 0 then
        packet.drop()
        return
    end

    local writer = starfish.encoding.writer()
    writer:varint(packet.id)
    writer:varint(starfish.protocol.PLAYER_LIST_ACTION_REMOVE)
    writer:varint(#kept)
    for _, uuid in ipairs(kept) do
        writer:uuid(uuid)
    end
    packet.replace(writer:build())
end)

starfish.packets.intercept("inbound", starfish.protocol.TEAMS, function(packet)
    local reader = starfish.encoding.reader(packet.data)
    reader:varint()
    local teamName = reader:string()
    if reader:byte() ~= starfish.protocol.TEAM_MODE_REMOVE_PLAYERS then return end

    local protectedNames = {}
    for name in pairs(managed) do
        if shouldProtect(name) then
            protectedNames[name] = true
        end
    end

    local count = reader:varint()
    local kept = {}
    for _ = 1, count do
        local playerName = reader:string()
        if not protectedNames[playerName] then
            table.insert(kept, playerName)
        end
    end
    if #kept == count then return end
    if #kept == 0 then
        packet.drop()
        return
    end

    local writer = starfish.encoding.writer()
    writer:varint(packet.id)
    writer:string(teamName)
    writer:byte(starfish.protocol.TEAM_MODE_REMOVE_PLAYERS)
    writer:varint(#kept)
    for _, playerName in ipairs(kept) do
        writer:string(playerName)
    end
    packet.replace(writer:build())
end)

-- Chat stat lines

local function blockedMarker(name)
    local entry = callPlugin("denicker", "getIgnoreEntry", getRealName(name) or name)
    if not entry then return "" end
    local note = entry.note and (" §7- " .. entry.note) or ""
    return " §8[§cblocked" .. note .. "§8]"
end

local function statLine(name, st)
    local displayName = (st and st.displayName) or name
    if not st then
        return teamFormatted(name, displayName) .. " §8- §cstats unavailable" .. blockedMarker(name)
    end
    if st.isNicked then
        return teamFormatted(name, displayName) .. " §8- §cnicked" .. blockedMarker(name)
    end
    if st.fetchError then
        return teamFormatted(name, displayName) .. " §8- §crequest failed (" .. st.fetchError .. ")" .. blockedMarker(name)
    end

    local parts = {}
    for _, column in ipairs(enabledColumns()) do
        local text = column.value(st, name)
        if column.key == "stars" then
            table.insert(parts, text)
        else
            table.insert(parts, "§7" .. column.header .. " " .. text)
        end
    end
    return teamFormatted(name, displayName) .. " §8- §r" .. table.concat(parts, " §8| §r") .. blockedMarker(name)
end

local function printStats(name)
    requestStats(name, function(st)
        starfish.chat.send(starfish.chat.prefix(statLine(name, st)))
    end)
end

-- Height limit

local function mapHeightLimit(map)
    if not map then return nil end
    return HEIGHT_LIMITS[map:lower():gsub(" ", "_"):gsub("'", "")]
end

local function heightBarText(remaining, limit)
    if remaining <= 0 then
        return "§4At the height limit §8(§e" .. limit .. "§8)"
    end
    local color = remaining <= 3 and "§c" or "§e"
    return color .. remaining .. " §7block" .. (remaining == 1 and "" or "s") .. " below the height limit §8(§e" .. limit .. "§8)"
end

local function updateHeightBar()
    local pos = starfish.players.getPosition()
    if not pos then return end
    local remaining = heightWatch.limit - math.floor(pos.y)
    if remaining <= HEIGHT_WARN_RANGE then
        starfish.chat.actionBar(heightBarText(remaining, heightWatch.limit))
    end
end

local function stopHeightWatch()
    if heightWatch.timer then
        starfish.events.clearTimer(heightWatch.timer)
        heightWatch.timer = nil
    end
    heightWatch.limit = nil
end

local function startHeightWatch()
    stopHeightWatch()
    if not getConfig("heightLimit.enabled", true) then return end
    heightWatch.limit = mapHeightLimit(location.map)
    if heightWatch.limit then
        heightWatch.timer = starfish.events.interval(HEIGHT_BAR_MS, updateHeightBar)
    end
end

-- Game flow

local function sendWho()
    if not getConfig("who.enabled", true) then return end
    local now = os.time() * 1000
    if now - lastWhoAt < AUTO_WHO_DEDUPE_MS then return end
    lastWhoAt = now

    starfish.events.delay(getConfig("who.delay", 500), function()
        starfish.chat.sendToServer("/who")
    end)
end

local function resetGame()
    for _, respawn in pairs(game.respawns) do
        starfish.events.clearTimer(respawn.timer)
    end
    game.started = false
    game.respawns = {}
    game.eliminated = {}
    flagged = {}
    stopHeightWatch()
end

local function onGameStart()
    resetGame()
    game.started = true
    lobby.active = false
    requeueTriggered = false
    sendWho()
    startHeightWatch()
end

local function performRequeue()
    if not lastMode then
        starfish.chat.send(starfish.chat.error("No recent BedWars mode to requeue."))
        return
    end
    starfish.chat.send(starfish.chat.prefix("§7Requeueing §f" .. lastMode .. "§7..."))
    starfish.chat.sendToServer("/play " .. lastMode)
end

local function onGameEnd()
    if requeueTriggered then return end
    requeueTriggered = true
    game.started = false
    stopHeightWatch()
    if not getConfig("requeue.auto", false) then return end

    starfish.events.delay(getConfig("requeue.delay", 1000), performRequeue)
end

-- Death and respawn tracking

local function markEliminated(name)
    local respawn = game.respawns[name]
    if respawn then starfish.events.clearTimer(respawn.timer) end
    game.respawns[name] = nil
    game.eliminated[name] = true
    dirty = true
end

local function markTeamEliminated(teamColor)
    for name in pairs(managed) do
        if teamColorOf(name) == teamColor then
            markEliminated(name)
        end
    end
end

local function trackRespawn(name, seconds)
    if game.eliminated[name] then return end
    local existing = game.respawns[name]
    if existing then starfish.events.clearTimer(existing.timer) end

    local respawn = { remaining = seconds }
    game.respawns[name] = respawn
    respawn.timer = starfish.events.interval(1000, function()
        respawn.remaining = respawn.remaining - 1
        dirty = true
        if respawn.remaining <= 0 then
            starfish.events.clearTimer(respawn.timer)
            if game.respawns[name] == respawn then
                game.respawns[name] = nil
            end
        end
    end)
    dirty = true
end

local function onRejoin(kind)
    if not game.started then onGameStart() end

    local me = starfish.players.me()
    if not me then return end
    if kind == "spectator" then
        markEliminated(me.name)
    else
        trackRespawn(me.name, RECONNECT_RESPAWN_SECONDS)
    end
end

local DEATH_PHRASES = {
    " was ", "fell into the void", "hit the ground too hard",
    "burned to death", "drowned", "went up in flames", " died",
}

local function isDeathMessage(message)
    if message:sub(-1) ~= "." then return false end
    for _, phrase in ipairs(DEATH_PHRASES) do
        if message:find(phrase, 1, true) then return true end
    end
    return false
end

local function handleGameChat(message)
    if message:find(":", 1, true) then return false end

    local eliminatedTeam = message:match("^TEAM ELIMINATED > (%a+) Team")
    if eliminatedTeam and TEAM_COLORS[eliminatedTeam] then
        markTeamEliminated(TEAM_COLORS[eliminatedTeam])
        return true
    end

    local reconnected = message:match("^([%w_]+) reconnected%.$")
    if reconnected and managed[reconnected] then
        trackRespawn(reconnected, RECONNECT_RESPAWN_SECONDS)
        return true
    end

    local subject = message:match("^([%w_]+) ")
    if not subject or not managed[subject] then return false end

    if message:sub(-11) == "FINAL KILL!" then
        markEliminated(subject)
        return true
    end
    if isDeathMessage(message) then
        trackRespawn(subject, RESPAWN_SECONDS)
        return true
    end
    return false
end

-- Lobby and mention stats

local function extractSpeaker(message)
    local before = message:match("^([^:]+):")
    if not before then return nil end
    return before:match("([%w_]+)%s*$")
end

local function handleLobbyChat(message)
    local speaker = extractSpeaker(message)
    if not speaker then return end
    if not starfish.players.find(speaker) then return end

    local me = starfish.players.me()
    if me and speaker == me.name then return end

    if lobby.active and getConfig("lobbyStats.enabled", true) and not lobby.statsSeen[speaker] then
        lobby.statsSeen[speaker] = true
        printStats(speaker)
        return
    end

    if getConfig("lobbyStats.mentions", true) and me and not lobby.mentionsSeen[speaker] then
        local content = message:match("^[^:]+:%s*(.+)$")
        if content and content:lower():find(me.name:lower(), 1, true) then
            lobby.mentionsSeen[speaker] = true
            printStats(speaker)
        end
    end
end

-- Party counter

local function partyGroupSize(count, maxPlayers)
    if maxPlayers == 8 then return false end
    return count >= 2 and count <= math.floor(maxPlayers / 4)
end

local function handlePartyCounter(message)
    if not getConfig("partyCounter.enabled", true) then return end

    local _, maxPlayers = message:match("%((%d+)/(%d+)%)!$")
    if maxPlayers then party.maxPlayers = tonumber(maxPlayers) end

    local isJoin = message:match("has joined %(%d+/%d+%)!$") ~= nil
    local isLeave = message:match("has quit!$") ~= nil
    if not isJoin and not isLeave then return end

    party.count = party.count + 1
    party.isJoin = isJoin
    if party.timer then
        starfish.events.clearTimer(party.timer)
    end
    party.timer = starfish.events.delay(PARTY_GROUP_MS, function()
        party.timer = nil
        if partyGroupSize(party.count, party.maxPlayers) then
            local arrow = party.isJoin and "»" or "«"
            local color = party.isJoin and "§b" or "§3"
            local verb = party.isJoin and "joined" or "left"
            starfish.chat.send(starfish.chat.prefix("§8" .. arrow .. " §7Party of " .. color .. party.count .. " §7" .. verb .. "."))
        end
        party.count = 0
    end)
end

-- Event wiring

local function applyLocation(loc)
    location.inBedwars = loc.serverType == "BEDWARS"
    local wasInGame = location.inGame
    location.inGame = location.inBedwars and loc.lobbyName == nil and loc.mode ~= nil
    location.map = loc.map

    if location.inGame then
        lastMode = loc.mode:lower()
        if not wasInGame then
            resetGame()
            lobby.active = true
            lobby.statsSeen = {}
            lobby.mentionsSeen = {}
        end
    else
        lobby.active = false
        if wasInGame then
            resetGame()
            deactivateTab()
        end
    end

    if location.inGame and game.started and not heightWatch.timer then
        startHeightWatch()
    end
end

starfish.events.on("hypixel:location", function(event)
    if not event.success then return end
    applyLocation(event.location)
end)

starfish.events.on("chat", function(event)
    if event.position == 2 then return end
    if not location.inBedwars then return end

    local message = stripColors(event.message or "")

    local whoList = message:match("^ONLINE: (.+)$")
    if whoList then
        deactivateTab()
        local names = {}
        for name in whoList:gmatch("[^,%s]+") do
            table.insert(names, name)
        end
        activateTab(names)
        return
    end

    if REJOIN_MESSAGES[message] then
        onRejoin(REJOIN_MESSAGES[message])
        return
    end

    if message:find(GAME_START_PHRASE, 1, true) and not message:find(":", 1, true) then
        onGameStart()
        return
    end

    if message:find(GAME_END_PHRASE, 1, true) then
        onGameEnd()
        return
    end

    if game.started and handleGameChat(message) then return end
    handlePartyCounter(message)
    handleLobbyChat(message)
end)

starfish.events.on("player_join", function(event)
    if not tabActive or not pendingJoins[event.name] then return end
    pendingJoins[event.name] = nil
    managed[event.name] = { uuid = event.uuid }
    requestStats(event.name)
    dirty = true
end)

starfish.events.on("scoreboard_team", function()
    if tabActive then dirty = true end
end)

starfish.events.on("denicker:nick_resolved", function(event)
    if managed[event.nickName] then
        requestStats(event.nickName)
        dirty = true
    end
end)

starfish.events.on("anticheat:flag", function(event)
    if flagged[event.name] then return end
    flagged[event.name] = true
    if managed[event.name] then dirty = true end
end)

starfish.events.on("plugin_restored", function(event)
    if event.pluginName == "bedwars" then
        deactivateTab()
    end
end)

starfish.events.on("config_changed", function(event)
    if event.plugin ~= "bedwars" then return end
    if tabActive then dirty = true end

    if event.key == "enabled" then
        if event.value == false then
            deactivateTab()
            stopHeightWatch()
        elseif location.inGame then
            sendWho()
        end
    elseif event.key == "tab.mode" and event.value ~= "off" and location.inGame and not tabActive then
        sendWho()
    elseif event.key == "heightLimit.enabled" then
        if event.value == false then
            stopHeightWatch()
        elseif game.started then
            startHeightWatch()
        end
    end
end)

-- Commands

starfish.commands.register("stats", {
    description = "Show a player's BedWars stats",
    arguments = {
        starfish.commands.arg("player", "Player name to look up")
    }
}, function(args)
    if #args == 0 then
        starfish.chat.send(starfish.chat.error("Usage: /bw stats <player>"))
        return
    end
    printStats(args[1])
end)

starfish.commands.register("height", {
    description = "Show the build height limit for a map",
    arguments = {
        starfish.commands.greedy("map", "Map name (defaults to the current map)")
    }
}, function(args)
    local map = #args > 0 and table.concat(args, " ") or location.map
    if not map then
        starfish.chat.send(starfish.chat.error("No map detected. Usage: /bw height <map>"))
        return
    end

    local height = mapHeightLimit(map)
    if height then
        starfish.chat.send(starfish.chat.prefix("§bHeight limit for §a" .. map .. " §bis §e" .. height))
    else
        starfish.chat.send(starfish.chat.error("Unknown map: " .. map))
    end
end)

starfish.commands.registerGlobal("rq", {
    description = "Requeue the last played BedWars mode"
}, function()
    performRequeue()
end)

-- Startup

local restored = callPlugin("hypixel-mod-api", "getLocation")
if restored and restored.serverName then
    applyLocation(restored)
end
