module.exports = {
  name: 'ready',
  once: true,
  execute: async (client) => {
    console.log(`✅ Discord bot logged in as ${client.user.tag}`);
    client.user.setActivity('reports', { type: 'WATCHING' });
  },
};
