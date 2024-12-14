# SCIOS: Sentinel Operating System

A modular, robust operating system for ComputerCraft, designed to provide a seamless and powerful computing experience.

## Features
- Modular architecture
- Customizable theme system
- Secure login mechanism
- Error handling and logging

## Module Structure
The system uses a modular architecture with all modules located in the `/scios/` directory. Module loading is handled automatically by the startup sequence:

```lua
-- It looks for modules in this order:
/scios/?        -- Direct module name
/scios/?.lua    -- Module with .lua extension
/?              -- Root fallback
/?.lua          -- Root fallback with extension
```

Only `startup.lua` lives in the root directory - it's like the bouncer that gets everything started.

## Latest Updates

#### Theme System
- Improved theme initialization process
- Added error handling for theme operations
- Implemented safe theme access via `_G.safeTheme()`
- Added fallback mechanisms

#### Known Issues
- Theme initialization may require further optimization
- UI components initialization timing needs review

## Installation

To install SCIOS, run the following command in your ComputerCraft terminal:
```
wget run https://raw.githubusercontent.com/ickycoolboy/SCIOS-Computercraft/Github-updating-test/Installer.lua