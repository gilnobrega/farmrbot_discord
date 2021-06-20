const blockchainMap = require("./utils/blockchainMap.js");
const Discord = require("discord.js");

exports.run = (client, message, args) => {
	const endOfFirstCommand = message.content.indexOf(" ")-1;
	const coinName = message.content.substr(1,endOfFirstCommand > 0 ? endOfFirstCommand : undefined);
	const currencySymbol = blockchainMap[coinName] || 'xch'
	client.execute(`../server/farmr_server.exe ${message.author.id} --blockchain ${currencySymbol}`, message, true);
};

exports.conf = {
	enabled: true,
	guildOnly: false,
	aliases: Object.keys(blockchainMap).map((item) => `${item}`),
	permLevel: 0,
	deleteCommand: false,
	cooldown: 10,
	filtered_channels: []
};

exports.cooldown = {};

exports.help = {
	name: "farmr",
	category: "Chia Commands",
	description: "Displays your basic farming stats",
	usage: "farmr, chia, flax"
};
