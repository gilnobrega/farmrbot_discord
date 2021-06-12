const Discord = require("discord.js");
exports.run = (client, message, args) => {
    var id = args[0];
    var user = message.author.id;
     
    try {
     client.linkUser(id, user, message).catch();
    }
    catch (err) {}
};

exports.conf = {
    enabled: true,
    guildOnly: false,
    aliases: ['chia link'],
    permLevel: 0,
    deleteCommand: false,
    cooldown: 10,
    filtered_channels: []
};

exports.cooldown = {};

exports.help = {
    name: "link",
    category: "Chia Commands",
    description: "Links a new id",
    usage: "link <ID>"
};