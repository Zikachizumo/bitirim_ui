fx_version 'cerulean'
game 'gta5'

author 'Bitirim'
description 'Bitirim First Login / Character Creation'
version '1.1.0'

lua54 'yes'

shared_script '@ox_lib/init.lua'

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
    'web/fonts/BungeeInline-Regular.ttf'
}

client_script 'client.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'qbx_core',
    'ox_lib',
    'oxmysql',
    'illenium-appearance',
}
