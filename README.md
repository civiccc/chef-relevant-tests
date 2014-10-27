Chef-Relevant-Tests
=========

> "Finally, a Chef gem not named after something food-related!" –Everyone

Have you ever wished that you could be *just a little* smarter about which
tests you run when changing your Chef cookbooks? This is the gem for you!

This is built to scratch an itch we have at Brigade: our single Chef repo has
(as of writing) 19 test-kitchen suites, but many of them are not relevant to
the average commit. Also, we want to encourage the addition of more integration
test coverage by reducing the per-commit cost of adding a new suite. So, for
every commit we want to filter out the unaffected cookbooks as much as
possible.

Usage
--------
`chef-relevant-tests [old git ref] [expander]`

This command will examine all sources of difference between HEAD and your
previous ref (currently only the `Berksfile.lock`) and runs the updated
cookbook versions though a list of expanders which convert the the version
differences into the names of test suites.

Currently, the following expanders exist:

### test-kitchen
This gem will expand the run lists in your `.kitchen.yml` and only run suites dependent on changed cookbooks.

```bash
# if you have GNU xargs:
chef-relevant-tests [old git ref] test-kitchen | xargs --no-run-if-empty bundle exec kitchen test

# if you don't:
tests=$(chef-relevant-tests [old git ref] test-kitchen)
if [ -z "$tests" ]; then
  echo "No tests to run. Sweet!"
  exit 0
fi
kitchen test $tests
```

Architecture
----------
This gem is meant to be extended by adding new `ChangeDetectors` (which convert
the diff between two git refs into cookbook names) or `Expanders` (which take
cookbook names and convert it into test suite names).
