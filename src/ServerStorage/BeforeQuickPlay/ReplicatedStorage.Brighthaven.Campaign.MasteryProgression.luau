local Side=require(game.ReplicatedStorage.Brighthaven.Campaign.SideQuestData)
local Mastery={}
Mastery.Games={
    school={Level=1,Practice=0},
    dumpsite={Level=2,Practice=2},
    wood={Level=3,Practice=4},
    train={Level=4,Practice=6},
    clinic={Level=5,Practice=8},
    shop={Level=6,Practice=10},
    power={Level=7,Practice=12},
    lab={Level=8,Practice=13},
}
function Mastery.Tasks(profile)
    local count=profile.SchoolComplete and 1 or 0
    for node in pairs(Mastery.Games) do
        if node~="school" and node~="lab" and profile.Nodes and profile.Nodes[node] then count+=1 end
    end
    for _,quest in ipairs(Side.Quests) do
        local progress=profile.SideQuests and profile.SideQuests[quest.Id]
        if progress and progress.Complete then count+=1 end
    end
    for _,done in pairs(profile.LabRounds or {}) do if done==true then count+=1 end end
    return count
end
function Mastery.Gate(profile,node,stats)
    local required=Mastery.Games[node] or {Level=1,Practice=0}
    local tasks=Mastery.Tasks(profile)
    local xpNeeded=math.max(0,(required.Level-1)*100-stats.XP)
    local jobsNeeded=math.max(0,required.Practice-tasks)
    local complete=node=="school" and profile.SchoolComplete or profile.Nodes and profile.Nodes[node]
    local ready=complete or profile.MasteryResumeNode==node or xpNeeded==0 and jobsNeeded==0
    local reason=""
    if not ready then
        if xpNeeded>0 then
            reason="Reach Helper Level "..required.Level..". Earn "..xpNeeded.." more XP by finishing division jobs with neighbors."
        else
            reason="Finish "..jobsNeeded.." more division job"..(jobsNeeded==1 and "" or "s").." with neighbors. Share in equal chunks and check your work."
        end
    end
    return {RequiredLevel=required.Level,RequiredPractice=required.Practice,PracticeCount=tasks,
        XPNeeded=xpNeeded,JobsNeeded=jobsNeeded,Ready=ready==true,Reason=reason}
end
return Mastery
