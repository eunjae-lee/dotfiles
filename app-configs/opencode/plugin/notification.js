export const NotificationPlugin = async ({ client, $ }) => {
  return {
    event: async ({ event }) => {
      // Send notification on session completion
      if (event.type === "session.idle") {
        await $`afplay /System/Library/Sounds/Hero.aiff`
        // await $`osascript -e 'display notification "Session completed!" with title "opencode"'`
      }
    },
  }
}
