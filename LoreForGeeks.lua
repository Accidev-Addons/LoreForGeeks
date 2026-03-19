local NPC_ID = 79003
local QUEST_NAME = "Шкатулка мудрости"
local cachedAnswer = nil
local questActive = false

local function IsQuestNPC()
    local guid = UnitGUID("npc")
    if not guid then return false end
    if C_GUID and C_GUID.GetObjectID then
        return C_GUID.GetObjectID(guid) == NPC_ID
    end
    return tonumber(guid:sub(-12, -7), 16) == NPC_ID
end

local function ClosePopup()
    for i = 1, STATICPOPUP_NUMDIALOGS do
        local popup = _G["StaticPopup" .. i]
        if popup and popup:IsShown() and popup.editBox and popup.editBox:IsShown() then
            popup:Hide()
            return
        end
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("GOSSIP_SHOW")
f:RegisterEvent("QUEST_DETAIL")
f:RegisterEvent("GOSSIP_ENTER_CODE")
f:RegisterEvent("QUEST_PROGRESS")
f:RegisterEvent("QUEST_COMPLETE")

f:SetScript("OnEvent", function(self, event, ...)
    if event == "GOSSIP_SHOW" then
        if not IsQuestNPC() then return end

        local numAvailable = GetNumGossipAvailableQuests()
        if numAvailable > 0 then
            local quests = {GetGossipAvailableQuests()}
            for i = 1, numAvailable do
                local title = quests[(i - 1) * 5 + 1]
                if title and title:find(QUEST_NAME) then
                    SelectGossipAvailableQuest(i)
                    return
                end
            end
        end

        local options = {GetGossipOptions()}
        for i = 1, #options, 2 do
            if options[i] and options[i]:find("Ответить") then
                SelectGossipOption((i + 1) / 2)
                return
            end
        end

        local numActive = GetNumGossipActiveQuests()
        if numActive > 0 then
            local quests = {GetGossipActiveQuests()}
            for i = 1, numActive do
                local title = quests[(i - 1) * 4 + 1]
                if title and title:find(QUEST_NAME) then
                    SelectGossipActiveQuest(i)
                    return
                end
            end
        end

    elseif event == "QUEST_DETAIL" then
        local title = GetTitleText()
        if title and title:find(QUEST_NAME) then
            cachedAnswer = LoreForGeeks_FindAnswer(GetQuestText())
            if cachedAnswer then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[LFG]|r Ответ: |cFFFFFF00" .. cachedAnswer .. "|r")
            end
            AcceptQuest()
        end

    elseif event == "GOSSIP_ENTER_CODE" then
        if not IsQuestNPC() then return end
        if not cachedAnswer then
            cachedAnswer = LoreForGeeks_FindAnswer(GetQuestText())
        end
        if cachedAnswer then
            SelectGossipOption(..., cachedAnswer, true)
            ClosePopup()
            cachedAnswer = nil
            questActive = true
        end

    elseif event == "QUEST_PROGRESS" then
        if not questActive then return end
        if (GetTitleText() or ""):find(QUEST_NAME) then
            CompleteQuest()
        end

    elseif event == "QUEST_COMPLETE" then
        if not questActive then return end
        if (GetTitleText() or ""):find(QUEST_NAME) then
            GetQuestReward()
            questActive = false
        end
    end
end)
