local function toggleNuiFrame(shouldShow)
  SetNuiFocus(shouldShow, shouldShow)
  SendReactMessage('setVisible', shouldShow)
end

RegisterCommand('radioDebug', function()
    print('Primary Radio', LocalPlayer.state.primRadioChannel)
    print('Primary Radio unmuted', LocalPlayer.state.primRadioEnabled)
    print('Secondary Radio', LocalPlayer.state.secRadioChannel)
    print('Primary Radio unmuted', LocalPlayer.state.secRadioEnabled)
    print('Tertiary Radio', LocalPlayer.state.terRadioChannel)
    print('Primary Radio unmuted', LocalPlayer.state.terRadioEnabled)
    print('Radio Volume', LocalPlayer.state['radio'])
end)

--------------------------------------------------------
local config = require 'config.client'
local sharedConfig = require 'config.shared'

local primRadioChannel, secRadioChannel, terRadioChannel = nil, nil, nil
local primRadioConnected, secRadioConnected, terRadioConnected = false, false, false

local radioVolume = LocalPlayer.state['radio'] or 50

local micClicks = config.defaultMicClicks

local radioOn = false

local radioMenu = false

function OpenRadio()
    local RadioData = {
        primRadioData = {
            value = primRadioChannel,
            connected = primRadioConnected,
            radioType = 'prim',
            muted = not LocalPlayer.state['primRadioEnabled'] or false
        },
        secRadioData = {
            value = secRadioChannel,
            connected = secRadioConnected,
            radioType = 'sec',
            muted = not LocalPlayer.state['secRadioEnabled'] or false
        },
        terRadioData = {
            value = terRadioChannel,
            connected = terRadioConnected,
            radioType = 'ter',
            muted = not LocalPlayer.state['terRadioEnabled'] or false
        },
        radioVolume = radioVolume
    }

    print(json.encode(RadioData, {indent = true}))
    SendReactMessage('radio:initData', RadioData)
    toggleNuiFrame(true)
end

local function toggleRadio(toggle)
    radioMenu = toggle
    SetNuiFocus(radioMenu, radioMenu)
    if radioMenu then
        exports.scully_emotemenu:playEmoteByCommand('wt')
        local RadioData = {
            primRadioData = {
                value = primRadioChannel,
                connected = primRadioConnected,
                radioType = 'prim',
                muted = not LocalPlayer.state['primRadioEnabled'] or true
            },
            secRadioData = {
                value = secRadioChannel,
                connected = secRadioConnected,
                radioType = 'sec',
                muted = not LocalPlayer.state['secRadioEnabled'] or true
            },
            terRadioData = {
                value = terRadioChannel,
                connected = terRadioConnected,
                radioType = 'ter',
                muted = not LocalPlayer.state['terRadioEnabled'] or true
            },
            radioVolume = radioVolume
        }

        print(json.encode(RadioData, {indent = true}))
        SendReactMessage('radio:initData', RadioData)
        toggleNuiFrame(true)
    else
        exports.scully_emotemenu:cancelEmote()
    end
end

local function updateUI(rType)
    local data = {}

    if rType == 'prim' then
        data.value = primRadioChannel
        data.connected = primRadioConnected
        data.muted = not LocalPlayer.state['primRadioEnabled'] or false
    elseif rType == 'sec' then
        data.value = secRadioChannel
        data.connected = secRadioConnected
        data.muted = not LocalPlayer.state['secRadioEnabled'] or false
    elseif rType == 'ter' then
        data.value = terRadioChannel
        data.connected = terRadioConnected
        data.muted = not LocalPlayer.state['terRadioEnabled'] or false
    end

    data.rType = rType

    print('Updated Radio', json.encode(data, {indent = true}))
    SendReactMessage('radio:updateUI', data)
end

local function leaveAllChannels()
    qbx.playAudio({
        audioName = 'End_Squelch',
        audioRef = 'CB_RADIO_SFX',
        source = cache.ped
    })
    exports.qbx_core:Notify(locale('left_channel'), 'error')
    exports['pma-voice']:setRadioChannel(0, 'primRadio')
    primRadioChannel = nil
    exports['pma-voice']:setRadioChannel(0, 'secRadio')
    secRadioChannel = nil
    exports['pma-voice']:setRadioChannel(0, 'terRadio')
    terRadioChannel = nil

    primRadioConnected, secRadioConnected, terRadioConnected = false, false, false

    updateUI('prim')
    updateUI('sec')
    updateUI('ter')
    --exports['pma-voice']:setVoiceProperty('radioEnabled', false)
end

local function powerButton()
    radioOn = not radioOn
    exports['pma-voice']:setVoiceProperty('radioEnabled', radioOn)
    if not radioOn then
        leaveAllChannels()
    end
end

RegisterNUICallback('radio:toggleRadio', function(_, cb)
    qbx.playAudio({
        audioName = "On_High",
        audioRef = 'MP_RADIO_SFX',
        source = cache.ped
    })
    powerButton()
    cb(radioOn and 'on' or 'off')
end)

RegisterNUICallback('radio:updateVolume', function(data, cb)
    if not radioOn then return cb('ok') end

    local updatedVolume = data.volume

    if radioVolume == updatedVolume or updatedVolume > 100 then return cb('ok') end

    radioVolume = updatedVolume
    exports.qbx_core:Notify(locale('new_volume')..radioVolume, 'success')
    exports['pma-voice']:setRadioVolume(radioVolume)
    cb('ok')
end)

RegisterNUICallback('radio:handleMute', function(data, cb)
    if not radioOn then return cb('ok') end

    local rType = data.radio

    if rType == 'prim' then
      local curr = LocalPlayer.state['primRadioEnabled']
      LocalPlayer.state:set('primRadioEnabled', not curr, true)
    elseif rType == 'sec' then
      local curr = LocalPlayer.state['secRadioEnabled']
      LocalPlayer.state:set('secRadioEnabled', not curr, true)
    elseif rType == 'ter' then
      local curr = LocalPlayer.state['terRadioEnabled']
      LocalPlayer.state:set('terRadioEnabled', not curr, true)
    end
    print('Updated Channel Mute', rType)
    Wait(100)
    updateUI(rType)

    cb('ok')
end)

RegisterNUICallback('radio:changeChannel', function(data, cb)
    print('Channel Change Started', json.encode(data))
    if not radioOn then 
      print('Radio is OFF')
      return cb('0') 
    end

    local rType = data.radio
    local rChannel = tonumber(data.channel)

    print(rType, rChannel)

    if rChannel == 0 or rChannel == nil then
      if rType == 'prim' and primRadioConnected then
          exports['pma-voice']:setRadioChannel(0, 'primRadio')
          primRadioChannel = nil
          primRadioConnected = false
          exports.qbx_core:Notify('Left Primary Channel', 'success')
          updateUI(rType)
          return
      elseif rType == 'sec' and secRadioConnected then
          exports['pma-voice']:setRadioChannel(0, 'secRadio')
          secRadioChannel = nil
          secRadioConnected = false
          exports.qbx_core:Notify('Left Secondary Channel', 'success')
          updateUI(rType)
          return
      elseif rType == 'ter' and terRadioConnected then
          exports['pma-voice']:setRadioChannel(0, 'terRadio')
          terRadioChannel = nil
          terRadioConnected = false
          exports.qbx_core:Notify('Left Primary Channel', 'success')
          updateUI(rType)
          return
      else
          return
      end
    end
    
    if rChannel > config.maxFrequency then 
        exports.qbx_core:Notify(locale('invalid_channel'), 'error')
        return cb('0')
    end

    rChannel = qbx.math.round(rChannel, config.decimalPlaces)

    if rType == 'prim' and primRadioChannel == rChannel then
        exports.qbx_core:Notify(locale('on_channel'), 'error')
        cb('ok')
        return
    end

    if rType == 'sec' and secRadioChannel == rChannel then
        exports.qbx_core:Notify(locale('on_channel'), 'error')
        cb('ok')
        return
    end

    if rType == 'ter' and terRadioChannel == rChannel then
        exports.qbx_core:Notify(locale('on_channel'), 'error')
        cb('ok')
        return
    end

    if rChannel == primRadioChannel or rChannel == secRadioChannel or rChannel == terRadioChannel then
        exports.qbx_core:Notify(locale('on_channel'), 'error')
        cb('ok')
        return
    end

    local frequency = not sharedConfig.whitelistSubChannels and math.floor(rChannel) or rChannel

    if sharedConfig.restrictedChannels[frequency] and (not sharedConfig.restrictedChannels[frequency][QBX.PlayerData.job.name] or not QBX.PlayerData.job.onduty) then
        exports.qbx_core:Notify(locale('restricted_channel'), 'error')
        cb('ok')
        return
    end

    if rType == 'prim' then
        exports['pma-voice']:setRadioChannel(rChannel, 'primRadio')
        primRadioChannel = rChannel
        primRadioConnected = true
        exports.qbx_core:Notify('Connected Primary Radio To :'..primRadioChannel, 'success')
    elseif rType == 'sec' then
        exports['pma-voice']:setRadioChannel(rChannel, 'secRadio')
        secRadioChannel = rChannel
        secRadioConnected = true
        exports.qbx_core:Notify('Connected Primary Radio To :'..secRadioChannel, 'success')
    elseif rType == 'ter' then
        exports['pma-voice']:setRadioChannel(rChannel, 'terRadio')
        terRadioChannel = rChannel
        terRadioConnected = true
        exports.qbx_core:Notify('Connected Primary Radio To :'..terRadioChannel, 'success')
    else
        return
    end

    qbx.playAudio({
        audioName = 'Start_Squelch',
        audioRef = 'CB_RADIO_SFX',
        source = cache.ped
    })

    updateUI(rType)
    cb('ok')
end)

RegisterNUICallback('hideFrame', function(_, cb)
    toggleNuiFrame(false)
    toggleRadio(false)
    cb({})
end)

local function isRadioOn()
    return radioOn
end

exports('IsRadioOn', isRadioOn)

AddEventHandler('ox_inventory:itemCount', function(itemName, totalCount)
    if itemName ~= 'radio' then return end
    if totalCount <= 0 and radioChannel ~= 0 then
        powerButton()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    exports['pma-voice']:setVoiceProperty("micClicks", config.defaultMicClicks)
end)

-- Resets state on logout, in case of character change.
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    powerButton()
end)

RegisterNetEvent('qbx_radio:client:use', function()
    toggleRadio(not radioMenu)
end)

RegisterNetEvent('qbx_radio:client:onRadioDrop', function()
    if radioChannel ~= 0 then
        powerButton()
    end
end)

if config.leaveOnDeath then
    AddStateBagChangeHandler('isDead', ('player:%s'):format(cache.serverId), function(_, _, value)
        if value and radioOn then
            leaveAllChannels()
        end
    end)
end

AddEventHandler('onResourceStart', function(resource)
    if resource ~= cache.resource then return end
    exports['pma-voice']:setVoiceProperty("micClicks", config.defaultMicClicks)
    exports['pma-voice']:setVoiceProperty('radioEnabled', false)
end)

