fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name        'rde_carservice'
author      'RDE | SerpentsByte | rd-elite.com'
version     '1.1.0'
description 'Car Delivery & Pickup Service | NPWD Phone App | ox_core native'

shared_scripts {
    '@ox_lib/init.lua',
    '@ox_core/lib/init.lua',
    'config.lua',
}

client_scripts {
    'client.lua',
    'phone_app.lua',    -- NPWD Bridge (läuft nach client.lua)
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    '@ox_core/lib/init.lua',
    'server.lua',
}

files {
    'web/dist/remoteEntry.js',
    'web/dist/assets/*.js',  -- NPWD Phone App (React Module Federation)
}

dependencies {
    'ox_core',
    'ox_lib',
    'ox_target',
    'oxmysql',
}
