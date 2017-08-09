const drupal = require('./drupal-org');


class PatchChecker {
  /**
   * The JSON of a valid composer.json file.
   *
   * To check issues for patches, the patchfile keys should be in the form of:
   * 'issuenr - human readable description'
   *
   * This way the issue number (node id on drupal.org) can be easily parsed.
   *
   * @param json
   */
  constructor(json) {
    this.json = json;
  }

  /**
   * Checks if the composer file for this PatchChecker contains any patches.
   *
   * @returns {boolean}
   */
  hasPatches() {
    return typeof this.json.extra !== 'undefined' && typeof this.json.extra.patches !== 'undefined';
  }

  /**
   * Retrieves the status of the issues to which the patches belong.
   *
   * @returns {Array}
   */
  getPatchStatus() {
    if (!this.hasPatches()) {
      return [];
    }

    const patches = this.json.extra.patches;
    let requests = [];

    for (let project in patches) {
      for (let summary in patches[project]) {
        // We support summaries in a 'issuenr - shortdesc' format
        const parts = summary.split('-', 2);
        const issuenr = parts[0].trim();

        // Create a request and add it to our array
        requests.push(drupal.getNode(issuenr, { project: project }));
      }
    }

    return Promise.all(requests);
  }
}

module.exports = PatchChecker;