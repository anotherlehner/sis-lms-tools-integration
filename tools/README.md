# Simpltools

Simple external tools from hypothetical vendors, integrated with the LMS.

## Acme

Acme's standalone Guess the Number application lives in [`acme/`](./acme/). It is a Rack app launched by the LMS in the same browser tab through LTI 1.3 Core. The LMS sends a signed OIDC launch; the tool reports a 100/100 score after a correct guess using LTI Assignment and Grade Services (AGS).

The number of guesses is sent in the standard AGS result comment (for example, `Solved in 4 guesses`). The LMS stores that count in the activity completion and displays it in the course and instructor gradebook.

### Run locally

From the repository root:

```sh
cd tools/acme
bundle install
cd ../..
./dev start all
```

The Acme app listens on `http://127.0.0.1:3002`; the LMS platform listens on `http://127.0.0.1:3000`. The root `./dev` script generates local RSA signing keys in the ignored `.local/lti/` directory when starting the LMS or tool. They are demo credentials and must not be used in a deployed system.

In the LMS, sign in as `instructor`, open the seeded course section, and add **Guess the Number**. Then sign in as `student` and launch the activity from the course page. The activity runs in the separate Acme app in the same tab. After a successful guess, its score and attempt count are sent back to the LMS; use the tool's **Return to course** link to continue.

The local registration uses the client ID `acme-guess-the-number` and deployment ID `local-acme`. Deep Linking and other LTI Advantage services are intentionally outside this first demo. Active game state is stored in the Acme process memory and is cleared by a server restart.
