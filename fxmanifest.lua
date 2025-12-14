fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rde_vehicles'
author 'RDE | SerpentsByte'
version '1.0.0'
description 'Car Delivery & Pickup Service System for ox_core'

shared_scripts {
    '@ox_lib/init.lua',
    '@ox_core/lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    '@ox_core/lib/init.lua',
    'server.lua'
}

dependencies {
    'ox_core',
    'ox_lib',
    'ox_target',
    'oxmysql'
}