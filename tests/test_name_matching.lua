--[[
    Name Matching Tests

    Verifies that Steam game names can be matched to HLTB names through
    sanitization and simplification. Each test case represents a real-world
    Steam name that should resolve to the corresponding HLTB name.

    Run with: busted tests/
]]

package.path = package.path .. ";backend/?.lua"
local utils = require("hltb_utils")

-- Test cases: Steam name -> expected HLTB name
-- These are real examples where Steam names differ from HLTB names
local test_cases = {
    -- Edition suffixes
    {
        steam = "The Witcher: Enhanced Edition Director's Cut",
        hltb = "The Witcher"
    },
    {
        steam = "The Witcher 2: Assassins of Kings Enhanced Edition",
        hltb = "The Witcher 2: Assassins of Kings"
    },
    {
        steam = "Pathfinder: Wrath of the Righteous - Enhanced Edition",
        hltb = "Pathfinder: Wrath of the Righteous"
    },

    -- Complete Edition with special characters
    {
        steam = "Scott Pilgrim vs. The World: The Game - Complete Edition",
        hltb = "Scott Pilgrim vs. The World: The Game"
    },

    -- Anniversary Edition
    {
        steam = "Microsoft Flight Simulator (2020) 40th Anniversary Edition",
        hltb = "Microsoft Flight Simulator"
    },
    {
        steam = "Warhammer 40,000: Space Marine - Anniversary Edition",
        hltb = "Warhammer 40,000: Space Marine"
    },

    -- Collection suffix
    {
        steam = "Sonic & All-Stars Racing Transformed Collection",
        hltb = "Sonic & All-Stars Racing Transformed"
    },

    -- Legacy/Maximum Edition
    {
        steam = "Company of Heroes - Legacy Edition",
        hltb = "Company of Heroes"
    },
    {
        steam = "Crysis 2 - Maximum Edition",
        hltb = "Crysis 2"
    },

    -- Year tags
    {
        steam = "Risk of Rain (2013)",
        hltb = "Risk of Rain"
    },

    -- Remastered
    {
        steam = "Legacy of Kain Soul Reaver 1&2 Remastered",
        hltb = "Legacy of Kain Soul Reaver 1&2"
    },

    -- Trademark symbols
    {
        steam = "DOOM Eternal™",
        hltb = "DOOM Eternal"
    },
    {
        steam = "The Elder Scrolls V: Skyrim®",
        hltb = "The Elder Scrolls V: Skyrim"
    },

    -- Names that should remain unchanged
    {
        steam = "Dark Souls III",
        hltb = "Dark Souls III"
    },
    {
        steam = "Hollow Knight",
        hltb = "Hollow Knight"
    },
}

describe("Steam to HLTB name matching", function()
    for _, case in ipairs(test_cases) do
        it(case.steam .. " -> " .. case.hltb, function()
            local sanitized = utils.sanitize_game_name(case.steam)
            local simplified = utils.simplify_game_name(sanitized)

            -- Match if either sanitized or simplified equals HLTB name
            local matches = (sanitized == case.hltb) or (simplified == case.hltb)
            assert.is_true(matches,
                string.format("\nExpected: '%s'\nSanitized: '%s'\nSimplified: '%s'",
                    case.hltb, sanitized, simplified))
        end)
    end
end)

describe("sanitize_game_name", function()
    it("removes trademark symbol", function()
        assert.equals("Game Name", utils.sanitize_game_name("Game Name™"))
    end)

    it("removes registered symbol", function()
        assert.equals("Game Name", utils.sanitize_game_name("Game Name®"))
    end)

    it("removes copyright symbol", function()
        assert.equals("Game Name", utils.sanitize_game_name("Game Name©"))
    end)

    it("normalizes whitespace", function()
        assert.equals("Game Name", utils.sanitize_game_name("Game  Name"))
    end)

    it("trims whitespace", function()
        assert.equals("Game Name", utils.sanitize_game_name("  Game Name  "))
    end)
end)

describe("simplify_game_name", function()
    it("normalizes en-dash to hyphen", function()
        local result = utils.simplify_game_name("Game – Edition")
        assert.equals("Game - Edition", result)
    end)

    it("normalizes em-dash to hyphen", function()
        local result = utils.simplify_game_name("Game — Edition")
        assert.equals("Game - Edition", result)
    end)

    it("removes trailing punctuation", function()
        assert.equals("Game Name", utils.simplify_game_name("Game Name -"))
        assert.equals("Game Name", utils.simplify_game_name("Game Name:"))
    end)

    it("handles stacked suffixes", function()
        local result = utils.simplify_game_name("Game: Enhanced Edition Director's Cut")
        assert.equals("Game", result)
    end)
end)

describe("levenshtein_distance", function()
    it("returns 0 for identical strings", function()
        assert.equals(0, utils.levenshtein_distance("hello", "hello"))
    end)

    it("returns length for empty string comparison", function()
        assert.equals(5, utils.levenshtein_distance("hello", ""))
        assert.equals(5, utils.levenshtein_distance("", "hello"))
    end)

    it("calculates single character difference", function()
        assert.equals(1, utils.levenshtein_distance("hello", "hallo"))
    end)

    it("calculates insertion distance", function()
        assert.equals(1, utils.levenshtein_distance("hello", "helloo"))
    end)

    it("calculates deletion distance", function()
        assert.equals(1, utils.levenshtein_distance("hello", "hell"))
    end)
end)
