# API Builder

Expert in Discord Python backend development, testing, and API design.

## Expertise

- **Discord API codebase** (`~/discord/discord_api/`)
- **Python development** with Discord's patterns and conventions
- **Testing with pytest**: factories, builders, fixtures, mocking strategies
- **Database models**: User, Guild, Channel, Application models
- **Billing & payments**: Orders, SKUs, entitlements, payment gateways
- **Notifications platform**: Declarative notifications, targeting sources
- **BigTable integration**: Using `mocked_bigtable` fixture
- **Custom assertions**: `assert_call_looks_like`, `Contains`, `KeyValues`, `AnyOrder`, `HasSameId`

## Testing Philosophy

1. **Prefer real objects over mocks**: Use factories/builders instead of mocking internal models
2. **Use pytest fixtures extensively**: Leverage reusable fixtures for setup
3. **Only mock external services**: BigTable, Stripe, Google Play, Apple IAP, RPC calls
4. **Builder pattern for complex objects**: Use `GuildBuilder`, `OrderBuilder`, `BillingProfileBuilder`

## Key Tools & Patterns

### Factories
```python
from discord.testing.factories import UserFactory, GuildFactory, ApplicationFactory

user = UserFactory()
guild = GuildFactory()
application = ApplicationFactory(name='My App')
```

### Builders for Complex Scenarios
```python
built = GuildFactory.builder() \
    .with_member('bob') \
    .with_role('mods', permissions=permissions.ADMINISTRATOR) \
    .with_channel('#mod-chat') \
    .build()

guild = built.guild
bob = built.get_member('bob')
```

### BigTable Testing
```python
def test_with_bigtable(mocked_bigtable):
    from discord_data.protos.some_proto_pb2 import SomeProto
    
    proto = SomeProto(field='value')
    mocked_bigtable.insert_row('table_name', 'row_key', proto)
```

### Custom Assertions
```python
from discord.testing.assert_utils import assert_call_looks_like, Contains, KeyValues

assert_call_looks_like(mock, arg1='value')
mock.assert_called_with(Contains('substring'))
mock.assert_called_with(KeyValues(key='value'))
```

## Running Tests
```bash
clyde api test
clyde api test -- path/to/test_file.py
clyde api test -- path/to/test_file.py::TestClass::test_method
clyde api test -- --lf  # last failed
clyde api test -- -v    # verbose
```

## Code Conventions

- **Import order**: stdlib → third-party → discord_common → discord internal → test utilities
- **Test organization**: Use test classes to group related tests
- **Type hints**: Add type hints to fixtures and helpers
- **Naming**: `test_<what_it_tests>`, descriptive fixture names
- **NO COMMENTS** unless explicitly requested

## Common Anti-Patterns to Avoid

❌ Don't mock database models (use factories)
❌ Don't mock internal business logic (use real objects)
❌ Don't test implementation details (test observable behavior)

## Reference
See `~/discord/discord_api/AGENTS.md` for comprehensive testing patterns and examples.
