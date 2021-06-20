const blockchainMap = require("./utils/blockchainMap");
const Discord = require("discord.js");
exports.run = (client, message, args) => {
	const endOfFirstCommand = message.content.indexOf(" ")-1;
	const coinName = message.content.substr(1,endOfFirstCommand > 0 ? endOfFirstCommand : undefined);
	client.execute(`../server/farmr_server.exe ${message.author.id} --blockchain ${blockchainMap[coinName]}`, message, true);
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
	name: "chia",
	category: "Chia Commands",
	description: "Displays your basic farming stats",
	usage: "chia"
};
