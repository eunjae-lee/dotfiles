# Setup Crontab

`crontab -e`

## personal

```
*/5 * * * * shortcuts run "Clean Up Tasks"
0 * * * * sh /Users/eunjae/workspace/raycast-scripts/commands/always/sync-dotfiles.sh
```

## work

```
0 * * * * sh /Users/eunjae/workspace/raycast-scripts/commands/always/sync-dotfiles.sh
```
