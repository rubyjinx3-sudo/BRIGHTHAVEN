local Locations={}
Locations.List={
    {Id="home",Name="My Home",Path={"BrighthavenHomes","StarterHome","Entry"}},
    {Id="hall",Name="Barangay Hall",Path={"BrighthavenPrototype","Locations_1_2","Location1_BarangayHall","CaptainKapaPrompt"}},
    {Id="school",Name="School",Path={"BrighthavenPrototype","Locations_1_2","Location2_SchoolEvacuation","SchoolVolunteerPrompt"}},
    {Id="clinic",Name="Clinic",Path={"BrighthavenStoryExtension","clinic","HelperAnchor"}},
    {Id="train",Name="Train Station",Path={"BrighthavenStoryExtension","train","HelperAnchor"}},
    {Id="dumpsite",Name="Recycling Yard",Path={"BrighthavenStoryExtension","dumpsite","HelperAnchor"}},
    {Id="wood",Name="Wood Yard",Path={"BrighthavenStoryExtension","wood","HelperAnchor"}},
    {Id="shop",Name="General Store",Path={"BrighthavenStoryExtension","shop","HelperAnchor"}},
    {Id="power",Name="Power Station",Path={"BrighthavenStoryExtension","power","HelperAnchor"}},
    {Id="lab",Name="Weather Lab",Path={"BrighthavenStoryExtension","lab","HelperAnchor"}},
    {Id="basketball",Name="Basketball Court",Path={"BrighthavenFilipinoNeighborhood","BarangayBasketballCourt"}},
    {Id="store1",Name="Sari-Sari Store 1",Path={"BrighthavenFilipinoNeighborhood","SariSariStore_1"}},
    {Id="store2",Name="Sari-Sari Store 2",Path={"BrighthavenFilipinoNeighborhood","SariSariStore_2"}},
    {Id="store3",Name="Sari-Sari Store 3",Path={"BrighthavenFilipinoNeighborhood","SariSariStore_3"}},
    {Id="store4",Name="Sari-Sari Store 4",Path={"BrighthavenFilipinoNeighborhood","SariSariStore_4"}},
}
table.insert(Locations.List,{Id="practice",Name="Palengke / Community Games",Path={"BarangayCommunityBlocks","CommunityGameHub","MapAnchor"}})
Locations.ById={}
for _,location in ipairs(Locations.List) do Locations.ById[location.Id]=location end
function Locations.Position(location)
    if type(location)=="string" then location=Locations.ById[location] end
    if not location then return nil end
    local object=workspace
    for _,name in ipairs(location.Path) do object=object:FindFirstChild(name);if not object then return nil end end
    if object:IsA("BasePart") then return object.Position end
    if object:IsA("Model") then return object:GetPivot().Position end
    local part=object:FindFirstChildWhichIsA("BasePart",true)
    return part and part.Position
end
function Locations.ValidPoint(point)
    return typeof(point)=="Vector3" and point.X==point.X and point.Y==point.Y and point.Z==point.Z
        and math.abs(point.X)<1200 and math.abs(point.Z)<1100 and point.Y>=-150 and point.Y<=-125
end
return Locations

