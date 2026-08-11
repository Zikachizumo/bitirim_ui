local creatorOpen = false

local previewPed = nil
local previewCam = nil
local previewHeading = 180.0
local hiddenPlayerPed = nil

local creationState = {
    step = 1,
    gender = nil,
    firstName = nil,
    lastName = nil,

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

    local cameraDistance
    local cameraHeight
    local targetHeight
    local targetHorizontalOffset
    local fov

    if mode == 'body' then

        cameraDistance = 3.15
        cameraHeight = 1.05

        targetHeight = 0.95

        targetHorizontalOffset = -1.05

        fov = 31.0

    else

        --
        -- FACE / HERITAGE / DETAILS
        --

        cameraDistance = 1.55
        cameraHeight = 1.62

        targetHeight = 1.58

        targetHorizontalOffset = -0.55

        fov = 29.0

    end


    local cameraCoords =
        GetOffsetFromEntityInWorldCoords(
            previewPed,
            0.0,
            cameraDistance,
            cameraHeight
        )


    local targetCoords =
        GetOffsetFromEntityInWorldCoords(
            previewPed,
            targetHorizontalOffset,
            0.0,
            targetHeight
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
        ('^3[bitirim_ui]^7 Preview camera: %s | targetX %.2f | targetZ %.2f')
        :format(
            mode,
            targetHorizontalOffset,
            targetHeight
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

    local coords = GetEntityCoords(playerPed)

    previewHeading = 180.0

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
        ('^2[bitirim_ui]^7 Preview ped created. Entity: %s | Model: %s')
        :format(
            previewPed,
            modelName
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

    return true
end


-- =========================================================
-- CREATOR OPEN/CLOSE
-- =========================================================

local function openCreator()
    if creatorOpen then
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
