                                                                                                                                                                                                                       --[[
                                          __/\\\\____________/\\\\_________________________________________________________        
		      	                   _\/\\\\\\________/\\\\\\_________________________________________________________       
			                    _\/\\\//\\\____/\\\//\\\_________________________________________________________      
			                     _\/\\\\///\\\/\\\/_\/\\\_____/\\\\\_____/\\/\\\\\\\___/\\\\\\\\\\_____/\\\\\\\\__     
			                      _\/\\\__\///\\\/___\/\\\___/\\\///\\\__\/\\\/////\\\_\/\\\//////____/\\\/////\\\_    
			                       _\/\\\____\///_____\/\\\__/\\\__\//\\\_\/\\\___\///__\/\\\\\\\\\\__/\\\\\\\\\\\__   
			                        _\/\\\_____________\/\\\_\//\\\__/\\\__\/\\\_________\////////\\\_\//\\///////___  
			                         _\/\\\_____________\/\\\__\///\\\\\/___\/\\\__________/\\\\\\\\\\__\//\\\\\\\\\\_ 
			                          _\///______________\///_____\/////_____\///__________\//////////____\//////////__

                                                                                                                                                                                                                        --]]
	
local Players = game.Players
local Player = Players['LocalPlayer']

local Character = Player.Character or Player.CharacterAdded:wait()
local HRP = Character['HumanoidRootPart']
local Stat = workspace.Stats[Player.Name]

local DE = game.ReplicatedStorage.DataEvent
local UE = Player.PlayerGui.MainGUI.Scripts.Inventory.UpdateEvent

local PP = workspace.PizzaPlanet
local Stations = PP['BakerWorkstations']
local Crates = PP['IngredientCrates']
local Working, Stocking = true

Stat.Job:GetPropertyChangedSignal('Value'):Connect(function()
    if Stat.Job.Value == 'PizzaPlanetBaker' then Working = false
    else Working = true end
end)
if Stat.Job.Value == 'PizzaPlanetBaker' then Working = false end

local Orders = {
    Cheese = {true,true,true,false};
    Vegetable = {true,true,true,'Vegetable'};
    Ham = {true,true,true,'Ham'};
    Pepperoni = {true,true,true,'Pepperoni'}
}

local CrateTP = Vector3.new(1163.78955, 13.5, 258.54892)
local Positions = {
    Vector3.new(1173.34778, 13.5, 226.585571),
    Vector3.new(1172.8501, 13.5, 238.183029),
    Vector3.new(1173.20837, 13.5, 250.465881),
    Vector3.new(1173.47266, 13.5, 259.170837)
}

local Part1 = coroutine.wrap(function()
    while wait() do
        for __, station in next, (Stations:GetChildren()) do
            if Working then break end
            local CT = station:FindFirstChild('CounterTop')
            if CT then CT.Parent = nil end
            station.InUse.Value = Player
            
            local Pos = Positions[__]
            Character.Humanoid.WalkToPoint = Pos
            repeat wait() until (HRP.Position - Pos).magnitude < 2 or Working
            if Working then break end

            local NI = station['OrderDisplay']['DisplayMain']:FindFirstChild('NoIngredients',true)
            if NI and NI.Visible and not Working then
                Stocking = true
                local Pos = CrateTP
                Character.Humanoid.WalkToPoint = Pos
                repeat wait() until (HRP.Position - Pos).magnitude < 2.75 or Working
                if Working then break end
                
                local Crate = Crates.Crate;
                for __, cr in next, (Crates:GetChildren()) do
                    if (cr.Position - HRP.Position).magnitude < (Crate.Position - HRP.Position).magnitude then
                        Crate = cr
                    end
                end
                Crate.Parent = game.Lighting.TempFolder
                wait()
                DE:FireServer({
                    Object = game.Lighting.TempFolder.Crate,
                    Type = 'TakeIngredientCrate'
                })
                Crate.Parent = Crates
                UE:Fire(Stat.EquippedItem)
                wait()
            end
            
            local Pos = Positions[__]
            Character.Humanoid.WalkToPoint = Pos
            repeat wait() until (HRP.Position - Pos).magnitude < 2 or Working
            if Working then break end
            if Stocking then
                 DE:FireServer({
                    Workstation = station,
                    Type = 'RestockIngredients'
                })
            end
            Stocking = false
        end
        for i = #Positions, 1, -1 do
            local station = Stations:GetChildren()[i]
            if Working then break end
            local CT = station:FindFirstChild('CounterTop')
            if CT then CT.Parent = nil end
            station.InUse.Value = Player
            
            local Pos = Positions[i]
            Character.Humanoid.WalkToPoint = Pos
            repeat wait() until (HRP.Position - Pos).magnitude < 2 or Working
            if Working then break end

            local NI = station['OrderDisplay']['DisplayMain']:FindFirstChild('NoIngredients',true)
            if NI and NI.Visible and not Working then
                Stocking = true
                local Pos = CrateTP
                Character.Humanoid.WalkToPoint = Pos
                repeat wait() until (HRP.Position - Pos).magnitude < 2.75 or Working
                if Working then break end
                
                local Crate = Crates.Crate;
                for __, cr in next, (Crates:GetChildren()) do
                    if (cr.Position - HRP.Position).magnitude < (Crate.Position - HRP.Position).magnitude then
                        Crate = cr
                    end
                end
                Crate.Parent = game.Lighting.TempFolder
                wait()
                DE:FireServer({
                    Object = game.Lighting.TempFolder.Crate,
                    Type = 'TakeIngredientCrate'
                })
                Crate.Parent = Crates
                UE:Fire(Stat.EquippedItem)
                wait()
            end
            
            local Pos = Positions[i]
            Character.Humanoid.WalkToPoint = Pos
            repeat wait() until (HRP.Position - Pos).magnitude < 2 or Working
            if Working then break end
            if Stocking then
                 DE:FireServer({
                    Workstation = station,
                    Type = 'RestockIngredients'
                })
            end
            Stocking = false
        end
    end
end)

local Part2 = coroutine.wrap(function()
    while wait(1) do
        for __, station in next, (Stations:GetChildren()) do
            if Working or Stocking then break end
            local send = Orders[station.Order.Value]
            local count = station.Order.IngredientsLeft.Value
            DE:FireServer({
                Workstation = station,
                Type = 'UseWorkstation'
            })
            
            if Working or Stocking then break end
            if count > 2 then count = count - 1 end
            for i = 1, count do
                DE:FireServer({
                    Workstation = station,
                    Type = 'UseWorkstation'
                })
            end

            if Working or Stocking then break end

            DE:FireServer({
                Order = send,
                Workstation = station,
                Type = 'FinishOrder'
            })
            UE:Fire(Stat.Job.ShiftEarnings)
        end
    end
end)

Part1()
Part2()
