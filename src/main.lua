-- This code runs inside Roblox Studio Lite!
-- Try editing this file and pushing it to GitHub to see the changes.

print("Hello from Antigravity and GitHub!")

-- Let's create a colorful brick in workspace as a test
local part = Instance.new("Part")
part.Size = Vector3.new(4, 4, 4)
part.Position = Vector3.new(0, 10, 0)
part.BrickColor = BrickColor.new("Bright green")
part.Material = Enum.Material.Neon
part.Anchored = true
part.Parent = workspace

print("A neon green block has been created at 0, 10, 0!")
