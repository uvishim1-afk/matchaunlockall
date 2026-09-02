-- join for more open source scripts: https://discord.gg/TZkv6sS3fg
-- AC Bypass
-- Guard exploit-only APIs before using them to avoid "attempt to call a nil value"
local _stbl = nil
if type(hookfunction) == "function" and type(newcclosure) == "function" and type(getrenv) == "function" then
    _stbl = hookfunction(getrenv().setmetatable, newcclosure(function(tbl, mt)
        if mt and typeof(mt) == "table" and rawget(mt, "__mode") == "kv" then
            local tr = debug.traceback()
            if tr:find("MiscellaneousController") then
                return _stbl({1,2,3}, {})
            end
        end
        return _stbl(tbl, mt)
    end))
end

-- Improved safe require wrapper: pcall(require, arg) first; on failure, inspect the error string
-- and if it indicates a string was expected, try requiring by the module's Name as a fallback.
local function _safe_require(mod)
    local function try_require(x)
        local ok, res = pcall(require, x)
        if ok then return true, res end
        return false, res
    end

    if type(mod) == "string" then
        local ok, res = try_require(mod)
        if ok then return res end
        return nil
    end

    -- detect Instance when typeof is available
    local isInstance = false
    if typeof then
        isInstance = (typeof(mod) == "Instance")
    else
        isInstance = (type(mod) == "table" and mod.ClassName ~= nil)
    end

    if isInstance then
        -- try requiring the instance
        local ok, res = try_require(mod)
        if ok then return res end

        -- if require failed, inspect error message
        if type(res) == "string" then
            local lowered = res:lower()
            if lowered:find("string expected") or (lowered:find("expected") and lowered:find("string")) then
                local ok2, res2 = try_require(mod.Name)
                if ok2 then return res2 end
            end
        end

        return nil
    end

    local ok, res = try_require(mod)
    if ok then return res end
    return nil
end

coroutine.wrap(function()
    pcall(function()
        local function _proc(o)
            pcall(function()
                if o:IsA("LocalScript") or o:IsA("ModuleScript") then
                    local _s, nm = pcall(function() return o.Name:lower() end)
                    if not _s or not nm then return end
                    local _tags = {"anticheat","ac","detection","ban","kick","security","moderation"}
                    for _i = 1, #_tags do
                        if nm:find(_tags[_i]) then
                            pcall(function() o.Disabled = true end)
                            break
                        end
                    end
                end
            end)
        end
        pcall(function()
            local _desc = game:GetDescendants()
            for _i = 1, #_desc do _proc(_desc[_i]) end
        end)
        pcall(function() game.DescendantAdded:Connect(_proc) end)
    end)
    pcall(function()
        local _nc = game:GetService("NetworkClient")
        if not _nc then return end
        _nc.ChildAdded:Connect(function(ch)
            pcall(function()
                local _ok, _n = pcall(function() return ch.Name:lower() end)
                if _ok and _n then
                    if _n:find("anticheat") or _n:find("detection") then
                        pcall(function() ch:Destroy() end)
                    end
                end
            end)
        end)
    end)
end)()

local _fakeEv
pcall(function()
    _fakeEv = Instance.new("RemoteEvent")
    _fakeEv.Name = "ClientAlert"
    _fakeEv.Parent = LocalPlayer
end)

pcall(function()
    local _rf = game:GetService("ReplicatedFirst")
    local _tgt = _rf:WaitForChild("LocalScript3", 10)
    local _ct = 0
    local _gc = getgc(false)
    for _i = 1, #_gc do
        local _fn = _gc[_i]
        if type(_fn) ~= "function" then continue end
        local _ok1, _env = pcall(getfenv, _fn)
        if not _ok1 or type(_env) ~= "table" then continue end
        local _ok2, _scr = pcall(function() return rawget(_env, "script") end)
        if not _ok2 or not _scr or typeof(_scr) ~= "Instance" then continue end
        local _ok3, _ss = pcall(tostring, _scr)
        if not _ok3 then continue end
        if not (_scr == _tgt or (type(_ss) == "string" and _ss:find("LoadingScreen"))) then continue end
        local _ok4, _consts = pcall(debug.getconstants, _fn)
        if not _ok4 or type(_consts) ~= "table" then continue end
        for _j = 1, #_consts do
            local _c = _consts[_j]
            if type(_c) == "string" and (_c:find("TakeTheL") or _c:find("ban") or _c:find("kick")) then
                pcall(function()
                    if type(hookfunction) == "function" then
                        hookfunction(_fn, function() end)
                    end
                    _ct += 1
                end)
                break
            end
        end
    end
end)

task.wait(4)

-- Unlock All Skins / Wraps / Charms.
local _plrs    = game:GetService("Players")
local _rs      = game:GetService("ReplicatedStorage")
local _http    = game:GetService("HttpService")
local _run     = game:GetService("RunService")
local _ws      = game:GetService("Workspace")
local _lp      = _plrs.LocalPlayer
local _pscripts = _lp.PlayerScripts
local _ctrl    = _pscripts.Controllers
local _mods    = _rs:WaitForChild("Modules", 10)

local _enumLib = _safe_require(_mods:WaitForChild("EnumLibrary", 10))
if _enumLib then pcall(function() _enumLib:WaitForEnumBuilder() end) end

local _cosLib  = _safe_require(_mods:WaitForChild("CosmeticLibrary", 10))
local _itmLib  = _safe_require(_mods:WaitForChild("ItemLibrary", 10))
local _datCtrl = _safe_require(_ctrl:WaitForChild("PlayerDataController", 10))

-- Ensure _cosLib exists and provide safe defaults to avoid indexing nil
if not _cosLib or type(_cosLib) ~= "table" then
    _cosLib = {}
end
_cosLib.Cosmetics = _cosLib.Cosmetics or {}

-- Preserve original methods when present; provide safe fallbacks otherwise
local _origOwnsCosmetic = (_cosLib.OwnsCosmetic and type(_cosLib.OwnsCosmetic) == "function") and _cosLib.OwnsCosmetic or function() return false end
local _origOwnsNormally = (_cosLib.OwnsCosmeticNormally and type(_cosLib.OwnsCosmeticNormally) == "function") and _cosLib.OwnsCosmeticNormally or _origOwnsCosmetic
local _origOwnsUniversally = (_cosLib.OwnsCosmeticUniversally and type(_cosLib.OwnsCosmeticUniversally) == "function") and _cosLib.OwnsCosmeticUniversally or _origOwnsCosmetic
local _origOwnsForWeapon = (_cosLib.OwnsCosmeticForWeapon and type(_cosLib.OwnsCosmeticForWeapon) == "function") and _cosLib.OwnsCosmeticForWeapon or _origOwnsCosmetic

local _eq, _favs = {}, {}
local _buildingWep, _viewProf = nil, nil
local _lastWep = nil
local _fakeInv = {}

local function _mkCosmetic(nm, ctype, opts)
    local _base = _cosLib.Cosmetics[nm]
    if not _base then return nil end
    local _d = {}
    for k, v in pairs(_base) do _d[k] = v end
    _d.Name = nm
    _d.Type = _d.Type or ctype
    _d.Seed = _d.Seed or math.random(1, 1000000)
    if _enumLib then
        local _s, _eid = pcall(_enumLib.ToEnum, _enumLib, nm)
        if _s and _eid then
            _d.Enum = _eid
{