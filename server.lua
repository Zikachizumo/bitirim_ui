-- =========================================================
-- STARTER SKIN PERSISTENCE
-- =========================================================
--
-- Mirrors illenium-appearance's own save sequence
-- (server/framework/qb/main.lua: UpdateActiveField -> DeleteByModel -> Add)
-- since those functions are resource-local and not exported.
--

lib.callback.register('bitirim_ui:server:saveStarterSkin', function(source, citizenId, appearance)
    if type(citizenId) ~= 'string' or citizenId == '' then
        return false
    end

    if type(appearance) ~= 'table' or type(appearance.model) ~= 'string' then
        return false
    end

    local encoded = json.encode(appearance)

    MySQL.update.await(
        'UPDATE playerskins SET active = 0 WHERE citizenid = ?',
        { citizenId }
    )

    MySQL.query.await(
        'DELETE FROM playerskins WHERE citizenid = ? AND model = ?',
        { citizenId, appearance.model }
    )

    MySQL.insert.await(
        'INSERT INTO playerskins (citizenid, model, skin, active) VALUES (?, ?, ?, 1)',
        { citizenId, appearance.model, encoded }
    )

    return true
end)
