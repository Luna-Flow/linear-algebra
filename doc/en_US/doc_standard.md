# Documentation Standard

## Document Types and Organization

### Main Document Types

1. **API Reference Documentation (api.md)** - Detailed specifications for each public interface
2. **User Guide (tutorial.md)** - User-oriented tutorials and best practices
3. **Design Documentation (design.md)** - Architecture and algorithm descriptions for developers
4. **Performance Reports (benchmark.md)** - Benchmark tests and performance analysis documentation

### Documentation Organization Principles

- Organized by package/file, for example:
  
  ```txt
  docs/
    |- en_US
    |- ja_JP 
    |- zh_CN
        |- immut
        |   |- matrix
        |   |   |- api.md
        |   |   |- tutorial.md
        |   |   |- design.md
        |   |   |- benchmark.md
        |   |- ...
        |- mutable
        |   |- matrix
        |   |   |- ...
        |   |- ...
        |- ...
  ```

- Further subdivided by `vector`, `matrix` etc. files under each package
- Maintain consistency between documentation and code structure