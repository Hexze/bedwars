plugin = {
    name = "bedwars",
    displayName = "BedWars",
    command = "bw",
    prefix = "§cB§fW",
    version = "1.3.1",
    description = "Quality of life features for BedWars",
    dependencies = {
        { name = "hypixel-mod-api" },
        { name = "urchin" },
        { name = "denicker", optional = true },
    },
}

-- Constants

local HYPIXEL_API_HOST = "https://api.hypixel.net/v2"
local CACHE_TTL = 300
local FETCH_RETRIES = 3
local RETRY_BASE_MS = 2000
local REFUSED_STATUSES = { [401] = true, [403] = true }
local PARTY_GROUP_MS = 250
local SOLO_LOBBY_SIZE = 8
local PARTY_GROUP_DENOMINATOR = 4
local STATS_LOADING_TIMEOUT_MS = 10000
local ACTION_BAR_MS = 250
local ACTION_BAR_SEPARATOR = " §8| "
local ACTION_BAR_ORDER = { "heightLimit", "magicMilk" }
local HEIGHT_WARN_RANGE = 10
local MAGIC_MILK_ITEM = "minecraft:milk_bucket"
local MAGIC_MILK_DURATION_MS = 30000
local MAGIC_MILK_WARNING_SECONDS = 5
local MS_PER_SECOND = 1000
local ITEM_USE_FINISHED_STATUS = 9
local GAME_START_PHRASE = "powerful upgrades"
local GAME_END_PHRASE = "1st Killer "
local NPC_PREFIX = "[NPC]"
local REJOIN_MESSAGES = {
    ["You will respawn in 10 seconds!"] = true,
    ["Your bed was destroyed so you are a spectator!"] = true,
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

-- Config schema

starfish.schema.section({
    key = "statsSource",
    label = "Stats Source",
    description = "Which source to ask first for player stats.",
    settings = {
        { key = "statsSource.preferred", type = "cycle", default = "urchin", label = "Preferred Source", description = "The source asked first; the other is the fallback.", values = {
            { text = "Urchin", value = "urchin" },
            { text = "Hypixel", value = "hypixel" }
        }},
    }
})

starfish.schema.section({
    key = "hypixelApi",
    label = "Hypixel API Key",
    description = "Your Hypixel API key, used as a fallback source for player stats.",
    settings = {
        { key = "hypixelApi.key", type = "text", default = "", label = "API Key", description = "Get one at developer.hypixel.net." },
    }
})

starfish.schema.section({
    key = "chatStats",
    label = "Chat Stats",
    description = "Show a player's stats in chat when they talk.",
    settings = {
        { key = "chatStats.enabled", type = "toggle", default = true, label = "Enabled", description = "Turn chat stats on or off." },
        { key = "chatStats.mention", type = "toggle", default = true, label = "Mentions", description = "Show stats when someone mentions your name." },
        { key = "chatStats.pregame", type = "toggle", default = true, label = "Pre-Game Lobby", description = "Show stats for everyone who talks in the pre-game lobby." },
    }
})

starfish.schema.section({
    key = "heightLimit",
    label = "Height Limit",
    description = "Warn in the action bar as you build near the height limit.",
    settings = {
        { key = "heightLimit.enabled", type = "toggle", default = true, label = "Enabled", description = "Turn the height limit warning on or off." },
    }
})

starfish.schema.section({
    key = "magicMilk",
    label = "Magic Milk",
    description = "Show a Magic Milk countdown in the action bar.",
    settings = {
        { key = "magicMilk.enabled", type = "toggle", default = true, label = "Enabled", description = "Turn the Magic Milk countdown on or off." },
    }
})

starfish.schema.section({
    key = "partyCounter",
    label = "Party Counter",
    description = "Announce groups of players joining or leaving your lobby together.",
    settings = {
        { key = "partyCounter.enabled", type = "toggle", default = true, label = "Enabled", description = "Turn the party counter on or off." },
    }
})

-- Session state

local location = { server = nil, inBedwars = false, inGame = false, inReplay = false, map = nil }
local lastMode = nil
local stats = {}
local fetchCallbacks = {}
local game = { started = false, alive = true }
local chatStats = { seen = {} }
local party = { count = 0, timer = nil, maxPlayers = 0, isJoin = false }
local actionBar = { sources = {}, timer = nil }
local heightWatch = { limit = nil }
local magicMilk = { drankAt = nil }

-- Stat formatting

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

local function formatNumber(n)
    local result = tostring(math.floor(n))
    local pos = #result - 3
    while pos > 0 do
        result = result:sub(1, pos) .. "," .. result:sub(pos + 1)
        pos = pos - 3
    end
    return result
end

-- Player identity

local function getRealName(name)
    return starfish.plugins.optional("denicker").getRealName(name)
end

local function getRealUuid(name)
    return starfish.plugins.optional("denicker").getRealUuid(name)
end

local function isNicked(name)
    return starfish.plugins.optional("denicker").isNicked(name) == true
end

local function normalizeUuid(text)
    return text:gsub("-", ""):lower()
end

local function asUuid(text)
    local undashed = normalizeUuid(text)
    if #undashed == 32 and not undashed:find("%X") then return undashed end
end

local function skinProfileId(player)
    local textures = player.properties.textures
    local decoded = textures and starfish.base64.decode(textures.value)
    local ok, profile = pcall(json.decode, decoded)
    return ok and profile and profile.profileId and normalizeUuid(profile.profileId) or nil
end

local function tabUuid(player)
    if not player then return nil end
    if location.inReplay then return skinProfileId(player) end
    return normalizeUuid(player.uuid)
end

local function lookupTarget(query, uuid)
    return { query = query, key = query:lower(), uuid = uuid }
end

local function typedTarget(typed)
    local typedUuid = asUuid(typed)
    return lookupTarget(typedUuid or typed, typedUuid or tabUuid(starfish.players.byName(typed)))
end

local function denickedTarget(name)
    local realUuid = getRealUuid(name)
    local identity = realUuid or getRealName(name)
    return identity and lookupTarget(identity, realUuid)
end

local function resolveTarget(name, listedTarget)
    local denicked = denickedTarget(name)
    if denicked then return denicked end
    if isNicked(name) then return nil end
    return listedTarget
end

local function teamFormatted(name, displayText)
    local player = starfish.players.byName(name)
    local team = player and player.team
    return ((team and team.prefix) or "") .. displayText .. ((team and team.suffix) or "")
end

-- Stats service

local NICKED_STATS = { isNicked = true }

local BEDWARS_MODES = {
    { "Solo", "eight_one" }, { "Doubles", "eight_two" },
    { "Threes", "four_three" }, { "Fours", "four_four" }, { "4v4", "two_four" }
}

local function mostPlayedMode(gains)
    local best, top = nil, 0
    for _, mode in ipairs(BEDWARS_MODES) do
        local games = (gains[mode[2] .. "_wins_bedwars"] or 0) + (gains[mode[2] .. "_losses_bedwars"] or 0)
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
end

local function hypixelApiKey()
    local key = starfish.config.get("hypixelApi.key")
    return key ~= "" and key or nil
end

local function preferredSource()
    return starfish.config.get("statsSource.preferred")
end

local function otherSource(source)
    return source == "hypixel" and "urchin" or "hypixel"
end

local function sourceAvailable(source, uuid)
    if source == "hypixel" then return hypixelApiKey() ~= nil and uuid ~= nil end
    return true
end

local pendingUrchinFetches = {}

local function fetchFromHypixel(uuid, callback)
    local url = HYPIXEL_API_HOST .. "/player?key=" .. hypixelApiKey() .. "&uuid=" .. uuid
    starfish.http.get(url, {}, function(res)
        local body = res.success and res.data
        if body and body.player then
            callback(body.player)
        elseif body and body.success then
            callback(nil, "nicked")
        else
            callback(nil, res.error or ("HTTP " .. tostring(res.status or "?")), not REFUSED_STATUSES[res.status])
        end
    end)
end

local function fetchFromSource(source, target, callback)
    if source == "hypixel" then
        fetchFromHypixel(target.uuid, callback)
    else
        pendingUrchinFetches[target.key] = callback
        starfish.plugins.require("urchin").fetchPlayer(target.query)
    end
end

local function availableSources(uuid)
    local preferred = preferredSource()
    local sources = {}
    for _, source in ipairs({ preferred, otherSource(preferred) }) do
        if sourceAvailable(source, uuid) then
            table.insert(sources, source)
        end
    end
    return sources
end

local function fetchFromSources(sources, target, callback, retryableSources)
    retryableSources = retryableSources or {}
    local source = table.remove(sources, 1)
    fetchFromSource(source, target, function(player, err, retryable)
        if retryable then table.insert(retryableSources, source) end
        if player or err == "nicked" or #sources == 0 then
            callback(player, err, retryableSources)
            return
        end
        fetchFromSources(sources, target, callback, retryableSources)
    end)
end

local fetchStats

local function resolveFetch(target, attempt, player, err, retryableSources)
    local key = target.key
    if player then
        stats[key] = parseBedwarsStats(player)
        notifyFetched(key)
    elseif err == "nicked" then
        stats[key] = { isNicked = true, timestamp = os.time() }
        notifyFetched(key)
    else
        local tries = attempt or 1
        if tries < FETCH_RETRIES and #retryableSources > 0 then
            starfish.timers.delay(RETRY_BASE_MS * 2 ^ (tries - 1), function()
                fetchStats(target, tries + 1, retryableSources)
            end)
        else
            stats[key] = { fetchError = err or "request failed" }
            notifyFetched(key)
        end
    end
end

function fetchStats(target, attempt, sources)
    local key = target.key
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

    fetchFromSources(sources or availableSources(target.uuid), target, function(player, err, retryableSources)
        resolveFetch(target, attempt, player, err, retryableSources)
    end)
end

local function requestStats(target, callback)
    fetchCallbacks[target.key] = fetchCallbacks[target.key] or {}
    table.insert(fetchCallbacks[target.key], callback)
    fetchStats(target)
end

-- Text width

local SPACE_WIDTH = 4
local DEFAULT_CHAR_WIDTH = 6
local CHAR_WIDTH = {
    [" "] = SPACE_WIDTH,
    ["!"] = 2, ["\""] = 4, ["'"] = 2, ["("] = 5, [")"] = 5, ["*"] = 4,
    [","] = 2, ["."] = 2, [":"] = 2, [";"] = 2, ["<"] = 5, [">"] = 5,
    ["@"] = 7, ["["] = 4, ["]"] = 4, ["`"] = 3, ["{"] = 5, ["|"] = 2, ["}"] = 5,
    ["I"] = 4, ["f"] = 5, ["i"] = 2, ["k"] = 5, ["l"] = 3, ["t"] = 4,
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
    return ("§r "):rep(spaceCount(deficit))
end

-- Stat lines

local function statSummary(st)
    if not st then return "§cstats unavailable" end
    if st.isNicked then return "§cnicked" end
    if st.fetchError then return "§crequest failed (" .. st.fetchError .. ")" end

    return "§r" .. table.concat({
        st.starText,
        "§7FKDR: " .. STAT_COLORS.fkdr(st.fkdr) .. string.format("%.1f", st.fkdr),
        "§7Finals: " .. STAT_COLORS.finals(st.finals) .. formatNumber(st.finals),
    }, " §8| §r")
end

local function statLine(name, st)
    local displayName = (st and st.displayName) or name
    return teamFormatted(name, displayName) .. " §8- " .. statSummary(st)
end

local function printNicked(name)
    starfish.chat.info(statLine(name, NICKED_STATS))
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

local function sessionGains(session)
    local bedwars = session and session.delta and session.delta.stats and session.delta.stats.Bedwars
    local gains = {}
    for stat, change in pairs(bedwars or {}) do
        if type(change) == "number" then gains[stat] = change end
    end
    return gains
end

local function sessionStarsGained(gains, overall)
    local xpGained = gains.Experience
    if not xpGained or not (overall and overall.xp) then return 0 end
    local before = starfish.plugins.require("urchin").bedwarsLevel(overall.xp - xpGained)
    return overall.level - before.level
end

local function sessionSummary(session, overall)
    local gains = sessionGains(session)
    local fk, fd = gains.final_kills_bedwars or 0, gains.final_deaths_bedwars or 0
    local beds = gains.beds_broken_bedwars or 0
    if (gains.wins_bedwars or 0) == 0 and (gains.losses_bedwars or 0) == 0 and fk == 0 then return nil end

    local header = "§7Session §8(§7Monthly§8)"
    local mode = mostPlayedMode(gains)
    if mode then header = header .. " §8| §7Most Played: §f" .. mode end

    local fkdr = fk / math.max(1, fd)
    local columns = {}
    local stars = sessionStarsGained(gains, overall)
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

local function appendOverall(parts, overall)
    local totals = totalsLines(overall)
    if not totals then
        appendLine(parts, statSummary(overall))
        return
    end

    appendLine(parts, progressLine(overall))
    appendLine(parts, "")
    for _, line in ipairs(totals) do
        appendLine(parts, line)
    end
end

local function sendCheck(overall, check)
    local parts = { starfish.text.of("\n" .. RULE .. "\n"), specComponent(check.header) }
    for _, badge in ipairs(check.badges or {}) do
        table.insert(parts, specComponent(badge))
    end

    appendOverall(parts, overall)
    appendLine(parts, RULE)
    appendSession(parts, check, overall)
    if check.error then
        appendLine(parts, "§7Urchin: §c" .. check.error)
    end
    appendLine(parts, RULE)

    starfish.chat.info(starfish.text.join(parts))
end

local function printCheck(name)
    starfish.chat.info("§7Looking up " .. name .. "...")
    local target = resolveTarget(name, typedTarget(name))
    if not target then
        printNicked(name)
        return
    end

    local overall, check
    local remaining = 2
    local function finish()
        remaining = remaining - 1
        if remaining == 0 then sendCheck(overall, check) end
    end

    requestStats(target, function(st) overall = st; finish() end)
    pendingChecks[target.key] = function(result) check = result; finish() end
    starfish.plugins.require("urchin").fetchCheck(target.query)
end

-- Action bar

local function actionBarLine()
    local parts = {}
    for _, key in ipairs(ACTION_BAR_ORDER) do
        local source = actionBar.sources[key]
        local text = source and source()
        if text then table.insert(parts, text) end
    end
    return table.concat(parts, ACTION_BAR_SEPARATOR)
end

local function renderActionBar()
    local line = actionBarLine()
    if line ~= "" then starfish.chat.actionBar(line) end
end

local function showInActionBar(key, source)
    actionBar.sources[key] = source
    actionBar.timer = actionBar.timer or starfish.timers.interval(ACTION_BAR_MS, renderActionBar)
end

local function hideFromActionBar(key)
    actionBar.sources[key] = nil
    if actionBar.timer and next(actionBar.sources) == nil then
        actionBar.timer:off()
        actionBar.timer = nil
    end
end

-- Game state

local function isPlaying()
    return game.started and game.alive
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

local function currentHeightBarText()
    local me = starfish.players.me()
    if not me then return nil end
    local remaining = heightWatch.limit - math.floor(me.position.y)
    if remaining > HEIGHT_WARN_RANGE then return nil end
    return heightBarText(remaining, heightWatch.limit)
end

local function stopHeightWatch()
    heightWatch.limit = nil
    hideFromActionBar("heightLimit")
end

local function startHeightWatch()
    stopHeightWatch()
    if not isPlaying() or not starfish.config.get("heightLimit.enabled") then return end
    heightWatch.limit = mapHeightLimit(location.map)
    if heightWatch.limit then
        showInActionBar("heightLimit", currentHeightBarText)
    end
end

local function applyHeightLimitSetting(enabled)
    if enabled == false then
        stopHeightWatch()
    else
        startHeightWatch()
    end
end

-- Magic Milk

local function magicMilkSecondsLeft()
    local remainingMs = MAGIC_MILK_DURATION_MS - starfish.time.since(magicMilk.drankAt)
    return math.max(0, math.ceil(remainingMs / MS_PER_SECOND))
end

local function magicMilkBarText(seconds)
    local color = seconds <= MAGIC_MILK_WARNING_SECONDS and "§c" or "§f"
    return "§dMagic Milk " .. color .. seconds .. "s"
end

local function stopMagicMilkCountdown()
    hideFromActionBar("magicMilk")
end

local function currentMagicMilkBarText()
    local seconds = magicMilkSecondsLeft()
    if seconds == 0 then stopMagicMilkCountdown() end
    return magicMilkBarText(seconds)
end

local function startMagicMilkCountdown()
    magicMilk.drankAt = starfish.time.monotonic()
    showInActionBar("magicMilk", currentMagicMilkBarText)
end

local function isMe(entity)
    local me = starfish.players.me()
    return entity ~= nil and me ~= nil and entity.entityId == me.entityId
end

local function holdingMagicMilk()
    local held = starfish.inventory.heldItem()
    return held ~= nil and held.id == MAGIC_MILK_ITEM
end

local function drankMagicMilk(event)
    return event.status == ITEM_USE_FINISHED_STATUS and isMe(event.entity) and holdingMagicMilk()
end

local function onEntityStatus(event)
    if not isPlaying() or not starfish.config.get("magicMilk.enabled") then return end
    if drankMagicMilk(event) then startMagicMilkCountdown() end
end

local function applyMagicMilkSetting(enabled)
    if enabled == false then stopMagicMilkCountdown() end
end

-- Game flow

local function isPreGame()
    local sidebar = starfish.scoreboard.displayed("sidebar")
    return sidebar ~= nil and sidebar.name:match("^Pre") ~= nil
end

local function onGameStart()
    game.started = true
    startHeightWatch()
end

local function resumeGame()
    if not game.started then onGameStart() end
end

local function stopGameFeatures()
    stopHeightWatch()
    stopMagicMilkCountdown()
end

local function endGame()
    game.started = false
    game.alive = true
    stopGameFeatures()
end

local function onAbilities(abilities)
    if not game.started then return end
    game.alive = not abilities.canFly
    if game.alive then startHeightWatch() else stopGameFeatures() end
end

local function performRequeue()
    if not lastMode then
        starfish.chat.error("No recent BedWars mode to requeue.")
        return
    end
    starfish.chat.info("§7Requeueing §f" .. lastMode .. "§7...")
    starfish.chat.sendToServer("/play " .. lastMode)
end

-- Chat stats

local function sendChatStats(speaker, summary)
    if summary.nicked then return printNicked(speaker) end

    local parts = { starfish.text.of("\n" .. RULE .. "\n"), specComponent(summary.header) }
    for _, badge in ipairs(summary.badges) do
        table.insert(parts, specComponent(badge))
    end
    appendLine(parts, summary.line)
    appendLine(parts, RULE)

    starfish.chat.info(starfish.text.join(parts))
end

local function printChatStats(speaker)
    local target = resolveTarget(speaker, lookupTarget(speaker))
    if not target then return false end

    pendingSummaries[target.key] = function(summary) sendChatStats(speaker, summary) end
    starfish.plugins.require("urchin").fetchSummary(target.query)
    return true
end

local function hasWhiteColon(legacy)
    local before = legacy:match("^(.-)§f:")
    return before ~= nil and not before:find(":", 1, true)
end

local function extractSpeaker(message)
    if message:sub(1, #NPC_PREFIX) == NPC_PREFIX then return nil end

    local before = message:match("^([^:]+):")
    if not before then return nil end
    return (before:gsub("%s*%b[]%s*$", "")):match("([%w_]+)%s*$")
end

local function mentionsMe(message, me)
    local content = message:match("^[^:]+:%s*(.+)$")
    return content ~= nil and content:lower():find(me.name:lower(), 1, true) ~= nil
end

local function shouldShowChatStats(message, me)
    if starfish.config.get("chatStats.mention") and mentionsMe(message, me) then return true end
    return starfish.config.get("chatStats.pregame") and location.inGame and isPreGame()
end

local function handleChatStats(message, kind)
    if kind ~= "chat" then return end
    if not starfish.config.get("chatStats.enabled") then return end

    local speaker = extractSpeaker(message)
    if not speaker then return end

    local me = starfish.players.me()
    if not me or speaker == me.name or chatStats.seen[speaker] then return end

    if shouldShowChatStats(message, me) and printChatStats(speaker) then
        chatStats.seen[speaker] = true
    end
end

-- Party counter

local function partyGroupSize(count, maxPlayers)
    if maxPlayers == SOLO_LOBBY_SIZE then return false end
    return count >= 2 and count <= math.floor(maxPlayers / PARTY_GROUP_DENOMINATOR)
end

local function handlePartyCounter(message)
    if not starfish.config.get("partyCounter.enabled") then return end

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

-- Server location

local function resetForNewServer()
    endGame()
    chatStats.seen = {}
    if party.timer then party.timer:off() end
    party = { count = 0, timer = nil, maxPlayers = 0, isJoin = false }
end

local function applyLocation(loc)
    local changedServer = loc.serverName ~= location.server

    location.server = loc.serverName
    location.inBedwars = loc.serverType == "BEDWARS"
    location.inReplay = loc.serverType == "REPLAY"
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

    if location.inGame and not heightWatch.limit then
        startHeightWatch()
    end
end

-- Event wiring

starfish.events.on("urchin:playerFetched", function(event)
    local key = event.player and event.player:lower()
    local onDone = key and pendingUrchinFetches[key]
    if not onDone then return end
    pendingUrchinFetches[key] = nil
    onDone(event.data, event.error, event.retryable)
end)

starfish.events.on("urchin:checkFetched", function(event)
    resolvePending(pendingChecks, event)
end)

starfish.events.on("urchin:summaryFetched", function(event)
    resolvePending(pendingSummaries, event)
end)

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

    if REJOIN_MESSAGES[message] then
        resumeGame()
        return
    end

    if message:find(GAME_START_PHRASE, 1, true) and not message:find(":", 1, true) then
        onGameStart()
        return
    end

    if message:find(GAME_END_PHRASE, 1, true) and not message:find(":", 1, true) then
        endGame()
        return
    end

    handlePartyCounter(message)
    if hasWhiteColon(event.message or "") then
        handleChatStats(message, event.kind)
    end
end)

starfish.events.on("entity:status", onEntityStatus)
starfish.events.on("player:abilities", onAbilities)

local SETTING_HANDLERS = {
    ["heightLimit.enabled"] = applyHeightLimitSetting,
    ["magicMilk.enabled"] = applyMagicMilkSetting,
}

starfish.events.on("config:changed", function(event)
    local apply = SETTING_HANDLERS[event.key]
    if apply then apply(event.value) end
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

local restored = starfish.plugins.require("hypixel-mod-api").getLocation()
if restored and restored.serverName then
    applyLocation(restored)
end
