# OneRoster integration reference

## Standard

This project targets a documented subset of **OneRoster 1.2 REST/JSON**. 1EdTech identifies 1.2 as the latest available release.

- [OneRoster 1.2 overview and service map](https://www.imsglobal.org/spec/oneroster/v1p2/)
- [Rostering Service REST Binding](https://www.imsglobal.org/spec/oneroster/v1p2/rostering/bind/rest)
- [Gradebook Service REST Binding](https://www.imsglobal.org/spec/oneroster/v1p2/gradebook/bind/rest)

The final release was issued September 19, 2022. These links point to the official documents; the copyrighted specification text is not reproduced here.

## Roles and synchronization direction

OneRoster REST defines provider and consumer roles. Consumers request data from providers. The standard defines the data services and REST operations, but does not prescribe scheduling or a user-facing trigger.

This project's synchronization is:

1. The SIS provides rostering data; the LMS consumes it.
2. The LMS provides gradebook results; the SIS consumes them.

The repository-root `sync` script initiates the two operations in that order. It calls a separate authenticated control endpoint in each app; those endpoints start a synchronous consumer operation and do not carry OneRoster data.

## Implemented data mapping

The initial implementation covers only data represented by the existing application models:

| OneRoster service | Provider | Consumer | Project mapping |
| --- | --- | --- | --- |
| Rostering | SIS | LMS | `Person` and role -> `User`; `Course` and course code -> `Course`; `Section` and class code -> OneRoster `Class`; student enrollments and instructor assignments -> `Enrollment` |
| Gradebook | LMS | SIS | LMS activity completions and section midterm/final scores -> `LineItem` and `Result`; SIS stores activity results as `Grade` and section scores on `Enrollment` |

Organizations are represented by a single documented default organization because the SIS has no organization model. Stable OneRoster `sourcedId` values are persisted for users, courses, classes, roster enrollments, grade line items, and imported results. Unmodeled OneRoster fields and services are outside this subset; this project does not claim full conformance or certification.

Only student and teacher roles are included in the roster subset. SIS administrators and staff are intentionally excluded; the LMS does not grant administrator privileges based on an incoming roster role.

For this demonstration, SIS-to-LMS user records include the optional OneRoster `User.password` field, and the LMS applies it as the user's login password on each sync. This is demo-only behavior and must not be used in a production system: it transfers reusable credentials between applications and does not define a safe password lifecycle. Use SSO or a separate secure account invitation and password reset flow in production.

The current consumer subset imports only records with `active` status. Handling inactive or `tobedeleted` records and reconciliation-based removal is not implemented; such statuses are reported as sync errors rather than silently applied.

## API and trigger boundaries

- OneRoster service routes use the `/ims/oneroster/v1p2/` prefix and JSON service envelopes.
- OAuth client-credentials tokens are issued at `/ims/oneroster/v1p2/oauth/token`.
- Provider APIs use OAuth 2.0 bearer tokens with the applicable read-only scope.
- App-specific sync control endpoints use a separate control credential and are not OneRoster service operations.
- The sync control routes are `POST /sync/roster` on the LMS and `POST /sync/gradebook` on the SIS.
- Configure service URLs and credentials through environment variables. Do not commit credentials.

For local development, `./dev` and `./sync` source the root `tokens` script. It creates and reuses the control token and both provider client credential pairs in the ignored root `.tokens` file, restricted to the current user. The LMS receives the `LMS_ONEROSTER_CLIENT_ID`/`LMS_ONEROSTER_CLIENT_SECRET` pair as its `ONEROSTER_CLIENT_ID`/`ONEROSTER_CLIENT_SECRET`; the SIS receives the SIS pair the same way. The consumer apps use the corresponding `LMS_ONEROSTER_*` and `SIS_ONEROSTER_*` values. Set any of these variables in the environment to override the local defaults. Provider URLs default to `http://127.0.0.1:3001` (SIS) and `http://127.0.0.1:3000` (LMS) and can be overridden with `SIS_ONEROSTER_URL` and `LMS_ONEROSTER_URL`.

## Sync script

Run `./sync` after both Rails apps are available. It loads the persisted local credentials automatically, starts the LMS roster pull first, and starts the SIS gradebook pull only after the LMS reports success. A failed request stops the script with a non-zero exit status.
