local creatorOpen = false

local previewPed = nil
local previewCam = nil
local previewHeading = 180.0
local hiddenPlayerPed = nil

local CREATOR_LOCATION = vec4(-1579.56, -559.02, 85.5, 184.51)

--
-- Not collected in the NUI (no player-facing fields for them),
-- but qbx_core:server:createCharacter silently refuses to
-- create a character without both, so we send fixed values.
--

local DEFAULT_NATIONALITY = 'American'
local DEFAULT_BIRTHDATE = '1990-01-01'


local creationState = {
    step = 1,
    gender = nil,
    firstName = nil,
    lastName = nil,
    nationality = DEFAULT_NATIONALITY,
    birthdate = DEFAULT_BIRTHDATE,

    appearance = {
        mother = 21,
        father = 0,

        resemblance = 0.50,
        skinMix = 0.50,

        eyeColor = 3,

        ageing = -1,
        complexion = -1,
        moles = -1,

        face = {
            [0] = 0.0,
            [1] = 0.0,
            [2] = 0.0,
            [3] = 0.0,
            [4] = 0.0,
            [5] = 0.0,
            [6] = 0.0,
            [7] = 0.0,
            [8] = 0.0,
            [9] = 0.0,
            [10] = 0.0,
            [11] = 0.0,
            [12] = 0.0,
            [13] = 0.0,
            [14] = 0.0,
            [15] = 0.0,
            [16] = 0.0,
            [17] = 0.0,
            [18] = 0.0,
            [19] = 0.0
        }
    }
}


-- =========================================================
-- HELPERS
-- =========================================================

local function clamp(value, minimum, maximum)
    value = tonumber(value) or minimum

    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end


local function resetAppearance()
    creationState.appearance = {
        mother = 21,
        father = 0,

        resemblance = 0.50,
        skinMix = 0.50,

        eyeColor = 3,

        ageing = -1,
        complexion = -1,
        moles = -1,

        face = {
            [0] = 0.0,
            [1] = 0.0,
            [2] = 0.0,
            [3] = 0.0,
            [4] = 0.0,
            [5] = 0.0,
            [6] = 0.0,
            [7] = 0.0,
            [8] = 0.0,
            [9] = 0.0,
            [10] = 0.0,
            [11] = 0.0,
            [12] = 0.0,
            [13] = 0.0,
            [14] = 0.0,
            [15] = 0.0,
            [16] = 0.0,
            [17] = 0.0,
            [18] = 0.0,
            [19] = 0.0
        }
    }
end


local function resetCreationState()
    creationState = {
        step = 1,
        gender = nil,
        firstName = nil,
        lastName = nil,
        nationality = DEFAULT_NATIONALITY,
        birthdate = DEFAULT_BIRTHDATE,
        appearance = nil
    }

    resetAppearance()
end


-- =========================================================
-- PREVIEW CLEANUP
-- =========================================================

local function destroyPreview()
    if previewCam and DoesCamExist(previewCam) then
        RenderScriptCams(false, true, 350, true, true)

        DestroyCam(previewCam, false)

        previewCam = nil
    end

    if previewPed and DoesEntityExist(previewPed) then
        DeleteEntity(previewPed)

        previewPed = nil
    end

    if hiddenPlayerPed and DoesEntityExist(hiddenPlayerPed) then
        SetEntityVisible(
            hiddenPlayerPed,
            true,
            false
        )

        FreezeEntityPosition(
            hiddenPlayerPed,
            false
        )
    end

    ClearFocus()

    hiddenPlayerPed = nil

    SetTimecycleModifier('default')
end


-- =========================================================
-- PREVIEW CAMERA
-- =========================================================

local function updatePreviewCamera(mode)
    if not previewPed or not DoesEntityExist(previewPed) then
        return
    end

    if not previewCam or not DoesCamExist(previewCam) then
        previewCam = CreateCam(
            'DEFAULT_SCRIPTED_CAMERA',
            true
        )
    end

    --
    -- IMPORTANT:
    --
    -- NUI preview box is on the RIGHT side of the screen.
    --
    -- A native GTA camera always renders the whole game
    -- viewport, therefore we intentionally compose the ped
    -- toward the right side of the camera frame.
    --
    -- Negative target X makes the camera optical center look
    -- slightly to the LEFT of the ped, which makes the ped
    -- appear on the RIGHT side of the screen.
    --

    --
    -- Camera and target always share the exact same height, so
    -- the line between them is perfectly horizontal at any
    -- distance (values below calibrated live in-game).
    --

    local cameraDistance
    local previewHeight
    local targetHorizontalOffset
    local fov

    if mode == 'body' then

        cameraDistance = 8.05
        previewHeight = -0.25

        targetHorizontalOffset = 1.65

        fov = 31.0

    else

        --
        -- FACE / HERITAGE / DETAILS
        --

        cameraDistance = 2.4
        previewHeight = 0.57

        targetHorizontalOffset = 0.45

        fov = 29.0

    end


    local cameraCoords =
        GetOffsetFromEntityInWorldCoords(
            previewPed,
            0.0,
            cameraDistance,
            previewHeight
        )


    local targetCoords =
        GetOffsetFromEntityInWorldCoords(
            previewPed,
            targetHorizontalOffset,
            0.0,
            previewHeight
        )


    SetCamCoord(
        previewCam,
        cameraCoords.x,
        cameraCoords.y,
        cameraCoords.z
    )


    PointCamAtCoord(
        previewCam,
        targetCoords.x,
        targetCoords.y,
        targetCoords.z
    )


    SetCamFov(
        previewCam,
        fov
    )


    SetCamActive(
        previewCam,
        true
    )


    RenderScriptCams(
        true,
        true,
        350,
        true,
        true
    )


    print(
        ('^3[bitirim_ui]^7 Preview camera: %s | distance %.3f | height %.3f | targetX %.3f')
        :format(
            mode,
            cameraDistance,
            previewHeight,
            targetHorizontalOffset
        )
    )
end


-- =========================================================
-- FIXED STARTER LOOK
-- =========================================================

local function applyStarterLook(ped)
    if not ped or not DoesEntityExist(ped) then
        return
    end

    --
    -- No player-selectable clothes / hair here.
    -- GTA freemode default clothing is used as the
    -- temporary starter outfit.
    --

    SetPedDefaultComponentVariation(ped)

    --
    -- Fixed neutral hair component.
    --

    SetPedComponentVariation(
        ped,
        2,
        0,
        0,
        2
    )

    ClearAllPedProps(ped)

    ClearPedBloodDamage(ped)

    SetPedCanRagdoll(
        ped,
        false
    )
end


-- =========================================================
-- HEAD OVERLAY
-- =========================================================

local function applyOverlay(ped, overlayId, selectedIndex)
    selectedIndex = tonumber(selectedIndex) or -1

    if selectedIndex < 0 then
        SetPedHeadOverlay(
            ped,
            overlayId,
            255,
            0.0
        )

        return
    end

    local count = GetPedHeadOverlayNum(overlayId)

    if count and count > 0 then
        selectedIndex = math.floor(
            clamp(
                selectedIndex,
                0,
                count - 1
            )
        )
    end

    SetPedHeadOverlay(
        ped,
        overlayId,
        selectedIndex,
        1.0
    )
end


-- =========================================================
-- APPLY APPEARANCE
-- =========================================================

local function applyAppearance()
    if not previewPed or not DoesEntityExist(previewPed) then
        return
    end

    local appearance = creationState.appearance

    SetPedHeadBlendData(
        previewPed,

        appearance.father,
        appearance.mother,
        0,

        appearance.father,
        appearance.mother,
        0,

        appearance.resemblance,
        appearance.skinMix,
        0.0,

        false
    )

    for index = 0, 19 do
        SetPedFaceFeature(
            previewPed,
            index,
            appearance.face[index] or 0.0
        )
    end

    SetPedEyeColor(
        previewPed,
        appearance.eyeColor
    )

    --
    -- 3 = Ageing
    -- 6 = Complexion
    -- 9 = Moles / Freckles
    --

    applyOverlay(
        previewPed,
        3,
        appearance.ageing
    )

    applyOverlay(
        previewPed,
        6,
        appearance.complexion
    )

    applyOverlay(
        previewPed,
        9,
        appearance.moles
    )
end


-- =========================================================
-- SPAWN PREVIEW PED
-- =========================================================

local function createPreviewPed()
    destroyPreview()

    local playerPed = PlayerPedId()

    hiddenPlayerPed = playerPed

    local modelName

    if creationState.gender == 'female' then
        modelName = 'mp_f_freemode_01'
    else
        modelName = 'mp_m_freemode_01'
    end

    local model = joaat(modelName)

    RequestModel(model)

    local timeout = GetGameTimer() + 10000

    while not HasModelLoaded(model) do
        Wait(0)

        if GetGameTimer() > timeout then
            print(
                '^1[bitirim_ui]^7 Preview ped model could not be loaded.'
            )

            return false
        end
    end

    SetEntityCoordsNoOffset(
        playerPed,
        CREATOR_LOCATION.x,
        CREATOR_LOCATION.y,
        CREATOR_LOCATION.z,
        false,
        false,
        false
    )

    SetEntityHeading(
        playerPed,
        CREATOR_LOCATION.w
    )

    RequestCollisionAtCoord(
        CREATOR_LOCATION.x,
        CREATOR_LOCATION.y,
        CREATOR_LOCATION.z
    )

    local collisionTimeout = GetGameTimer() + 5000

    while not HasCollisionLoadedAroundEntity(playerPed)
        and GetGameTimer() < collisionTimeout
    do
        RequestCollisionAtCoord(
            CREATOR_LOCATION.x,
            CREATOR_LOCATION.y,
            CREATOR_LOCATION.z
        )

        Wait(0)
    end

    --
    -- 'hud_def_blur' (previously used here to fix a
    -- pitch-black-at-night location) is itself a depth-of-field
    -- blur effect -- it was making the ped visibly blurry once
    -- it was finally visible. The current CREATOR_LOCATION is
    -- an interior with its own baked lighting, so no timecycle
    -- modifier is needed at all.
    --

    local coords = GetEntityCoords(playerPed)

    previewHeading = CREATOR_LOCATION.w

    previewPed = CreatePed(
        4,
        model,
        coords.x,
        coords.y,
        coords.z,
        previewHeading,
        false,
        false
    )

    SetModelAsNoLongerNeeded(model)

    if not previewPed or previewPed == 0 then
        print(
            '^1[bitirim_ui]^7 Preview ped could not be created.'
        )

        return false
    end

    print(
        ('^2[bitirim_ui]^7 Preview ped created. Entity: %s | Model: %s | coords: %.2f, %.2f, %.2f | collisionLoaded: %s')
        :format(
            previewPed,
            modelName,
            coords.x,
            coords.y,
            coords.z,
            tostring(HasCollisionLoadedAroundEntity(playerPed))
        )
    )

    SetFocusEntity(previewPed)

    SetEntityAsMissionEntity(
        previewPed,
        true,
        true
    )

    FreezeEntityPosition(
        previewPed,
        true
    )

    SetEntityInvincible(
        previewPed,
        true
    )

    SetEntityCollision(
        previewPed,
        false,
        false
    )

    SetBlockingOfNonTemporaryEvents(
        previewPed,
        true
    )

    TaskStandStill(
        previewPed,
        -1
    )

    SetEntityVisible(
        playerPed,
        false,
        false
    )

    FreezeEntityPosition(
        playerPed,
        true
    )

    applyStarterLook(previewPed)

    applyAppearance()

    updatePreviewCamera('face')

    --
    -- First fade-in of the session (bootstrap deliberately skips
    -- it). Comes last, after the real ped is hidden and the
    -- dressed preview ped + camera are fully set up, so nothing
    -- but the finished shot is ever visible.
    --

    DoScreenFadeIn(500)

    return true
end


-- =========================================================
-- CREATOR OPEN/CLOSE
-- =========================================================

local function openCreator()
    if creatorOpen then
        return
    end

    local playerData = exports.qbx_core:GetPlayerData()

    if playerData and playerData.citizenid then
        print(
            '^1[bitirim_ui]^7 openCreator blocked, player already has a loaded character.'
        )

        return
    end

    resetCreationState()

    creatorOpen = true

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)

    SendNUIMessage({
        action = 'open',
        state = creationState
    })
end


local function closeCreator()
    if not creatorOpen then
        return
    end

    destroyPreview()

    creatorOpen = false

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    SendNUIMessage({
        action = 'close'
    })
end


-- =========================================================
-- SPAWN HANDOFF
-- =========================================================
--
-- This server only has qbx_spawn/bitirim_spawn wired up for
-- the qb-spawn:client:setupSpawns event -- the vanilla
-- apartments:client:setupSpawnUI branch has no listener here,
-- so we deliberately never use it.
--

--
-- skipToHotel tells bitirim_spawn to bypass its Hotel/Last
-- Location picker entirely and spawn straight into Hotel
-- (spawns[1]). Used whenever a citizenid's DB "position" is
-- still the character creator room -- never a genuine previous
-- session -- whether that's because the character was just
-- created this exact session, or because a PRIOR session got
-- interrupted (crash/kick/disconnect) between character
-- creation and ever completing a real first spawn. Showing the
-- picker in that case is actively wrong: "Last Location" would
-- teleport the player right back into the creator room.
--

local function triggerSpawnUI(targetCitizenId, skipToHotel)
    TriggerEvent('qb-spawn:client:setupSpawns', targetCitizenId, skipToHotel)
    TriggerEvent('qb-spawn:client:openUI', true)
end

--
-- True if this citizenid has no real last location on record --
-- either none at all, or one still within a few meters of
-- CREATOR_LOCATION (the only place a not-yet-fully-spawned
-- character's saved position could be). Must only be called
-- after the player is logged in (qbx_spawn:server:getLastLocation
-- reads the currently logged-in source's own citizenid).
--

local function hasNoRealLastLocation()
    local lastCoords = lib.callback.await(
        'qbx_spawn:server:getLastLocation',
        false
    )

    if not lastCoords then
        return true
    end

    local dx = lastCoords.x - CREATOR_LOCATION.x
    local dy = lastCoords.y - CREATOR_LOCATION.y

    return (dx * dx + dy * dy) < (15.0 * 15.0)
end

--
-- Used ONLY by the bootstrap thread (returning player, who
-- hasn't logged in yet this session). qbx_core:server:loadCharacter
-- calls its internal Login(source, citizenId) -- qbx_core drops
-- the player as an "exploit" if Login runs a second time for a
-- source that's already logged in (QBX.Players[source] already
-- set), so this must never be called for a player who is
-- already logged in.
--

--
-- qbx_core:server:loadCharacter's callback never returns an
-- explicit value on EITHER path (success just falls off the end
-- of the function, failure is a bare "return") -- both resolve
-- to nil on this end, so its return value cannot be used to
-- tell success from failure. A genuine failure (bad license,
-- exploit) already gets the player dropped server-side by
-- qbx_core itself, so there is nothing left for us to branch on
-- here -- just wait for it and continue.
--

local function beginSpawnHandoff(targetCitizenId)
    lib.callback.await(
        'qbx_core:server:loadCharacter',
        false,
        targetCitizenId
    )

    triggerSpawnUI(targetCitizenId, hasNoRealLastLocation())

    return true
end


-- =========================================================
-- STEP 1
-- =========================================================

RegisterNUICallback('selectGender', function(data, cb)
    local gender = data and data.gender

    if gender ~= 'female' and gender ~= 'male' then
        cb({
            ok = false,
            error = 'invalid_gender'
        })

        return
    end

    creationState.gender = gender

    cb({
        ok = true
    })
end)


RegisterNUICallback('continueGender', function(_, cb)
    if not creationState.gender then
        cb({
            ok = false,
            error = 'gender_required'
        })

        return
    end

    creationState.step = 2

    SendNUIMessage({
        action = 'step',
        step = 2,
        state = creationState
    })

    cb({
        ok = true
    })
end)


-- =========================================================
-- STEP 2
-- =========================================================

RegisterNUICallback('saveIdentity', function(data, cb)
    local firstName = data and data.firstName
    local lastName = data and data.lastName

    if type(firstName) ~= 'string' or type(lastName) ~= 'string' then
        cb({
            ok = false,
            error = 'invalid_identity'
        })

        return
    end

    firstName = firstName:match('^%s*(.-)%s*$')
    lastName = lastName:match('^%s*(.-)%s*$')

    if #firstName < 2 or #firstName > 20 then
        cb({
            ok = false,
            error = 'invalid_first_name'
        })

        return
    end

    if #lastName < 2 or #lastName > 20 then
        cb({
            ok = false,
            error = 'invalid_last_name'
        })

        return
    end

    creationState.firstName = firstName
    creationState.lastName = lastName
    creationState.step = 3

    createPreviewPed()

    SendNUIMessage({
        action = 'step',
        step = 3,
        state = creationState
    })

    cb({
        ok = true
    })
end)


-- =========================================================
-- STEP 3 - APPEARANCE
-- =========================================================

RegisterNUICallback('appearanceUpdate', function(data, cb)
    local appearance = creationState.appearance

    local kind = data and data.kind

    if kind == 'heritage' then
        appearance.mother =
            math.floor(
                clamp(
                    data.mother,
                    21,
                    41
                )
            )

        appearance.father =
            math.floor(
                clamp(
                    data.father,
                    0,
                    20
                )
            )

        appearance.resemblance =
            clamp(
                data.resemblance,
                0.0,
                1.0
            )

        appearance.skinMix =
            clamp(
                data.skinMix,
                0.0,
                1.0
            )

    elseif kind == 'face' then
        local index =
            math.floor(
                clamp(
                    data.index,
                    0,
                    19
                )
            )

        local value =
            clamp(
                data.value,
                -1.0,
                1.0
            )

        appearance.face[index] = value

    elseif kind == 'eyeColor' then
        appearance.eyeColor =
            math.floor(
                clamp(
                    data.value,
                    0,
                    7
                )
            )

    elseif kind == 'detail' then
        local detailName = data.name

        local value =
            math.floor(
                clamp(
                    data.value,
                    -1,
                    20
                )
            )

        if detailName == 'ageing' then
            appearance.ageing = value

        elseif detailName == 'complexion' then
            appearance.complexion = value

        elseif detailName == 'moles' then
            appearance.moles = value
        end
    end

    applyAppearance()

    cb({
        ok = true
    })
end)


RegisterNUICallback('appearanceReset', function(_, cb)
    resetAppearance()

    applyStarterLook(previewPed)

    applyAppearance()

    SendNUIMessage({
        action = 'appearanceState',
        appearance = creationState.appearance
    })

    cb({
        ok = true
    })
end)


RegisterNUICallback('appearanceRandomize', function(_, cb)
    local appearance = creationState.appearance

    appearance.mother =
        math.random(21, 41)

    appearance.father =
        math.random(0, 20)

    appearance.resemblance =
        math.random(20, 80) / 100

    appearance.skinMix =
        math.random(20, 80) / 100

    appearance.eyeColor =
        math.random(0, 7)

    for index = 0, 19 do
        appearance.face[index] =
            math.random(-65, 65) / 100
    end

    --
    -- Keep details subtle.
    --

    appearance.ageing =
        math.random(-1, 3)

    appearance.complexion =
        math.random(-1, 3)

    appearance.moles =
        math.random(-1, 4)

    applyAppearance()

    SendNUIMessage({
        action = 'appearanceState',
        appearance = appearance
    })

    cb({
        ok = true
    })
end)


RegisterNUICallback('appearanceRotate', function(data, cb)
    if previewPed and DoesEntityExist(previewPed) then
        local direction = data and data.direction or 0

        previewHeading =
            previewHeading +
            (
                direction > 0
                and 10.0
                or -10.0
            )

        SetEntityHeading(
            previewPed,
            previewHeading
        )

        updatePreviewCamera('face')
    end

    cb({
        ok = true
    })
end)


RegisterNUICallback('appearanceCamera', function(data, cb)
    local mode = data and data.mode or 'face'

    if mode ~= 'body' then
        mode = 'face'
    end

    updatePreviewCamera(mode)

    cb({
        ok = true
    })
end)


RegisterNUICallback('appearanceContinue', function(_, cb)
    creationState.step = 4

    updatePreviewCamera('body')

    SendNUIMessage({
        action = 'step',
        step = 4,
        state = creationState
    })

    cb({
        ok = true
    })
end)


-- =========================================================
-- STEP 4 - FINISH
-- =========================================================

RegisterNUICallback('finishCreation', function(_, cb)
    if creationState.step ~= 4
        or not creationState.gender
        or not creationState.firstName
        or not creationState.lastName
        or not creationState.nationality
        or not creationState.birthdate
    then
        cb({
            ok = false,
            error = 'incomplete'
        })

        return
    end

    local genderValue = creationState.gender == 'female' and 1 or 0

    local created = lib.callback.await(
        'qbx_core:server:createCharacter',
        false,
        {
            firstname = creationState.firstName,
            lastname = creationState.lastName,
            nationality = creationState.nationality,
            birthdate = creationState.birthdate,
            gender = genderValue
        }
    )

    if not created or not created.citizenid then
        cb({
            ok = false,
            error = 'create_failed'
        })

        return
    end

    local appearance =
        previewPed and DoesEntityExist(previewPed)
        and exports['illenium-appearance']:getPedAppearance(previewPed)
        or nil

    if appearance then
        local skinSaved = lib.callback.await(
            'bitirim_ui:server:saveStarterSkin',
            false,
            created.citizenid,
            appearance
        )

        if not skinSaved then
            print(
                '^1[bitirim_ui]^7 Starter skin save failed for ' ..
                created.citizenid ..
                ', continuing with default appearance.'
            )
        end
    end

    --
    -- destroyPreview() reveals the real player ped again, which
    -- was never actually re-modeled/dressed this whole time (only
    -- the separate preview ped was) -- it's still the raw default
    -- GTA ped underneath. Fading out first means that reveal, and
    -- the camera easing back to the default gameplay cam, both
    -- happen behind black instead of flashing on screen for a
    -- moment before bitirim_spawn's own hide-and-teleport setup
    -- takes over.
    --

    DoScreenFadeOut(300)

    while not IsScreenFadedOut() do
        Wait(0)
    end

    destroyPreview()

    --
    -- qbx_core:server:createCharacter already logged this player
    -- in (its own internal Login call). Calling
    -- qbx_core:server:loadCharacter here too -- i.e. going
    -- through beginSpawnHandoff -- would be a SECOND Login for
    -- the same source, which qbx_core treats as a login-twice
    -- exploit and drops the player for. Go straight to the spawn
    -- UI instead.
    --

    triggerSpawnUI(created.citizenid, true)

    closeCreator()

    cb({
        ok = true
    })
end)


RegisterNUICallback('retrySpawnHandoff', function(data, cb)
    local citizenId = data and data.citizenId

    if not citizenId then
        cb({
            ok = false
        })

        return
    end

    --
    -- Same reasoning as finishCreation above: this only ever
    -- retries after a character was already created (and thus
    -- already logged in) earlier in this same session, so it
    -- must not call loadCharacter either.
    --

    triggerSpawnUI(citizenId, true)

    closeCreator()

    cb({
        ok = true
    })
end)


-- =========================================================
-- BACK
-- =========================================================

RegisterNUICallback('back', function(_, cb)
    if creationState.step == 4 then
        creationState.step = 3

        updatePreviewCamera('face')

        SendNUIMessage({
            action = 'step',
            step = 3,
            state = creationState
        })

        cb({ ok = true })
        return
    end

    if creationState.step == 3 then
        creationState.step = 2

        destroyPreview()

        SendNUIMessage({
            action = 'step',
            step = 2,
            state = creationState
        })

        cb({ ok = true })
        return
    end

    if creationState.step == 2 then
        creationState.step = 1

        SendNUIMessage({
            action = 'step',
            step = 1,
            state = creationState
        })

        cb({ ok = true })
        return
    end

    closeCreator()

    cb({ ok = true })
end)


RegisterNUICallback('close', function(_, cb)
    closeCreator()

    cb({
        ok = true
    })
end)


-- =========================================================
-- TEST COMMANDS
-- =========================================================

RegisterCommand('karakterolustur', function()
    openCreator()
end, false)


RegisterCommand('karakterkapat', function()
    closeCreator()
end, false)


exports('OpenCharacterCreator', function()
    openCreator()
end)


exports('CloseCharacterCreator', function()
    closeCreator()
end)


exports('GetCreationState', function()
    return creationState
end)


-- =========================================================
-- CREATOR WORLD PROTECTION
-- =========================================================

CreateThread(function()
    while true do
        if creatorOpen and creationState.step >= 3 then
            Wait(0)

            HideHudAndRadarThisFrame()

            DisableAllControlActions(0)

            EnableControlAction(
                0,
                249,
                true
            )
        else
            Wait(300)
        end
    end
end)


AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    destroyPreview()

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end)


-- =========================================================
-- BOOTSTRAP
-- =========================================================
--
-- Replaces qbx_core's own client/character.lua flow
-- (disabled server-side via config.characters.useExternalCharacters).
-- That file used to be the one starting the solo tutorial
-- session and dismissing the loading screen before showing
-- anything -- since it's fully disabled now, we own that setup
-- too, otherwise the loading screen/NUI stays on top and the
-- live ped preview renders as a black box behind it.
--
-- Returning players skip straight to spawn handoff; brand new
-- accounts open our own creator UI. The tutorial session is
-- ended by bitirim_spawn once qb-spawn:client:setupSpawns
-- actually places the player in the world.
--

CreateThread(function()
    while not NetworkIsSessionStarted() do
        Wait(0)
    end

    --
    -- Vanilla qbx_core always disabled spawnmanager's own
    -- autospawn before doing anything else, so its timer never
    -- raced the character flow and dropped the player in with a
    -- random default ped. We own that responsibility now too.
    --

    pcall(function()
        exports.spawnmanager:setAutoSpawn(false)
    end)

    NetworkStartSoloTutorialSession()

    while not NetworkIsInTutorialSession() do
        Wait(0)
    end

    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()

    --
    -- Deliberately NOT fading in here. The raw connection ped is
    -- still the default GTA model (Michael) with nothing hiding
    -- or repositioning it yet -- fading in this early flashed it
    -- on screen for a second before the creator UI or bitirim_spawn's
    -- own hide-and-position setup ever ran. The screen stays black
    -- (its native starting state) until whichever path actually
    -- needs the world visible fades it in itself, by which point
    -- the real ped is already hidden: createPreviewPed() for new
    -- characters, bitirim_spawn's own setup for returning ones.
    --

    local characters = lib.callback.await(
        'qbx_core:server:getCharacters',
        false
    )

    if characters and characters[1] and characters[1].citizenid then
        print(
            '^3[bitirim_ui]^7 bootstrap: returning player, citizenid=' ..
            tostring(characters[1].citizenid)
        )

        beginSpawnHandoff(characters[1].citizenid)

        return
    end

    print('^3[bitirim_ui]^7 bootstrap: no character found, opening creator')

    openCreator()
end)
