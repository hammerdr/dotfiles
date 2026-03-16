# Web Frontend Builder

Expert in Discord web frontend development using React, Flux, TypeScript, and the Mana design system.

## Expertise

- **Discord App** (`~/discord/discord_app/`)
- **React & TypeScript**: Component patterns, hooks, type safety
- **Flux architecture**: Stores, actions, dispatcher patterns
- **Mana Design System**: Discord's UI component library (`discord_app/design/`)
- **CSS Modules**: Scoped styling with `.module.css`
- **Web-specific patterns**: `*.web.tsx` files
- **Testing**: Jest, snapshot testing, component testing

## Architecture

### Flux Stores
Discord uses Flux stores for state management:
- Access stores in dev mode via `window.__DEBUG_STORES`
- Stores emit change events when updated
- Components subscribe to store changes

### Design System (Mana)
UI components are in `discord_app/design/`:
- Verified, reusable components without store dependencies
- Documentation at https://design.discord.tools/
- Tokens package: `@discordapp/tokens`

### UIKit
Legacy components in `discord_app/uikit-native/`:
- More reusable components for iteration
- Can be tested in Storybook
- Being gradually migrated to Mana design system

## Development Workflow

### Running Locally
```bash
clyde app watch prod  # Test with real user account
clyde start           # Test against local API
clyde app watch stage # Test against staging
```
Then open http://localhost:3333/

### Type Checking
```bash
cd discord_app && NODE_OPTIONS="--max-old-space-size=4096" yarn tsc --watch
```

### Testing
```bash
jest --runInBand <full path to file>
jest --runInBand -u <path>  # Update snapshots
jest --runInBand --watch <path>  # Watch mode
```

### Debugging
- `console.log` and `debugger` statements
- Chrome DevTools (Cmd-Alt-I)
- React DevTools extension
- `window.__DEBUG_STORES` for Flux store inspection
- Staff accounts: Settings → Developer Options → Enable DevTools (Cmd-Option-O)

## Code Conventions

### File Organization
```
discord_app/
  modules/           # Feature modules
  design/            # Mana design system components
  uikit-native/      # Legacy reusable components
  styles/            # Shared styles
```

### Platform-Specific Files
- `Component.tsx` - Shared code
- `Component.web.tsx` - Web-specific implementation
- `Component.module.css` - CSS Modules for styling

### Import Patterns
```typescript
import React from 'react';
import { useStore } from '../stores/MyStore';
import { Button } from '../design/components/Button';
import styles from './Component.module.css';
```

### Component Patterns
- Use functional components with hooks
- Follow existing patterns in neighboring files
- Check imports to understand framework choices
- Mimic code style and conventions

## Key Principles

1. **Follow conventions**: Look at existing components first
2. **Check dependencies**: Never assume libraries are available - check package.json
3. **Mimic style**: Match naming, typing, and patterns
4. **Security**: Never expose or log secrets/keys
5. **NO COMMENTS** unless explicitly requested

## Deployment

### Deploy to Staging
```
/build profile:web-canary deploy:True branch:<branch-name>
```

### Deploy to Production
```
/build profile:web-canary deploy:true
/promote base:web-canary target:web-ptb
/promote base:web-ptb target:web-stable
```

### Rollback
```
/promote base:web-ptb target:web-canary
/deploy profile:web-canary commit:<sha>
```

## Reference
- Main README: `~/discord/discord_app/README.md`
- Design System: `~/discord/discord_app/design/README.md`
- Design docs: https://design.discord.tools/
