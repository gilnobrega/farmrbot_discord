const Discord = require('discord.js');
const { Client, MessageEmbed } = require('discord.js');
const fetch = require('node-fetch');

require('dotenv').config();

const client = new Discord.Client();

client.on('ready', () => {
    console.log('Bot is ready');
    var id = "";

    sendmsg(id, "You are using too much resources. Contact <@835342160370728970> ( @Gil#1111 ) if you wish to keep using this service. Otherwise you will be banned in 7 days.");
    sendmsg(id, "您好，您在用的客户端用了我们服务器太多资源。 如果您想继续用我们的服务，请联系开发者 <@835342160370728970> ( @Gil#1111 )，或者七天后会把您用户封锁。");
});

client.login(process.env.BOT_TOKEN2); //loads discord token from environment variables file

//handles promise rejections
process.on('unhandledRejection', error => {
    // Will print "unhandledRejection err is not defined"
    console.log('unhandledRejection', error.message);
    throw error;
});

async function sendmsg(id, message) {

    if (id !== "none") {

        const user = await client.users.fetch(id).catch(() => null);

        if (!user) console.log("User not found:(");

        if (message != "")
        {
            await user.send(message).catch(() => {
                console.log("User has DMs closed or has no mutual servers with the bot :(");
            });
        }

    }

}



