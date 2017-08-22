#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const Table = require('cli-table');

const PatchChecker = require('./lib/patchchecker');

let composerFile = '';

if (process.argv.length === 2) {
  composerFile = 'composer.json';
}
else if (process.argv.length === 3) {
  composerFile = process.argv[2];
}
else {
  console.log("Checks the status of Drupal issues or GitHub pull request for patches applied in the current composer.json");
  console.log();
  console.log("Usage:\n\tindex.js [composer.json]");
  console.log();
  console.log("\tIf no composer.json file is specified it will use the one in the current directory.");
  return 0;
}

// Find the file relative to the current working directory (or absolute path)
let file = path.resolve(process.cwd(), composerFile);

// Load the composer.json file
let composer = require(file);

const checker = new PatchChecker(composer);

let name = composer.name;

if (!checker.hasPatches()) {
  console.log("Project " + name + " does not have any patches applied!");
  return;
}

const status = checker.getPatchStatus();

// We receive an array of data objects from the drupal.getNode function
status
  .then(function (issues) {
    let table = new Table({
      head: ['ID', 'Project', 'Status', 'Title', 'Link']
    });

    for (let i in issues) {
      let issue = issues[i].issue;

      const title = breakTitle(issue.title);
      table.push([issue.id, issues[i].project, issue.status, title, issue.link]);
    }

    console.log(table.toString());
  })
  .catch(function (error) {
    console.log("Could not retrieve node ", error);
  });

/**
 * Splits a title at the space after x characters.
 *
 * @param title
 */
function breakTitle(title, length) {
  "use strict";

  if (typeof length !== 'number') {
    length = 60;
  }

  let ret = '';

  while (title.length) {
    let idx = title.indexOf(' ', length);

    if (idx === -1) {
      ret += title;
      title = '';
    }
    else {
      ret += title.substr(0, idx) + "\n";
      title = title.substr(idx + 1);
    }
  }

  return ret;
}