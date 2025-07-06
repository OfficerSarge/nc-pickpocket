Config = {}

-- Framework Settings
Config.Framework = 'qb'               -- 'qb' for QBCore, 'esx' for ESX

-- General Settings
Config.EnableSkillCheck = true         -- Enable or disable the skill check minigame
Config.MaxPickpocketAttempts = 3       -- Maximum number of attempts per NPC
Config.CooldownTime = 30 * 60000       -- Cooldown time between pickpocketing the same NPC (in ms)
Config.RequiredPolice = 0              -- Number of police required to pickpocket
Config.EnableLegacyFuel = false        -- Enable pickpocketing for fuel
Config.UseTkDispatch = true            -- Set to true to use tk_dispatch instead of qb-dispatch
Config.UseQBDispatch = false           -- Set to true if using qb-dispatch
Config.MaxItemsPerPickpocket = 5       -- Maximum number of items to show in pickpocket minigame

-- Target System Settings
Config.UseQBTarget = false            -- Set to true to use qb-target (QBCore only)
Config.UseOxTarget = true            -- Set to true to use ox_target (works with both QBCore and ESX)

-- Difficulty Settings
Config.MinigameSpeed = .25        -- Speed of the arrow (higher = harder)
Config.SuccessPercentage = 75          -- Percentage needed to succeed overall

-- Inventory Image Path Configuration
Config.InventoryType = "ox"            -- Options: "qb", "ox", "custom"
Config.InventoryImagePath = {
    qb = "qb-inventory/html/images/",
    ox = "ox_inventory/web/images/",
    custom = "your-inventory/path/"
}
Config.UseInventoryImagePath = true    -- Set to false to use local imgs folder instead

-- NPC Reaction Settings
Config.NPCCallPoliceChance = 35       -- Chance of NPC calling police on failed attempt (0-100)
Config.NPCAggressiveChance = 60       -- Chance of NPC becoming aggressive on discovery (0-100)
Config.DiscoveryChance = 35            -- Chance of NPC discovering theft even after success (0-100)
Config.NPCCallPoliceTimeout = 15000    -- Time (ms) before police is dispatched after NPC calls
Config.BlipTimeout = 500               -- Time (ms) for police blip to fade out

-- Items Settings
Config.EmptyPocketChance = 30          -- Chance of finding empty pockets (0-100)

-- Possible items to steal with their values and chances
Config.StealableItems = {
    { item = 'money', label = 'Cash', min = 10, max = 150, chance = 75, value = '$' },
	{ item = 'money', label = 'Cash', min = 60, max = 250, chance = 30, value = '$' },
	{ item = 'money', label = 'Cash', min = 120, max = 250, chance = 5, value = '$' },
    { item = 'goldwatch', label = 'Gold Watch', min = 1, max = 1, chance = 35, value = '1x' },
    { item = 'goldchain', label = 'Gold Chain', min = 1, max = 1, chance = 5, value = '1x' },
    { item = 'x_fakecredit', label = 'Credit Card', min = 1, max = 1, chance = 40, value = '1x' },
    { item = 'cigs', label = 'Cigarettes', min = 1, max = 2, chance = 40, value = '1x' },
    { item = 'lighter', label = 'Lighter', min = 1, max = 1, chance = 40, value = '1x' },
    { item = 'lockpick', label = 'Lockpick', min = 1, max = 1, chance = 40, value = '1x' },
	{ item = 'sky_kush_joint', label = 'Joint', min = 1, max = 3, chance = 40, value = '1x' },
	{ item = 'skykush2g', label = 'Weed', min = 1, max = 1, chance = 40, value = '1x' },
    { item = 'screwdriver', label = 'Screwdriver', min = 1, max = 1, chance = 40, value = '1x' },
	{ item = 'hr_phone', label = 'Phone', min = 1, max = 1, chance = 40, value = '1x' }
}

-- Blacklisted NPCs
Config.UseModelBlacklist = true       -- Set to true to enable NPC model blacklisting
Config.BlacklistedNPCModels = {
    -- Add model hashes or names here
    's_m_m_autoshop_01',    -- Mechanic NPC Model
    'ig_mechanic',          -- Another mechanic model
    'csb_trafficwarden',     -- Example of another NPC model
	'u_m_m_jewelsec_01',
	"a_f_y_bevhills_04",
	"a_f_y_bevhills_04",
	"a_m_y_smartcaspat_01",
	"s_m_m_security_01",
	'a_c_boar',
	'a_c_cat_0',
	'a_c_chickenhawk',
	'a_c_chimp',
	'a_c_chop',
	'a_c_cormorant',
	'a_c_cow',
	'a_c_coyote',
	'a_c_crow',
	'a_c_deer',
	'a_c_dolphine',
	'a_c_fish',
	'a_c_sharkhammer',
	'a_c_hen',
	'a_c_humpback',
	'a_c_husky',
	'a_c_killerwhale',
	'a_c_mtlion',
	'a_c_pig',
	'a_c_pigeon',
	'a_c_poodle',
	'a_c_pug',
	'a_c_rabbit',
	'a_c_rat',
	'a_c_retriever',
	'a_c_seagull',
	'a_c_shepherd',
	'a_c_stingray',
	'a_c_sharktiger',
	'a_c_westy',
    -- Add more models as needed
}

-- Notification Messages
Config.Notifications = {
    NoItems = 'The pockets are empty...',
    SuccessfulPickpocket = 'You successfully pickpocketed the person!',
    FailedPickpocket = 'You failed to pickpocket!',
    NPCCalling = 'The person is calling the police!',
    NPCNoticed = 'The person noticed you!',
    CooldownActive = 'You need to wait before trying again.',
    NotEnoughPolice = 'Not enough police in the city.',
    AlreadyPickpocketing = 'You are already pickpocketing someone!'
}

-- tk_dispatch specific settings
Config.TkDispatch = {
    title = 'Pickpocket',
    code = '10-31',
    priority = 'Priority 2',
    showLocation = true,
    showDirection = true,
    showGender = false,
    showVehicle = false,
    showWeapon = false,
    takePhoto = false,
    coordsOffset = 20,
    removeTime = 1000 * 60 * 10, -- 10 minutes (in milliseconds)
    showTime = 10000, -- 10 seconds notification (in milliseconds)
    blip = {
        sprite = 225,
        scale = 1.0,
        color = 1, -- Red color
        radius = 100.0
    },
    jobs = {'police', 'sheriff'} -- Jobs that should receive the dispatch
}
