local HttpService=game:GetService("HttpService")
local Review={}
local limit=12
local types={Division=true,Multiplication=true,Subtraction=true,["Skip counting"]=true,Remainders=true,Budgeting=true,Boost=true}
local function numeric(value)
    local n=tonumber(value)
    return n and n==n and math.abs(n)<=1000000 and n or nil
end
function Review.Merge(left,right)
    local result={Counts={},Recent={}}
    local seen={}
    for _,saved in ipairs({left or false,right or false}) do
        if type(saved)=="table" then
            for skill in pairs(types) do
                local count=type(saved.Counts)=="table" and numeric(saved.Counts[skill])
                if count and count>0 then result.Counts[skill]=math.max(result.Counts[skill] or 0,math.floor(count)) end
            end
            for _,item in ipairs(type(saved.Recent)=="table" and saved.Recent or {}) do
                if type(item)=="table" and type(item.Id)=="string" and not seen[item.Id] and types[item.Skill]
                    and type(item.Label)=="string" and type(item.At)=="number" and item.At>0 and item.At<math.huge
                    and numeric(item.Answer) and numeric(item.Expected) then
                    seen[item.Id]=true
                    table.insert(result.Recent,{Id=item.Id:sub(1,36),Skill=item.Skill,Label=item.Label:sub(1,72),
                        Answer=numeric(item.Answer),Expected=numeric(item.Expected),
                        Extra=numeric(item.Extra),ExpectedExtra=numeric(item.ExpectedExtra),At=item.At})
                end
            end
        end
    end
    table.sort(result.Recent,function(a,b)
        return a.At>b.At or a.At==b.At and a.Id<b.Id
    end)
    while #result.Recent>limit do table.remove(result.Recent) end
    return result
end
function Review.Add(profile,skill,label,answer,expected,extra,expectedExtra)
    answer,expected=numeric(answer),numeric(expected)
    if not types[skill] or not answer or not expected then return end
    extra,expectedExtra=numeric(extra),numeric(expectedExtra)
    if answer==expected and extra==expectedExtra then return end
    local data=profile.AnswerReview or {Counts={},Recent={}}
    profile.AnswerReview=data
    data.Counts[skill]=(data.Counts[skill] or 0)+1
    table.insert(data.Recent,1,{Id=HttpService:GenerateGUID(false),Skill=skill,Label=label:sub(1,72),
        Answer=answer,Expected=expected,Extra=extra,ExpectedExtra=expectedExtra,At=DateTime.now().UnixTimestampMillis})
    if #data.Recent>limit then table.remove(data.Recent) end
end
local reported=Instance.new("BindableEvent")
Review.Reported=reported.Event
function Review.ForPlayer(...) reported:Fire(...) end
return Review
