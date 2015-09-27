# Morning Stroll

## Development

```bash
$ npm install

# to install
$ grunt install

# to read some docs
$ grunt docs

# to run unit tests
$ grunt test

# to start developing
$ grunt
```

### Sample ST2 Project File

```json
{
  "folders":
  [
    {
      "path": "morning-stroll",
      "file_exclude_patterns":
      [
        "*.mp3",
        "docs/*",
        "lib/*",
        "release/*",
        "tests/specs/*"
      ],
      "folder_exclude_patterns":
      [
        ".grunt",
        "node_modules"
      ]
    }
  ]
}
```

## License

Copyright (c) 2012-2015 Yinglei Yang, Peng Wang
