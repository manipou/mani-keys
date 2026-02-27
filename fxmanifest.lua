
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

client_scripts {
	'client/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
	'server/*.lua',
}

shared_script '@jet-lib/init.lua'

files {
	'config.lua',
	'locales/*.json',
}