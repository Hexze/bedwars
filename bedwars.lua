plugin = {
    name = "bedwars",
    displayName = "BedWars",
    command = "bw",
    prefix = "§cB§fW",
    version = "0.4.0",
    description = "Various BedWars tools and quality of life features",
    readme = [[
Various BedWars tools and quality of life features

- Keyless tablist stats overlay
- Player respawn timer
- Auto /who
- Party counter
- Height limit indicator]],
dependencies = {
        { name = "hypixel-mod-api", minVersion = "1.0.0" },
        { name = "urchin", minVersion = "0.5.0" },
        { name = "denicker", optional = true }
    }
}

-- Constants

local HYPIXEL_API_HOST = "https://api.hypixel.net/v2"
local CACHE_TTL = 300
local FETCH_RETRIES = 3
local RETRY_BASE_MS = 2000
local REFRESH_MS = 500
local AUTO_WHO_DEDUPE_MS = 5000
local PARTY_GROUP_MS = 250
local SOLO_LOBBY_SIZE = 8
local PARTY_GROUP_DENOMINATOR = 4
local RESPAWN_SECONDS = 5
local RECONNECT_RESPAWN_SECONDS = 10
local RESPAWN_CONFIRM_GRACE_MS = 500
local STATS_LOADING_TIMEOUT_MS = 10000
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

local GRAYED_COLOR = "§8"
local RESPAWNING_COLOR = "§7"

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

-- Stat colors

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
    kdr = function(v)
        return statTier(v, {{8, "5"}, {7, "d"}, {6, "4"}, {5, "c"}, {4, "6"}, {3, "e"}, {2, "2"}, {1, "a"}, {0.5, "f"}})
    end,
    winstreak = function(v)
        return statTier(v, {{500, "5"}, {250, "d"}, {100, "4"}, {75, "c"}, {50, "6"}, {40, "e"}, {25, "2"}, {15, "a"}, {5, "f"}})
    end,
}

local TOTAL_COLORS = {
    wlr        = function(v) return statTier(v, {{30, "5"}, {15, "d"}, {9, "4"}, {6, "c"}, {3, "6"}, {2.1, "e"}, {1.5, "2"}, {0.9, "a"}, {0.3, "f"}}) end,
    bblr       = function(v) return statTier(v, {{20, "5"}, {10, "d"}, {6, "4"}, {4, "c"}, {2, "6"}, {1.4, "e"}, {1, "2"}, {0.6, "a"}, {0.2, "f"}}) end,
    wins       = function(v) return statTier(v, {{30000, "5"}, {15000, "d"}, {7500, "4"}, {4500, "c"}, {2250, "6"}, {1500, "e"}, {450, "2"}, {300, "a"}, {150, "f"}}) end,
    kills      = function(v) return statTier(v, {{75000, "5"}, {37500, "d"}, {18750, "4"}, {11250, "c"}, {5625, "6"}, {3750, "e"}, {1875, "2"}, {750, "a"}, {375, "f"}}) end,
    bedsBroken = function(v) return statTier(v, {{50000, "5"}, {25000, "d"}, {12500, "4"}, {7500, "c"}, {3750, "6"}, {2500, "e"}, {1250, "2"}, {500, "a"}, {250, "f"}}) end,
}

local SESSION_COLORS = {
    fkdr = function(v) return statTier(v, {{500, "5"}, {250, "d"}, {150, "4"}, {100, "c"}, {50, "6"}, {35, "e"}, {25, "2"}, {15, "a"}, {5, "f"}}) end,
}

-- Column slots

local SLOTS = {
    { content = "star",      shown = true },
    { content = "username",  shown = true },
    { content = "winstreak", shown = false },
    { content = "fkdr",      shown = true },
    { content = "finals",    shown = true },
    { content = "kdr",       shown = false },
}

local SLOT_CONTENTS = {
    { text = "Star", value = "star" },
    { text = "Username", value = "username" },
    { text = "Winstreak", value = "winstreak" },
    { text = "FKDR", value = "fkdr" },
    { text = "Finals", value = "finals" },
    { text = "KDR", value = "kdr" },
}

local function slotKey(index, field)
    return "tab.slot" .. index .. "." .. field
end

-- Config schema

local function registerTabSection()
    local settings = {
        { key = "tab.enabled", type = "toggle", default = true, description = "Show BedWars stats in the tab list." },
    }
    if starfish.config.get("tab.enabled", true) then
        table.insert(settings, { key = "tab.grayOwnTeam", type = "toggle", default = false, displayLabel = "Gray Own Team", description = "Render your own team's stats in gray to de-emphasize them." })
    end

    starfish.schema.section({
        key = "tab",
        label = "Tab Stats",
        description = "Show BedWars stats in the tab list after /who.",
        settings = settings
    })
end

local function registerStatsSourceSection()
    starfish.schema.section({
        key = "statsSource",
        label = "Stats Source",
        description = "Which source to try first for player stats.",
        settings = {
            { key = "statsSource.preferred", type = "cycle", default = "urchin", description = "Preferred stats source.", displayLabel = "Preferred", values = {
                { text = "Urchin", value = "urchin" },
                { text = "Hypixel", value = "hypixel" }
            }},
        }
    })
end

local function registerHypixelApiSection()
    starfish.schema.section({
        key = "hypixelApi",
        label = "Hypixel API Key",
        description = "Optional personal Hypixel API key, used as a fallback stats source. Doesn't include Bedwars-specific stats.",
        settings = {
            { key = "hypixelApi.key", type = "text", default = "", description = "Get a key at developer.hypixel.net." },
        }
    })
end

local function registerRespawnTimerSection()
    starfish.schema.section({
        key = "respawnTimer",
        label = "Respawn Timer",
        description = "Show a respawn countdown in a player's tab row while they are dead.",
        settings = {
            { key = "respawnTimer.enabled", type = "toggle", default = true, description = "Show a respawn countdown in a player's tab row while they are dead." },
            { key = "keepDisconnected.enabled", type = "toggle", default = true, displayLabel = "Keep Disconnected", description = "Keep a disconnected player's tab entry visible, marked [DISCONNECTED], until they reconnect." },
        }
    })
end

local function registerSlotSections()
    for index, slot in ipairs(SLOTS) do
        starfish.schema.section({
            key = "tab.slot" .. index,
            label = "Column " .. index,
            description = "Configure tab column " .. index .. ".",
            settings = {
                { key = slotKey(index, "enabled"), type = "toggle", default = slot.shown,
                  description = "Show tab column " .. index .. "." },
                { key = slotKey(index, "content"), type = "cycle", default = slot.content, values = SLOT_CONTENTS,
                  description = "What tab column " .. index .. " shows." },
            }
        })
    end
end

local function registerWhoSection()
    starfish.schema.section({
        key = "who",
        label = "Auto /who",
        description = "Automatically run /who when a game starts.",
        settings = {
            { key = "who.enabled", type = "toggle", default = true, description = "Send /who at game start to load everyone's stats." },
            { key = "who.delay", type = "cycle", default = 500, description = "Delay before sending /who.", displayLabel = "Delay", values = {
                { text = "0ms", value = 0 },
                { text = "500ms", value = 500 },
                { text = "1000ms", value = 1000 }
            }},
        }
    })
end

local function registerChatStatsSection()
    starfish.schema.section({
        key = "chatStats",
        label = "Chat Stats",
        description = "Show a player's stats in chat when they speak.",
        settings = {
            { key = "chatStats.enabled", type = "toggle", default = true, description = "Show a player's stats in chat when they speak." },
            { key = "chatStats.mention", type = "toggle", default = true, displayLabel = "Mention", description = "Show a player's stats when their message mentions your name." },
            { key = "chatStats.pregame", type = "toggle", default = true, displayLabel = "Pregame Messages", description = "Show a player's stats when they chat in the pre-game lobby." },
        }
    })
end

local function registerPartyCounterSection()
    starfish.schema.section({
        key = "partyCounter",
        label = "Party Counter",
        description = "Detect groups of players joining or leaving the lobby together.",
        settings = {
            { key = "partyCounter.enabled", type = "toggle", default = true, description = "Announce when a party of players joins or leaves your lobby." },
        }
    })
end

local function registerHeightLimitSection()
    starfish.schema.section({
        key = "heightLimit",
        label = "Height Limit",
        description = "Warn in the action bar as you build near the map's height limit.",
        settings = {
            { key = "heightLimit.enabled", type = "toggle", default = true, description = "Show a live action bar warning when you are close to the build height limit." },
        }
    })
end

local function registerSchema()
    registerWhoSection()
    registerTabSection()
    registerRespawnTimerSection()
    registerStatsSourceSection()
    registerHypixelApiSection()
    registerChatStatsSection()
    registerHeightLimitSection()
    registerPartyCounterSection()
    if starfish.config.get("tab.enabled", true) then
        registerSlotSections()
    end
end

registerSchema()

local function syncTabSchemaVisibility()
    starfish.schema.clear()
    registerSchema()
end

-- State

local location = { server = nil, inBedwars = false, inGame = false, map = nil }
local lastMode = nil
local stats = {}
local fetchCallbacks = {}
local managed = {}
local pendingJoins = {}
local lastApplied = {}
local tabActive = false
local refreshTimer = nil
local dirty = false
local game = { started = false, eliminated = {}, respawns = {}, disconnected = {} }
local chatStats = { seen = {} }
local party = { count = 0, timer = nil, maxPlayers = 0, isJoin = false }
local heightWatch = { limit = nil, timer = nil }
local lastWhoAt = nil

local NICKED_STATS = { isNicked = true }

-- Helpers

local function formatNumber(n)
    local result = tostring(math.floor(n))
    local pos = #result - 3
    while pos > 0 do
        result = result:sub(1, pos) .. "," .. result:sub(pos + 1)
        pos = pos - 3
    end
    return result
end

local function tabEnabled()
    return starfish.config.get("tab.enabled", true)
end

local function getRealName(name)
    return starfish.plugins.optional("denicker").getRealName(name)
end

local function isNicked(name)
    return starfish.plugins.optional("denicker").isNicked(name) == true
end

local function resolveTeam(name)
    local player = starfish.players.byName(name)
    return player and player.team
end

local function hasTeamData(name)
    local team = resolveTeam(name)
    return team and team.prefix and starfish.text.plain(team.prefix) ~= ""
end

local function teamPrefixOf(name)
    local entry = managed[name]
    if entry and entry.teamPrefix then return entry.teamPrefix end
    local team = resolveTeam(name)
    return (team and team.prefix) or ""
end

local function teamSuffixOf(name)
    local team = resolveTeam(name)
    return (team and team.suffix) or ""
end

local function displayNameOf(name)
    local entry = managed[name]
    if entry and entry.displayName then return entry.displayName end
    local player = starfish.players.byName(name)
    return (player and player.displayName) or name
end

local function teamColorOf(name)
    local last = nil
    for code in teamPrefixOf(name):gmatch("§([0-9a-f])") do
        last = code
    end
    return last and ("§" .. last) or nil
end

local function teamFormatted(name, displayText)
    return teamPrefixOf(name) .. (displayText or name) .. teamSuffixOf(name)
end

-- Stats service

local BEDWARS_MODES = {
    { "Solo", "eight_one" }, { "Doubles", "eight_two" },
    { "Threes", "four_three" }, { "Fours", "four_four" }, { "4v4", "two_four" }
}

local function mostPlayedMode(bw)
    local best, top = nil, 0
    for _, mode in ipairs(BEDWARS_MODES) do
        local games = (bw[mode[2] .. "_wins_bedwars"] or 0) + (bw[mode[2] .. "_losses_bedwars"] or 0)
        if games > top then
            top = games
            best = mode[1]
        end
    end
    return best
end

local function parseBedwarsStats(player)
    local bw = player.stats and player.stats.Bedwars or {}
    local fk = bw.final_kills_bedwars or 0
    local kills = bw.kills_bedwars or 0
    local level = starfish.plugins.require("urchin").bedwarsLevel(bw.Experience, player.achievements and player.achievements.bedwars_level)

    return {
        xp = bw.Experience,
        level = level.level,
        progress = level.progress,
        starText = level.starText,
        nextStarText = level.nextStarText,
        fkdr = fk / math.max(1, bw.final_deaths_bedwars or 1),
        finals = fk,
        kdr = kills / math.max(1, bw.deaths_bedwars or 1),
        winstreak = bw.winstreak,
        displayName = player.displayname,
        timestamp = os.time(),
        totals = {
            wins = bw.wins_bedwars or 0,
            losses = bw.losses_bedwars or 0,
            finalKills = fk,
            finalDeaths = bw.final_deaths_bedwars or 0,
            kills = kills,
            deaths = bw.deaths_bedwars or 0,
            bedsBroken = bw.beds_broken_bedwars or 0,
            bedsLost = bw.beds_lost_bedwars or 0
        }
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

local function hypixelApiKey()
    local key = starfish.config.get("hypixelApi.key", "")
    return key ~= "" and key or nil
end

local function preferredSource()
    return starfish.config.get("statsSource.preferred", "urchin")
end

local function otherSource(source)
    return source == "hypixel" and "urchin" or "hypixel"
end

local function sourceAvailable(source, uuid)
    if source == "hypixel" then return hypixelApiKey() ~= nil and uuid ~= nil end
    return true
end

local pendingUrchinFetches = {}

starfish.events.on("urchin:playerFetched", function(event)
    local key = event.player and event.player:lower()
    local onDone = key and pendingUrchinFetches[key]
    if not onDone then return end
    pendingUrchinFetches[key] = nil
    onDone(event.data, event.error)
end)

local function fetchFromHypixel(uuid, callback)
    local url = HYPIXEL_API_HOST .. "/player?key=" .. hypixelApiKey() .. "&uuid=" .. uuid
    starfish.http.get(url, {}, function(res)
        if res.success and res.data and res.data.player then
            callback(res.data.player)
        else
            callback(nil, res.error or ("HTTP " .. tostring(res.status or "?")))
        end
    end)
end

local function fetchFromSource(source, key, query, uuid, callback)
    if source == "hypixel" then
        fetchFromHypixel(uuid, callback)
    else
        pendingUrchinFetches[key] = callback
        starfish.plugins.require("urchin").fetchPlayer(query)
    end
end

local fetchStats

local function resolveFetch(key, query, uuid, attempt, player, err)
    if player then
        stats[key] = parseBedwarsStats(player)
        notifyFetched(key)
    elseif err == "nicked" then
        stats[key] = { isNicked = true, timestamp = os.time() }
        notifyFetched(key)
    else
        local tries = attempt or 1
        if tries < FETCH_RETRIES then
            starfish.timers.delay(RETRY_BASE_MS * 2 ^ (tries - 1), function()
                fetchStats(key, query, uuid, tries + 1)
            end)
        else
            stats[key] = { fetchError = err or "request failed" }
            notifyFetched(key)
        end
    end
end

function fetchStats(key, query, uuid, attempt)
    local cached = stats[key]
    if cached and not cached.isLoading and cached.timestamp and os.time() - cached.timestamp < CACHE_TTL then
        notifyFetched(key)
        return
    end
    if cached and cached.isLoading and (attempt or 1) == 1
        and starfish.time.monotonic() - cached.startedAt < STATS_LOADING_TIMEOUT_MS then
        return
    end

    stats[key] = { isLoading = true, startedAt = starfish.time.monotonic() }

    local primary = preferredSource()
    local fallback = otherSource(primary)
    fetchFromSource(primary, key, query, uuid, function(player, err)
        if player or err == "nicked" or not sourceAvailable(fallback, uuid) then
            resolveFetch(key, query, uuid, attempt, player, err)
            return
        end
        fetchFromSource(fallback, key, query, uuid, function(fallbackPlayer, fallbackErr)
            resolveFetch(key, query, uuid, attempt, fallbackPlayer, fallbackErr)
        end)
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

    local player = starfish.players.byName(query) or starfish.players.byName(name)
    fetchStats(key, query, player and player.uuid)
end

local function statsFor(name)
    local realName = getRealName(name)
    if not realName and isNicked(name) then return NICKED_STATS end
    return stats[(realName or name):lower()]
end

-- Font metrics

local SPACE_WIDTH = 4
local DEFAULT_CHAR_WIDTH = 6
local CHAR_WIDTH = {
    [" "] = SPACE_WIDTH,
    ["!"] = 2, ["\""] = 4, ["'"] = 2, ["("] = 5, [")"] = 5, ["*"] = 4,
    [","] = 2, ["."] = 2, [":"] = 2, [";"] = 2, ["<"] = 5, [">"] = 5,
    ["@"] = 7, ["["] = 4, ["]"] = 4, ["`"] = 3, ["{"] = 5, ["|"] = 2, ["}"] = 5,
    ["I"] = 4, ["f"] = 5, ["i"] = 2, ["k"] = 5, ["l"] = 3, ["t"] = 4,
    ["✫"] = 8.5, ["✪"] = 8.5, ["⚝"] = 8.5, ["✥"] = 9, ["✭"] = 8.5,
}

local function textWidth(text)
    local width = 0
    for _, code in utf8.codes(starfish.text.plain(text)) do
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

local function statsUnavailable(st)
    return st.isNicked or st.fetchError
end

local COLUMNS = {
    star = {
        header = "✫",
        selfLabeled = true,
        value = function(st)
            if not st or st.isLoading then return "§8[---✫]" end
            if statsUnavailable(st) then return "§c[???✫]" end
            return st.starText
        end
    },
    username = {
        header = "Name",
        isName = true
    },
    winstreak = {
        header = "WS",
        value = function(st)
            if not st or st.isLoading then return "§8-" end
            if statsUnavailable(st) or st.winstreak == nil then return "§c?" end
            return STAT_COLORS.winstreak(st.winstreak) .. formatNumber(st.winstreak)
        end
    },
    fkdr = {
        header = "FKDR",
        value = function(st)
            if not st or st.isLoading then return "§8-.-" end
            if statsUnavailable(st) then return "§c?.?" end
            return STAT_COLORS.fkdr(st.fkdr) .. string.format("%.1f", st.fkdr)
        end
    },
    finals = {
        header = "Finals",
        value = function(st)
            if not st or st.isLoading then return "§8-" end
            if statsUnavailable(st) then return "§c?" end
            return STAT_COLORS.finals(st.finals) .. formatNumber(st.finals)
        end
    },
    kdr = {
        header = "KDR",
        value = function(st)
            if not st or st.isLoading then return "§8-.-" end
            if statsUnavailable(st) then return "§c?.?" end
            return STAT_COLORS.kdr(st.kdr) .. string.format("%.1f", st.kdr)
        end
    },
}

local SUFFIX_PRIORITY = 100

local function slotColumn(index, slot)
    if not starfish.config.get(slotKey(index, "enabled"), slot.shown) then return nil end
    return COLUMNS[starfish.config.get(slotKey(index, "content"), slot.content)]
end

local function visibleColumns()
    local columns, hasName = {}, false
    for index, slot in ipairs(SLOTS) do
        local column = slotColumn(index, slot)
        if column and not (column.isName and hasName) then
            hasName = hasName or column.isName == true
            table.insert(columns, column)
        end
    end
    return columns
end

local function nameColumnIndex(columns)
    for index, column in ipairs(columns) do
        if column.isName then return index end
    end
    return #columns + 1
end

-- Tab entry protection

local function shouldProtect(name)
    if not managed[name] then return false end
    if game.disconnected[name] then
        return starfish.config.get("keepDisconnected.enabled", true)
    end
    if game.eliminated[name] then return false end
    return true
end

local function syncRemovalHolds()
    for name, entry in pairs(managed) do
        if shouldProtect(name) then
            starfish.display.holdRemoval(entry.uuid)
        else
            starfish.display.releaseRemoval(entry.uuid)
        end
    end
end

-- Tab manager

local function snapshotIdentity(name, entry)
    local player = starfish.players.byName(name)
    if player then
        entry.displayName = player.displayName or player.name
    end
    if hasTeamData(name) then
        entry.teamPrefix = resolveTeam(name).prefix
    end
end

local function snapshotIdentities()
    for name, entry in pairs(managed) do
        snapshotIdentity(name, entry)
    end
end

local function manage(name, uuid)
    local entry = { uuid = uuid }
    managed[name] = entry
    snapshotIdentity(name, entry)
    starfish.display.holdRemoval(uuid)
    requestStats(name)
    dirty = true
end

local function myTeamColor()
    local me = starfish.players.me()
    return me and teamColorOf(me.name) or nil
end

local function isGrayed(teamColor, ownTeamColor)
    return ownTeamColor ~= nil and starfish.config.get("tab.grayOwnTeam", false) and teamColor == ownTeamColor
end

local function teamPrefixWidth(name)
    return textWidth(teamPrefixOf(name))
end

local function computeMaxTeamPrefixWidth()
    local maxWidth = 0
    for name in pairs(managed) do
        local width = teamPrefixWidth(name)
        if width > maxWidth then maxWidth = width end
    end
    return maxWidth
end

local function nameColumnWidth(name, uuid)
    return textWidth(displayNameOf(name))
        + textWidth(starfish.display.othersPrefix(uuid))
        + textWidth(starfish.display.othersSuffix(uuid))
end

local function computeMaxNameColumnWidth()
    local maxWidth = textWidth("Name")
    for name, entry in pairs(managed) do
        local width = nameColumnWidth(name, entry.uuid)
        if width > maxWidth then maxWidth = width end
    end
    return maxWidth
end

local function maxColumnWidth(column)
    if column.isName then return computeMaxNameColumnWidth() end
    local maxWidth = textWidth(column.header)
    for name in pairs(managed) do
        local width = textWidth(column.value(statsFor(name), name))
        if width > maxWidth then maxWidth = width end
    end
    return maxWidth
end

local function computeLayout()
    local columns = visibleColumns()
    local widths = {}
    for index, column in ipairs(columns) do
        widths[index] = maxColumnWidth(column)
    end

    local nameIndex = nameColumnIndex(columns)
    widths[nameIndex] = widths[nameIndex] or computeMaxNameColumnWidth()

    return {
        columns = columns,
        widths = widths,
        nameIndex = nameIndex,
        teamPrefixPad = computeMaxTeamPrefixWidth(),
        ownTeamColor = myTeamColor()
    }
end

local SEPARATOR = " §8| §r"

local function emitFixed(row, parts, text)
    table.insert(parts, text)
    local width = textWidth(text)
    row.x, row.target = row.x + width, row.target + width
end

local function emitAligned(row, parts, text, width, alignRight)
    row.target = row.target + width
    local textW = textWidth(text)
    local pad, padW = padSpaces(row.target - row.x - textW)

    if alignRight then
        table.insert(parts, pad)
        table.insert(parts, text)
    else
        table.insert(parts, text)
        table.insert(parts, pad)
    end

    row.x = row.x + textW + padW
end

local function cellText(row, column)
    local text = column.value(statsFor(row.name), row.name)
    if row.grayed then return GRAYED_COLOR .. starfish.text.plain(text) end
    return text
end

local function emitCells(row, parts, first, last, alignRight)
    for index = first, last do
        if index > 1 then emitFixed(row, parts, SEPARATOR) end
        local column = row.layout.columns[index]
        emitAligned(row, parts, cellText(row, column), row.layout.widths[index], alignRight)
    end
end

local function emitNameCell(row, uuid)
    row.x = row.x + nameColumnWidth(row.name, uuid)
    row.target = row.target + row.layout.widths[row.layout.nameIndex]
    local pad, padW = padSpaces(row.target - row.x)
    table.insert(row.suffix, pad)
    row.x = row.x + padW
end

local function respawnCountdown(name)
    if not starfish.config.get("respawnTimer.enabled", true) then return nil end
    local respawn = game.respawns[name]
    return respawn and respawn.remaining
end

local function nameColor(teamColor)
    return teamColor or ""
end

local DISCONNECTED_LABEL = "DISCONNECTED"

local function bracketRow(label)
    return " §8[§c" .. label .. "§8] " .. RESPAWNING_COLOR, ""
end

local function respawnRow(remaining)
    return bracketRow(remaining .. "s")
end

local function disconnectedRow()
    return bracketRow(DISCONNECTED_LABEL)
end

local function startRow(name, layout)
    local ownPrefixWidth = teamPrefixWidth(name)
    local teamPad, teamPadW = padSpaces(layout.teamPrefixPad - ownPrefixWidth)
    local teamColor = teamColorOf(name)

    return {
        name = name,
        teamColor = teamColor,
        grayed = isGrayed(teamColor, layout.ownTeamColor),
        layout = layout,
        prefix = { teamPad },
        suffix = {},
        x = ownPrefixWidth + teamPadW,
        target = layout.teamPrefixPad
    }
end

local function buildRow(name, uuid, layout)
    if game.disconnected[name] then return disconnectedRow() end

    local remaining = respawnCountdown(name)
    if remaining then return respawnRow(remaining) end

    local row = startRow(name, layout)
    local nameAt, lastAt = layout.nameIndex, #layout.columns

    emitCells(row, row.prefix, 1, nameAt - 1, true)
    if nameAt > 1 then emitFixed(row, row.prefix, SEPARATOR) end
    table.insert(row.prefix, nameColor(row.teamColor))

    if nameAt < lastAt then
        emitNameCell(row, uuid)
        emitCells(row, row.suffix, nameAt + 1, lastAt, false)
    end

    return table.concat(row.prefix), table.concat(row.suffix)
end

local function headerLabelsLine(layout)
    local parts = {}

    for index, column in ipairs(layout.columns) do
        if index > 1 then table.insert(parts, SEPARATOR) end

        local label = column.header
        local text = "§7" .. label
        local pad = (padSpaces(layout.widths[index] - textWidth(label)))

        if index < layout.nameIndex then
            table.insert(parts, pad .. text)
        else
            table.insert(parts, text .. pad)
        end
    end

    return table.concat(parts)
end

local function updateTabHeader(layout)
    starfish.display.setTabHeaderAppend(headerLabelsLine(layout))
end

local function forgetPlayer(name)
    local entry = managed[name]
    if not entry then return end
    starfish.display.clearPrefix(entry.uuid)
    starfish.display.clearSuffix(entry.uuid)
    starfish.display.releaseRemoval(entry.uuid)
    lastApplied[entry.uuid] = nil
    managed[name] = nil
end

local function clearTabDecorations()
    for _, entry in pairs(managed) do
        starfish.display.clearPrefix(entry.uuid)
        starfish.display.clearSuffix(entry.uuid)
        starfish.display.releaseRemoval(entry.uuid)
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
        refreshTimer:off()
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

    snapshotIdentities()
    syncRemovalHolds()

    local layout = computeLayout()
    updateTabHeader(layout)

    for name, entry in pairs(managed) do
        if entry.teamPrefix then
            local prefix, suffix = buildRow(name, entry.uuid, layout)
            local combined = prefix .. "\0" .. suffix
            if lastApplied[entry.uuid] ~= combined then
                lastApplied[entry.uuid] = combined
                starfish.display.setPrefix(entry.uuid, prefix)
                starfish.display.setSuffix(entry.uuid, suffix, { priority = SUFFIX_PRIORITY })
            end
        end
    end
end

local function activateTab(names)
    if not tabEnabled() then return end

    for _, name in ipairs(names) do
        if not managed[name] then
            local player = starfish.players.byName(name)
            if player and player.uuid then
                manage(name, player.uuid)
            else
                pendingJoins[name] = true
            end
        end
    end

    if next(managed) or next(pendingJoins) then
        tabActive = true
        dirty = true
        if not refreshTimer then
            refreshTimer = starfish.timers.interval(REFRESH_MS, refreshTab)
        end
    end
end

-- Chat stat lines

local function chatStatText(column, st, name)
    local text = column.value(st, name)
    if column.selfLabeled then return text end
    return "§7" .. column.header .. ": " .. text
end

local function statSummary(name, st)
    if not st then return "§cstats unavailable" end
    if st.isNicked then return "§cnicked" end
    if st.fetchError then return "§crequest failed (" .. st.fetchError .. ")" end

    local parts = {}
    for _, column in ipairs(visibleColumns()) do
        if not column.isName then
            table.insert(parts, chatStatText(column, st, name))
        end
    end
    return "§r" .. table.concat(parts, " §8| §r")
end

local function statLine(name, st)
    local displayName = (st and st.displayName) or name
    return teamFormatted(name, displayName) .. " §8- " .. statSummary(name, st)
end

local function printStats(name)
    requestStats(name, function(st)
        starfish.chat.info(statLine(name, st))
    end)
end

-- Player check

local TOP_WINSTREAKS = 3
local PROGRESS_BAR_LENGTH = 15
local COLUMN_GAP_WIDTH = 20
local RULE = "§7§m-------------------------------------§r"

local pendingChecks = {}
local pendingSummaries = {}

local function resolvePending(pending, event)
    local key = event.player and event.player:lower()
    local onDone = key and pending[key]
    if not onDone then return end
    pending[key] = nil
    onDone(event)
end

starfish.events.on("urchin:checkFetched", function(event)
    resolvePending(pendingChecks, event)
end)

starfish.events.on("urchin:summaryFetched", function(event)
    resolvePending(pendingSummaries, event)
end)

local function formatRatio(value)
    return (string.format("%.2f", value):gsub("%.00$", ""))
end

local function totalsRow(ratioLabel, countLabel, pos, neg, ratioColor, countColor)
    local ratio = neg > 0 and pos / neg or pos
    return {
        ratio = "§7" .. ratioLabel .. ": " .. ratioColor(ratio) .. formatRatio(ratio),
        counts = "§7" .. countLabel .. ": §8(" .. countColor(pos) .. formatNumber(pos) .. " §8/ §7" .. formatNumber(neg) .. "§8)"
    }
end

local function alignColumns(rows)
    local widest = 0
    for _, row in ipairs(rows) do
        widest = math.max(widest, textWidth(row.ratio))
    end

    local lines = {}
    for i, row in ipairs(rows) do
        lines[i] = row.ratio .. padSpaces(widest - textWidth(row.ratio) + COLUMN_GAP_WIDTH) .. row.counts
    end
    return lines
end

local function totalsLines(stats)
    local t = stats and stats.totals
    if not t or (t.wins == 0 and t.losses == 0 and t.finalKills == 0) then return nil end

    return alignColumns({
        totalsRow("WLR", "Wins", t.wins, t.losses, TOTAL_COLORS.wlr, TOTAL_COLORS.wins),
        totalsRow("FKDR", "Finals", t.finalKills, t.finalDeaths, STAT_COLORS.fkdr, STAT_COLORS.finals),
        totalsRow("KDR", "Kills", t.kills, t.deaths, STAT_COLORS.kdr, TOTAL_COLORS.kills),
        totalsRow("BBLR", "Beds", t.bedsBroken, t.bedsLost, TOTAL_COLORS.bblr, TOTAL_COLORS.bedsBroken)
    })
end

local function progressLine(stats)
    local filled = math.floor(stats.progress * PROGRESS_BAR_LENGTH + 0.5)
    return stats.starText
        .. " §8[§b" .. ("■"):rep(filled)
        .. "§7" .. ("■"):rep(PROGRESS_BAR_LENGTH - filled)
        .. "§8] " .. stats.nextStarText
end

local function sessionStarsGained(bw, overall)
    local xpGained = bw.Experience
    if type(xpGained) ~= "number" or not (overall and overall.xp) then return 0 end
    local before = starfish.plugins.require("urchin").bedwarsLevel(overall.xp - xpGained)
    return overall.level - before.level
end

local function sessionSummary(session, overall)
    local bw = session and session.delta and session.delta.stats and session.delta.stats.Bedwars
    if not bw then return nil end

    local fk, fd = bw.final_kills_bedwars or 0, bw.final_deaths_bedwars or 0
    local beds = bw.beds_broken_bedwars or 0
    if (bw.wins_bedwars or 0) == 0 and (bw.losses_bedwars or 0) == 0 and fk == 0 then return nil end

    local header = "§7Session §8(§7Monthly§8)"
    local mode = mostPlayedMode(bw)
    if mode then header = header .. " §8| §7Most Played: §f" .. mode end

    local fkdr = fk / math.max(1, fd)
    local columns = {}
    local stars = sessionStarsGained(bw, overall)
    if stars > 0 then
        table.insert(columns, "§b+" .. stars .. "✫")
    end
    table.insert(columns, "§7FKDR: " .. SESSION_COLORS.fkdr(fkdr) .. formatRatio(fkdr))
    table.insert(columns, "§7Finals: " .. STAT_COLORS.finals(fk) .. formatNumber(fk))
    table.insert(columns, "§7Beds: " .. TOTAL_COLORS.bedsBroken(beds) .. formatNumber(beds))

    return { header, table.concat(columns, " §8| §r") }
end

local function winstreakLine(winstreaks)
    local core = winstreaks and winstreaks.modes and winstreaks.modes.core
    if not core or #core == 0 then return nil end

    local badges = {}
    local hoverLines = { "§fTop Winstreaks", RULE }
    for i = 1, math.min(TOP_WINSTREAKS, #core) do
        local streak = core[i]
        local badge = "§8" .. i .. ". " .. STAT_COLORS.winstreak(streak.value) .. streak.value .. (streak.approximate and "+" or "")
        table.insert(badges, badge)
        table.insert(hoverLines, badge .. " §8— §7" .. (streak.readable or ""))
    end
    table.insert(hoverLines, "§8+ approximate")

    return {
        text = "§7Top Winstreaks: " .. table.concat(badges, " §8| "),
        hover = table.concat(hoverLines, "\n")
    }
end

local function specComponent(spec)
    return starfish.text.of(spec.text):hover(spec.hover):suggest(spec.paste)
end

local function appendLine(parts, text, hover)
    local line = starfish.text.of("\n" .. text)
    table.insert(parts, hover and line:hover(hover) or line)
end

local function appendSession(parts, check, overall)
    local summary = sessionSummary(check.session, overall)
    local streaks = winstreakLine(check.winstreaks)

    for _, line in ipairs(summary or {}) do
        appendLine(parts, line)
    end
    if summary and streaks then
        appendLine(parts, "")
    end
    if streaks then
        appendLine(parts, streaks.text, streaks.hover)
    end
    if not summary and not streaks then
        appendLine(parts, "§8No tracked session stats")
    end
end

local function appendOverall(parts, name, overall)
    local totals = totalsLines(overall)
    if not totals then
        appendLine(parts, statSummary(name, overall))
        return
    end

    appendLine(parts, progressLine(overall))
    appendLine(parts, "")
    for _, line in ipairs(totals) do
        appendLine(parts, line)
    end
end

local function sendCheck(name, overall, check)
    local parts = { starfish.text.of("\n" .. RULE .. "\n"), specComponent(check.header) }
    for _, badge in ipairs(check.badges or {}) do
        table.insert(parts, specComponent(badge))
    end

    appendOverall(parts, name, overall)
    appendLine(parts, RULE)
    appendSession(parts, check, overall)
    if check.error then
        appendLine(parts, "§7Urchin: §c" .. check.error)
    end
    appendLine(parts, RULE)

    starfish.chat.info(starfish.text.join(parts))
end

local function printCheck(name)
    local query = getRealName(name)
    if not query and isNicked(name) then
        printStats(name)
        return
    end
    query = query or name

    local overall, check
    local remaining = 2
    local function finish()
        remaining = remaining - 1
        if remaining == 0 then sendCheck(name, overall, check) end
    end

    requestStats(name, function(st) overall = st; finish() end)
    pendingChecks[query:lower()] = function(result) check = result; finish() end
    starfish.plugins.require("urchin").fetchCheck(query)
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
    local me = starfish.players.me()
    if not me then return end
    local remaining = heightWatch.limit - math.floor(me.position.y)
    if remaining <= HEIGHT_WARN_RANGE then
        starfish.chat.actionBar(heightBarText(remaining, heightWatch.limit))
    end
end

local function stopHeightWatch()
    if heightWatch.timer then
        heightWatch.timer:off()
        heightWatch.timer = nil
    end
    heightWatch.limit = nil
end

local function startHeightWatch()
    stopHeightWatch()
    if not starfish.config.get("heightLimit.enabled", true) then return end
    heightWatch.limit = mapHeightLimit(location.map)
    if heightWatch.limit then
        heightWatch.timer = starfish.timers.interval(HEIGHT_BAR_MS, updateHeightBar)
    end
end

-- Game flow

local function isPreGame()
    local sidebar = starfish.scoreboard.displayed("sidebar")
    return sidebar ~= nil and sidebar.name:match("^Pre") ~= nil
end

local function sendWho()
    if not starfish.config.get("who.enabled", true) then return end
    if lastWhoAt and starfish.time.since(lastWhoAt) < AUTO_WHO_DEDUPE_MS then return end
    lastWhoAt = starfish.time.monotonic()

    starfish.timers.delay(starfish.config.get("who.delay", 500), function()
        starfish.chat.sendToServer("/who")
    end)
end

local function stopRespawnTimers()
    for _, respawn in pairs(game.respawns) do
        respawn.timer:off()
    end
    game.respawns = {}
end

local function resetGame()
    stopRespawnTimers()
    game.started = false
    game.eliminated = {}
    game.disconnected = {}
    stopHeightWatch()
end

local function onGameStart()
    resetGame()
    game.started = true
    sendWho()
    startHeightWatch()
end

local function performRequeue()
    if not lastMode then
        starfish.chat.error("No recent BedWars mode to requeue.")
        return
    end
    starfish.chat.info("§7Requeueing §f" .. lastMode .. "§7...")
    starfish.chat.sendToServer("/play " .. lastMode)
end

local function onGameEnd()
    game.started = false
    stopRespawnTimers()
    stopHeightWatch()
    dirty = true
end

-- Death and respawn tracking

local function markEliminated(name)
    local respawn = game.respawns[name]
    if respawn then respawn.timer:off() end
    game.respawns[name] = nil
    game.eliminated[name] = true
    game.disconnected[name] = nil
    forgetPlayer(name)
    dirty = true
end

local function markDisconnected(name)
    if game.disconnected[name] then return end
    game.disconnected[name] = true
    dirty = true
end

local function clearDisconnected(name)
    if not game.disconnected[name] then return end
    game.disconnected[name] = nil
    dirty = true
end

local function markTeamEliminated(teamColor)
    for name in pairs(managed) do
        if teamColorOf(name) == teamColor then
            markEliminated(name)
        end
    end
end

local function confirmRespawned(name)
    if game.respawns[name] or not managed[name] then return end
    if not starfish.players.byName(name) then
        markDisconnected(name)
    end
end

local function trackRespawn(name, seconds)
    if game.eliminated[name] then return end
    clearDisconnected(name)
    local existing = game.respawns[name]
    if existing then existing.timer:off() end

    local respawn = { remaining = seconds }
    game.respawns[name] = respawn
    respawn.timer = starfish.timers.interval(1000, function()
        respawn.remaining = respawn.remaining - 1
        dirty = true
        if respawn.remaining <= 0 then
            respawn.timer:off()
            if game.respawns[name] == respawn then
                game.respawns[name] = nil
            end
            starfish.timers.delay(RESPAWN_CONFIRM_GRACE_MS, function()
                confirmRespawned(name)
            end)
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

    local disconnected = message:match("^([%w_]+) disconnected%.")
    if disconnected and managed[disconnected] then
        markDisconnected(disconnected)
        if message:sub(-11) == "FINAL KILL!" then
            markEliminated(disconnected)
        end
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

-- Chat stats

local function sendChatStats(summary)
    local parts = { starfish.text.of("\n" .. RULE .. "\n"), specComponent(summary.header) }
    for _, badge in ipairs(summary.badges) do
        table.insert(parts, specComponent(badge))
    end
    appendLine(parts, summary.line)
    appendLine(parts, RULE)

    starfish.chat.info(starfish.text.join(parts))
end

local function printChatStats(name)
    local query = getRealName(name)
    if not query and isNicked(name) then return end

    pendingSummaries[(query or name):lower()] = sendChatStats
    starfish.plugins.require("urchin").fetchSummary(query or name)
end

local function extractSpeaker(message)
    local before = message:match("^([^:]+):")
    if not before then return nil end
    return before:match("([%w_]+)%s*$")
end

local function mentionsMe(message, me)
    local content = message:match("^[^:]+:%s*(.+)$")
    return content ~= nil and content:lower():find(me.name:lower(), 1, true) ~= nil
end

local function shouldShowChatStats(message, me)
    if starfish.config.get("chatStats.mention", true) and mentionsMe(message, me) then return true end
    return starfish.config.get("chatStats.pregame", true) and location.inGame and isPreGame()
end

local function handleChatStats(message, kind)
    if kind ~= "chat" then return end
    if not starfish.config.get("chatStats.enabled", true) then return end

    local speaker = extractSpeaker(message)
    if not speaker or not starfish.players.byName(speaker) then return end

    local me = starfish.players.me()
    if not me or speaker == me.name or chatStats.seen[speaker] then return end

    if shouldShowChatStats(message, me) then
        chatStats.seen[speaker] = true
        printChatStats(speaker)
    end
end

-- Party counter

local function partyGroupSize(count, maxPlayers)
    if maxPlayers == SOLO_LOBBY_SIZE then return false end
    return count >= 2 and count <= math.floor(maxPlayers / PARTY_GROUP_DENOMINATOR)
end

local function handlePartyCounter(message)
    if not starfish.config.get("partyCounter.enabled", true) then return end

    local _, maxPlayers = message:match("%((%d+)/(%d+)%)!$")
    if maxPlayers then party.maxPlayers = tonumber(maxPlayers) end

    local isJoin = message:match("has joined %(%d+/%d+%)!$") ~= nil
    local isLeave = message:match("has quit!$") ~= nil
    if not isJoin and not isLeave then return end

    party.count = party.count + 1
    party.isJoin = isJoin
    if party.timer then
        party.timer:off()
    end
    party.timer = starfish.timers.delay(PARTY_GROUP_MS, function()
        party.timer = nil
        if partyGroupSize(party.count, party.maxPlayers) then
            local arrow = party.isJoin and "»" or "«"
            local color = party.isJoin and "§b" or "§3"
            local verb = party.isJoin and "joined" or "left"
            starfish.chat.info("§8" .. arrow .. " §7Party of " .. color .. party.count .. " §7" .. verb .. ".")
        end
        party.count = 0
    end)
end

-- Event wiring

local function resetForNewServer()
    resetGame()
    deactivateTab()
    chatStats.seen = {}
    lastWhoAt = nil
    if party.timer then party.timer:off() end
    party = { count = 0, timer = nil, maxPlayers = 0, isJoin = false }
end

local function applyLocation(loc)
    local changedServer = loc.serverName ~= location.server

    location.server = loc.serverName
    location.inBedwars = loc.serverType == "BEDWARS"
    location.inGame = location.inBedwars and loc.lobbyName == nil and loc.mode ~= nil
    location.map = loc.map
    if location.inGame then
        lastMode = loc.mode:lower()
    end

    if changedServer then
        resetForNewServer()
    end

    if location.inGame and not game.started and not isPreGame() then
        onGameStart()
    end

    if location.inGame and game.started and not heightWatch.timer then
        startHeightWatch()
    end
end

starfish.events.on("hypixel:location", function(event)
    if not event.success then return end
    applyLocation(event.location)
end)

starfish.events.on("session:join", function()
    resetForNewServer()
    location.server = nil
end)

starfish.events.on("chat:receive", function(event)
    if event.kind == "actionBar" then return end
    if not location.inBedwars then return end

    local message = starfish.text.plain(event.message or "")

    local whoList = message:match("^ONLINE: (.+)$")
    if whoList then
        deactivateTab()
        local names = {}
        for name in whoList:gmatch("[^,%s]+") do
            table.insert(names, name)
            clearDisconnected(name)
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

    if message:find(GAME_END_PHRASE, 1, true) and not message:find(":", 1, true) then
        onGameEnd()
        return
    end

    if game.started and handleGameChat(message) then return end
    handlePartyCounter(message)
    handleChatStats(message, event.kind)
end)

starfish.events.on("player:join", function(event)
    clearDisconnected(event.name)
    if not tabActive or not pendingJoins[event.name] then return end
    pendingJoins[event.name] = nil
    manage(event.name, event.uuid)
end)

starfish.events.on("team:update", function()
    if tabActive then dirty = true end
end)

starfish.events.on("denicker:nick_resolved", function(event)
    if managed[event.nickName] then
        requestStats(event.nickName)
        dirty = true
    end
end)

starfish.events.on("config:changed", function(event)
    if tabActive then dirty = true end

    if event.key == "tab.enabled" then
        syncTabSchemaVisibility()
        if event.value == true and location.inGame and not tabActive then
            sendWho()
        end
    elseif event.key == "heightLimit.enabled" then
        if event.value == false then
            stopHeightWatch()
        elseif game.started then
            startHeightWatch()
        end
    end
end)

-- Commands

starfish.commands.register("check", {
    description = "Show a player's BedWars stats, session, and Urchin tags",
    arguments = {
        { name = "player", type = "string", description = "Player name to look up" }
    }
}, function(ctx)
    printCheck(ctx.args.player)
end)

starfish.commands.registerGlobal("rq", {
    description = "Requeue the last played BedWars mode"
}, function()
    performRequeue()
end)

-- Startup

local hypixelModApi = starfish.plugins.optional("hypixel-mod-api")
local restored = hypixelModApi and hypixelModApi.getLocation()
if restored and restored.serverName then
    applyLocation(restored)
end
