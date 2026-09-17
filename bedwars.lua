plugin = {
    name = "bedwars",
    displayName = "BedWars",
    command = "bw",
    prefix = "§cB§fW",
    version = "0.3.2",
    author = "Starfish",
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
        { name = "denicker",  optional = true },
        { name = "urchin",    optional = true }
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
    kdr = function(v)
        return statTier(v, {{8, "5"}, {7, "d"}, {6, "4"}, {5, "c"}, {4, "6"}, {3, "e"}, {2, "2"}, {1, "a"}, {0.5, "f"}})
    end,
    winstreak = function(v)
        return statTier(v, {{500, "5"}, {250, "d"}, {100, "4"}, {75, "c"}, {50, "6"}, {40, "e"}, {25, "2"}, {15, "a"}, {5, "f"}})
    end,
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
    starfish.schema.section({
        key = "tab",
        label = "Tab Stats",
        description = "Show BedWars stats in the tab list after /who.",
        settings = {
            { key = "tab.enabled", type = "toggle", default = true, description = "Show BedWars stats in the tab list." },
        }
    })
end

local function registerGrayOwnTeamSection()
    starfish.schema.section({
        key = "grayOwnTeam",
        label = "Gray Own Team",
        description = "Render your own team's stats in gray to de-emphasize them.",
        settings = {
            { key = "tab.grayOwnTeam", type = "toggle", default = false, description = "Render your own team's stats in gray to de-emphasize them." },
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
        }
    })
end

local function registerKeepDisconnectedSection()
    starfish.schema.section({
        key = "keepDisconnected",
        label = "Keep Disconnected",
        description = "Keep a disconnected player's tab entry visible, marked [DISCONNECTED], until they reconnect.",
        settings = {
            { key = "keepDisconnected.enabled", type = "toggle", default = true, description = "Keep a disconnected player's tab entry visible, marked [DISCONNECTED], until they reconnect." },
        }
    })
end

local function registerSlotSections()
    for index, slot in ipairs(SLOTS) do
        starfish.schema.section({
            key = "tab.slot" .. index,
            label = "Column Slot " .. index,
            description = "Configure tab column slot " .. index .. ".",
            settings = {
                { key = slotKey(index, "enabled"), type = "toggle", default = slot.shown,
                  description = "Show tab column slot " .. index .. "." },
                { key = slotKey(index, "content"), type = "cycle", default = slot.content, values = SLOT_CONTENTS,
                  description = "What tab column slot " .. index .. " shows." },
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

local function registerMentionStatsSection()
    starfish.schema.section({
        key = "mentionStats",
        label = "Show Stats On Mention",
        description = "Show a player's stats whenever they mention your name in chat.",
        settings = {
            { key = "mentionStats.enabled", type = "toggle", default = true, description = "Show a stat line for anyone whose chat message mentions your name." },
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

local function registerRequeueSection()
    starfish.schema.section({
        key = "requeue",
        label = "Requeue",
        description = "Requeue the last played mode with /rq.",
        settings = {
            { key = "requeue.auto", type = "toggle", default = false, description = "Automatically requeue when a game ends." },
            { key = "requeue.delay", type = "cycle", default = 1000, description = "Delay before auto-requeueing.", displayLabel = "Delay", values = {
                { text = "0ms", value = 0 },
                { text = "1000ms", value = 1000 },
                { text = "2000ms", value = 2000 },
                { text = "3000ms", value = 3000 }
            }},
        }
    })
end

local function registerSchema()
    registerWhoSection()
    registerTabSection()
    if starfish.config.get("tab.enabled", true) then
        registerSlotSections()
        registerGrayOwnTeamSection()
    end
    registerRespawnTimerSection()
    registerKeepDisconnectedSection()
    registerMentionStatsSection()
    registerPartyCounterSection()
    registerHeightLimitSection()
    registerRequeueSection()
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
local mentions = { seen = {} }
local party = { count = 0, timer = nil, maxPlayers = 0, isJoin = false }
local heightWatch = { limit = nil, timer = nil }
local lastWhoAt = nil
local requeueTriggered = false

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
    local kills = bw.kills_bedwars or 0
    local stars = player.achievements and player.achievements.bedwars_level
        or levelFromXp(bw.Experience or 0)

    return {
        stars = stars,
        fkdr = fk / math.max(1, bw.final_deaths_bedwars or 1),
        finals = fk,
        kdr = kills / math.max(1, bw.deaths_bedwars or 1),
        winstreak = bw.winstreak,
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
    if cached and cached.isLoading and (attempt or 1) == 1
        and starfish.time.monotonic() - cached.startedAt < STATS_LOADING_TIMEOUT_MS then
        return
    end

    stats[key] = { isLoading = true, startedAt = starfish.time.monotonic() }
    starfish.http.get(STATS_API .. query .. "&max_cache_age=" .. STATS_MAX_CACHE_AGE, {}, function(res)
        if res.success and res.data and res.data.player then
            stats[key] = parseBedwarsStats(res.data.player)
            notifyFetched(key)
        elseif res.success and res.data and res.data.player == nil then
            stats[key] = { isNicked = true, timestamp = os.time() }
            notifyFetched(key)
        else
            local tries = attempt or 1
            if tries < FETCH_RETRIES then
                starfish.timers.delay(RETRY_BASE_MS * 2 ^ (tries - 1), function()
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
    star = {
        header = "✫",
        selfLabeled = true,
        value = function(st)
            if not st or st.isLoading then return "§8[---✫]" end
            if statsUnavailable(st) then return "§c[???✫]" end
            return colorizeStars(st.stars)
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
    local team = resolveTeam(name)
    if team and team.prefix and starfish.text.plain(team.prefix) ~= "" then
        entry.teamPrefix = team.prefix
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
        local prefix, suffix = buildRow(name, entry.uuid, layout)
        local combined = prefix .. "\0" .. suffix
        if lastApplied[entry.uuid] ~= combined then
            lastApplied[entry.uuid] = combined
            starfish.display.setPrefix(entry.uuid, prefix)
            starfish.display.setSuffix(entry.uuid, suffix, { priority = SUFFIX_PRIORITY })
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
    return "§7" .. column.header .. " " .. text
end

local function statLine(name, st)
    local displayName = (st and st.displayName) or name
    if not st then
        return teamFormatted(name, displayName) .. " §8- §cstats unavailable"
    end
    if st.isNicked then
        return teamFormatted(name, displayName) .. " §8- §cnicked"
    end
    if st.fetchError then
        return teamFormatted(name, displayName) .. " §8- §crequest failed (" .. st.fetchError .. ")"
    end

    local parts = {}
    for _, column in ipairs(visibleColumns()) do
        if not column.isName then
            table.insert(parts, chatStatText(column, st, name))
        end
    end
    return teamFormatted(name, displayName) .. " §8- §r" .. table.concat(parts, " §8| §r")
end

local function printStats(name)
    requestStats(name, function(st)
        starfish.chat.info(statLine(name, st))
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
    requeueTriggered = false
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
    if requeueTriggered then return end
    requeueTriggered = true
    game.started = false
    stopRespawnTimers()
    stopHeightWatch()
    dirty = true
    if not starfish.config.get("requeue.auto", false) then return end

    starfish.timers.delay(starfish.config.get("requeue.delay", 1000), performRequeue)
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
        clearDisconnected(reconnected)
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

-- Mention stats

local function extractSpeaker(message)
    local before = message:match("^([^:]+):")
    if not before then return nil end
    return before:match("([%w_]+)%s*$")
end

local function handleMentionChat(message, kind)
    if kind ~= "chat" then return end
    if not starfish.config.get("mentionStats.enabled", true) then return end

    local speaker = extractSpeaker(message)
    if not speaker then return end
    if not starfish.players.byName(speaker) then return end

    local me = starfish.players.me()
    if not me or speaker == me.name or mentions.seen[speaker] then return end

    local content = message:match("^[^:]+:%s*(.+)$")
    if content and content:lower():find(me.name:lower(), 1, true) then
        mentions.seen[speaker] = true
        printStats(speaker)
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
    mentions.seen = {}
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
    handleMentionChat(message, event.kind)
end)

starfish.events.on("player:join", function(event)
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

starfish.commands.register("stats", {
    description = "Show a player's BedWars stats",
    arguments = {
        { name = "player", type = "string", description = "Player name to look up" }
    }
}, function(ctx)
    printStats(ctx.args.player)
end)

starfish.commands.register("height", {
    description = "Show the build height limit for a map",
    arguments = {
        { name = "map", type = "greedy", optional = true, description = "Map name (defaults to the current map)" }
    }
}, function(ctx)
    local map = ctx.args.map or location.map
    if not map then
        starfish.chat.error("No map detected. Usage: /bw height <map>")
        return
    end

    local height = mapHeightLimit(map)
    if height then
        starfish.chat.info("§bHeight limit for §a" .. map .. " §bis §e" .. height)
    else
        starfish.chat.error("Unknown map: " .. map)
    end
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
