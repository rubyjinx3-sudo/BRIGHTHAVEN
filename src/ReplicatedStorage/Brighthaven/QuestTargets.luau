local folder = game.ReplicatedStorage.Brighthaven
local Quests = require(folder.Campaign.QuestData)
local Side = require(folder.Campaign.SideQuestData)
local Targets = {}

function Targets.Resolve(player, state, kind, id)
    if not state then return nil end
    if kind == "side" then
        local quest = Side.ById[id]
        local progress = state.SideQuests and state.SideQuests[id]
        if not quest or not (state.SideDiscovered and state.SideDiscovered[id]) or (progress and progress.Complete) then return nil end
        local anchor = Side.Anchor(quest)
        if not anchor then return nil end
        if state.SideActiveId == id and quest.Kind == "collect" and progress and not Side.Ready(quest, progress) then
            local group = workspace:FindFirstChild("BrighthavenSideQuests")
            group = group and group:FindFirstChild(id)
            for _,item in ipairs(quest.Items) do
                if not progress.Items[item.Id] then
                    local model = group and group:FindFirstChild(item.Id)
                    if model and model.PrimaryPart then return model.PrimaryPart, item.Name, quest.Title end
                    break
                end
            end
        end
        return anchor, quest.Speaker, quest.Title
    end
    if kind ~= "story" or state.StoryFinished then return nil end
    local quest = Quests.Current(state)
    if id ~= quest.Id then return nil end
    local locations = workspace.BrighthavenPrototype.Locations_1_2
    if player:GetAttribute("CaptainMetThisVisit") ~= true or quest.Id == "captain" or quest.Id == "home" then
        return locations.Location1_BarangayHall.CaptainKapaPrompt, "Captain Kappa", quest.Title
    end
    if quest.Id == "school" then
        if player:GetAttribute("SchoolShuttleArrived") ~= true then
            return workspace.BrighthavenSchoolShuttle.Stops.HallBoarding, "School Shuttle", quest.Title
        end
        return locations.Location2_SchoolEvacuation.SchoolVolunteerPrompt, quest.Helper, quest.Title
    end
    local area = workspace.BrighthavenStoryExtension:FindFirstChild(quest.Id)
    return area and area:FindFirstChild("HelperAnchor"), quest.Helper, quest.Title
end

return Targets
