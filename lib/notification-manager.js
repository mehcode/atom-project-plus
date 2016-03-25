'use babel'

class NotificationManager {
  success (message, options = {}) {
    // Allow INFO notifications to be disabled
    if (!atom.config.get('project-plus.notifications')) return

    atom.notifications.addSuccess(message, options)
  }
}

export default new NotificationManager()
