const Discord = require('discord.js');
const { Client, MessageEmbed } = require('discord.js');
const fetch = require('node-fetch');
const nodemailer = require("nodemailer");

require('dotenv').config();

const client = new Discord.Client();

client.on('ready', () => {
    console.log('Bot is ready');

    checkNotifs();
});

client.login(process.env.BOT_TOKEN2); //loads discord token from environment variables file

//handles promise rejections
process.on('unhandledRejection', error => {
    // Will print "unhandledRejection err is not defined"
    console.log('unhandledRejection', error.message);
    throw error;
});

async function sendmsg(id, command, name) {

    if (id !== "none") {
        message = "";

        if (command == "block") message = "🤑 " + name + " just found a block!";
        else if (command == "coldBlock") message = "🥶 Cold Wallet in " + name + " just received funds. Is it a block?";

        else if (command == "plot") message = "🎉 " + name + " just completed another plot.";

        else if (command == "offline") message = "☠️ Lost connection to " + name + "!";
        else if (command == "online") message = "😊 " + name + " has reconnected!";

        else if (command == "stopped") message = "😱 " + name + " stopped farming/harvesting!";
        else if (command == "started") message = "😎 " + name + " started farming/harvesting!";

        else if (command == "drive") message = "💿 " + name + " lost one of its drives!";

        //sends email
        if (id.includes("@")) {

            // create reusable transporter object using the default SMTP transport
            let transporter = nodemailer.createTransport({
                host: "smtppro.zoho.eu",
                port: 465,
                secure: true, // true for 465, false for other ports
                auth: {
                    user: process.env.EMAIL_USER, // generated ethereal user
                    pass: process.env.EMAIL_PASSWORD, // generated ethereal password
                },
            });

            // send mail with defined transport object
            let info = await transporter.sendMail({
                from: '"farmr.net" <no-reply@farmr.net>', // sender address
                to: id, // list of receivers
                subject: message, // Subject line
                text: message, // plain text body
                html: "", // html body
            });

            console.log("Email sent to " + id);

        }
        //sends discord notification
        else {
            const user = await client.users.fetch(id).catch(() => null);

            if (!user) console.log("User not found:(");

            if (message != "") {
                await user.send(message).catch(() => {
                    console.log("User has DMs closed or has no mutual servers with the bot :(");
                });

                console.log("Discord notification sent to " + id);

            }

        }

    }
}

const db_config = {
    host: 'localhost',
    user: process.env.MYSQL_USER,
    password: process.env.MYSQL_PASSWORD,
    database: 'chiabot',
    waitForConnections: true,
    connectionLimit: 1
};

async function checkNotifs() {

    const mysql = require('mysql2/promise');

    while (true) {

        const connection = await mysql.createConnection(db_config); // Recreate the connection, since

        [results, fields] = await connection.execute('SELECT notificationID,user,type,name from notifications');

        for (var i = 0; i < results.length; i++) {
            var result = results[i];
            var notificationID = result['notificationID'];
            var userID = result['user'];
            var type = result['type'];
            var name = result['name'];

            await connection.execute('DELETE from notifications where notificationID=' + notificationID);

            console.log(type + " " + userID + " " + name);

            //sends notification
            await sendmsg(userID, type, name);

        }

        await updateStatus(connection);

        //sleep 1 minute
        await sleep(1 * 60 * 1000);

    }

}

var userCount = 0;
var devicesCount = 0;
var serverCount = 0;

async function updateStatus(connection) {

    [results1, fields1] = await connection.execute(
        "SELECT user FROM farms WHERE data<>'' AND data<>';' AND user<>'none' group by user");

    userCount = results1.length;

    [results2, fields2] = await connection.execute(
        "SELECT id FROM farms WHERE data<>'' AND data<>';'");

    devicesCount = results2.length;

    serverCount = client.guilds.cache.size;

    //thanks big O!
    var status = userCount + " users, " + devicesCount + " devices, " + serverCount + " servers";
    client.user.setActivity(status, { type: "LISTENING" });
}

//https://stackoverflow.com/questions/30514584/delay-each-loop-iteration-in-node-js-async
async function sleep(millis) {
    return new Promise(resolve => setTimeout(resolve, millis));
}





