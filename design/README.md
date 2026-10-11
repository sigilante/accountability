# Design prototype

`Accountability Explorer.dc.html` is the design prototype for the dashboard. It was made in a design tool and needs that tool's `support.js` runtime, which is not in this repository, so it does not render on its own. It also loads fonts from Google Fonts.

`desk/web/dashboard.html` implements this design and supersedes it. The shipped page differs in these ways:

- It has an event feed.
- It uses ~zod as the OTA reference, where the prototype used the majority hash.
- It has no "never rekeyed" category.
- It shows unscored and unkeyed states.
- It draws real sigils.
- It serves its fonts from the ship.
