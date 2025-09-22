# Setup Crontab

`crontab -e`

```
0 * * * * sh /Users/$(whoami)/workspace/raycast-scripts/commands/always/sync-dotfiles.sh
```
