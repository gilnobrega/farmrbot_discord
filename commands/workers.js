const blockchainMap = require("./utils/blockchainMap.js");
const Discord = require("discord.js");

exports.run = (client, message, args) => {
	const endOfFirstCommand = message.content.indexOf(" ")-1;
	const coinName = message.content.substr(1,endOfFirstCommand > 0 ? endOfFirstCommand : undefined);
	console.log(coinName);
    client.execute(`../server/farmr_server.exe ${message.author.id} workers --blockchain ${blockchainMap[coinName]}`, message, true);
};


exports.conf = {
	enabled: true,
	guildOnly: false,
	aliases: Object.keys(blockchainMap).map((item) => `${item} workers`),
	permLevel: 0,
	deleteCommand: false,
	cooldown: 10,
	filtered_channels: ['829057822213931062']
};

exports.cooldown = {};

exports.help = {
	name: "workers",
	category: "Chia Commands",
	description: "Displays your workers",
	usage: "workers, chia workers, flax workers"
};
