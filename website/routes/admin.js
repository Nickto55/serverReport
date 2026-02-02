const express = require('express');
const pool = require('../db');
const { authMiddleware, adminMiddleware } = require('../middleware/auth');

const router = express.Router();

router.use(authMiddleware, adminMiddleware);

router.get('/users', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, username, email, role, status, created_at FROM users ORDER BY created_at DESC'
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch users' });
  }
});

router.get('/users/:userId/reports', async (req, res) => {
  try {
    const { userId } = req.params;
    const result = await pool.query(
      'SELECT * FROM reports WHERE user_id = $1 ORDER BY created_at DESC',
      [userId]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch user reports' });
  }
});

router.get('/reports', async (req, res) => {
  try {
    const { status, priority } = req.query;
    let query = 'SELECT r.*, u.username FROM reports r JOIN users u ON r.user_id = u.id WHERE 1=1';
    const params = [];

    if (status) {
      query += ' AND r.status = $' + (params.length + 1);
      params.push(status);
    }

    if (priority) {
      query += ' AND r.priority = $' + (params.length + 1);
      params.push(priority);
    }

    query += ' ORDER BY r.created_at DESC';

    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch reports' });
  }
});

router.put('/reports/:reportId/status', async (req, res) => {
  try {
    const { reportId } = req.params;
    const { status } = req.body;

    if (!['open', 'in_progress', 'closed', 'resolved'].includes(status)) {
      return res.status(400).json({ message: 'Invalid status' });
    }

    const result = await pool.query(
      'UPDATE reports SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
      [status, reportId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Report not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ message: 'Failed to update report status' });
  }
});

router.get('/stats', async (req, res) => {
  try {
    const totalUsers = await pool.query('SELECT COUNT(*) as count FROM users');
    const totalReports = await pool.query('SELECT COUNT(*) as count FROM reports');
    const openReports = await pool.query('SELECT COUNT(*) as count FROM reports WHERE status = $1', ['open']);
    const discordIntegrations = await pool.query('SELECT COUNT(*) as count FROM discord_integrations');
    const telegramIntegrations = await pool.query('SELECT COUNT(*) as count FROM telegram_integrations');

    res.json({
      totalUsers: parseInt(totalUsers.rows[0].count),
      totalReports: parseInt(totalReports.rows[0].count),
      openReports: parseInt(openReports.rows[0].count),
      discordIntegrations: parseInt(discordIntegrations.rows[0].count),
      telegramIntegrations: parseInt(telegramIntegrations.rows[0].count),
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch statistics' });
  }
});

module.exports = router;
