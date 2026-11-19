require "test_helper"
require "open3"
require "tmpdir"

class SyncScriptTest < ActiveSupport::TestCase
  SCRIPT_PATH = Rails.root.join("..", "sync").expand_path

  test "calls the LMS roster endpoint before the SIS gradebook endpoint" do
    status, output, log = run_script

    assert_predicate status, :success?
    assert_match "OneRoster synchronization completed successfully.", output
    assert_equal 2, log.lines.length
    assert_match %r{http://lms.example/sync/roster}, log.lines[0]
    assert_match %r{http://sis.example/sync/gradebook}, log.lines[1]
    assert_match "Authorization: Bearer test-control-token", log
  end

  test "does not start gradebook sync when roster sync fails" do
    status, output, log = run_script(fail_at: "1")

    refute_predicate status, :success?
    assert_match "SIS gradebook sync was not started", output
    assert_equal 1, log.lines.length
  end

  test "reports a failure from the second sync step" do
    status, output, log = run_script(fail_at: "2")

    refute_predicate status, :success?
    assert_match "SIS gradebook sync failed", output
    assert_equal 2, log.lines.length
  end

  test "requires a control token" do
    status, output, log = run_script(token: "")

    assert_equal 2, status.exitstatus
    assert_match "SYNC_CONTROL_TOKEN must be set", output
    assert_empty log
  end

  test "loads and reuses its control token from the local tokens file" do
    Dir.mktmpdir do |directory|
      token_file = File.join(directory, "tokens")
      first_status, _first_output, first_log = run_script(token: nil, token_file: token_file)
      second_status, _second_output, second_log = run_script(token: nil, token_file: token_file)

      assert_predicate first_status, :success?
      assert_predicate second_status, :success?
      assert_match %r{Authorization: Bearer [a-f0-9]{64}}, first_log
      assert_equal first_log, second_log
      assert_equal 0o600, File.stat(token_file).mode & 0o777
    end
  end

  private

  def run_script(fail_at: "", token: "test-control-token", token_file: nil)
    Dir.mktmpdir do |directory|
      curl_path = File.join(directory, "curl")
      log_path = File.join(directory, "curl.log")
      token_file ||= File.join(directory, "tokens")
      File.write(curl_path, <<~'SH')
        #!/bin/sh
        headers=$(cat)
        printf '%s|%s\n' "$*" "$headers" | tr '\n' ' ' >> "$SYNC_CURL_LOG"
        printf '\n' >> "$SYNC_CURL_LOG"
        count=$(wc -l < "$SYNC_CURL_LOG")
        if [ "$SYNC_FAIL_AT" = "$count" ]; then
          exit 22
        fi
        printf '{"status":"completed"}'
      SH
      File.chmod(0o755, curl_path)
      env = {
        "PATH" => "#{directory}:#{ENV.fetch("PATH")}",
        "SYNC_CURL_LOG" => log_path,
        "SYNC_FAIL_AT" => fail_at,
        "SYNC_CONTROL_TOKEN" => token,
        "LMS_STANDARDS_TOKENS_FILE" => token_file,
        "LMS_BASE_URL" => "http://lms.example",
        "SIS_BASE_URL" => "http://sis.example"
      }
      stdout, stderr, status = Open3.capture3(env, SCRIPT_PATH.to_s)
      log = File.exist?(log_path) ? File.read(log_path) : ""
      [status, stdout + stderr, log]
    end
  end
end
