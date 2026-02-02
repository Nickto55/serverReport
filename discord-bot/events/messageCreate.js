const { ChannelType } = require('discord.js');

module.exports = {
  name: 'messageCreate',
  execute: async (message, client) => {
    if (message.author.bot) return;

    const PREFIX = '!';

    if (message.channel.type === ChannelType.DM) {
      // Handle DMs for report creation
      if (message.content.startsWith(`${PREFIX}report`)) {
        const command = client.commands.get('report');
        if (command) {
          try {
            await command.execute(message, client);
          } catch (error) {
            console.error('Error executing command:', error);
            message.reply('An error occurred while processing your command.');
          }
        }
      }
      return;
    }

    if (!message.content.startsWith(PREFIX)) return;

    const args = message.content.slice(PREFIX.length).trim().split(/ +/);
    const commandName = args.shift().toLowerCase();

    const command = client.commands.get(commandName);

    if (!command) return;

    try {
      await command.execute(message, client, args);
    } catch (error) {
      console.error('Error executing command:', error);
      message.reply('An error occurred while executing this command.');
    }
  },
};
