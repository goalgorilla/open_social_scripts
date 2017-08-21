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

  // Add the context to the result, ensuring node is always there.
  reqOpts.transform = (page) => {
    let issue = {
      id: page.number,
      title: page.title,
      link: page.html_url,
      status: page.state,
    };

    return Object.assign({}, context, { issue: issue });
  };

  return request(reqOpts);
}

module.exports = {
  getPatchStatus: getPatchStatus
};