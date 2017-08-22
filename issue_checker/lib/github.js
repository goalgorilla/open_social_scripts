const request = require('request-promise-native');

const httpOptions = {
  url: 'https://api.github.com/repos/:project/pulls/:number',
  headers: {
    'Accept': 'application/vnd.github.v3+json',
    'User-Agent': 'Patchchecker/1.1.0 (alexander@goalgorilla.com)'
  },
  json: true,
  transform2xxOnly: true
};

// Simple object to store some things to reduce the amount of requests.
let cache = {};

function getPatchStatus(pr_id, context) {
  "use strict";
  // Allow a context to be passed to the final promise
  if (typeof context === 'undefined') {
    context = {};
  }

  if (typeof context.project === 'undefined') {
    throw Error("Patch status for GitHub requires a project to be defined");
  }

  const dynamic_options = {
    url: httpOptions.url.replace(':project', context.project).replace(':number', pr_id)
  };

  let reqOpts = Object.assign({}, httpOptions, dynamic_options);

  // Add the context to the result, ensuring issue is always there.
  reqOpts.transform = (page) => {
    let issue = {
      id: page.number,
      title: page.title,
      link: page.html_url,
      status: page.state,
    };

    return Object.assign({}, context, { issue: issue, _raw: page });
  };

  return request(reqOpts).then(insertMergedStatus);
}

/**
 * For issues that are merged we want to add some extra info to show if the
 * change has been released yet.
 *
 * @param data
 *  The pull request data and context provided.
 */
function insertMergedStatus(data) {
  "use strict";
  const page = data._raw;
  const issue = data.issue;
  const project = data.project;

  // Don't leak the entire original request
  delete data._raw;

  // If this issue is not yet merged there's nothing we need to do.
  if (!page.merged) {
    data.issue.merged = "";
    return data;
  }

  // Retrieve the date of the merge commit
  const merge_commit_sha = page.merge_commit_sha;

  const dynamic_options = {
    url: 'https://api.github.com/repos/:project/commits/:sha'.replace(':project', project).replace(':sha', merge_commit_sha)
  };

  let reqOpts = Object.assign({}, httpOptions, dynamic_options);

  reqOpts.transform = (page) => {
    return Date.parse(page.commit.committer.date);
  };

  return request(reqOpts).then((date) => {
    // Use the date of the commit to get the first tag that contained it.
    return getProjectTags(project).then((tags) => {
      if (!tags.length) {
        return '';
      }

      return getLowestContainingTag(tags, date, 0);
    }).then((version) => {
      // Add that version to our data and unwrap the stack
      data.issue.merged = version;
      return data;
    });
  });
}

/**
 * Loops through the tags as a promise chain and finds the first tag created
 * after compare_date.
 *
 * @param tags
 * @param compare_date
 * @param idx
 * @return {Promise.<TResult>}
 */
function getLowestContainingTag(tags, compare_date, idx) {
  "use strict";
  return tags[idx].getDate().then((date) => {
    // If this tag is dated after the compare_date we continue to the next older
    // tag.
    if (date > compare_date) {
      let next_idx = idx+1;
      // If we run out of tags we just return the oldest available tag.
      if (next_idx === tags.length) {
        return tags[idx].version;
      }

      return getLowestContainingTag(tags, compare_date, idx+1);
    }

    // If this tag is older than the commit, we need to use one tag newer.
    // This only works if this is not the newest tag, then we just return no tag.
    if (idx === 0) {
      return '';
    }

    return tags[idx-1].version;
  })
}

/**
 * Returns a promise that resolves to the tags available for a given project.
 *
 * @param project
 * @returns {Promise.<T>}
 */
function getProjectTags(project) {
  "use strict";
  if (typeof cache['tags'] === 'undefined') {
    cache['tags'] = {};
  }

  if (typeof cache['tags'][project] !== 'undefined') {
    return Promise.resolve(cache['tags'][project]);
  }

  const dynamic_options = {
    url: 'https://api.github.com/repos/:project/tags'.replace(':project', project)
  };

  let reqOpts = Object.assign({}, httpOptions, dynamic_options);

  return request(reqOpts).then((page) => {
    let tags = [];

    // Iterate through the tags and convert them to promise returning objects
    for (let i=0;i<page.length;i++) {
      let version = page[i].name;
      let commit = page[i].commit.url;
      tags.push({
        version: page[i].name,
        getDate: createDateRetriever(project, commit),
      })
    }

    cache['tags'][project] = tags;
    return cache['tags'][project];
  });
}

function createDateRetriever(project, commit) {
  "use strict";
  let date = null;

  return () => {
    if (date !== null) {
      return Promise.resolve(date);
    }

    let self = this;

    const dynamic_options = {
      url: commit
    };

    let reqOpts = Object.assign({}, httpOptions, dynamic_options);

    reqOpts.transform = (page) => {
      return Date.parse(page.commit.committer.date);
    };

    return request(reqOpts).then((retrieved_date) => {
      date = retrieved_date;
      return date;
    });
  }
}

module.exports = {
  getPatchStatus: getPatchStatus
};