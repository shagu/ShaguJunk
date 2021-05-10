local gfind = string.gmatch or string.gfind

do -- config
  ShaguJunk_vendor = ShaguJunk_vendor or {}
  ShaguJunk_delete = ShaguJunk_delete or {}

  SLASH_SHAGUJUNK1, SLASH_SHAGUJUNK2, SLASH_SHAGUJUNK3 = "/sjunk", "/junk", "/sj"
  SlashCmdList["SHAGUJUNK"] = function(message)
    local commandlist = { }
    local command

    for command in gfind(message, "[^ ]+") do
      table.insert(commandlist, string.lower(command))
    end

    -- add vendor entry
    if commandlist[1] == "vendor" then
      local addstring = table.concat(commandlist," ",2)
      if addstring == "" then return end

      -- support item links
      local _, _, itemLink = string.find(addstring, "(item:%d+:%d+:%d+:%d+)")
      local itemName = itemLink and GetItemInfo(itemLink)

      addstring = itemName or addstring

      table.insert(ShaguJunk_vendor, string.lower(addstring))
      DEFAULT_CHAT_FRAME:AddMessage("=> adding |cff33ffcc".. addstring .."|r to your vendor list")

    -- add delete entry
  elseif commandlist[1] == "delete" then
      local addstring = table.concat(commandlist," ",2)
      if addstring == "" then return end

      -- support item links
      local _, _, itemLink = string.find(addstring, "(item:%d+:%d+:%d+:%d+)")
      local itemName = itemLink and GetItemInfo(itemLink)

      addstring = itemName or addstring

      table.insert(ShaguJunk_delete, string.lower(addstring))
      DEFAULT_CHAT_FRAME:AddMessage("=> adding |cff33ffcc".. addstring .."|r to your delete list")

    -- remove entry
    elseif commandlist[1] == "rm" then
      local vendor = tonumber(commandlist[2])
      local delete = tonumber(commandlist[2]) - table.getn(ShaguJunk_vendor)

      if ShaguJunk_vendor[vendor] then
        DEFAULT_CHAT_FRAME:AddMessage("=> Removing entry " .. commandlist[2]
          .. " (" .. ShaguJunk_vendor[vendor]
          .. ") from your vendor list")

        table.remove(ShaguJunk_vendor, vendor)

      elseif ShaguJunk_delete[delete] then
        DEFAULT_CHAT_FRAME:AddMessage("=> Removing entry " .. commandlist[2]
          .. " (" .. ShaguJunk_delete[delete]
          .. ") from your deletion list")

        table.remove(ShaguJunk_delete, delete)
      end
    elseif commandlist[1] == "ls" then
      DEFAULT_CHAT_FRAME:AddMessage("|cff33ee33Vendor Items:")
      for id, hl in pairs(ShaguJunk_vendor) do
        DEFAULT_CHAT_FRAME:AddMessage(" |r[|cff33ee33"..id.."|r] "..hl)
        printID = id
      end
      DEFAULT_CHAT_FRAME:AddMessage("|cffaa3333Delete Items:")
      for id, hl in pairs(ShaguJunk_delete) do
        DEFAULT_CHAT_FRAME:AddMessage(" |r[|cffee3333"..id+printID.."|r] "..hl)
      end
    else
      DEFAULT_CHAT_FRAME:AddMessage("ShaguJunk Usage:")
      DEFAULT_CHAT_FRAME:AddMessage("|cffaaffdd/sjunk vendor Fel Iron Blood Ring|cffaaaaaa - |rAutomatically vendors Fel Iron Rings")
      DEFAULT_CHAT_FRAME:AddMessage("|cffaaffdd/sjunk delete Light Hide|cffaaaaaa - |rAutomatically deletes Light Hide")
      DEFAULT_CHAT_FRAME:AddMessage("|cffaaffdd/sjunk rm 3|cffaaaaaa - |rRemoves entry '3' of your list")
      DEFAULT_CHAT_FRAME:AddMessage("|cffaaffdd/sjunk ls|cffaaaaaa - |rDisplays your current list")
    end
  end
end

do -- autovendor
  local autovendor = CreateFrame("Frame")
  autovendor:Hide()

  autovendor:RegisterEvent("MERCHANT_SHOW")
  autovendor:RegisterEvent("MERCHANT_CLOSED")
  autovendor:SetScript("OnEvent", function()
    if event == "MERCHANT_CLOSED" then
      autovendor.merchant = nil
      autovendor:Hide()
    elseif event == "MERCHANT_SHOW" then
      autovendor.merchant = true
      autovendor:Show()
    end
  end)

  autovendor:SetScript("OnUpdate", function()
    -- throttle to to one item per .1 second
    if ( this.tick or 1) > GetTime() then return else this.tick = GetTime() + .1 end

    -- iterate through bag
    for bag = 0, 4, 1 do
      for slot = 1, GetContainerNumSlots(bag), 1 do
        local rawlink = GetContainerItemLink(bag, slot)
        local _, _, link = string.find((rawlink or ""), "(item:%d+:%d+:%d+:%d+)")
        local name = link and string.lower(GetItemInfo(link))

        if name then
          for i, vendor in pairs(ShaguJunk_vendor) do
            -- abort if the merchant window disappeared
            if not this.merchant then return end

            if name == vendor then
              -- clear cursor and sell the item
              ClearCursor()
              UseContainerItem(bag, slot)
              -- continue next update
              return
            end
          end
        end
      end
    end

    -- stop processing
    this:Hide()
  end)
end

do -- autodelete
  local autodelete = CreateFrame("Frame")
  autodelete:Hide()

  autodelete:RegisterEvent("ITEM_PUSH")
  autodelete:SetScript("OnEvent", function()
    autodelete:Show()
  end)

  autodelete:SetScript("OnUpdate", function()
    -- throttle to to one item per .1 second
    if ( this.tick or 1) > GetTime() then return else this.tick = GetTime() + .1 end

    -- iterate through bag
    for bag = 0, 4, 1 do
      for slot = 1, GetContainerNumSlots(bag), 1 do
        local rawlink = GetContainerItemLink(bag, slot)
        local _, _, link = string.find((rawlink or ""), "(item:%d+:%d+:%d+:%d+)")
        local name = link and string.lower(GetItemInfo(link))

        if name then
          for i, vendor in pairs(ShaguJunk_delete) do
            if name == vendor then
              -- clear cursor and delete the item
              ClearCursor()
              PickupContainerItem(bag, slot)
              DeleteCursorItem()
              -- continue next update
              return
            end
          end
        end
      end
    end

    -- stop processing
    this:Hide()
  end)
end
