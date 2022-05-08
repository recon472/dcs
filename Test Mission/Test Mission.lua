-- unique mission names that will get randomly chosen
local MissionNamePool = {
"Operation Slip 'N Slide",
"Operation Silver Ghost",
"Operation Purple Gardens",
"Operation Swamp Vengeance",
"Operation Greenhouse",
"Operation Javelin",
"Operation Black Redemption",
"Operation Poker Face",
"Operation Bronze Doom",
"Operation Gray Charger",
"Operation Camouflage",
"Operation Blind Heart",
"Operation Jungle Maniac",
"Operation Orange Avalanche",
"Operation Pink Dust",
"Operation White Freedom",
"Operation Urban Cougar",
"Operation Jungle Champion",
"Operation Predator 'N Prey",
"Operation Bone Picking",
"Operation Swamp Angel",
"Operation Triple Cross",
"Operation Pink Hammer",
"Operation Yellow Thunder",
"Operation Desert Rain",
"Operation Purple Blade",
"Operation Ocean Dust",
"Operation Urban Garden",
"Operation Blue Dryad",
"Operation Silver Eye",
"Operation Constatine",
"Operation Brown Sword",
"Operation Brown Hand",
"Operation Brass Mammoth",
"Operation Seismic Toss",
"Operation Sea Eclipse",
"Operation Silver Lion",
"Operation Rock And Roast",
"Operation Sea Giant",
"Operation Urban Eyes",
"Operation Pink Redemption",
"Operation Blue Rhino",
"Operation Silver Cougar",
"Operation Pink Rhino",
"Operation Purple Salvation",
"Operation Hidden Knuckle",
"Operation Blind Garden",
"Operation Harmony",
"Operation Brass Snow",
"Operation Bronze Puma",
"Operation Urban Flake",
"Operation Greenhouse",
"Operation Green Lion",
"Operation Red Angel",
"Operation Desert Meteor",
"Operation Pink Paladin",
"Operation Orange Eye",
"Operation Bread And Water",
"Operation Desert Vengeance",
"Operation Bad News",
"Operation Sea Eyes",
"Operation Green Garden",
"Operation Hidden Heart",
"Operation Ingigo",
"Operation Green Vanguard",
"Operation Red Moon",
"Operation Silver Dragon",
"Operation Pink Jewel",
"Operation Blind Vanguard",
"Operation Wrecking Ball",
"Operation Fire Fighter"
}

-- unit templates
local Templates_RED_Occupation = {
  "RED Template Occupation #001",
  "RED Template Occupation #002",
  "RED Template Occupation #003"
}

-- array to hold missions
local Missions = {}

-- mission info class
local Mission = {}
function Mission:New(Name, GroupName)
  local object = {
    Name = Name,
    GroupName = GroupName
  }
  return object
end

-- print out mission info function
function FormatMissionInfo(Mission)
  return Mission.Name
end

function ListOneMission(Mission)
  MessageToAll(FormatMissionInfo(Mission), 10)
end

function ListAllMissions()
  if #Missions == 0 then
    MessageToAll("No missions available", 10)
  end

  local Text = ""
  for Index = 1, #Missions, 1 do
    ListOneMission(Missions[Index])
  end
end

function NotifyNewMission(Mission)
  MessageToAll("New Mission "..Mission.Name, 10)
end

function NotifyMissionEnd(Mission)
  MessageToAll("Mission Completed "..Mission.Name, 10)
end

-- get unique mission name, if none available, return nil
function GetMissionName()
  local Index;
  local Name;

  if #Missions >= #MissionNamePool then
    return nil
  end

  repeat
    local valid = true
    Index = math.random(1, #MissionNamePool)
    Name = MissionNamePool[Index]
    for Index = 1, #Missions, 1 do
      if Missions[Index].Name == Name then
        valid = false
        break
      end
    end
  until valid
  return Name
end

-- create mission menu
local Menu_Missions = MENU_COALITION:New(coalition.side.BLUE, "Missions")
local Menu_List_All_Missions = MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Show All", Menu_Missions, ListAllMissions)

-- create a mission
function CreateMission(Templates, SpawnGroup)

  -- if we already have a mission with this group, return
  for Index = 1, #Missions, 1 do
    if Missions[Index].GroupName == SpawnGroup then
      return
    end
  end

  -- try to get unique mission name, if nil, return
  local Name = GetMissionName()  
  if Name == nil then
    return
  end
 
  -- create mission info, menu, and notify the player there's a new mission
  local Mission_Info = Mission:New(Name, SpawnGroup)
  local Menu_Item = MENU_COALITION_COMMAND:New(coalition.side.BLUE, Name, Menu_Missions, ListOneMission, Mission_Info)
  table.insert(Missions, Mission_Info)
  NotifyNewMission(Mission_Info)

  -- spawn units in a random circle around the target location choosing one of the templates
  local RED_Occupation_Spawn = SPAWN:New(SpawnGroup)
  RED_Occupation_Spawn:InitRandomizeTemplate(Templates)
  RED_Occupation_Spawn:InitRandomizeUnits(true, 1500, 0)
  local RED_Occupation_Group = RED_Occupation_Spawn:Spawn()

  -- make sure the units are on the road
  local List = RED_Occupation_Group:GetUnits()
  for Index = 1, #List, 1 do
    local Unit = List[Index]
    local Road_Coordinate = Unit:GetCoordinate():GetClosestPointToRoad(false)
    Unit:ReSpawnAt(Road_Coordinate, math.random(0, 359))
  end

  -- if all units in the group are dead
  -- notify the player the mission is finished
  -- remove the menu item for the mission and remove the mission from the mission list
  RED_Occupation_Group:HandleEvent(EVENTS.Dead)
  function RED_Occupation_Group:OnEventDead(EventData)
    if RED_Occupation_Group:GetSize() == 1 then
        NotifyMissionEnd(Mission_Info)
        Menu_Item:Remove()
        for Index = 1, #Missions, 1 do
          if Missions[Index].Name == Name then
            table.remove(Missions, Index)
            break
          end
        end
    end
  end
  
  ------------------------------------------------------
  -- debug code to complete the mission automatically
  SCHEDULER:New( nil, 
    function()
      for Index = 1, #List, 1 do
        local Unit = List[Index]
        Unit:Explode(100, 1 * Index)
      end
    end, {}, 10 
  )
end

---------
--- Mission Start

CreateMission(Templates_RED_Occupation, "RED Spawn Occupation #001")
CreateMission(Templates_RED_Occupation, "RED Spawn Occupation #001")
CreateMission(Templates_RED_Occupation, "RED Spawn Occupation #002")