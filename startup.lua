-- SCI Sentinel OS Startup File
-- This file will automatically start SCI Sentinel when the computer boots

-- Ensure we're in the root directory
shell.run("cd", "/")

-- Start SCI Sentinel
shell.run("scios/sci_sentinel.lua")
