--!strict

--Roblox Services
local Selection: Selection = game:GetService("Selection")

--Modules
local Janitor = require(script.Parent.Packages.Janitor)

--Constants
local reservedKeys: {string} = {"_InstanceProperties"} -- in addition to all _ prefixed keys.
local moduleStringTemplate: string = "local %s = {\n%s\n}\n\nreturn %s"

--Variables

----------------------------
local Datablox = {}
Datablox._janitor = Janitor.new()


function Datablox:ConvertModulesToInstances(): ()
    local function computeClassName(dict: {[number | string]: any}): string
        local className: string = "Folder"--"Configuration"
    
        -- Instance property set by the dev overrides all checks
        if dict._InstanceProperties and dict._InstanceProperties.ClassName then
            return dict._InstanceProperties.ClassName
        end
        
        -- If there are any attributes, ClassName will be Configuration. Folder otherwise.
        for k, v in dict do
            if table.find(reservedKeys, k) then
                continue
            end
    
            if typeof(v) ~= "table" then
                className = "Configuration"
                break
            end
        end
    
    
        return className
    end

    local function convertDictToInstances(dict: {[number | string]: any}, name: string | number): (Instance)
        local root: Instance = Instance.new(computeClassName(dict))
        if typeof(name) == "number" then
            root.Name = dict.Name or name
            root:SetAttribute("_dataBloxIndex", name)
        else
            root.Name = name
        end


        for key, value in dict do
            if table.find(reservedKeys, key) or string.match(key, "^_") then
                continue
            end 

            if typeof(value) == "table" then
                local childInstance = convertDictToInstances(value, key)
                childInstance.Parent = root
            else
                -- We ignore key-value pairs if value is a function OR if its a string prefixed with _
                if typeof(value) == "function" then
                    continue
                elseif typeof(value) == "Instance" then
                    local objValue: ObjectValue = Instance.new("ObjectValue") :: ObjectValue
                    objValue.Name = key
                    objValue.Value = value
                    objValue.Parent = root

                    continue
                end

                root:SetAttribute(key, value)
            end
        end

        return root
    end

    local convertedInstanceTreeRoots: {Instance} = {}
    local selectedInstances: {Instance} = Selection:Get()
    local warnUser: boolean = true

    for _, instance: Instance in selectedInstances do
        if not instance:IsA("ModuleScript") then
            continue
        end

        local module = instance :: ModuleScript
        warnUser = false

        local dict: any? = require(module)
        if typeof(dict) ~= "table" then
            warn(string.format("[PLUGIN][DataBlox]: table expected, got %s\nModule: %s\nTraceback: %s", typeof(dict), module:GetFullName(), debug.traceback()))
            continue
        end

        local newTreeRoot = convertDictToInstances(dict :: {[number | string]: any}, module.Name)
        newTreeRoot.Parent = workspace

        table.insert(convertedInstanceTreeRoots, newTreeRoot)
    end

    Selection:Set(convertedInstanceTreeRoots)

    if warnUser then
        warn(string.format("[PLUGIN][DataBlox]: No module(s) selected, select at least 1 module script first."))
    end

    return
end


function Datablox:ConvertInstancesToModules(): ()
    local function convertInstancesToDict(root: Instance): {[string]: any}
        local dict = {}

        local children: {Instance} = root:GetChildren()
        for _, child in children do
            local index = child:GetAttribute("_dataBloxIndex")
            local key = index or child.Name

            if child:IsA("ObjectValue") then
                dict[key] = child.Value
            else
                dict[key] = convertInstancesToDict(child)
            end
        end

        for attrName, attrVal in root:GetAttributes() do
            if attrName == "_dataBloxIndex" then
                continue
            end
            attrName = tonumber(attrName) or attrName
            dict[attrName] = attrVal
        end

        return dict
    end

    local function convertToString(dict: {[string]: any})
        local dictString = ""

        for k, v in dict do
            dictString = dictString .. "%s"

            local valString: string
            if typeof(v) == "table" then
                valString = string.format("{\n%s}", convertToString(v))
            elseif typeof(v) == "Instance" then
                valString = v:GetFullName()
            elseif typeof(v) == "string" then
                valString = `\"{v}\"`
            elseif typeof(v) == "boolean" or typeof(v) == "number" then
                valString = tostring(v)
            elseif typeof(v) == "Vector2" then
                valString = `Vector2.new({v.X}, {v.Y})`
            elseif typeof(v) == "Vector3" then
                valString = `Vector3.new({v.X}, {v.Y}, {v.Z})`
            else
                error("Unknown entry type! Got " .. typeof(v))
            end

            local keyString: string
            if typeof(k) == "number" or tonumber(k) then
                k = tonumber(k)
                keyString = `[{tostring(k)}]`
            elseif typeof(k) == "string" then
                keyString = if string.match(k, " ") then `[\"{k}\"]` else k
            else
                error("Unknown entry type! Got " .. typeof(k))
            end

            local entryFormatArray: string = "%s,\n"
            local entryFormatDict: string = "%s = %s,\n"
            local str: string = entryFormatDict

            if typeof(k) == "number" then
                str = string.format(entryFormatArray, valString)
            else
                str = string.format(entryFormatDict, keyString, valString)
            end

            print(str)
            dictString = string.format(dictString, str)
        end

        return dictString
    end

    local convertedModuleScripts: {ModuleScript} = {}

    local selectedInstances: {Instance} = Selection:Get()
    if #selectedInstances < 1 then
        warn(string.format("[PLUGIN][DataBlox]: No instances(s) selected, select at least 1 instance first."))
    end

    for _, instance: Instance in selectedInstances do
        local dict = convertInstancesToDict(instance)
        print(dict)

        local newModuleScript = Instance.new("ModuleScript")
        newModuleScript.Name = instance.Name
        newModuleScript.Source = string.format(moduleStringTemplate, instance.Name, convertToString(dict), instance.Name)
        newModuleScript.Parent = workspace

        table.insert(convertedModuleScripts, newModuleScript)
    end

    Selection:Set(convertedModuleScripts)

    return
end

function Datablox:Init()
    
end

function Datablox:Unload()
    self._janitor:Destroy()
end

return Datablox