local Game = {
    new = function(self, game)
        self.__index = self
        setmetatable(game, self)
        return game
    end
}

function Game.getParty(game)
    local party = {}
    local monStart = game._party
    local nameStart = game._partyNames
    local otStart = game._partyOt
    for i = 1, emu:read8(game._partyCount) do
        party[i] = game:_readPartyMon(monStart, nameStart, otStart)
        monStart = monStart + game._partyMonSize
        if game._partyNames then
            nameStart = nameStart + game._monNameLength + 1
        end
        if game._partyOt then
            otStart = otStart + game._playerNameLength + 1
        end
    end
    return party
end

function Game.toString(game, rawstring)
    local string = ""
    for _, char in ipairs({rawstring:byte(1, #rawstring)}) do
        if char == game._terminator then
            break
        end
        string = string .. game._charmap[char]
    end
    return string
end

function Game.getSpeciesName(game, id)
    if game._speciesIndex then
        local index = game._index
        if not index then
            index = {}
            for i = 0, 255 do
                index[emu.memory.cart0:read8(game._speciesIndex + i)] = i
            end
            game._index = index
        end
        id = index[id]
    end
    local pointer = game._speciesNameTable + (game._speciesNameLength) * id
    return game:toString(emu.memory.cart0:readRange(pointer, game._monNameLength))
end

local GBAGameEn = Game:new{
    _terminator = 0xFF,
    _monNameLength = 10,
    _speciesNameLength = 11,
    _playerNameLength = 10
}

local Generation3En = GBAGameEn:new{
    _boxMonSize = 80,
    _partyMonSize = 100
}

GBAGameEn._charmap = { [0]=
	" ", "À", "Á", "Â", "Ç", "È", "É", "Ê", "Ë", "Ì", "こ", "Î", "Ï", "Ò", "Ó", "Ô",
	"Œ", "Ù", "Ú", "Û", "Ñ", "ß", "à", "á", "ね", "ç", "è", "é", "ê", "ë", "ì", "ま",
	"î", "ï", "ò", "ó", "ô", "œ", "ù", "ú", "û", "ñ", "º", "ª", "�", "&", "+", "あ",
	"ぃ", "ぅ", "ぇ", "ぉ", "v", "=", "ょ", "が", "ぎ", "ぐ", "げ", "ご", "ざ", "じ", "ず", "ぜ",
	"ぞ", "だ", "ぢ", "づ", "で", "ど", "ば", "び", "ぶ", "べ", "ぼ", "ぱ", "ぴ", "ぷ", "ぺ", "ぽ",
	"っ", "¿", "¡", "P\u{200d}k", "M\u{200d}n", "P\u{200d}o", "K\u{200d}é", "�", "�", "�", "Í", "%", "(", ")", "セ", "ソ",
	"タ", "チ", "ツ", "テ", "ト", "ナ", "ニ", "ヌ", "â", "ノ", "ハ", "ヒ", "フ", "ヘ", "ホ", "í",
	"ミ", "ム", "メ", "モ", "ヤ", "ユ", "ヨ", "ラ", "リ", "⬆", "⬇", "⬅", "➡", "ヲ", "ン", "ァ",
	"ィ", "ゥ", "ェ", "ォ", "ャ", "ュ", "ョ", "ガ", "ギ", "グ", "ゲ", "ゴ", "ザ", "ジ", "ズ", "ゼ",
	"ゾ", "ダ", "ヂ", "ヅ", "デ", "ド", "バ", "ビ", "ブ", "ベ", "ボ", "パ", "ピ", "プ", "ペ", "ポ",
	"ッ", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "!", "?", ".", "-", "・",
	"…", "“", "”", "‘", "’", "♂", "♀", "$", ",", "×", "/", "A", "B", "C", "D", "E",
	"F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U",
	"V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k",
	"l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "▶",
	":", "Ä", "Ö", "Ü", "ä", "ö", "ü", "⬆", "⬇", "⬅", "�", "�", "�", "�", "�", ""
}

function _read16BE(emu, address)
    return (emu:read8(address) << 8) | emu:read8(address + 1)
end

function Generation3En._readBoxMon(game, address)
    local mon = {}
    mon.personality = emu:read32(address + 0)
    mon.otId = emu:read32(address + 4)
    mon.nickname = game:toString(emu:readRange(address + 8, game._monNameLength))
    mon.language = emu:read8(address + 18)
    local flags = emu:read8(address + 19)
    mon.isBadEgg = flags & 1
    mon.hasSpecies = (flags >> 1) & 1
    mon.isEgg = (flags >> 2) & 1
    mon.otName = game:toString(emu:readRange(address + 20, game._playerNameLength))
    mon.markings = emu:read8(address + 27)

    local key = mon.otId ~ mon.personality
    local substructSelector = {
        [0] = {0, 1, 2, 3},
        [1] = {0, 1, 3, 2},
        [2] = {0, 2, 1, 3},
        [3] = {0, 3, 1, 2},
        [4] = {0, 2, 3, 1},
        [5] = {0, 3, 2, 1},
        [6] = {1, 0, 2, 3},
        [7] = {1, 0, 3, 2},
        [8] = {2, 0, 1, 3},
        [9] = {3, 0, 1, 2},
        [10] = {2, 0, 3, 1},
        [11] = {3, 0, 2, 1},
        [12] = {1, 2, 0, 3},
        [13] = {1, 3, 0, 2},
        [14] = {2, 1, 0, 3},
        [15] = {3, 1, 0, 2},
        [16] = {2, 3, 0, 1},
        [17] = {3, 2, 0, 1},
        [18] = {1, 2, 3, 0},
        [19] = {1, 3, 2, 0},
        [20] = {2, 1, 3, 0},
        [21] = {3, 1, 2, 0},
        [22] = {2, 3, 1, 0},
        [23] = {3, 2, 1, 0}
    }

    local pSel = substructSelector[mon.personality % 24]
    local ss0 = {}
    local ss1 = {}
    local ss2 = {}
    local ss3 = {}

    for i = 0, 2 do
        ss0[i] = emu:read32(address + 32 + pSel[1] * 12 + i * 4) ~ key
        ss1[i] = emu:read32(address + 32 + pSel[2] * 12 + i * 4) ~ key
        ss2[i] = emu:read32(address + 32 + pSel[3] * 12 + i * 4) ~ key
        ss3[i] = emu:read32(address + 32 + pSel[4] * 12 + i * 4) ~ key
    end

    mon.species = ss0[0] & 0xFFFF
    mon.heldItem = ss0[0] >> 16
    mon.experience = ss0[1]
    mon.ppBonuses = ss0[2] & 0xFF
    mon.friendship = (ss0[2] >> 8) & 0xFF

    mon.moves = {ss1[0] & 0xFFFF, ss1[0] >> 16, ss1[1] & 0xFFFF, ss1[1] >> 16}
    mon.pp = {ss1[2] & 0xFF, (ss1[2] >> 8) & 0xFF, (ss1[2] >> 16) & 0xFF, ss1[2] >> 24}

    mon.hpEV = ss2[0] & 0xFF
    mon.attackEV = (ss2[0] >> 8) & 0xFF
    mon.defenseEV = (ss2[0] >> 16) & 0xFF
    mon.speedEV = ss2[0] >> 24
    mon.spAttackEV = ss2[1] & 0xFF
    mon.spDefenseEV = (ss2[1] >> 8) & 0xFF
    mon.cool = (ss2[1] >> 16) & 0xFF
    mon.beauty = ss2[1] >> 24
    mon.cute = ss2[2] & 0xFF
    mon.smart = (ss2[2] >> 8) & 0xFF
    mon.tough = (ss2[2] >> 16) & 0xFF
    mon.sheen = ss2[2] >> 24

    mon.pokerus = ss3[0] & 0xFF
    mon.metLocation = (ss3[0] >> 8) & 0xFF
    flags = ss3[0] >> 16
    mon.metLevel = flags & 0x7F
    mon.metGame = (flags >> 7) & 0xF
    mon.pokeball = (flags >> 11) & 0xF
    mon.otGender = (flags >> 15) & 0x1
    flags = ss3[1]
    mon.hpIV = flags & 0x1F
    mon.attackIV = (flags >> 5) & 0x1F
    mon.defenseIV = (flags >> 10) & 0x1F
    mon.speedIV = (flags >> 15) & 0x1F
    mon.spAttackIV = (flags >> 20) & 0x1F
    mon.spDefenseIV = (flags >> 25) & 0x1F
    -- Bit 30 is another "isEgg" bit
    mon.altAbility = (flags >> 31) & 1
    flags = ss3[2]
    mon.coolRibbon = flags & 7
    mon.beautyRibbon = (flags >> 3) & 7
    mon.cuteRibbon = (flags >> 6) & 7
    mon.smartRibbon = (flags >> 9) & 7
    mon.toughRibbon = (flags >> 12) & 7
    mon.championRibbon = (flags >> 15) & 1
    mon.winningRibbon = (flags >> 16) & 1
    mon.victoryRibbon = (flags >> 17) & 1
    mon.artistRibbon = (flags >> 18) & 1
    mon.effortRibbon = (flags >> 19) & 1
    mon.marineRibbon = (flags >> 20) & 1
    mon.landRibbon = (flags >> 21) & 1
    mon.skyRibbon = (flags >> 22) & 1
    mon.countryRibbon = (flags >> 23) & 1
    mon.nationalRibbon = (flags >> 24) & 1
    mon.earthRibbon = (flags >> 25) & 1
    mon.worldRibbon = (flags >> 26) & 1
    mon.eventLegal = (flags >> 27) & 0x1F
    return mon
end

function Generation3En._readPartyMon(game, address)
    -- base data + IV/EVs come from the existing Box reader
    local mon = game:_readBoxMon(address)

    -- battle‑only stats
    mon.status = emu:read32(address + 80)
    mon.level = emu:read8(address + 84)
    mon.mail = emu:read32(address + 85)
    mon.hp = emu:read16(address + 86)
    mon.maxHP = emu:read16(address + 88)
    mon.attack = emu:read16(address + 90)
    mon.defense = emu:read16(address + 92)
    mon.speed = emu:read16(address + 94)
    mon.spAttack = emu:read16(address + 96)
    mon.spDefense = emu:read16(address + 98)

    ----------------------------------------------------------------
    -- SHINY CHECK  (tid ⊕ sid ⊕ pidLow ⊕ pidHigh) < 8
    ----------------------------------------------------------------
    local tid = mon.otId & 0xFFFF
    local sid = (mon.otId >> 16) & 0xFFFF
    local pidLow = mon.personality & 0xFFFF
    local pidHigh = (mon.personality >> 16) & 0xFFFF
    mon.isShiny = ((tid ~ sid ~ pidLow ~ pidHigh) & 0xFFFF) < 8

    return mon
end

function Generation3En:getOpponentMon(slot)
    slot = slot or 0
    if not self._opponent then
        return nil
    end
    local addr = self._opponent + slot * self._partyMonSize
    return self:_readPartyMon(addr)
end

local gameEmeraldEn = Generation3En:new{
    name = "Emerald (USA)",
    _party = 0x20244ec,
    _partyCount = 0x20244e9,
    _speciesNameTable = 0x3185c8,
    _opponent = 0x02024744
}

gameCodes = {

    ["AGB-BPEE"] = gameEmeraldEn

}

function printPartyStatus(game, buffer)
    buffer:clear()
    for _, mon in ipairs(game:getParty()) do
        buffer:print(string.format("%-10s (Lv%3i %10s): %3i/%3i\n", mon.nickname, mon.level,
            game:getSpeciesName(mon.species), mon.hp, mon.maxHP))
    end
end

function printOpponentStatus(game, buffer)
    if not game.getOpponentMon then
        return
    end -- not Gen III
    local foe = game:getOpponentMon()
    if not foe or foe.species == 0 then
        return
    end -- no battle
    buffer:clear()
    buffer:print(string.format("%-10s (Lv%3i %10s)%s\n  HP:%3i/%3i  IVs %2i/%2i/%2i/%2i/%2i/%2i\n \n Personality:%2i", foe.nickname,
        foe.level, game:getSpeciesName(foe.species), foe.isShiny and " ✧" or "Not Shiny", -- little star for shinies
        foe.hp, foe.maxHP, foe.hpIV, foe.attackIV, foe.defenseIV, foe.spAttackIV, foe.spDefenseIV, foe.speedIV, foe.personality))

end

function detectGame()
    local checksum = 0
    for i, v in ipairs({emu:checksum(C.CHECKSUM.CRC32):byte(1, 4)}) do
        checksum = checksum * 256 + v
    end

    game = gameCodes[emu:getGameCode()]

    if not game then
        console:error("This is not pokemon emerald!")

    end

    if not game then
        console:error("Unknown game!")
    else
        console:log("Found game: " .. game.name)
        -- if not partyBuffer then
        --     partyBuffer = console:createBuffer("Party")

        -- end
        if not enemyBuffer then
            enemyBuffer = console:createBuffer("Enemy")
        end
    end
end

function updateBuffer()
    -- if not game or not partyBuffer or not enemyBuffer then
    --     return
    -- end
    if not game or not enemyBuffer then
        return
    end
    -- printPartyStatus(game, partyBuffer)

    printOpponentStatus(game, enemyBuffer)
end

callbacks:add("start", detectGame)
callbacks:add("frame", updateBuffer)
if emu then
    detectGame()
end
