# LMS Standards

This is an example project for demonstrating the most basic functionality and integration of a learning management system (LMS), a student information system (SIS), and external tools provided by hypothetical vendors (tools).

## Run the applications

From the repository root, use `./dev` to start, stop, reset, or test the LMS, SIS, and Acme tool:

```sh
./dev start          # Start all applications
./dev stop           # Stop all applications
./dev reset          # Stop all, reset the LMS/SIS databases, and restart
./dev start lms      # Start only the LMS
./dev start acme     # Start only Acme's tool
./dev stop sis       # Stop only the SIS
./dev reset lms      # Reset only the LMS database and restart the LMS
./dev test           # Run tests for all applications
./dev test lms       # Run tests for only the LMS
./dev test sis       # Run tests for only the SIS
./dev test acme      # Run tests for only the Acme tool
```

The LMS runs at [http://127.0.0.1:3000](http://127.0.0.1:3000), the SIS at [http://127.0.0.1:3001](http://127.0.0.1:3001), and the Acme tool at [http://127.0.0.1:3002](http://127.0.0.1:3002). Initialize each app's database once using its README, and install each app's dependencies before starting it; the tool's dependencies are installed with `cd tools/acme && bundle install`. Starting either the LMS or Acme generates local-only LTI signing keys under the ignored `.local/lti/` directory. Starting the LMS applies pending LMS migrations and restarts its managed server if the database schema changed. The reset action deletes existing LMS/SIS development database data and reloads their seed data. Server output is written to each app's `log/root-dev-server.log`.

For the LTI demo, use `./dev start all`, sign into the LMS as `instructor`, open the seeded course section, and add the **Guess the Number** tool. Sign in as `student` and open the activity. The LMS displays the activity in the course page; launching it navigates in the same tab to the separately running Acme app. On completion, the tool submits a 100/100 score to the LMS and returns to the course.

The LTI registration is static and local, using LTI 1.3 Core launch and Assignment and Grade Services (AGS). The guess count is sent using the AGS result `comment` and saved by the LMS as structured completion data. Game state is in memory and is lost if the Acme server restarts. This is a standards demonstration, not production-ready LTI infrastructure.

# Notes

OneRoster handles background administrative data syncing (primarily between a Student Information System and downstream apps), whereas LTI handles interactive, real-time tool launches and data exchange inside a Learning Management System (LMS).

## OneRoster synchronization

The [OneRoster integration reference](docs/oneroster.md) describes the SIS-to-LMS roster flow and LMS-to-SIS gradebook flow. The root `tokens` script, loaded automatically by `./dev` and `./sync`, creates and reuses local credentials in the ignored, owner-only `.tokens` file. Start both apps and run:

```sh
./sync
```

The script waits for roster synchronization to finish before starting gradebook synchronization and stops if either operation fails.

> **Demonstration only:** The SIS-to-LMS roster sync includes SIS user passwords in the optional OneRoster `User.password` field and applies them to LMS accounts. This deliberately demonstrates password provisioning and must not be used in production. Use an identity provider/SSO integration or a secure password setup and reset flow instead.