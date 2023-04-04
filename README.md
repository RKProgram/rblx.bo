# rblx.bo

roblox chat bot api

## example code

```lua
local rblxbo = loadstring(game:HttpGet("https://raw.githubusercontent.com/RKProgram/rblx.bo/main/main.lua"))()

local client = rblxbo:CreateClient("!")

client:CreateCommand("monkey", function(ctx)
	local author = ctx.author
	client:Send(author.Name.." executed the command "..client.Prefix.."monkey")
end)

```
