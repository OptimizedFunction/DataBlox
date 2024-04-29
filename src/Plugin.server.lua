--!strict

local Datablox = require(script.Parent.Datablox)
local Janitor = require(script.Parent.Packages.Janitor)

local TOOLBAR_NAME: string = "DataBlox"

local DICT_TO_INSTANCES_BUTTON_PROPS = {
    Id = "Module To Instance",
    Tooltip = "Attempts to convert the selected module script(s) into hierarchy of instances of folders and configuration objects. Parents to Workspace",
    Icon = "",
}
local INSTANCES_TO_DICT_BUTTON_PROPS = {
    Id = "Instance To Module",
    Tooltip = "Converts the given Instance(s) and its descendants into a dictionary. Writes to a module script, which is parented to Workspace",
    Icon = "",
}

local Interface = {}

local _janitor = Janitor.new()

function initUI()
    Interface.Toolbar = plugin:CreateToolbar(TOOLBAR_NAME)

    Interface.DictionaryToInstancesButton = Interface.Toolbar:CreateButton(DICT_TO_INSTANCES_BUTTON_PROPS.Id, DICT_TO_INSTANCES_BUTTON_PROPS.Tooltip, DICT_TO_INSTANCES_BUTTON_PROPS.Icon)
    Interface.InstancesToDictionaryButton = Interface.Toolbar:CreateButton(INSTANCES_TO_DICT_BUTTON_PROPS.Id, INSTANCES_TO_DICT_BUTTON_PROPS.Tooltip, INSTANCES_TO_DICT_BUTTON_PROPS.Icon)
end

function destroyUI()
    if Interface.DictionaryToInstancesButton then
        Interface.DictionaryToInstancesButton:Destroy()
    end

    if Interface.InstancesToDictionaryButton then
        Interface.InstancesToDictionaryButton:Destroy()
    end

    if Interface.Toolbar then
        Interface.Toolbar:Destroy()
    end
end

function init()
    initUI()
    Datablox:Init()

    _janitor:Add(Interface.DictionaryToInstancesButton.Click:Connect(function()
        Datablox:ConvertModulesToInstances()
    end))
    _janitor:Add(Interface.InstancesToDictionaryButton.Click:Connect(function()
        Datablox:ConvertInstancesToModules()
    end))
end

plugin.Unloading:Connect(function()
    destroyUI()
    Datablox:Unload()
end)


init()