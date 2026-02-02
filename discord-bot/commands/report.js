module.exports = {
  name: 'report',
  description: 'Create a new report',
  execute: async (message, client, args) => {
    try {
      const userId = message.author.id;
      const username = message.author.username;

      // Check if user exists or create integration
      let user = await client.db.query(
        'SELECT id FROM discord_integrations WHERE discord_user_id = $1',
        [userId]
      );

      if (user.rows.length === 0) {
        // Create new integration
        await client.db.query(
          'INSERT INTO discord_integrations (discord_user_id, discord_username) VALUES ($1, $2) ON CONFLICT (discord_user_id) DO NOTHING',
          [userId, username]
        );
      }

      message.reply('📝 Please provide the report details:\n1. Title\n2. Description\n3. Category (optional)\n\nReply with your report title first.');
    } catch (error) {
      console.error('Error creating report:', error);
      message.reply('Failed to create report.');
    }
  },
};
