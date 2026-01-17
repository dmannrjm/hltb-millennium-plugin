--[[
    Steam API Unit Tests

    Tests for URL construction, response parsing, and HTTP integration.
    Uses mock HTTP module to test without network calls.

    Run with: busted tests/steam_spec.lua

    Adding a fallback API (e.g., SteamHunters):
        1. Add build_url_fallback() and parse_response_fallback() functions
        2. Copy create_mock_http pattern for your API's response format
        3. Add tests for URL construction and response parsing
        4. Test fallback logic triggers when primary API fails
]]

package.path = package.path .. ";backend/?.lua"

-- Use dkjson for tests: pure Lua, no C compilation needed
-- (Millennium provides its own 'json' module at runtime)
local json = require("dkjson")

-- Pre-load mock modules before requiring steam
-- Millennium provides 'http' and 'json' at runtime; we mock them for tests
package.loaded["json"] = json
package.loaded["http"] = { get = function() return nil, "No mock configured" end }

-- Mock HTTP module factory
-- Returns a mock http module that responds based on URL-to-response mapping
local function create_mock_http(responses)
    return {
        get = function(url, opts)
            local mock = responses[url]
            if not mock then
                return nil, "No mock for URL: " .. url
            end
            if mock.error then
                return nil, mock.error
            end
            return {
                status = mock.status or 200,
                body = mock.body
            }
        end
    }
end

describe("steam", function()
    local steam

    before_each(function()
        -- Fresh module load for each test to reset _http
        package.loaded["steam"] = nil
        steam = require("steam")
    end)

    describe("build_url", function()
        it("constructs correct URL with app_id", function()
            local url = steam.build_url(1086940)
            assert.equals(
                "https://store.steampowered.com/api/appdetails?appids=1086940&l=english",
                url
            )
        end)

        it("handles string app_id", function()
            local url = steam.build_url("570")
            assert.equals(
                "https://store.steampowered.com/api/appdetails?appids=570&l=english",
                url
            )
        end)

        it("always requests English language", function()
            local url = steam.build_url(123)
            assert.matches("&l=english", url)
        end)
    end)

    describe("parse_response", function()
        it("extracts app data from successful response", function()
            local response = {
                ["1086940"] = {
                    success = true,
                    data = {
                        name = "Baldur's Gate 3",
                        type = "game"
                    }
                }
            }
            local data, err = steam.parse_response(response, 1086940)
            assert.is_nil(err)
            assert.equals("Baldur's Gate 3", data.name)
            assert.equals("game", data.type)
        end)

        it("returns error for unsuccessful response", function()
            local response = {
                ["1086940"] = { success = false }
            }
            local data, err = steam.parse_response(response, 1086940)
            assert.is_nil(data)
            assert.equals("App not found", err)
        end)

        it("returns error for missing app in response", function()
            local response = {
                ["999999"] = { success = true, data = { name = "Other Game" } }
            }
            local data, err = steam.parse_response(response, 1086940)
            assert.is_nil(data)
            assert.equals("App not found in response", err)
        end)

        it("returns error for nil data", function()
            local data, err = steam.parse_response(nil, 1086940)
            assert.is_nil(data)
            assert.equals("No data", err)
        end)

        it("returns error when success but no data field", function()
            local response = {
                ["1086940"] = { success = true }
            }
            local data, err = steam.parse_response(response, 1086940)
            assert.is_nil(data)
            assert.equals("No app data", err)
        end)

        it("handles numeric app_id by converting to string for lookup", function()
            local response = {
                ["1086940"] = {
                    success = true,
                    data = { name = "Baldur's Gate 3" }
                }
            }
            local data, err = steam.parse_response(response, 1086940)
            assert.is_nil(err)
            assert.equals("Baldur's Gate 3", data.name)
        end)
    end)

    describe("get_app_details", function()
        it("returns nil for nil app_id", function()
            local data, err = steam.get_app_details(nil)
            assert.is_nil(data)
            assert.equals("app_id is nil", err)
        end)

        it("returns app data on successful request", function()
            local mock_response = {
                ["1086940"] = {
                    success = true,
                    data = { name = "Baldur's Gate 3", type = "game" }
                }
            }
            steam._http = create_mock_http({
                [steam.build_url(1086940)] = {
                    status = 200,
                    body = json.encode(mock_response)
                }
            })

            local data, err = steam.get_app_details(1086940)
            assert.is_nil(err)
            assert.equals("Baldur's Gate 3", data.name)
        end)

        it("returns error on HTTP failure", function()
            steam._http = create_mock_http({
                [steam.build_url(1086940)] = { error = "Connection refused" }
            })

            local data, err = steam.get_app_details(1086940)
            assert.is_nil(data)
            assert.matches("Request failed", err)
        end)

        it("returns error on non-200 status", function()
            steam._http = create_mock_http({
                [steam.build_url(1086940)] = { status = 500, body = "" }
            })

            local data, err = steam.get_app_details(1086940)
            assert.is_nil(data)
            assert.equals("HTTP 500", err)
        end)

        it("returns error on invalid JSON", function()
            steam._http = create_mock_http({
                [steam.build_url(1086940)] = { status = 200, body = "not json" }
            })

            local data, err = steam.get_app_details(1086940)
            assert.is_nil(data)
            assert.equals("Invalid JSON response", err)
        end)

        it("returns error when app not found", function()
            local mock_response = {
                ["1086940"] = { success = false }
            }
            steam._http = create_mock_http({
                [steam.build_url(1086940)] = {
                    status = 200,
                    body = json.encode(mock_response)
                }
            })

            local data, err = steam.get_app_details(1086940)
            assert.is_nil(data)
            assert.equals("App not found", err)
        end)
    end)

    describe("get_game_name", function()
        it("returns game name on success", function()
            local mock_response = {
                ["1086940"] = {
                    success = true,
                    data = { name = "Baldur's Gate 3" }
                }
            }
            steam._http = create_mock_http({
                [steam.build_url(1086940)] = {
                    status = 200,
                    body = json.encode(mock_response)
                }
            })

            local name, err = steam.get_game_name(1086940)
            assert.is_nil(err)
            assert.equals("Baldur's Gate 3", name)
        end)

        it("returns error when request fails", function()
            steam._http = create_mock_http({
                [steam.build_url(1086940)] = { error = "Timeout" }
            })

            local name, err = steam.get_game_name(1086940)
            assert.is_nil(name)
            assert.is_not_nil(err)
        end)

        it("returns nil for nil app_id", function()
            local name, err = steam.get_game_name(nil)
            assert.is_nil(name)
            assert.equals("app_id is nil", err)
        end)
    end)
end)
