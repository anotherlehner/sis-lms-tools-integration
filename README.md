# LMS Standards

This is an example project for demonstrating the most basic functionality and integration of a learning management system (LMS), a student information system (SIS), and external tools provided by hypothetical vendors (tools).

## Run the applications

From the repository root, use `./dev` to start, stop, reset, or test either application or both:

```sh
./dev start          # Start both applications
./dev stop           # Stop both applications
./dev reset          # Stop both, reset both development databases, and restart
./dev start lms      # Start only the LMS
./dev stop sis       # Stop only the SIS
./dev reset lms      # Reset only the LMS database and restart the LMS
./dev test           # Run tests for both applications
./dev test lms       # Run tests for only the LMS
./dev test sis       # Run tests for only the SIS
```

The LMS runs at [http://127.0.0.1:3000](http://127.0.0.1:3000) and the SIS at [http://127.0.0.1:3001](http://127.0.0.1:3001). The reset action deletes existing development database data and reloads each selected app's seed data. Server output is written to each app's `log/root-dev-server.log`.

