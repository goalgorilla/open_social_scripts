const request = require('request-promise-native');
const parseString = require('xml2js-es6-promise');

const issue_status = {
  1: 'active',
  2: 'fixed',
  3: 'closed (duplicate)',
  4: 'postponed',
  5: 'closed (won\'t fix)',
  6: 'closed (works as designed)',
  7: 'closed (fixed)',
  8: 'needs review',
  13: 'needs work',
  14: 'reviewed & tested by the community',
  15: 'patch (to be ported)',
  16: 'postponed (maintainer needs more info)',
  17: 'closed (outdated)',
  18: 'closed (cannot reproduce)'
};

const httpOptions = {
  url: 'https://www.drupal.org/api-d7/node.json',
  headers: {
    'Accept': 'application/json',
    'User-Agent': 'Patchchecker/1.1.0 (alexander@goalgorilla.com)'
  },
  json: true,
  transform2xxOnly: true
};

function getPatchStatus(node_id, context) {
  "use strict";
  // Allow a context to be passed to the final promise
  if (typeof context === 'undefined') {
    context = {};
  }

  let reqOpts = Object.assign({}, httpOptions, { url: httpOptions.url + "?nid=" + node_id });

  // Add the context to the result, ensuring node is always there.
  reqOpts.transform = (page) => {
    const node = page.list[0];

    // Translate the issue status to a string
    if (typeof node.field_issue_status !== 'undefined') {
      node.field_issue_status = issue_status[node.field_issue_status];
    }

    // Normalise fields
    node.id = node.nid;
    node.status = node.field_issue_status;

    // Add a link to the issue
    node.link = 'https://www.drupal.org/node/' + node.nid;

    return Object.assign({}, context, { issue: node, project_node_id: node.field_project.id });
  };

  return request(reqOpts).then(insertReleaseStatus);
}


/**
 * For issues that are fixed/merged we want to add some extra info to show if
 * the change has been released yet.
 *
 * @param data
 *  The pull request data and context provided.
 */
function insertReleaseStatus(data) {
  "use strict";
  const issue = data.issue;

  // Get the project_node_id passed to use if we need it but don't expose it.
  const project_node_id = data.project_node_id;
  delete data.project_node_id;

  // If this issue is not yet merged there's nothing we need to do.
  if (['fixed', 'closed (fixed)'].indexOf(issue.status) === -1) {
    data.issue.merged = "";
    return data;
  }

  const dynamic_options = {
    url: 'https://www.drupal.org/api-d7/comment.json?node=' + issue.id
  };

  let reqOpts = Object.assign({}, httpOptions, dynamic_options);

  reqOpts.transform = (page) => {
    return { comments: page.list, project_nid: project_node_id };
  };

  return request(reqOpts).then(findRelease).then((version) => {
    // Add that version to our data and unwrap the stack
    data.issue.merged = version;
    return data;
  });
}

/**
 * Finds a release using the commit message in a list of comments on an issue.
 *
 * @param data
 * @return {*}
 */
function findRelease(data) {
  "use strict";
  let { comments, project_nid } = data;

  let idx = -1;
  let comment = null;

  // Loop through the comments to find the system message with the commit
  // message. We assume it's at the end so do this in reverse order.
  for (let i=comments.length-1; i >= 0; i--) {
    comment = comments[i];
    if (comment.name !== "System Message") {
      continue;
    }

    const value = comment.comment_body.value;

    // Check for 'committed on' message.
    idx = value.indexOf("committed on");

    // Check if this is the message signaling the commit
    if (idx !== -1) {
      // Move the index to the start of the tag
      idx += "committed on <strong>".length;
      break;
    }

    // Check for 'authored on' message.
    idx = value.indexOf(' authored <a href="/commitlog');

    if (idx !== -1) {
      // Move to start of tag
      idx = value.indexOf('<strong>', idx) + '<strong>'.length;
      break;
    }
  }

  // We couldn't find the merge so we return 'Unknown' release.
  if (idx === -1) {
    return 'Unkown';
  }

  // We use the date of the message because its close enough to the commit to
  // find the release from.
  let timestamp = comment.created;

  // Find the branch the commit was made on
  let drupal_release = findDrupalMajor(comment.comment_body.value, idx);

  // To be able to get a list of releases we need the project's system name.
  let reqOpts = Object.assign({}, httpOptions, { url: httpOptions.url + "?nid=" + project_nid });

  reqOpts.transform = (page) => {
    return page.list[0].field_project_machine_name;
  };

  return request(reqOpts).then((system_name) => {
    // In our final act we retrieve a list of the available releases and find
    // the one that was released shortest after our comment's date.
    const dynamic_options = {
      url: 'https://updates.drupal.org/release-history/:project/:drupal_release'.replace(':project', system_name).replace(':drupal_release', drupal_release),
      json: false,
    };

    let reqOpts = Object.assign({}, httpOptions, dynamic_options);

    reqOpts.transform = (xml) => {
      return parseString(xml);
    };

    return request(reqOpts).then((release_data) => {
      return getClosestRelease(release_data.project.releases[0].release, timestamp);
    });
  });
}

/**
 * Finds the Drupal major version from a commit message in a comment.
 *
 * @param message
 * @param branch_start
 * @return {string}
 */
function findDrupalMajor(message, branch_start) {
  "use strict";
  // The magic string after the branch name
  const marker = "</strong>";

  let branch_end = message.indexOf(marker, branch_start);

  const branch = message.substr(branch_start, branch_end - branch_start);

  if (typeof branch === 'undefined' || !branch.length) {
    return '';
  }

  return branch.split('-')[0];
}

/**
 * Finds the closest release in a update.drupal.org list of releases using a
 * given date.
 *
 * The returned release will be the first release _after_ the date.
 *
 * @param releases
 * @param date
 * @return {string}
 */
function getClosestRelease(releases, date) {
  "use strict";

  let version = '';
  // Loop through the releases in descending chronological order (provided by
  // d.o). If the release is newer than our comparison date then it's closer.
  // When we pass the comparison date we're done.
  for (let i=0; i < releases.length; i++) {
    let release = releases[i];
    if (release.date > date) {
      version = release.version[0];
    }
    else {
      break;
    }
  }

  return version;
}

module.exports = {
  getPatchStatus: getPatchStatus
};
