local RS=game.ReplicatedStorage.Brighthaven
local Titles=require(RS.GameTitles)
local Campaign=require(RS.Campaign.CampaignData)
local School=require(RS.MissionData)
local Side=require(RS.Campaign.SideQuestData)
local Catalog={List={},ById={}}
local function add(entry)
 table.insert(Catalog.List,entry);Catalog.ById[entry.Id]=entry
end
for i,title in ipairs(Titles.Practice) do add({Id='practice_'..i,Title=title,Kind='Practice',PracticeIndex=i,Where='Laro sa Liwasan'}) end
for _,m in ipairs(School.Missions) do add({Id=m.Id,Title=m.Title,Kind='School',Node='school',Where='School courtyard'}) end
for _,m in ipairs(Campaign.Missions) do add({Id=m.Id,Title=m.Title,Kind='Story',Node=m.Node,Where=Campaign.Nodes[m.Node].Title}) end
for _,q in ipairs(Side.Quests) do add({Id=q.Id,Title=q.Title,Kind='Neighbor',Where=q.Speaker}) end
function Catalog.Position(entry)
 if type(entry)=='string' then entry=Catalog.ById[entry] end
 if not entry then return end
 if entry.Kind=='Practice' then return workspace.BarangayCommunityBlocks.CommunityGameHub.MapAnchor.Position end
 if entry.Kind=='School' then return workspace.BrighthavenPrototype.Locations_1_2.Location2_SchoolEvacuation.SchoolVolunteerPrompt.Position end
 if entry.Kind=='Story' then return Campaign.Nodes[entry.Node].Position end
 local anchor=Side.Anchor(Side.ById[entry.Id]);return anchor and anchor.Position
end
return Catalog
