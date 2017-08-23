# Issue Checker

The issue checker takes a composer.json file and checks the issue status of any 
patches that are applied in it.

## Installation
This package is not yet published to NPM so you will have to install this by 
checking out the repository to a folder.

## Usage

```
/path/to/issue_checker/index.js [composer.json]
```

The path to composer.json can be an absolute or relative path (from your 
current working directory). If you omit the path to composer.json the current
directory will be searched for the existence of a composer.json file. 
