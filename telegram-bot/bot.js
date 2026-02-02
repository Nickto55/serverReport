require('dotenv').config();
const { Telegraf } = require('telegraf');
const { Pool } = require('pg');

const bot = new Telegraf(process.env.TELEGRAM_TOKEN);
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

bot.db = pool;

// Start command
bot.start(async (ctx) => {
  const userId = ctx.from.id;
  const username = ctx.from.username || ctx.from.first_name;

  try {
    // Check if user exists
    let user = await pool.query(
      'SELECT id FROM telegram_integrations WHERE telegram_user_id = $1',
      [userId.toString()]
    );

    if (user.rows.length === 0) {
      // Create new integration
      await pool.query(
        'INSERT INTO telegram_integrations (telegram_user_id, telegram_username) VALUES ($1, $2) ON CONFLICT (telegram_user_id) DO NOTHING',
        [userId.toString(), username]
      );
    }

    ctx.reply(
      'Welcome to ServerReport Bot! 📋\n\n' +
      'Commands:\n' +
      '📝 /report - Create a new report\n' +
      '📊 /status <id> - Check report status\n' +
      '📚 /list - List your reports\n' +
      '❓ /help - Show help'
    );
  } catch (error) {
    console.error('Error in start:', error);
    ctx.reply('An error occurred. Please try again.');
  }
});

// Report command
bot.command('report', async (ctx) => {
  try {
    ctx.scene.enter('report_scene');
  } catch (error) {
    console.error('Error in report command:', error);
    ctx.reply('Failed to create report.');
  }
});

// Status command
bot.command('status', async (ctx) => {
  try {
    const args = ctx.message.text.split(' ');
    if (args.length < 2) {
      return ctx.reply('Please provide a report ID. Usage: /status <report_id>');
    }

    const reportId = args[1];
    const result = await pool.query('SELECT * FROM reports WHERE id = $1', [reportId]);

    if (result.rows.length === 0) {
      return ctx.reply('Report not found.');
    }

    const report = result.rows[0];
    const message =
      `*Report Status*\n\n` +
      `*Title:* ${report.title}\n` +
      `*Status:* ${report.status}\n` +
      `*Priority:* ${report.priority}\n` +
      `*Category:* ${report.category || 'N/A'}\n` +
      `*Created:* ${new Date(report.created_at).toLocaleString()}`;

    ctx.reply(message, { parse_mode: 'Markdown' });
  } catch (error) {
    console.error('Error in status command:', error);
    ctx.reply('Failed to check report status.');
  }
});

// List command
bot.command('list', async (ctx) => {
  try {
    const userId = ctx.from.id;
    const integration = await pool.query(
      'SELECT user_id FROM telegram_integrations WHERE telegram_user_id = $1',
      [userId.toString()]
    );

    if (integration.rows.length === 0) {
      return ctx.reply('You are not registered. Please use /start first.');
    }

    const reports = await pool.query(
      'SELECT id, title, status FROM reports WHERE user_id = $1 ORDER BY created_at DESC LIMIT 10',
      [integration.rows[0].user_id]
    );

    if (reports.rows.length === 0) {
      return ctx.reply('You have no reports.');
    }

    let message = '*Your Reports:*\n\n';
    reports.rows.forEach(report => {
      message += `📋 [${report.id}] ${report.title} - *${report.status}*\n`;
    });

    ctx.reply(message, { parse_mode: 'Markdown' });
  } catch (error) {
    console.error('Error in list command:', error);
    ctx.reply('Failed to fetch reports.');
  }
});

// Help command
bot.command('help', (ctx) => {
  ctx.reply(
    'ServerReport Bot Help 📖\n\n' +
    '📝 /report - Create a new report\n' +
    '📊 /status <id> - Check report status\n' +
    '📚 /list - List your reports\n' +
    '❓ /help - Show this help message'
  );
});

bot.launch().then(() => {
  console.log('✅ Telegram bot is running');
});

process.once('SIGINT', () => bot.stop('SIGINT'));
process.once('SIGTERM', () => bot.stop('SIGTERM'));

module.exports = bot;
