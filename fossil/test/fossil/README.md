# Fossil Repo Location for Testing

When doing test runs from this working tree,
use a bind mount like this:
`--mount "type=bind,source=$$(pwd)/test/fossil,target=/fossil"`
