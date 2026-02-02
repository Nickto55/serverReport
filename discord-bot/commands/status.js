module.exports = {
  name: 'status',
  description: 'Check report status',
  execute: async (message, client, args) => {
    try {
      if (args.length === 0) {
        return message.reply('Please provide a report ID. Usage: `!status <report_id>`');
      }

      const reportId = args[0];
      const result = await client.db.query('SELECT * FROM reports WHERE id = $1', [reportId]);

      if (result.rows.length === 0) {
        return message.reply('Report not found.');
      }

      const report = result.rows[0];
      const embed = {
        title: report.title,
        description: report.description,
        fields: [
          { name: 'Status', value: report.status, inline: true },
          { name: 'Priority', value: report.priority, inline: true },
          { name: 'Category', value: report.category || 'N/A', inline: true },
          { name: 'Created', value: new Date(report.created_at).toLocaleString(), inline: false },
        ],
        color: 0x0099ff,
      };

      message.reply({ embeds: [embed] });
    } catch (error) {
      console.error('Error checking status:', error);
      message.reply('Failed to check report status.');
    }
  },
};
