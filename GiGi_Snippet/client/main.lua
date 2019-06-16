local Keys = {
    ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57, 
    ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177, 
    ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
    ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
    ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
    ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70, 
    ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
    ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
    ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

Citizen.CreateThread(function()
    local dict = "missminuteman_1ig_2"

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(100)
    end
    local handsup = false
    while true do
        Citizen.Wait(1)
        if IsControlJustPressed(1, Keys['X']) and GetLastInputMethod(2) and IsPedOnFoot(PlayerPedId()) then --Start holding X
            if not handsup then
                TaskPlayAnim(GetPlayerPed(-1), dict, "handsup_enter", 8.0, 8.0, -1, 50, 0, false, false, false)
                handsup = true
            else
                handsup = false
                ClearPedTasks(GetPlayerPed(-1))
            end
        end
    end
end)

--Pointing
local mp_pointing = false
local keyPressed = false

local function startPointing()
    local ped = GetPlayerPed(-1)
    RequestAnimDict("anim@mp_point")
    while not HasAnimDictLoaded("anim@mp_point") do
        Wait(0)
    end
    SetPedCurrentWeaponVisible(ped, 0, 1, 1, 1)
    SetPedConfigFlag(ped, 36, 1)
    Citizen.InvokeNative(0x2D537BA194896636, ped, "task_mp_pointing", 0.5, 0, "anim@mp_point", 24)
    RemoveAnimDict("anim@mp_point")
end

local function stopPointing()
    local ped = GetPlayerPed(-1)
    Citizen.InvokeNative(0xD01015C7316AE176, ped, "Stop")
    if not IsPedInjured(ped) then
        ClearPedSecondaryTask(ped)
    end
    if not IsPedInAnyVehicle(ped, 1) then
        SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
    end
    SetPedConfigFlag(ped, 36, 0)
    ClearPedSecondaryTask(PlayerPedId())
end

local once = true
local oldval = false
local oldvalped = false

Citizen.CreateThread(function()
    while true do
        Wait(0)

        if once then
            once = false
        end

        if not keyPressed then
            if IsControlPressed(0, 29) and not mp_pointing and IsPedOnFoot(PlayerPedId()) then
                Wait(200)
                if not IsControlPressed(0, 29) then
                    keyPressed = true
                    startPointing()
                    mp_pointing = true
                else
                    keyPressed = true
                    while IsControlPressed(0, 29) do
                        Wait(50)
                    end
                end
            elseif (IsControlPressed(0, 29) and mp_pointing) or (not IsPedOnFoot(PlayerPedId()) and mp_pointing) then
                keyPressed = true
                mp_pointing = false
                stopPointing()
            end
        end

        if keyPressed then
            if not IsControlPressed(0, 29) then
                keyPressed = false
            end
        end
        if Citizen.InvokeNative(0x921CE12C489C4C41, PlayerPedId()) and not mp_pointing then
            stopPointing()
        end
        if Citizen.InvokeNative(0x921CE12C489C4C41, PlayerPedId()) then
            if not IsPedOnFoot(PlayerPedId()) then
                stopPointing()
            else
                local ped = GetPlayerPed(-1)
                local camPitch = GetGameplayCamRelativePitch()
                if camPitch < -70.0 then
                    camPitch = -70.0
                elseif camPitch > 42.0 then
                    camPitch = 42.0
                end
                camPitch = (camPitch + 70.0) / 112.0

                local camHeading = GetGameplayCamRelativeHeading()
                local cosCamHeading = Cos(camHeading)
                local sinCamHeading = Sin(camHeading)
                if camHeading < -180.0 then
                    camHeading = -180.0
                elseif camHeading > 180.0 then
                    camHeading = 180.0
                end
                camHeading = (camHeading + 180.0) / 360.0

                local blocked = 0
                local nn = 0

                local coords = GetOffsetFromEntityInWorldCoords(ped, (cosCamHeading * -0.2) - (sinCamHeading * (0.4 * camHeading + 0.3)), (sinCamHeading * -0.2) + (cosCamHeading * (0.4 * camHeading + 0.3)), 0.6)
                local ray = Cast_3dRayPointToPoint(coords.x, coords.y, coords.z - 0.2, coords.x, coords.y, coords.z + 0.2, 0.4, 95, ped, 7);
                nn,blocked,coords,coords = GetRaycastResult(ray)

                Citizen.InvokeNative(0xD5BB4025AE449A4E, ped, "Pitch", camPitch)
                Citizen.InvokeNative(0xD5BB4025AE449A4E, ped, "Heading", camHeading * -1.0 + 1.0)
                Citizen.InvokeNative(0xB0A6CFD2C69C1088, ped, "isBlocked", blocked)
                Citizen.InvokeNative(0xB0A6CFD2C69C1088, ped, "isFirstPerson", Citizen.InvokeNative(0xEE778F8C7E1142E2, Citizen.InvokeNative(0x19CAFA3C87F7C2FF)) == 4)
            end
        end
    end
end)

--Crouch
local crouched = false

Citizen.CreateThread( function()
    while true do 
        Citizen.Wait(1)

        local ped = GetPlayerPed(-1)

        if (DoesEntityExist(ped) and not IsEntityDead(ped)) then
            DisableControlAction( 0, 36, true ) -- INPUT_DUCK

            if (not IsPauseMenuActive()) then 
                if (IsDisabledControlJustPressed(0, 36)) then
                    RequestAnimSet("move_ped_crouched")

                    while (not HasAnimSetLoaded("move_ped_crouched")) do
                        Citizen.Wait(100)
                    end

                    if (crouched == true) then 
                        ResetPedMovementClipset(ped, 0)
                        crouched = false 
                    elseif (crouched == false) then
                        SetPedMovementClipset(ped, "move_ped_crouched", 0.25)
                        crouched = true
                    end
                end
            end
        end
    end
end)

--Npc Populacao + Retirar Npc da Policia
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0) 
                SetVehicleDensityMultiplierThisFrame(0.2) --Seleciona densidade do trafico
		SetPedDensityMultiplierThisFrame(0.1) --seleciona a densidade de Npc
		SetRandomVehicleDensityMultiplierThisFrame(0.3) --seleciona a densidade de viaturas estacionadas a andar etc
		SetParkedVehicleDensityMultiplierThisFrame(0.3) --seleciona a densidade de viaturas estacionadas
		SetScenarioPedDensityMultiplierThisFrame(1.0, 1.0) --seleciona a densidade de Npc a andar pela cidade
		SetGarbageTrucks(false) --Desactiva os Camioes do Lixo de dar Spawn Aleatoriamente
		SetRandomBoats(false) --Desactiva os Barcos de dar Spawn na agua
                SetCreateRandomCops(false) --Desactiva a Policia a andar pela cidade
		SetCreateRandomCopsNotOnScenarios(false) --Para o Spanw Aleatorio de Policias Fora do Cenario
		SetCreateRandomCopsOnScenarios(false) --Para o Spanw Aleatorio de Policias no Cenario
                DisablePlayerVehicleRewards(PlayerId()) --Nao mexer --> Impossibilita que os players possam ganhar armas nas viaturas da policia e ems
                local x,y,z = table.unpack(GetEntityCoords(PlayerPedId()))
		ClearAreaOfVehicles(x, y, z, 1000, false, false, false, false, false)
		RemoveVehiclesFromGeneratorsInArea(x - 500.0, y - 500.0, z - 500.0, x + 500.0, y + 500.0, z + 500.0);
	    end
        end)

--No Aim + Snipper Aim
Citizen.CreateThread(function()
    local isSniper = true
    while true do
        Citizen.Wait(11)
        local ped = GetPlayerPed(-1)
		local currentWeaponHash = GetSelectedPedWeapon(ped)

        if currentWeaponHash == 100416529 then
            isSniper = true
        elseif currentWeaponHash == 205991906 then
            isSniper = true
        elseif currentWeaponHash == -952879014 then
            isSniper = true
        elseif currentWeaponHash == GetHashKey('WEAPON_SNIPERRIFLE') then
            isSniper = true
        else
            isSniper = false
         end

        if not isSniper then
            HideHudComponentThisFrame(14)
         end
     end
end)

--Disable Dispatch
Citizen.CreateThread(function()
	for i = 1, 15 do
	    EnableDispatchService(i, false)
	end
    end)  

--NODROPNPC
Citizen.CreateThread(function()
    while true do
      Citizen.Wait(1)
      RemoveAllPickupsOfType(0xDF711959) -- Carbine rifle
      RemoveAllPickupsOfType(0xF9AFB48F) -- Pistol
      RemoveAllPickupsOfType(0xA9355DCD) -- Pumpshotgun
    end
  end)
