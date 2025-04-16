fx_version 'cerulean'
game 'gta5'

description 'Pickpocket - Created by NaorNC - Discord.gg/NCHub'
version '1.1.0'
author 'NaorNC'

ui_page 'html/index.html'

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua'
}

shared_scripts {
    'config.lua'
}

files {
    'html/index.html',
    'html/styles.css',
    'html/script.js',
    'html/imgs/*.jpg',
    'html/imgs/*.png'
}

lua54 'yes'
