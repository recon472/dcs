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

-- array to hold missions
local Missions = {}

-- mission info class
local Mission = {}
function Mission:New(Name, GroupName, Type, Briefing, Intel, Coordinates)
  local object = {
    Name = Name,
    GroupName = GroupName,
    Type = Type,
    Briefing = Briefing,
    Intel = Intel,
    Coordinates = Coordinates
  }
  return object
end

-- print out mission info function
function FormatMissionInfo(Mission)
  return Mission.Name.." | "..Mission.Type.." | "..Mission.Coordinates.."\n"..Mission.Briefing.."\n"..Mission.Intel
end

function ListOneMission(Mission)
  MessageToAll(FormatMissionInfo(Mission), 15)
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
  MessageToAll("New Mission "..Mission.Name.." | "..Mission.Type, 10)
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

-- get all group names from prefix
function GetGroupNamesFromPrefix(Prefix)
  local Occupation_Groups = SET_GROUP:New():FilterCoalitions("red"):FilterPrefixes(Prefix):FilterStart()
  return Occupation_Groups:GetSetNames()
end

-- get random group name from prefix
function GetRandomGroupNameFromPrefix(Prefix)
  local Names = GetGroupNamesFromPrefix(Prefix)
  return Names[math.random(1, #Names)]
end

-- create mission menu
local Menu_Missions = MENU_COALITION:New(coalition.side.BLUE, "Missions")
local Menu_List_All_Missions = MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Show All", Menu_Missions, ListAllMissions)

-- create a mission
function CreateMission(Templates, SpawnGroup, ConfigureSpawn, ConfigureUnits, Type, Briefing, Intel)

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

  -- create a spawn
  local RED_Occupation_Spawn = SPAWN:New(SpawnGroup)
  RED_Occupation_Spawn:InitRandomizeTemplate(Templates)
  
  -- configure it
  ConfigureSpawn(RED_Occupation_Spawn)
    
  -- spawn units
  local RED_Occupation_Group = RED_Occupation_Spawn:Spawn()
  
  -- create mission info, menu, and notify the player there's a new mission
  local Coordinate = RED_Occupation_Spawn:GetCoordinate()
  local Coordinate_Mark = Coordinate:MarkToCoalitionBlue(Name.." | "..Type.."\n\n"..Briefing, true)
  local Mission_Info = Mission:New(Name, SpawnGroup, Type, Briefing, Intel, Coordinate:ToStringLLDMS())
  local Menu_Item = MENU_COALITION_COMMAND:New(coalition.side.BLUE, Name, Menu_Missions, ListOneMission, Mission_Info)
  table.insert(Missions, Mission_Info)
  NotifyNewMission(Mission_Info)

  -- modify units
  local List = RED_Occupation_Group:GetUnits()
  ConfigureUnits(List)

  -- if all units in the group are dead
  -- notify the player the mission is finished
  -- remove the menu item for the mission and remove the mission from the mission list
  RED_Occupation_Group:HandleEvent(EVENTS.Dead)
  function RED_Occupation_Group:OnEventDead(EventData)
    if RED_Occupation_Group:GetSize() == 1 then
        NotifyMissionEnd(Mission_Info)
        Coordinate:RemoveMark(Coordinate_Mark)
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

-- create occupation mission
function CreateOccupationMission(Templates, SpawnGroup)
  -- spawn units in a circle around the point
  local ConfigureSpawn = function (Spawn)
    Spawn:InitRandomizeUnits(true, 1500, 0)
  end
  
  -- move them to a nearest point on the road
  local ModifyUnits = function (Units)
    for Index = 1, #Units, 1 do
      local Unit = Units[Index]
      local Road_Coordinate = Unit:GetCoordinate():GetClosestPointToRoad(false)
      Unit:ReSpawnAt(Road_Coordinate, math.random(0, 359))
    end
  end

  CreateMission(Templates, SpawnGroup, ConfigureSpawn, ModifyUnits, "Occupation", "Russian forces are occupying a nearby civilian town. Eliminate all hostiles and restore order.", "Expect small ground force [5-10] units with no or limited AA defense")
end

---------
--- Mission Start ---
--

CreateOccupationMission(GetGroupNamesFromPrefix("RED Template Occupation"), GetRandomGroupNameFromPrefix("RED Spawn Occupation"))